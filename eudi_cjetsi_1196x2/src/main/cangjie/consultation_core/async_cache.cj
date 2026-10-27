package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

import std.collection.*
import std.sync.*
import std.time.*

class CacheEntry<B> {
    public let future: Future<B>
    public let createdAtMs: Int64
    public let generation: Int64

    public init(future: Future<B>, createdAtMs: Int64, generation: Int64) {
        this.future = future
        this.createdAtMs = createdAtMs
        this.generation = generation
    }
}

/// In-memory TTL cache with mutex-protected LRU eviction.
/// Same-key requests share one `spawn` Future; `Future.get()` waits outside the lock
/// so other keys are not blocked (Kotlin Deferred-outside-lock).
public class AsyncCache<A, B> <: Disposable where A <: Equatable<A> & Hashable {
    private let clockNowMs: () -> Int64
    private let ttl: Duration
    private let maxCacheSize: Int64
    private let supplier: (A) -> B
    private let mutex = Mutex()
    private let cache = HashMap<A, CacheEntry<B>>()
    private var nextGeneration: Int64 = 0
    private var closed: Bool = false

    public init(
        ttl: Duration,
        maxCacheSize: Int64,
        supplier: (A) -> B
    ) {
        this.clockNowMs = { => DateTime.nowUTC().toUnixTimeStamp().toMilliseconds() }
        this.ttl = ttl
        this.maxCacheSize = maxCacheSize
        this.supplier = supplier
    }

    public init(
        clockNowMs: () -> Int64,
        ttl: Duration,
        maxCacheSize: Int64,
        supplier: (A) -> B
    ) {
        this.clockNowMs = clockNowMs
        this.ttl = ttl
        this.maxCacheSize = maxCacheSize
        this.supplier = supplier
    }

    public func invoke(key: A): B {
        let ttlMs = this.ttl.toMilliseconds()
        var pending: ?CacheEntry<B> = None
        synchronized(this.mutex) {
            if (this.closed) {
                throw Exception("AsyncCache has been closed")
            }
            let now = this.clockNowMs()
            match (this.cache.get(key)) {
                case Some(existing) =>
                    if ((now - existing.createdAtMs) < ttlMs) {
                        this.cache.remove(key)
                        this.cache.add(key, existing)
                        pending = existing
                    } else {
                        this.cache.remove(key)
                    }
                case None => ()
            }
            match (pending) {
                case Some(_) => ()
                case None =>
                    if (this.cache.size >= this.maxCacheSize && !this.cache.contains(key)) {
                        var eldest: ?A = None
                        for ((k, _) in this.cache) {
                            match (eldest) {
                                case None => eldest = k
                                case Some(_) => ()
                            }
                        }
                        match (eldest) {
                            case Some(oldKey) => let _ = this.cache.remove(oldKey)
                            case None => ()
                        }
                    }
                    let compute = this.supplier
                    let capturedKey = key
                    let fut = spawn { => compute(capturedKey) }
                    let generation = this.nextGeneration + 1
                    this.nextGeneration = generation
                    let entry = CacheEntry<B>(fut, now, generation)
                    this.cache.add(key, entry)
                    pending = entry
            }
        }
        match (pending) {
            case Some(entry) =>
                try {
                    entry.future.get()
                } catch (e: Exception) {
                    this.handleFailure(key, entry)
                    throw e
                }
            case None => throw Exception("AsyncCache produced no value")
        }
    }

    private func handleFailure(key: A, failed: CacheEntry<B>): Unit {
        synchronized(this.mutex) {
            match (this.cache.get(key)) {
                case Some(current) =>
                    if (current.generation == failed.generation) {
                        this.cache.remove(key)
                    }
                case None => ()
            }
        }
    }

    public func dispose(): Unit {
        let toCancel = ArrayList<Future<B>>()
        synchronized(this.mutex) {
            this.closed = true
            for ((_, entry) in this.cache) {
                toCancel.add(entry.future)
            }
            this.cache.clear()
        }
        for (fut in toCancel) {
            fut.cancel()
        }
    }
}
