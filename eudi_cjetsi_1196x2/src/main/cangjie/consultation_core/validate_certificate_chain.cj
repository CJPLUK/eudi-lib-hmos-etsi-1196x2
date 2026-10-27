package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

import std.collection.*

/// Outcome of validating a certificate chain against trust anchors.
public enum CertificationChainValidation<TRUST_ANCHOR> {
    | Trusted(TRUST_ANCHOR)
    | NotTrusted(String)
}

public func chainIsTrusted<TRUST_ANCHOR>(
    result: CertificationChainValidation<TRUST_ANCHOR>
): Bool {
    match (result) {
        case CertificationChainValidation.Trusted(_) => true
        case CertificationChainValidation.NotTrusted(_) => false
    }
}

/// Validates a certificate chain given a non-empty set of trust anchors.
public interface ValidateCertificateChain<CHAIN, TRUST_ANCHOR> {
    func invoke(chain: CHAIN, trustAnchors: NonEmptyList<TRUST_ANCHOR>): CertificationChainValidation<TRUST_ANCHOR>
}

/// PKIX path-validation engine. Implemented later by consultation_platform
/// using stdx.crypto.x509 — not Java DSS and not iOS SecTrust.
public interface ValidateCertificateChainUsingPKIX<CHAIN, TRUST_ANCHOR> <: ValidateCertificateChain<CHAIN, TRUST_ANCHOR> {
}

public class LambdaValidateCertificateChain<CHAIN, TRUST_ANCHOR> <: ValidateCertificateChain<CHAIN, TRUST_ANCHOR> {
    private let fn: (CHAIN, NonEmptyList<TRUST_ANCHOR>) -> CertificationChainValidation<TRUST_ANCHOR>

    public init(fn: (CHAIN, NonEmptyList<TRUST_ANCHOR>) -> CertificationChainValidation<TRUST_ANCHOR>) {
        this.fn = fn
    }

    public func invoke(
        chain: CHAIN,
        trustAnchors: NonEmptyList<TRUST_ANCHOR>
    ): CertificationChainValidation<TRUST_ANCHOR> {
        this.fn(chain, trustAnchors)
    }
}

/// Direct-trust validator: the chain is trusted iff the head certificate id
/// equals a trust-anchor id.
public class ValidateCertificateChainUsingDirectTrust<CHAIN, TRUST_ANCHOR, CERT_ID> <:
    ValidateCertificateChain<CHAIN, TRUST_ANCHOR> where CERT_ID <: Equatable<CERT_ID> {
    private let headCertificateId: (CHAIN) -> CERT_ID
    private let trustToCertificateId: (TRUST_ANCHOR) -> CERT_ID

    public init(
        headCertificateId: (CHAIN) -> CERT_ID,
        trustToCertificateId: (TRUST_ANCHOR) -> CERT_ID
    ) {
        this.headCertificateId = headCertificateId
        this.trustToCertificateId = trustToCertificateId
    }

    public func invoke(
        chain: CHAIN,
        trustAnchors: NonEmptyList<TRUST_ANCHOR>
    ): CertificationChainValidation<TRUST_ANCHOR> {
        let head = this.headCertificateId(chain)
        var i: Int64 = 0
        while (i < trustAnchors.size()) {
            let anchor = trustAnchors.get(i)
            if (this.trustToCertificateId(anchor) == head) {
                return CertificationChainValidation.Trusted(anchor)
            }
            i = i + 1
        }
        CertificationChainValidation.NotTrusted("Not trusted")
    }
}

public class ValidateCertificateChainContraMap<C1, C2, TA> <: ValidateCertificateChain<C2, TA> {
    private let delegate: ValidateCertificateChain<C1, TA>
    private let transform: (C2) -> C1

    public init(delegate: ValidateCertificateChain<C1, TA>, transform: (C2) -> C1) {
        this.delegate = delegate
        this.transform = transform
    }

    public func invoke(chain: C2, trustAnchors: NonEmptyList<TA>): CertificationChainValidation<TA> {
        this.delegate.invoke(this.transform(chain), trustAnchors)
    }
}

public func contraMapValidateCertificateChain<C1, C2, TA>(
    validator: ValidateCertificateChain<C1, TA>,
    transform: (C2) -> C1
): ValidateCertificateChain<C2, TA> {
    ValidateCertificateChainContraMap<C1, C2, TA>(validator, transform)
}

