package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

import std.collection.*

/// Default IsChainTrustedForContextF that merges disjoint per-context validators.
/// Callers inject GetTrustAnchors; this type does not know LoTE vs LOTL.
public class ComposeChainTrust<CHAIN, CTX, TRUST_ANCHOR> <:
    IsChainTrustedForContextF<CHAIN, CTX, TRUST_ANCHOR> where CTX <: Equatable<CTX> {
    private let sources: ArrayList<IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR>>

    public init(sources: ArrayList<IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR>>) {
        this.sources = sources
    }

    public static func empty(): ComposeChainTrust<CHAIN, CTX, TRUST_ANCHOR> {
        ComposeChainTrust<CHAIN, CTX, TRUST_ANCHOR>(
            ArrayList<IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR>>()
        )
    }

    public static func of(
        source: IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR>
    ): ComposeChainTrust<CHAIN, CTX, TRUST_ANCHOR> {
        let list = ArrayList<IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR>>()
        list.add(source)
        ComposeChainTrust<CHAIN, CTX, TRUST_ANCHOR>(list)
    }

    public static func ofTwo(
        first: IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR>,
        second: IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR>
    ): ComposeChainTrust<CHAIN, CTX, TRUST_ANCHOR> {
        ComposeChainTrust<CHAIN, CTX, TRUST_ANCHOR>.empty().plusContext(first).plusContext(second)
    }

    public func supportedContexts(): ArrayList<CTX> {
        let out = ArrayList<CTX>()
        for (source in this.sources) {
            for (ctx in source.supportedContexts) {
                if (!contextListContains(out, ctx)) {
                    out.add(ctx)
                }
            }
        }
        out
    }

    public func getTrustAnchors(): GetTrustAnchors<CTX, TRUST_ANCHOR> {
        LambdaGetTrustAnchors<CTX, TRUST_ANCHOR>({ query: CTX =>
            match (this.findSource(query)) {
                case None => None
                case Some(source) => source.getTrustAnchors.invoke(query)
            }
        })
    }

    public func invoke(chain: CHAIN, verificationContext: CTX): ?CertificationChainValidation<TRUST_ANCHOR> {
        match (this.findSource(verificationContext)) {
            case None => None
            case Some(source) => source.invoke(chain, verificationContext)
        }
    }

    public func plus(
        other: ComposeChainTrust<CHAIN, CTX, TRUST_ANCHOR>
    ): ComposeChainTrust<CHAIN, CTX, TRUST_ANCHOR> {
        let common = this.supportedContexts()
        if (contextListsOverlap(common, other.supportedContexts())) {
            throw IllegalArgumentException("Sources have overlapping queries")
        }
        let merged = ArrayList<IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR>>()
        for (item in this.sources) {
            merged.add(item)
        }
        for (item in other.sources) {
            merged.add(item)
        }
        ComposeChainTrust<CHAIN, CTX, TRUST_ANCHOR>(merged)
    }

    public func plusContext(
        other: IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR>
    ): ComposeChainTrust<CHAIN, CTX, TRUST_ANCHOR> {
        if (contextListsOverlap(this.supportedContexts(), other.supportedContexts)) {
            throw IllegalArgumentException("Sources have overlapping queries")
        }
        let merged = ArrayList<IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR>>()
        for (item in this.sources) {
            merged.add(item)
        }
        merged.add(other)
        ComposeChainTrust<CHAIN, CTX, TRUST_ANCHOR>(merged)
    }

    public func recoverWith(
        recovery: (CTX, String) -> ?IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR>
    ): IsChainTrustedForContextF<CHAIN, CTX, TRUST_ANCHOR> {
        UnsafeIsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR>(this, recovery)
    }

    public func contraMap<C2>(
        transformation: (C2) -> CHAIN
    ): ComposeChainTrust<C2, CTX, TRUST_ANCHOR> {
        let mapped = ArrayList<IsChainTrustedForContext<C2, CTX, TRUST_ANCHOR>>()
        for (src in this.sources) {
            mapped.add(src.contraMap(transformation))
        }
        ComposeChainTrust<C2, CTX, TRUST_ANCHOR>(mapped)
    }

    private func findSource(ctx: CTX): ?IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR> {
        for (source in this.sources) {
            if (source.contains(ctx)) {
                return source
            }
        }
        None
    }
}
