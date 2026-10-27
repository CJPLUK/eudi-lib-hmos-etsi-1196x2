package ohos_app_cangjie_eudi_cjetsi_1196x2.etsi_trust

import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation.VerifyJwtSignature

/**
 * iOS `EtsiTrustSource` — LoTE download locations and cache TTL. The manager
 * builds `EudiwIosTrust.cached` from this; the wallet app does not flatten
 * certificates itself.
 */
public class EtsiTrustSource {
    public static let defaultCacheTtlHours: Float64 = 24.0

    public let pidProviders: ?String
    public let walletProviders: ?String
    public let wrpacProviders: ?String
    public let wrprcProviders: ?String
    public let pubEaaProviders: ?String
    public let qeaProviders: ?String
    public let mdlProviders: ?String
    public let contextTypeMappings: ?EtsiContextTypeMappings
    public let cacheTtlHours: Float64
    public let customJwtSignatureVerifier: ?VerifyJwtSignature

    public init(
        pidProviders!: ?String = None,
        walletProviders!: ?String = None,
        wrpacProviders!: ?String = None,
        wrprcProviders!: ?String = None,
        pubEaaProviders!: ?String = None,
        qeaProviders!: ?String = None,
        mdlProviders!: ?String = None,
        contextTypeMappings!: ?EtsiContextTypeMappings = None,
        cacheTtlHours!: Float64 = EtsiTrustSource.defaultCacheTtlHours,
        customJwtSignatureVerifier!: ?VerifyJwtSignature = None
    ) {
        this.pidProviders = pidProviders
        this.walletProviders = walletProviders
        this.wrpacProviders = wrpacProviders
        this.wrprcProviders = wrprcProviders
        this.pubEaaProviders = pubEaaProviders
        this.qeaProviders = qeaProviders
        this.mdlProviders = mdlProviders
        this.contextTypeMappings = contextTypeMappings
        this.cacheTtlHours = cacheTtlHours
        this.customJwtSignatureVerifier = customJwtSignatureVerifier
    }

    public func withContextTypeMappings(mappings: ?EtsiContextTypeMappings): EtsiTrustSource {
        EtsiTrustSource(
            pidProviders: this.pidProviders,
            walletProviders: this.walletProviders,
            wrpacProviders: this.wrpacProviders,
            wrprcProviders: this.wrprcProviders,
            pubEaaProviders: this.pubEaaProviders,
            qeaProviders: this.qeaProviders,
            mdlProviders: this.mdlProviders,
            contextTypeMappings: mappings,
            cacheTtlHours: this.cacheTtlHours,
            customJwtSignatureVerifier: this.customJwtSignatureVerifier
        )
    }
}
