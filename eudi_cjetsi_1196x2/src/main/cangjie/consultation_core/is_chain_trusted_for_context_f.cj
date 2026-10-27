package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

/// Checks whether a certificate chain is trusted for a verification context.
/// A null / None result means the context is not configured.
public interface IsChainTrustedForContextF<CHAIN, CTX, TRUST_ANCHOR> {
    func invoke(chain: CHAIN, verificationContext: CTX): ?CertificationChainValidation<TRUST_ANCHOR>
}
