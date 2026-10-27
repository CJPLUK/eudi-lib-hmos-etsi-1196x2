package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

import std.collection.*
import std.sync.*

/// A resource that can be released.
public interface Disposable {
    func dispose(): Unit
}

/// A scope that binds disposable resources and releases them together.
public interface DisposableScope <: Disposable {
    func bind<T>(resource: T): T where T <: Disposable
}

/// Executes `block` and disposes every resource bound inside the scope.
public func useResources<T>(block: (DisposableScope) -> T): T {
    let scope = DisposableContainer()
    try {
        block(scope)
    } finally {
        scope.dispose()
    }
}

/// Collects disposables and releases them in reverse registration order.
public open class DisposableContainer <: DisposableScope {
    private let mutex = Mutex()
    private let resources = ArrayList<Disposable>()
    private var disposed: Bool = false

    public func add(disposable: Disposable): Unit {
        synchronized(this.mutex) {
            if (this.disposed) {
                disposable.dispose()
            } else {
                this.resources.add(disposable)
            }
        }
    }

    public func bind<T>(resource: T): T where T <: Disposable {
        this.add(resource)
        resource
    }

    public func dispose(): Unit {
        let toDispose = ArrayList<Disposable>()
        synchronized(this.mutex) {
            if (this.disposed) {
                return
            }
            this.disposed = true
            for (item in this.resources) {
                toDispose.add(item)
            }
            this.resources.clear()
        }
        var primary: ?Exception = None
        var i = toDispose.size - 1
        while (i >= 0) {
            try {
                toDispose[i].dispose()
            } catch (e: Exception) {
                match (primary) {
                    case None => primary = e
                    case Some(_) => ()
                }
            }
            i = i - 1
        }
        match (primary) {
            case Some(err) => throw err
            case None => ()
        }
    }
}
