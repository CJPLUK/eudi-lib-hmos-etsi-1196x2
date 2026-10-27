package ohos_app_cangjie_eudi_cjetsi_1196x2.etsi_trust

import std.collection.HashMap
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.VerificationContext

/**
 * iOS `TrustConfiguration` (wallet-kit) minus OpenID4VCI `issuerMetadataPolicy`,
 * which wallet-kit derives from `accessTrustManager` + `requireSignedMetadata`.
 *
 * Builds three managers:
 *   - issuer: doc-type mappings (default PID/mDL) + optional static fallback
 *   - access: same LoTE/static source with mappings cleared (WRPAC)
 *   - registration: same LoTE/static source with mappings cleared (WRPRC)
 */
public class TrustConfiguration {
    public let defaultPolicy: TrustPolicy
    public let docTypePolicies: HashMap<String, TrustPolicy>
    public let requireSignedMetadata: Bool
    public let statusTrustPolicy: TrustPolicy
    public let wrprcVpTrustPolicy: TrustPolicy
    public let wrprcVciTrustPolicy: TrustPolicy
    public let clockSkewSeconds: Float64
    public let issuerTrustManager: EtsiTrustManager
    public let accessTrustManager: EtsiTrustManager
    public let registrationTrustManager: EtsiTrustManager

    public init(
        trustSource: TrustSource,
        fallbackTrustSource!: ?TrustSource = None,
        defaultPolicy!: TrustPolicy = TrustPolicy.Enforce,
        docTypePolicies!: HashMap<String, TrustPolicy> = HashMap<String, TrustPolicy>(),
        requireSignedMetadata!: Bool = true,
        statusTrustPolicy!: TrustPolicy = TrustPolicy.Enforce,
        wrprcVpTrustPolicy!: TrustPolicy = TrustPolicy.Warning,
        wrprcVciTrustPolicy!: TrustPolicy = TrustPolicy.Enforce,
        clockSkewSeconds!: Float64 = 60.0
    ) {
        this.defaultPolicy = defaultPolicy
        this.docTypePolicies = docTypePolicies
        this.requireSignedMetadata = requireSignedMetadata
        this.statusTrustPolicy = statusTrustPolicy
        this.wrprcVpTrustPolicy = wrprcVpTrustPolicy
        this.wrprcVciTrustPolicy = wrprcVciTrustPolicy
        this.clockSkewSeconds = clockSkewSeconds
        let issuerSource = match (trustSource.contextTypeMappings()) {
            case None => trustSource.withContextTypeMappings(Some(defaultEtsiContextTypeMappings()))
            case Some(_) => trustSource
        }
        let fallbackMgr: ?EtsiTrustManager = match (fallbackTrustSource) {
            case None => None
            case Some(fts) =>
                let mapped = match (fts.contextTypeMappings()) {
                    case None => fts.withContextTypeMappings(Some(defaultEtsiContextTypeMappings()))
                    case Some(_) => fts
                }
                Some(EtsiTrustManager(mapped))
        }
        this.issuerTrustManager = EtsiTrustManager(issuerSource, fallback: fallbackMgr)
        let wrpacContext = EtsiContextType.WRPAC.verificationContext()
        let accessFallback: ?EtsiTrustManager = match (fallbackTrustSource) {
            case None => None
            case Some(fts) => Some(EtsiTrustManager(
                fts.withContextTypeMappings(None),
                defaultVerificationContext: wrpacContext
            ))
        }
        this.accessTrustManager = EtsiTrustManager(
            trustSource.withContextTypeMappings(None),
            fallback: accessFallback,
            defaultVerificationContext: wrpacContext
        )
        let wrprcContext = EtsiContextType.WRPRC.verificationContext()
        let registrationFallback: ?EtsiTrustManager = match (fallbackTrustSource) {
            case None => None
            case Some(fts) => Some(EtsiTrustManager(
                fts.withContextTypeMappings(None),
                defaultVerificationContext: wrprcContext
            ))
        }
        this.registrationTrustManager = EtsiTrustManager(
            trustSource.withContextTypeMappings(None),
            fallback: registrationFallback,
            defaultVerificationContext: wrprcContext
        )
    }

    public func policyFor(docType: String): TrustPolicy {
        match (this.docTypePolicies.get(docType)) {
            case Some(p) => p
            case None => this.defaultPolicy
        }
    }
}
