package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

import std.collection.*

public class ContextScopedTrustAnchors<CTX, TRUST_ANCHOR> <: GetTrustAnchors<CTX, TRUST_ANCHOR>
    where CTX <: Equatable<CTX> {
    private let supportedContexts: ArrayList<CTX>
    private let inner: GetTrustAnchors<CTX, TRUST_ANCHOR>

    public init(supportedContexts: ArrayList<CTX>, inner: GetTrustAnchors<CTX, TRUST_ANCHOR>) {
        this.supportedContexts = supportedContexts
        this.inner = inner
    }

    public func invoke(query: CTX): ?NonEmptyList<TRUST_ANCHOR> {
        if (contextListContains(this.supportedContexts, query)) {
            this.inner.invoke(query)
        } else {
            None
        }
    }
}

/// Elementary aggregation unit: one GetTrustAnchors + one ValidateCertificateChain
/// over a set of supported contexts.
public class IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR> <:
    IsChainTrustedForContextF<CHAIN, CTX, TRUST_ANCHOR> where CTX <: Equatable<CTX> {
    public let supportedContexts: ArrayList<CTX>
    public let getTrustAnchors: GetTrustAnchors<CTX, TRUST_ANCHOR>
    public let validateCertificateChain: ValidateCertificateChain<CHAIN, TRUST_ANCHOR>

    public init(
        supportedContexts: ArrayList<CTX>,
        getTrustAnchors: GetTrustAnchors<CTX, TRUST_ANCHOR>,
        validateCertificateChain: ValidateCertificateChain<CHAIN, TRUST_ANCHOR>
    ) {
        this.supportedContexts = supportedContexts
        this.getTrustAnchors = ContextScopedTrustAnchors<CTX, TRUST_ANCHOR>(supportedContexts, getTrustAnchors)
        this.validateCertificateChain = validateCertificateChain
    }

    public func invoke(chain: CHAIN, verificationContext: CTX): ?CertificationChainValidation<TRUST_ANCHOR> {
        match (this.getTrustAnchors.invoke(verificationContext)) {
            case None => None
            case Some(anchors) => Some(this.validateCertificateChain.invoke(chain, anchors))
        }
    }

    public func contains(ctx: CTX): Bool {
        contextListContains(this.supportedContexts, ctx)
    }

    public func plus(
        other: IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR>
    ): ComposeChainTrust<CHAIN, CTX, TRUST_ANCHOR> {
        ComposeChainTrust<CHAIN, CTX, TRUST_ANCHOR>.ofTwo(this, other)
    }

    public func contraMap<C1>(
        transformation: (C1) -> CHAIN
    ): IsChainTrustedForContext<C1, CTX, TRUST_ANCHOR> {
        IsChainTrustedForContext<C1, CTX, TRUST_ANCHOR>(
            this.supportedContexts,
            this.getTrustAnchors,
            contraMapValidateCertificateChain(this.validateCertificateChain, transformation)
        )
    }
}

public func composeChainTrustSources<CHAIN, CTX, TA>(
    sources: ArrayList<IsChainTrustedForContext<CHAIN, CTX, TA>>
): ComposeChainTrust<CHAIN, CTX, TA> where CTX <: Equatable<CTX> {
    var acc = ComposeChainTrust<CHAIN, CTX, TA>.empty()
    for (next in sources) {
        acc = acc.plusContext(next)
    }
    acc
}

public func contextListContains<CTX>(list: ArrayList<CTX>, ctx: CTX): Bool where CTX <: Equatable<CTX> {
    for (item in list) {
        if (item == ctx) {
            return true
        }
    }
    false
}

public func contextListsOverlap<CTX>(left: ArrayList<CTX>, right: ArrayList<CTX>): Bool where CTX <: Equatable<CTX> {
    for (item in left) {
        if (contextListContains(right, item)) {
            return true
        }
    }
    false
}
