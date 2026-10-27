package ohos_app_cangjie_eudi_cjetsi_1196x2.etsi_trust

import std.collection.ArrayList
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.ComposeChainTrust
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.VerificationContext
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation.VerifyJwtSignature
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation_platform.CachedTrustValidator
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation_platform.EudiwIosTrust
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation_platform.IosValidationResult
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation_platform.StdxCryptoJwtSignature
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation_platform.TrustListUrls

/**
 * iOS `EtsiTrustManager`. Builds either a cached LoTE validator or a bundled-
 * anchors validator and implements `CertificateTrustValidator`. When the
 * primary source has no verification context for the current `docType`,
 * `fallback` is consulted. `defaultVerificationContext` is used when no
 * doc-type mapping applies (WRPAC unless the manager is built for another
 * fixed context, e.g. WRPRC).
 */
public class EtsiTrustManager <: CertificateTrustValidator {
    public var docType: ?String = None
    private let mappings: ?EtsiContextTypeMappings
    private let fallback: ?EtsiTrustManager
    private let defaultVerificationContext: VerificationContext
    private let eval: EtsiChainEval

    public init(
        source: TrustSource,
        fallback!: ?EtsiTrustManager = None,
        defaultVerificationContext!: VerificationContext = EtsiContextType.WRPAC.verificationContext()
    ) {
        this.mappings = source.contextTypeMappings()
        this.fallback = fallback
        this.defaultVerificationContext = defaultVerificationContext
        this.eval = makeEval(source)
    }

    public func getVerificationContext(): ?VerificationContext {
        match (this.mappings) {
            case None => Some(this.defaultVerificationContext)
            case Some(map) =>
                match (this.docType) {
                    case None => Some(this.defaultVerificationContext)
                    case Some(dt) =>
                        match (map.get(dt)) {
                            case None => None
                            case Some(ctxType) => Some(ctxType.verificationContext())
                        }
                }
        }
    }

    public func createCertTrustPath(chain: Array<Array<UInt8>>): ?Array<Array<UInt8>> {
        match (this.validateInternal(chain)) {
            case None => None
            case Some(result) =>
                if (!result.isTrusted) {
                    return None
                }
                match (result.matchedAnchor) {
                    case None => Some(chain)
                    case Some(anchor) => Some(appendAnchorIfMissing(chain, anchor))
                }
        }
    }

    public func validateCertTrustPath(chain: Array<Array<UInt8>>): (Bool, ?String) {
        match (this.validateInternal(chain)) {
            case None =>
                (false, Some("Certificate chain validation could not be evaluated"))
            case Some(result) =>
                (result.isTrusted, result.failureReason)
        }
    }

    /**
     * DER anchors for the current verification context (WRPAC when mappings
     * are nil). Empty primary lists fall through to `fallback`, matching iOS
     * warning-policy + static CA behaviour. Used by wallet-kit until
     * OpenID4VP/VCI take a live validator.
     */
    public func trustAnchorsDer(): Array<Array<UInt8>> {
        match (this.getVerificationContext()) {
            case None => this.fallbackAnchorsDer()
            case Some(ctx) =>
                let ders = this.eval.trustAnchors(ctx)
                if (ders.size == 0) {
                    return this.fallbackAnchorsDer()
                }
                let out = Array<Array<UInt8>>(ders.size, repeat: Array<UInt8>())
                var i: Int64 = 0
                while (i < ders.size) {
                    out[i] = bytesToU8(ders[i])
                    i = i + 1
                }
                out
        }
    }

    private func fallbackAnchorsDer(): Array<Array<UInt8>> {
        match (this.fallback) {
            case None => Array<Array<UInt8>>()
            case Some(fb) =>
                fb.docType = this.docType
                fb.trustAnchorsDer()
        }
    }

    private func validateInternal(chain: Array<Array<UInt8>>): ?IosValidationResult {
        match (this.validatePrimary(chain)) {
            case Some(result) => Some(result)
            case None =>
                match (this.fallback) {
                    case None => None
                    case Some(fb) =>
                        fb.docType = this.docType
                        fb.validateInternal(chain)
                }
        }
    }

    private func validatePrimary(chain: Array<Array<UInt8>>): ?IosValidationResult {
        match (this.getVerificationContext()) {
            case None => None
            case Some(ctx) =>
                try {
                    let iosRes = this.eval.validate(chainToByteList(chain), ctx)
                    match (iosRes.failureReason) {
                        case Some(reason) =>
                            if (!iosRes.isTrusted && reason == "No validator configured for this context") {
                                return None
                            }
                        case None => ()
                    }
                    Some(iosRes)
                } catch (_: Exception) {
                    None
                }
        }
    }
}

interface EtsiChainEval {
    func validate(chain: ArrayList<Array<Byte>>, context: VerificationContext): IosValidationResult
    func trustAnchors(context: VerificationContext): ArrayList<Array<Byte>>
}

class CachedEtsiEval <: EtsiChainEval {
    private let inner: CachedTrustValidator

    public init(inner: CachedTrustValidator) {
        this.inner = inner
    }

    public func validate(
        chain: ArrayList<Array<Byte>>,
        context: VerificationContext
    ): IosValidationResult {
        this.inner.validate(chain, context)
    }

    public func trustAnchors(context: VerificationContext): ArrayList<Array<Byte>> {
        this.inner.trustAnchors(context)
    }
}

class BundledEtsiEval <: EtsiChainEval {
    private let inner: ComposeChainTrust<ArrayList<Array<Byte>>, VerificationContext, Array<Byte>>

    public init(inner: ComposeChainTrust<ArrayList<Array<Byte>>, VerificationContext, Array<Byte>>) {
        this.inner = inner
    }

    public func validate(
        chain: ArrayList<Array<Byte>>,
        context: VerificationContext
    ): IosValidationResult {
        EudiwIosTrust.validate(this.inner, chain, context)
    }

    public func trustAnchors(context: VerificationContext): ArrayList<Array<Byte>> {
        EudiwIosTrust.trustAnchors(this.inner, context)
    }
}

func makeEval(source: TrustSource): EtsiChainEval {
    match (source) {
        case TrustSource.Etsi(etsi) =>
            let urls = TrustListUrls()
            urls.pidProviders = etsi.pidProviders
            urls.walletProviders = etsi.walletProviders
            urls.wrpacProviders = etsi.wrpacProviders
            urls.wrprcProviders = etsi.wrprcProviders
            urls.pubEaaProviders = etsi.pubEaaProviders
            urls.qeaProviders = etsi.qeaProviders
            urls.mdlProviders = etsi.mdlProviders
            let verify: VerifyJwtSignature = match (etsi.customJwtSignatureVerifier) {
                case Some(v) => v
                case None => StdxCryptoJwtSignature(trustedSignerCertificates: ArrayList<Array<Byte>>())
            }
            CachedEtsiEval(EudiwIosTrust.cached(urls, etsi.cacheTtlHours, verify))
        case TrustSource.StaticList(staticList) =>
            BundledEtsiEval(
                EudiwIosTrust.usingBundledAnchors(staticList.bundledAnchors(), staticList.method)
            )
    }
}

func appendAnchorIfMissing(chain: Array<Array<UInt8>>, anchor: Array<Byte>): Array<Array<UInt8>> {
    for (der in chain) {
        if (derEqualU8(der, anchor)) {
            return chain
        }
    }
    let out = Array<Array<UInt8>>(chain.size + 1, repeat: Array<UInt8>())
    var i: Int64 = 0
    while (i < chain.size) {
        out[i] = chain[i]
        i = i + 1
    }
    out[chain.size] = bytesToU8(anchor)
    return out
}
