package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

import std.collection.*
import std.time.*

/// Functional source for retrieving trust anchors for a query.
/// LoTE/LOTL-backed implementations belong to downstream features.
public interface GetTrustAnchors<QUERY, TRUST_ANCHOR> {
    func invoke(query: QUERY): ?NonEmptyList<TRUST_ANCHOR>
}

public class LambdaGetTrustAnchors<QUERY, TRUST_ANCHOR> <: GetTrustAnchors<QUERY, TRUST_ANCHOR> {
    private let fn: (QUERY) -> ?NonEmptyList<TRUST_ANCHOR>

    public init(fn: (QUERY) -> ?NonEmptyList<TRUST_ANCHOR>) {
        this.fn = fn
    }

    public func invoke(query: QUERY): ?NonEmptyList<TRUST_ANCHOR> {
        this.fn(query)
    }
}

public func getTrustAnchorsOf<QUERY, TRUST_ANCHOR>(
    fn: (QUERY) -> ?NonEmptyList<TRUST_ANCHOR>
): GetTrustAnchors<QUERY, TRUST_ANCHOR> {
    LambdaGetTrustAnchors<QUERY, TRUST_ANCHOR>(fn)
}

public func validatorForQueries<C, Q, TA>(
    source: GetTrustAnchors<Q, TA>,
    supportedQueries: ArrayList<Q>,
    validateCertificateChain: ValidateCertificateChain<C, TA>
): IsChainTrustedForContext<C, Q, TA> where Q <: Equatable<Q> {
    IsChainTrustedForContext<C, Q, TA>(supportedQueries, source, validateCertificateChain)
}

public func validatorForQueryMap<C, Q, TA, Q1>(
    source: GetTrustAnchors<Q, TA>,
    transformation: HashMap<Q1, Q>,
    validateCertificateChain: ValidateCertificateChain<C, TA>
): IsChainTrustedForContext<C, Q1, TA> where Q1 <: Equatable<Q1> & Hashable {
    let keys = ArrayList<Q1>()
    for ((key, _) in transformation) {
        keys.add(key)
    }
    IsChainTrustedForContext<C, Q1, TA>(
        keys,
        contraMapGetTrustAnchors(source, { query: Q1 =>
            match (transformation.get(query)) {
                case Some(mapped) => mapped
                case None => throw IllegalArgumentException("Unsupported query")
            }
        }),
        validateCertificateChain
    )
}

/// Sensitive fallback combinator: first non-null source wins.
public class GetTrustAnchorsWithAlternative<QUERY, TRUST_ANCHOR> <: GetTrustAnchors<QUERY, TRUST_ANCHOR> {
    private let delegate: GetTrustAnchors<QUERY, TRUST_ANCHOR>
    private let alternative: GetTrustAnchors<QUERY, TRUST_ANCHOR>

    public init(
        delegate: GetTrustAnchors<QUERY, TRUST_ANCHOR>,
        alternative: GetTrustAnchors<QUERY, TRUST_ANCHOR>
    ) {
        this.delegate = delegate
        this.alternative = alternative
    }

    public func invoke(query: QUERY): ?NonEmptyList<TRUST_ANCHOR> {
        match (this.delegate.invoke(query)) {
            case Some(anchors) => Some(anchors)
            case None => this.alternative.invoke(query)
        }
    }
}

public func orGetTrustAnchors<Q, TA>(
    first: GetTrustAnchors<Q, TA>,
    other: GetTrustAnchors<Q, TA>
): GetTrustAnchorsWithAlternative<Q, TA> {
    GetTrustAnchorsWithAlternative<Q, TA>(first, other)
}

public class GetTrustAnchorsTransformingQuery<QUERY2, QUERY, TRUST_ANCHOR> <: GetTrustAnchors<QUERY2, TRUST_ANCHOR> {
    private let delegate: GetTrustAnchors<QUERY, TRUST_ANCHOR>
    private let transformation: (QUERY2) -> QUERY

    public init(
        delegate: GetTrustAnchors<QUERY, TRUST_ANCHOR>,
        transformation: (QUERY2) -> QUERY
    ) {
        this.delegate = delegate
        this.transformation = transformation
    }

    public func invoke(query: QUERY2): ?NonEmptyList<TRUST_ANCHOR> {
        this.delegate.invoke(this.transformation(query))
    }
}

public func contraMapGetTrustAnchors<Q, TA, Q2>(
    source: GetTrustAnchors<Q, TA>,
    transformation: (Q2) -> Q
): GetTrustAnchorsTransformingQuery<Q2, Q, TA> {
    GetTrustAnchorsTransformingQuery<Q2, Q, TA>(source, transformation)
}

public class GetTrustAnchorsCachedSource<QUERY, TRUST_ANCHOR> <: GetTrustAnchors<QUERY, TRUST_ANCHOR> & Disposable
    where QUERY <: Equatable<QUERY> & Hashable {
    private let cached: AsyncCache<QUERY, ?NonEmptyList<TRUST_ANCHOR>>

    public init(
        ttl: Duration,
        expectedQueries: Int64,
        delegate: GetTrustAnchors<QUERY, TRUST_ANCHOR>
    ) {
        this.cached = AsyncCache<QUERY, ?NonEmptyList<TRUST_ANCHOR>>(
            ttl,
            expectedQueries,
            { query: QUERY => delegate.invoke(query) }
        )
    }

    public func invoke(query: QUERY): ?NonEmptyList<TRUST_ANCHOR> {
        this.cached.invoke(query)
    }

    public func dispose(): Unit {
        this.cached.dispose()
    }
}

public func cachedGetTrustAnchors<Q, TA>(
    source: GetTrustAnchors<Q, TA>,
    ttl: Duration,
    expectedQueries: Int64
): GetTrustAnchorsCachedSource<Q, TA> where Q <: Equatable<Q> & Hashable {
    GetTrustAnchorsCachedSource<Q, TA>(ttl, expectedQueries, source)
}
