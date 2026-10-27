package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_dss

import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import std.collection.*
import std.env.*
import std.fs.*
import std.sync.*
import std.time.*
import stdx.crypto.digest.*
import stdx.net.http.*
import stdx.net.tls.TlsClientConfig

/// Dual-layer (memory TTL + file TTL) HTTP loader for LOTL/TL documents.
/// Kotlin `ConcurrentCacheDataLoader` contract without DSS `DataLoader` types.
public class ConcurrentCacheDataLoader <: Disposable {
    private let fileCacheExpiration: Duration
    private let fileCacheDirectory: Path
    private let httpCache: AsyncCache<String, Array<Byte>>
    private let mutexesLock = Mutex()
    private let mutexes = HashMap<String, Mutex>()
    private let cleanMemory: Bool
    private let cleanFileSystem: Bool
    private let trackedCacheFiles = ArrayList<Path>()
    private let fetchContext: HttpFetchContext
    private var closed: Bool = false

    public init(
        fileCacheExpiration!: Duration,
        cacheDirectory!: ?String = None,
        httpCacheTtl!: Duration,
        maxCacheSize!: Int64 = 100,
        cleanMemory!: Bool = true,
        cleanFileSystem!: Bool = true
    ) {
        if (fileCacheExpiration.compare(Duration.Zero) != Ordering.GT) {
            throw IllegalArgumentException("fileCacheExpiration must be positive")
        }
        let ctx = HttpFetchContext()
        this.fileCacheExpiration = fileCacheExpiration
        this.fileCacheDirectory = resolveCacheDir(cacheDirectory)
        this.cleanMemory = cleanMemory
        this.cleanFileSystem = cleanFileSystem
        this.fetchContext = ctx
        if (!exists(this.fileCacheDirectory)) {
            Directory.create(this.fileCacheDirectory, recursive: true)
        }
        this.httpCache = AsyncCache<String, Array<Byte>>(
            httpCacheTtl,
            maxCacheSize,
            { url: String => ctx.fetchGet(url) }
        )
    }

    public static func fromOptions(options: DssOptions): ConcurrentCacheDataLoader {
        ConcurrentCacheDataLoader(
            fileCacheExpiration: options.fileCacheExpiration,
            cacheDirectory: options.cacheDirectory,
            httpCacheTtl: options.httpCacheTtl,
            maxCacheSize: options.maxCacheSize,
            cleanMemory: options.cleanMemory,
            cleanFileSystem: options.cleanFileSystem
        )
    }

    public func get(url: String): Array<Byte> {
        this.fetch(url, false)
    }

    public func get(url: String, refresh!: Bool): Array<Byte> {
        this.fetch(url, refresh)
    }

    public func get(urlStrings: ArrayList<String>): Array<Byte> {
        if (urlStrings.size == 0) {
            throw Exception("Cannot process the GET call. List of URLs is empty!")
        }
        var lastError: ?Exception = None
        for (url in urlStrings) {
            try {
                let bytes = this.get(url)
                if (bytes.size > 0) {
                    return bytes
                }
            } catch (e: Exception) {
                lastError = e
            }
        }
        match (lastError) {
            case Some(err) => throw err
            case None => throw Exception("Cannot process the GET call. All URLs failed")
        }
    }

    public func post(url: String, content: Array<Byte>): Array<Byte> {
        this.fetchContext.fetchPost(url, content)
    }

    public func setContentType(contentType: String): Unit {
        this.fetchContext.contentType = contentType
    }

    public func getDocument(url: String): Array<Byte> {
        this.get(url)
    }

    public func getDocument(url: String, refresh!: Bool): Array<Byte> {
        this.fetch(url, refresh)
    }

    public func getDocumentFromCache(url: String): ?Array<Byte> {
        let cacheFile = this.cacheFileFor(url)
        if (!exists(cacheFile)) {
            None
        } else {
            Some(File.readFrom(cacheFile))
        }
    }

    public func remove(url: String): Bool {
        let cacheFile = this.cacheFileFor(url)
        if (!exists(cacheFile)) {
            false
        } else {
            try {
                deleteCacheFile(cacheFile)
                true
            } catch (e: Exception) {
                false
            }
        }
    }

    public func dispose(): Unit {
        synchronized(this.mutexesLock) {
            this.closed = true
        }
        if (this.cleanMemory) {
            this.httpCache.dispose()
        }
        if (this.cleanFileSystem) {
            this.deleteTrackedCacheFiles()
        }
    }

    private func deleteTrackedCacheFiles(): Unit {
        for (path in this.trackedCacheFiles) {
            try {
                if (exists(path)) {
                    remove(path)
                }
            } catch (e: Exception) {
                ()
            }
        }
    }


    private func fetch(url: String, refresh: Bool): Array<Byte> {
        let urlMutex = this.mutexFor(url)
        var result: ?Array<Byte> = None
        synchronized(urlMutex) {
            let cacheFile = this.cacheFileFor(url)
            if (!refresh) {
                match (this.readIfFresh(cacheFile)) {
                    case Some(cached) => result = cached
                    case None => ()
                }
            }
            match (result) {
                case Some(_) => ()
                case None =>
                    let bytes = this.httpCache.invoke(url)
                    if (bytes.size == 0) {
                        throw Exception("Cannot retrieve data from url [${url}]. Empty content is obtained!")
                    }
                    this.writeAtomically(cacheFile, bytes)
                    this.trackedCacheFiles.add(cacheFile)
                    result = bytes
            }
        }
        match (result) {
            case Some(bytes) => bytes
            case None => throw Exception("Cannot retrieve data from url [${url}]")
        }
    }

