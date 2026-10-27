package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation

import std.collection.*
import std.time.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model.*

class LoTECfg<CTX> where CTX <: Equatable<CTX> & Hashable {
    public let downloadUrl: Uri
    public let metadata: LotEMeta<CTX>

    public init(downloadUrl: Uri, metadata: LotEMeta<CTX>) {
        this.downloadUrl = downloadUrl
        this.metadata = metadata
    }
}

class CertificateProfileGroup<CTX> where CTX <: Equatable<CTX> & Hashable {
    public let profile: ?CertificateProfile
    public let svcTypePerCtx: HashMap<CTX, Uri>

    public init(profile: ?CertificateProfile) {
        this.profile = profile
        this.svcTypePerCtx = HashMap<CTX, Uri>()
    }
}

/// Composes GetTrustAnchorsFromLoTE instances (grouped by certificate profile)
/// into a ComposeChainTrust suitable for EUDIW verification contexts.
public class ProvisionTrustAnchorsFromLoTEs<CHAIN, CTX, TRUST_ANCHOR, CERT> where CTX <: Equatable<CTX> & Hashable {
    private let loadLoTEAndPointers: LoadLoTEAndPointers
    private let svcTypePerCtx: SupportedLists<LotEMeta<CTX>>
    private let createTrustAnchors: (ServiceDigitalIdentity) -> ArrayList<TRUST_ANCHOR>
    private let directTrust: ValidateCertificateChain<CHAIN, TRUST_ANCHOR>
    private let pkix: ValidateCertificateChain<CHAIN, TRUST_ANCHOR>
    private let continueOnProblem: ContinueOnProblem
    private let certificateProfileValidator: CertificateProfileValidator<CERT>
    private let endEntityCertificateOf: (CHAIN) -> CERT

    public init(
        loadLoTEAndPointers: LoadLoTEAndPointers,
        svcTypePerCtx: SupportedLists<LotEMeta<CTX>>,
        createTrustAnchors: (ServiceDigitalIdentity) -> ArrayList<TRUST_ANCHOR>,
        directTrust: ValidateCertificateChain<CHAIN, TRUST_ANCHOR>,
        pkix: ValidateCertificateChain<CHAIN, TRUST_ANCHOR>,
        certificateProfileValidator: CertificateProfileValidator<CERT>,
        endEntityCertificateOf: (CHAIN) -> CERT,
        continueOnProblem!: ContinueOnProblem = ContinueOnProblem.never()
    ) {
        this.loadLoTEAndPointers = loadLoTEAndPointers
        this.svcTypePerCtx = svcTypePerCtx
        this.createTrustAnchors = createTrustAnchors
        this.directTrust = directTrust
        this.pkix = pkix
        this.certificateProfileValidator = certificateProfileValidator
        this.endEntityCertificateOf = endEntityCertificateOf
        this.continueOnProblem = continueOnProblem
    }

    public func nonCached(
        loteLocationsSupported: SupportedLists<Uri>
    ): ComposeChainTrust<CHAIN, CTX, TRUST_ANCHOR> {
        let validators = ArrayList<IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR>>()
        for (cfg in this.cfgs(loteLocationsSupported).toList()) {
            let source = this.createGetTrustAnchorsFromLoTE(cfg)
            this.addValidators(validators, cfg.metadata, source)
        }
        composeChainTrustSources(validators)
    }

    public func cached(
        disposableScope: DisposableScope,
        loteLocationsSupported: SupportedLists<Uri>,
        ttl: Duration
    ): ComposeChainTrust<CHAIN, CTX, TRUST_ANCHOR> {
        let validators = ArrayList<IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR>>()
        for (cfg in this.cfgs(loteLocationsSupported).toList()) {
            let source = this.createGetTrustAnchorsFromLoTE(cfg)
            let cachedSource = this.cachedByUriValue(source, ttl, cfg.metadata.svcTypePerCtx.size)
            disposableScope.bind(cachedSource)
            let asUri: GetTrustAnchors<Uri, TRUST_ANCHOR> = contraMapGetTrustAnchors(
                cachedSource,
                { uri: Uri => uri.value }
            )
            this.addValidators(validators, cfg.metadata, asUri)
        }
        composeChainTrustSources(validators)
    }

