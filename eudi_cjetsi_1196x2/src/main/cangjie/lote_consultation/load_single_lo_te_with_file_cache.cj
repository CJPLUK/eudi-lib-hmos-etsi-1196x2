package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation

import std.fs.*
import std.sync.*
import std.time.*
import stdx.encoding.json.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model.*

public class LoTEFileMetadata {
    public let loadedAtMs: Int64
    public let expiresAtMs: Int64
    public let nextUpdateMs: Option<Int64>

    public init(loadedAtMs: Int64, expiresAtMs: Int64, nextUpdateMs: Option<Int64>) {
        this.loadedAtMs = loadedAtMs
        this.expiresAtMs = expiresAtMs
        this.nextUpdateMs = nextUpdateMs
    }

    public func toJson(): String {
        let obj = JsonObject()
        obj.put("loaded_at", JsonInt(this.loadedAtMs))
        obj.put("expires_at", JsonInt(this.expiresAtMs))
        match (this.nextUpdateMs) {
            case Some(ms) => obj.put("next_update", JsonInt(ms))
            case None => ()
        }
        obj.toString()
    }

    public static func fromJson(json: String): Option<LoTEFileMetadata> {
        try {
            let root = JsonValue.fromStr(json).asObject()
            let loaded = JsonFields.requireInt(root, "loaded_at")
            let expires = JsonFields.requireInt(root, "expires_at")
            let next: Option<Int64> = JsonFields.optionalInt(root, "next_update")
            Some(LoTEFileMetadata(loaded, expires, next))
        } catch (ignored: Exception) {
            None
        }
    }
}

class StoredLoTE {
    public let jwt: String
    public let metadata: LoTEFileMetadata

    public init(jwt: String, metadata: LoTEFileMetadata) {
        this.jwt = jwt
        this.metadata = metadata
    }
}

/// Cache-aside LoTE loader: file cache first, then optional HTTP download.
public class LoadSingleLoTEWithFileCache <: LoadLoTE {
    private let cacheDirectory: Path
    private let downloadSingleLoTE: Option<DownloadSingleLoTE>
    private let fileCacheExpiration: Duration
    private let parseJwt: ParseJwt
    private let mutex = Mutex()

    public init(
        cacheDirectory: String,
        downloadSingleLoTE!: Option<DownloadSingleLoTE> = None,
        fileCacheExpiration!: Duration = Duration.day
    ) {
        this.cacheDirectory = Path(cacheDirectory)
        this.downloadSingleLoTE = downloadSingleLoTE
        this.fileCacheExpiration = fileCacheExpiration
        this.parseJwt = ParseJwt()
        this.ensureCacheDirectory()
    }

    public func invoke(uri: Uri): LoadLoTEOutcome {
        var outcome: ?LoadLoTEOutcome = None
        synchronized(this.mutex) {
            outcome = Some(consultationPlatform().runIo({ =>
                this.loadLocked(uri)
            }))
        }
        match (outcome) {
            case Some(value) => value
            case None => throw IllegalStateException("LoTE cache load did not produce an outcome")
        }
    }

    public func delete(uri: Uri): Unit {
        synchronized(this.mutex) {
            let jwtPath = this.jwtPath(uri)
            let metaPath = this.metaPath(uri)
            if (exists(jwtPath)) {
                remove(jwtPath)
            }
            if (exists(metaPath)) {
                remove(metaPath)
            }
        }
    }

    public func clear(): Unit {
        synchronized(this.mutex) {
            if (exists(this.cacheDirectory)) {
                remove(this.cacheDirectory, recursive: true)
            }
            Directory.create(this.cacheDirectory, recursive: true)
        }
    }

    private func loadLocked(uri: Uri): LoadLoTEOutcome {
        match (this.readCache(uri)) {
            case Some(stored) =>
                let now = currentEpochMs()
                if (now < stored.metadata.expiresAtMs) {
                    return LoadLoTEOutcome.Loaded(stored.jwt)
                }
            case None => ()
        }
        match (this.downloadSingleLoTE) {
            case Some(downloader) => this.downloadAndStore(downloader, uri)
            case None => LoadLoTEOutcome.NotFound(None)
        }
    }

    private func downloadAndStore(downloader: DownloadSingleLoTE, uri: Uri): LoadLoTEOutcome {
        match (downloader.invoke(uri)) {
            case LoadLoTEOutcome.Loaded(jwt) =>
                let metadata = this.createMetadata(jwt)
                this.writeCache(uri, jwt, metadata)
                LoadLoTEOutcome.Loaded(jwt)
            case LoadLoTEOutcome.NotFound(cause) => LoadLoTEOutcome.NotFound(cause)
        }
    }

    private func createMetadata(jwt: String): LoTEFileMetadata {
        let loadedAt = currentEpochMs()
        var nextUpdate: Option<Int64> = None
        match (this.parseJwt.invoke(jwt)) {
            case ParseJwtOutcome.Parsed(_, claims) =>
                try {
                    let parsed = DateTime.parse(claims.listOfTrustedEntities.schemeInformation.nextUpdate.isoValue)
                    nextUpdate = Some(parsed.toUnixTimeStamp().toMilliseconds())
                } catch (ignored: Exception) {
                    nextUpdate = None
                }
            case ParseJwtOutcome.ParseFailed(_) => ()
        }
        let ttlMs = this.fileCacheExpiration.toMilliseconds()
        let expiresAt = match (nextUpdate) {
            case Some(nextMs) =>
                if (nextMs > loadedAt) {
                    nextMs
                } else {
                    loadedAt + ttlMs
                }
            case None => loadedAt + ttlMs
        }
        LoTEFileMetadata(loadedAt, expiresAt, nextUpdate)
    }

    private func readCache(uri: Uri): Option<StoredLoTE> {
        let jwtPath = this.jwtPath(uri)
        let metaPath = this.metaPath(uri)
        if (!exists(jwtPath) || !exists(metaPath)) {
            return None
        }
        try {
            let jwt = String.fromUtf8(File.readFrom(jwtPath))
            match (LoTEFileMetadata.fromJson(String.fromUtf8(File.readFrom(metaPath)))) {
                case Some(metadata) => Some(StoredLoTE(jwt, metadata))
                case None => None
            }
        } catch (ignored: Exception) {
            None
        }
    }

    private func writeCache(uri: Uri, jwt: String, metadata: LoTEFileMetadata): Unit {
        try {
            this.ensureCacheDirectory()
            File.writeTo(this.jwtPath(uri), jwt.toArray())
            File.writeTo(this.metaPath(uri), metadata.toJson().toArray())
        } catch (ignored: Exception) {
            ()
        }
    }

    private func ensureCacheDirectory(): Unit {
        if (!exists(this.cacheDirectory)) {
            Directory.create(this.cacheDirectory, recursive: true)
        }
    }

    private func jwtPath(uri: Uri): Path {
        this.cacheDirectory.join("${uriToFilename(uri)}.jwt")
    }

    private func metaPath(uri: Uri): Path {
        this.cacheDirectory.join("${uriToFilename(uri)}.meta.json")
    }
}

func currentEpochMs(): Int64 {
    DateTime.nowUTC().toUnixTimeStamp().toMilliseconds()
}

func uriToFilename(uri: Uri): String {
    uri.value.replace(":", "_").replace("/", "_").replace("?", "_").replace("&", "_").replace("=", "_")
}