    private func mutexFor(url: String): Mutex {
        var found: ?Mutex = None
        synchronized(this.mutexesLock) {
            if (this.closed) {
                throw Exception("ConcurrentCacheDataLoader has been closed")
            }
            match (this.mutexes.get(url)) {
                case Some(existing) => found = existing
                case None =>
                    let created = Mutex()
                    this.mutexes.add(url, created)
                    found = created
            }
        }
        match (found) {
            case Some(m) => m
            case None => throw Exception("mutex allocation failed")
        }
    }

    private func cacheFileFor(url: String): Path {
        let filename = sha256Hex(url)
        this.fileCacheDirectory.join("cache-${filename}")
    }

    private func readIfFresh(file: Path): ?Array<Byte> {
        if (!exists(file)) {
            return None
        }
        let lastModified = FileInfo(file).lastModificationTime.toUnixTimeStamp().toMilliseconds()
        let now = DateTime.nowUTC().toUnixTimeStamp().toMilliseconds()
        if ((now - lastModified) >= this.fileCacheExpiration.toMilliseconds()) {
            None
        } else {
            Some(File.readFrom(file))
        }
    }

    private func writeAtomically(target: Path, bytes: Array<Byte>): Unit {
        let parent = this.fileCacheDirectory
        if (!exists(parent)) {
            Directory.create(parent, recursive: true)
        }
        let tmpFile = File.createTemp(parent)
        try {
            tmpFile.write(bytes)
            let tmpPath = tmpFile.info.path
            tmpFile.close()
            rename(tmpPath, to: target, overwrite: true)
        } catch (e: Exception) {
            try {
                tmpFile.close()
            } catch (ignored: Exception) {
                ()
            }
            throw e
        }
    }
}

class HttpFetchContext {
    public var contentType: ?String = None

    public func fetchGet(url: String): Array<Byte> {
        var builder = HttpRequestBuilder().get().url(url)
        match (this.contentType) {
            case Some(ct) => builder = builder.header("Content-Type", ct)
            case None => ()
        }
        sendHttpRequest(builder.build(), url)
    }

    public func fetchPost(url: String, content: Array<Byte>): Array<Byte> {
        var builder = HttpRequestBuilder().post().url(url).body(content)
        match (this.contentType) {
            case Some(ct) => builder = builder.header("Content-Type", ct)
            case None => ()
        }
        sendHttpRequest(builder.build(), url)
    }
}

func sendHttpRequest(req: HttpRequest, url: String): Array<Byte> {
    let client = ClientBuilder()
        .tlsConfig(TlsClientConfig())
        .readTimeout(Duration.second * 10)
        .writeTimeout(Duration.second * 10)
        .build()
    try {
        let resp = client.send(req)
        try {
            let status = Int64(resp.status)
            if (status < 200 || status >= 300) {
                throw Exception("Cannot retrieve data from url [${url}]. HTTP status ${status}")
            }
            let bytes = readHttpBody(resp)
            if (bytes.size == 0) {
                throw Exception("Cannot retrieve data from url [${url}]. Empty content is obtained!")
            }
            bytes
        } finally {
            resp.close()
        }
    } finally {
        client.close()
    }
}

func deleteCacheFile(path: Path): Unit {
    remove(path)
}

func resolveCacheDir(cacheDirectory: ?String): Path {
    match (cacheDirectory) {
        case Some(dir) => Path(dir)
        case None => getTempDirectory().join("consultation_dss_tl_cache")
    }
}

func readHttpBody(resp: HttpResponse): Array<Byte> {
    let chunks = ArrayList<Byte>()
    let buf = Array<Byte>(4096, repeat: 0)
    while (true) {
        let n = resp.body.read(buf)
        if (n <= 0) {
            break
        }
        var i: Int64 = 0
        while (i < n) {
            chunks.add(buf[i])
            i = i + 1
        }
    }
    Array<Byte>(chunks.size, { i => chunks[i] })
}

func sha256Hex(url: String): String {
    let digest = SHA256()
    digest.write(url.toArray())
    let hashed = digest.finish()
    let sb = StringBuilder()
    var i: Int64 = 0
    while (i < hashed.size) {
        sb.append(hexByte(hashed[i]))
        i = i + 1
    }
    sb.toString()
}

func hexByte(b: Byte): String {
    let n = Int64(b) & 0xFF
    "${hexDigit(n / 16)}${hexDigit(n % 16)}"
}

func hexDigit(n: Int64): String {
    match (n) {
        case 0 => "0"
        case 1 => "1"
        case 2 => "2"
        case 3 => "3"
        case 4 => "4"
        case 5 => "5"
        case 6 => "6"
        case 7 => "7"
        case 8 => "8"
        case 9 => "9"
        case 10 => "a"
        case 11 => "b"
        case 12 => "c"
        case 13 => "d"
        case 14 => "e"
        case 15 => "f"
        case _ => "0"
    }
}