    public static func eudiw(
        loadLoTEAndPointers: LoadLoTEAndPointers,
        createTrustAnchors: (ServiceDigitalIdentity) -> ArrayList<TRUST_ANCHOR>,
        directTrust: ValidateCertificateChain<CHAIN, TRUST_ANCHOR>,
        pkix: ValidateCertificateChain<CHAIN, TRUST_ANCHOR>,
        certificateProfileValidator: CertificateProfileValidator<CERT>,
        endEntityCertificateOf: (CHAIN) -> CERT,
        svcTypePerCtx!: SupportedLists<LotEMeta<VerificationContext>> = euSupportedLists(),
        continueOnProblem!: ContinueOnProblem = ContinueOnProblem.never()
    ): ProvisionTrustAnchorsFromLoTEs<CHAIN, VerificationContext, TRUST_ANCHOR, CERT> {
        ProvisionTrustAnchorsFromLoTEs<CHAIN, VerificationContext, TRUST_ANCHOR, CERT>(
            loadLoTEAndPointers,
            svcTypePerCtx,
            createTrustAnchors,
            directTrust,
            pkix,
            certificateProfileValidator,
            endEntityCertificateOf,
            continueOnProblem: continueOnProblem
        )
    }

    private func cfgs(loteLocationsSupported: SupportedLists<Uri>): SupportedLists<LoTECfg<CTX>> {
        SupportedLists<Uri>.combine<Uri, LotEMeta<CTX>, LoTECfg<CTX>>(
            loteLocationsSupported,
            this.svcTypePerCtx,
            { url: Uri, meta: LotEMeta<CTX> =>
                LoTECfg<CTX>(url, meta)
            }
        )
    }

    private func createGetTrustAnchorsFromLoTE(cfg: LoTECfg<CTX>): GetTrustAnchors<Uri, TRUST_ANCHOR> {
        GetTrustAnchorsFromLoTE<TRUST_ANCHOR>(
            cfg.downloadUrl,
            this.loadLoTEAndPointers,
            this.createTrustAnchors,
            continueOnProblem: this.continueOnProblem
        )
    }

    private func cachedByUriValue(
        source: GetTrustAnchors<Uri, TRUST_ANCHOR>,
        ttl: Duration,
        expectedQueries: Int64
    ): GetTrustAnchorsCachedSource<String, TRUST_ANCHOR> {
        let stringSource = contraMapGetTrustAnchors(source, { value: String => Uri.parse(value) })
        cachedGetTrustAnchors(stringSource, ttl, expectedQueries)
    }

    private func addValidators(
        validators: ArrayList<IsChainTrustedForContext<CHAIN, CTX, TRUST_ANCHOR>>,
        metadata: LotEMeta<CTX>,
        getTrustAnchors: GetTrustAnchors<Uri, TRUST_ANCHOR>
    ): Unit {
        let base = this.baseCertificateChainValidators(metadata)
        for (group in groupPerCertificateProfile(metadata)) {
            if (group.svcTypePerCtx.size == 0) {
                throw IllegalArgumentException("svcTypePerCtx cannot be empty")
            }
            let chainValidator = match (group.profile) {
                case Some(profile) =>
                    withEndEntityProfile(
                        base,
                        this.certificateProfileValidator,
                        profile,
                        this.endEntityCertificateOf
                    )
                case None => base
            }
            validators.add(validatorForQueryMap(getTrustAnchors, group.svcTypePerCtx, chainValidator))
        }
    }

    private func baseCertificateChainValidators(
        metadata: LotEMeta<CTX>
    ): ValidateCertificateChain<CHAIN, TRUST_ANCHOR> {
        match (metadata.serviceDigitalIdentityCertificateType) {
            case ServiceDigitalIdentityCertificateType.EndEntity => this.directTrust
            case ServiceDigitalIdentityCertificateType.CA => this.pkix
            case ServiceDigitalIdentityCertificateType.EndEntityOrCA =>
                orValidateCertificateChain(this.directTrust, this.pkix)
        }
    }
}

func groupPerCertificateProfile<CTX>(
    metadata: LotEMeta<CTX>
): ArrayList<CertificateProfileGroup<CTX>> where CTX <: Equatable<CTX> & Hashable {
    let groups = ArrayList<CertificateProfileGroup<CTX>>()
    var noneGroup: Option<CertificateProfileGroup<CTX>> = None
    for ((ctx, svc) in metadata.svcTypePerCtx) {
        match (svc.endEntityProfile) {
            case None =>
                match (noneGroup) {
                    case Some(group) => group.svcTypePerCtx.add(ctx, svc.svcTypeIdentifier)
                    case None =>
                        let group = CertificateProfileGroup<CTX>(None)
                        group.svcTypePerCtx.add(ctx, svc.svcTypeIdentifier)
                        noneGroup = Some(group)
                        groups.add(group)
                }
            case Some(profile) =>
                let group = CertificateProfileGroup<CTX>(Some(profile))
                group.svcTypePerCtx.add(ctx, svc.svcTypeIdentifier)
                groups.add(group)
        }
    }
    groups
}
