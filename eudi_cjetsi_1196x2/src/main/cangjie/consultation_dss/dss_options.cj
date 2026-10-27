package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_dss

import std.time.*

/// Cache and freshness options for the native LOTL/TL loader.
/// Mirrors Kotlin `DssOptions` observable fields (TTL, cache dir, clean flags,
/// expiration acceptance). Does not wrap Java DSS loader types.
public class DssOptions {
    public let fileCacheExpiration: Duration
    public let cacheDirectory: ?String
    public let cleanMemory: Bool
    public let cleanFileSystem: Bool
    public let acceptExpiredTrustedList: Bool
    public let acceptInvalidTrustedList: Bool
    public let acceptExpiredListOfTrustedLists: Bool
    public let acceptInvalidListOfTrustedLists: Bool
    public let httpCacheTtl: Duration
    public let maxCacheSize: Int64

    public static let DEFAULT_CLEAN_MEMORY: Bool = true
    public static let DEFAULT_CLEAN_FILE_SYSTEM: Bool = true

    public init(
        fileCacheExpiration!: Duration,
        cacheDirectory!: ?String,
        cleanMemory!: Bool,
        cleanFileSystem!: Bool,
        acceptExpiredTrustedList!: Bool,
        acceptInvalidTrustedList!: Bool,
        acceptExpiredListOfTrustedLists!: Bool,
        acceptInvalidListOfTrustedLists!: Bool,
        httpCacheTtl!: Duration,
        maxCacheSize!: Int64
    ) {
        this.fileCacheExpiration = fileCacheExpiration
        this.cacheDirectory = cacheDirectory
        this.cleanMemory = cleanMemory
        this.cleanFileSystem = cleanFileSystem
        this.acceptExpiredTrustedList = acceptExpiredTrustedList
        this.acceptInvalidTrustedList = acceptInvalidTrustedList
        this.acceptExpiredListOfTrustedLists = acceptExpiredListOfTrustedLists
        this.acceptInvalidListOfTrustedLists = acceptInvalidListOfTrustedLists
        this.httpCacheTtl = httpCacheTtl
        this.maxCacheSize = maxCacheSize
    }

    public static func defaultFileCacheExpiration(): Duration {
        24 * Duration.hour
    }

    public static func defaultHttpCacheTtl(): Duration {
        5 * Duration.second
    }

    /// Kotlin `DssOptions.Default` / `usingFileCacheDataLoader` with the same
    /// defaults: 24h file TTL, temp cache dir, clean memory/fs, reject expired
    /// and invalid lists.
    public static func usingFileCacheDataLoader(
        fileCacheExpiration!: Duration,
        cacheDirectory!: ?String = None,
        cleanMemory!: Bool = true,
        cleanFileSystem!: Bool = true,
        acceptExpiredTrustedList!: Bool = false,
        acceptInvalidTrustedList!: Bool = false,
        acceptExpiredListOfTrustedLists!: Bool = false,
        acceptInvalidListOfTrustedLists!: Bool = false,
        httpCacheTtl!: Duration,
        maxCacheSize!: Int64 = 100
    ): DssOptions {
        DssOptions(
            fileCacheExpiration: fileCacheExpiration,
            cacheDirectory: cacheDirectory,
            cleanMemory: cleanMemory,
            cleanFileSystem: cleanFileSystem,
            acceptExpiredTrustedList: acceptExpiredTrustedList,
            acceptInvalidTrustedList: acceptInvalidTrustedList,
            acceptExpiredListOfTrustedLists: acceptExpiredListOfTrustedLists,
            acceptInvalidListOfTrustedLists: acceptInvalidListOfTrustedLists,
            httpCacheTtl: httpCacheTtl,
            maxCacheSize: maxCacheSize
        )
    }

    public static func Default(): DssOptions {
        usingFileCacheDataLoader(
            fileCacheExpiration: defaultFileCacheExpiration(),
            httpCacheTtl: defaultHttpCacheTtl()
        )
    }
}