public class ValidateCertificateChainUsingAlternatives<CHAIN, TRUST_ANCHOR> <:
    ValidateCertificateChain<CHAIN, TRUST_ANCHOR> {
    private let primary: ValidateCertificateChain<CHAIN, TRUST_ANCHOR>
    private let alternative: ValidateCertificateChain<CHAIN, TRUST_ANCHOR>

    public init(
        primary: ValidateCertificateChain<CHAIN, TRUST_ANCHOR>,
        alternative: ValidateCertificateChain<CHAIN, TRUST_ANCHOR>
    ) {
        this.primary = primary
        this.alternative = alternative
    }

    public func invoke(
        chain: CHAIN,
        trustAnchors: NonEmptyList<TRUST_ANCHOR>
    ): CertificationChainValidation<TRUST_ANCHOR> {
        let first = this.primary.invoke(chain, trustAnchors)
        match (first) {
            case CertificationChainValidation.Trusted(_) => first
            case CertificationChainValidation.NotTrusted(_) => this.alternative.invoke(chain, trustAnchors)
        }
    }
}

public func orValidateCertificateChain<CHAIN, TRUST_ANCHOR>(
    primary: ValidateCertificateChain<CHAIN, TRUST_ANCHOR>,
    alternative: ValidateCertificateChain<CHAIN, TRUST_ANCHOR>
): ValidateCertificateChain<CHAIN, TRUST_ANCHOR> {
    ValidateCertificateChainUsingAlternatives<CHAIN, TRUST_ANCHOR>(primary, alternative)
}

public class ValidateCertificateChainWithEndEntityProfile<CHAIN, TRUST_ANCHOR, CERT> <:
    ValidateCertificateChain<CHAIN, TRUST_ANCHOR> {
    private let primary: ValidateCertificateChain<CHAIN, TRUST_ANCHOR>
    private let endEntityCertificateProfile: CertificateProfile
    private let certificateProfileValidator: CertificateProfileValidator<CERT>
    private let endEntityCertificateOf: (CHAIN) -> CERT

    public init(
        primary: ValidateCertificateChain<CHAIN, TRUST_ANCHOR>,
        endEntityCertificateProfile: CertificateProfile,
        certificateProfileValidator: CertificateProfileValidator<CERT>,
        endEntityCertificateOf: (CHAIN) -> CERT
    ) {
        this.primary = primary
        this.endEntityCertificateProfile = endEntityCertificateProfile
        this.certificateProfileValidator = certificateProfileValidator
        this.endEntityCertificateOf = endEntityCertificateOf
    }

    public func invoke(
        chain: CHAIN,
        trustAnchors: NonEmptyList<TRUST_ANCHOR>
    ): CertificationChainValidation<TRUST_ANCHOR> {
        let endEntityCertificate = this.endEntityCertificateOf(chain)
        let evaluation = this.certificateProfileValidator.validate(
            this.endEntityCertificateProfile,
            endEntityCertificate
        )
        match (evaluation) {
            case CertificateConstraintEvaluation.Met =>
                this.primary.invoke(chain, trustAnchors)
            case CertificateConstraintEvaluation.Violated(items) =>
                var msg = "End-entity Certificate violates constraints: "
                var first = true
                for (item in items) {
                    if (!first) {
                        msg = msg + "\n"
                    }
                    msg = msg + item.reason
                    first = false
                }
                CertificationChainValidation.NotTrusted(msg)
        }
    }
}

public func withEndEntityProfile<CHAIN, TA, CERT>(
    validator: ValidateCertificateChain<CHAIN, TA>,
    certificateProfileValidator: CertificateProfileValidator<CERT>,
    endEntityCertificateProfile: CertificateProfile,
    endEntityCertificateOf: (CHAIN) -> CERT
): ValidateCertificateChain<CHAIN, TA> {
    ValidateCertificateChainWithEndEntityProfile<CHAIN, TA, CERT>(
        validator,
        endEntityCertificateProfile,
        certificateProfileValidator,
        endEntityCertificateOf
    )
}

public func withEndEntityProfileOfList<TA, CERT>(
    validator: ValidateCertificateChain<ArrayList<CERT>, TA>,
    certificateProfileValidator: CertificateProfileValidator<CERT>,
    endEntityCertificateProfile: CertificateProfile
): ValidateCertificateChain<ArrayList<CERT>, TA> {
    withEndEntityProfile(
        validator,
        certificateProfileValidator,
        endEntityCertificateProfile,
        { chain: ArrayList<CERT> =>
            if (chain.size == 0) {
                throw IllegalArgumentException("Chain cannot be empty")
            }
            chain[0]
        }
    )
}
