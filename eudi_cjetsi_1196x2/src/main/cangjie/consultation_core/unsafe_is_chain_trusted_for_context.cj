package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

/// Sensitive recovery wrapper: if primary returns NotTrusted, try a fallback validator.
public class UnsafeIsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR> <:
    IsChainTrustedForContextF<CHAIN, CTX, TRUST_ANCHOR> where CTX <: Equatable<CTX> {
    private let primary: ComposeChainTrust<CHAIN, CTX, TRUST_ANCHOR>
    private let recovery: (CTX, String) -> ?IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR>

    public init(
        primary: ComposeChainTrust<CHAIN, CTX, TRUST_ANCHOR>,
        recovery: (CTX, String) -> ?IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR>
    ) {
        this.primary = primary
        this.recovery = recovery
    }

    public func invoke(chain: CHAIN, verificationContext: CTX): ?CertificationChainValidation<TRUST_ANCHOR> {
        match (this.primary.invoke(chain, verificationContext)) {
            case None => None
            case Some(validation) =>
                match (validation) {
                    case CertificationChainValidation.Trusted(_) => Some(validation)
                    case CertificationChainValidation.NotTrusted(cause) =>
                        this.tryToRecover(chain, verificationContext, cause)
                }
        }
    }

    private func tryToRecover(
        chain: CHAIN,
        verificationContext: CTX,
        cause: String
    ): ?CertificationChainValidation<TRUST_ANCHOR> {
        match (this.recovery(verificationContext, cause)) {
            case None => None
            case Some(fallback) => fallback.invoke(chain, verificationContext)
        }
    }
}
