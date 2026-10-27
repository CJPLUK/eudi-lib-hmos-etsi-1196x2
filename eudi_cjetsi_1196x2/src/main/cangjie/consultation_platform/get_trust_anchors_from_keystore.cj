package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_platform

import std.collection.*
import std.regex.*
import stdx.crypto.x509.X509Certificate
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*

/// Alias-to-DER map. OHOS stand-in for java.security.KeyStore trusted-cert entries.
public class AliasDerStore {
    public let entries: HashMap<String, Array<Byte>>

    public init(entries: HashMap<String, Array<Byte>>) {
        this.entries = entries
    }

    public init() {
        this.entries = HashMap<String, Array<Byte>>()
    }

    public func put(alias: String, der: Array<Byte>): Unit {
        this.entries.add(alias, der)
    }

    public func putPem(alias: String, pem: String): Unit {
        let certs = X509Certificate.decodeFromPem(pem)
        if (certs.size == 0) {
            throw IllegalArgumentException("No certificate in PEM for alias ${alias}")
        }
        this.entries.add(alias, certs[0].encodeToDer().body)
    }
}

/// GetTrustAnchors backed by an alias/DER store. Query is a Regex over aliases,
/// matching JVM GetTrustAnchorsFromKeystore.
public class GetTrustAnchorsFromKeystore <: GetTrustAnchors<Regex, Array<Byte>> {
    private let store: AliasDerStore
    private let platform: ConsultationPlatform

    public init(store: AliasDerStore, platform: ConsultationPlatform) {
        this.store = store
        this.platform = platform
    }

    public init(store: AliasDerStore) {
        this.store = store
        this.platform = consultationPlatform()
    }

    public func invoke(query: Regex): ?NonEmptyList<Array<Byte>> {
        this.platform.runIo({ =>
            let matched = ArrayList<Array<Byte>>()
            for ((alias, der) in this.store.entries) {
                if (aliasEntireMatch(query, alias)) {
                    matched.add(der)
                }
            }
            NonEmptyList<Array<Byte>>.nelOrNull(matched)
        })
    }
}

public func usingKeyStore<CTX>(
    store: AliasDerStore,
    supportedVerificationContexts: ArrayList<CTX>,
    validateCertificateChain: ValidateCertificateChain<ArrayList<Array<Byte>>, Array<Byte>>,
    regexPerVerificationContext: (CTX) -> Regex
): IsChainTrustedForContext<ArrayList<Array<Byte>>, CTX, Array<Byte>> where CTX <: Equatable<CTX> & Hashable {
    let transformation = HashMap<CTX, Regex>()
    for (ctx in supportedVerificationContexts) {
        transformation.add(ctx, regexPerVerificationContext(ctx))
    }
    validatorForQueryMap(
        GetTrustAnchorsFromKeystore(store),
        transformation,
        validateCertificateChain
    )
}

func aliasEntireMatch(query: Regex, alias: String): Bool {
    match (query.find(alias, group: true)) {
        case None => false
        case Some(md) =>
            let pos = md.matchPosition()
            pos.start == 0 && pos.end == alias.size
    }
}
