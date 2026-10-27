package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation_platform

import std.collection.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_platform.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model.*

/// Flattened chain-validation outcome for callers that should not match on
/// CertificationChainValidation (Kotlin IosValidationResult).
public class IosValidationResult {
    public let isTrusted: Bool
    public let matchedAnchor: Option<Array<Byte>>
    public let failureReason: Option<String>

    public init(isTrusted: Bool, matchedAnchor: Option<Array<Byte>>, failureReason: Option<String>) {
        this.isTrusted = isTrusted
        this.matchedAnchor = matchedAnchor
        this.failureReason = failureReason
    }
}

/// The chain-validation strategy for EudiwIosTrust.usingBundledAnchors.
public enum BundledAnchorMethod {
    | PKIX
    | DirectTrust
}

/// LoTE download URL configuration for EudiwIosTrust.nonCached / cached.
public class TrustListUrls {
    public var pidProviders: ?String = None
    public var walletProviders: ?String = None
    public var wrpacProviders: ?String = None
    public var wrprcProviders: ?String = None
    public var pubEaaProviders: ?String = None
    public var qeaProviders: ?String = None
    public var mdlProviders: ?String = None

    public init() {}
}

/// Bundled DER certificate anchors for EudiwIosTrust.usingBundledAnchors.
public class BundledAnchors {
    public var pid: ?ArrayList<Array<Byte>> = None
    public var wallet: ?ArrayList<Array<Byte>> = None
    public var wrpac: ?ArrayList<Array<Byte>> = None
    public var wrprc: ?ArrayList<Array<Byte>> = None
    public var pubEaa: ?ArrayList<Array<Byte>> = None
    public var qea: ?ArrayList<Array<Byte>> = None
    public var mdl: ?ArrayList<Array<Byte>> = None

    public init() {}
}

/// One-call assembly of the OHOS LoTE-based trust validator.
/// iOS-named: Darwin HttpClient / SecTrust are not used; HTTP is stdx.net.http
/// via IosLoTEHttpClient → DownloadSingleLoTE, validation is consultation_platform.
public class EudiwIosTrust {
    public static let mdlUseCase: String = "mdl"
    public static let mdlSvcTypeIssuance: String = "http://trust.ec.europa.eu/lists/mDL/SvcType/Issuance"
    public static let mdlSvcTypeRevocation: String = "http://trust.ec.europa.eu/lists/mDL/SvcType/Revocation"

    public static func nonCached(
        urls: TrustListUrls,
        verifyJwtSignature: VerifyJwtSignature
    ): ComposeChainTrust<ArrayList<Array<Byte>>, VerificationContext, Array<Byte>> {
        eudiwIos(
            buildLoadLoTEAndPointers(verifyJwtSignature),
            svcTypePerCtx: buildSvcTypePerCtx(urls.mdlProviders)
        ).nonCached(buildLocations(urls))
    }

    public static func cached(
        urls: TrustListUrls,
        ttlHours: Float64,
        verifyJwtSignature: VerifyJwtSignature
    ): CachedTrustValidator {
        let scope = DisposableContainer()
        let validator = eudiwIos(
            buildLoadLoTEAndPointers(verifyJwtSignature),
            svcTypePerCtx: buildSvcTypePerCtx(urls.mdlProviders)
        ).cached(scope, buildLocations(urls), Duration.hour * ttlHours)
        CachedTrustValidator(scope, validator)
    }

    public static func usingBundledAnchors(
        anchors: BundledAnchors,
        method: BundledAnchorMethod
    ): ComposeChainTrust<ArrayList<Array<Byte>>, VerificationContext, Array<Byte>> {
        let anchorsByContext = HashMap<VerificationContext, ArrayList<Array<Byte>>>()
        putIfPresent(anchorsByContext, VerificationContext.PID, anchors.pid)
        putIfPresent(anchorsByContext, VerificationContext.WalletProviderAttestation, anchors.wallet)
        putIfPresent(
            anchorsByContext,
            VerificationContext.WalletRelyingPartyAccessCertificate,
            anchors.wrpac
        )
        putIfPresent(
            anchorsByContext,
            VerificationContext.WalletRelyingPartyRegistrationCertificate,
            anchors.wrprc
        )
        putIfPresent(anchorsByContext, VerificationContext.PubEAA, anchors.pubEaa)
        putIfPresent(anchorsByContext, VerificationContext.QEAA, anchors.qea)
        putIfPresent(anchorsByContext, VerificationContext.EAA(mdlUseCase), anchors.mdl)

        let source = getTrustAnchorsOf<VerificationContext, Array<Byte>>({ ctx: VerificationContext =>
            match (anchorsByContext.get(ctx)) {
                case Some(list) => NonEmptyList<Array<Byte>>.nelOrNull(list)
                case None => None
            }
        })
        let keys = ArrayList<VerificationContext>()
        for ((ctx, _) in anchorsByContext) {
            keys.add(ctx)
        }
        let validateChain: ValidateCertificateChain<ArrayList<Array<Byte>>, Array<Byte>> = match (method) {
            case BundledAnchorMethod.PKIX => iosPkix()
            case BundledAnchorMethod.DirectTrust => ValidateCertificateChainUsingDirectTrustIos
        }
        ComposeChainTrust<ArrayList<Array<Byte>>, VerificationContext, Array<Byte>>.of(
            validatorForQueries(source, keys, validateChain)
        )
    }

    public static func trustAnchors(
        validator: ComposeChainTrust<ArrayList<Array<Byte>>, VerificationContext, Array<Byte>>,
        context: VerificationContext
    ): ArrayList<Array<Byte>> {
        match (validator.getTrustAnchors().invoke(context)) {
            case None => ArrayList<Array<Byte>>()
            case Some(nel) => nel.items
        }
    }

    public static func validate(
        validator: ComposeChainTrust<ArrayList<Array<Byte>>, VerificationContext, Array<Byte>>,
        chain: ArrayList<Array<Byte>>,
        context: VerificationContext
    ): IosValidationResult {
        match (validator.invoke(chain, context)) {
            case None =>
                let noneAnchor: Option<Array<Byte>> = None
                IosValidationResult(
                    false,
                    noneAnchor,
                    Some("No validator configured for this context")
                )
            case Some(outcome) =>
                match (outcome) {
                    case CertificationChainValidation.Trusted(anchor) =>
                        let noneReason: Option<String> = None
                        IosValidationResult(true, Some(anchor), noneReason)
                    case CertificationChainValidation.NotTrusted(cause) =>
                        let noneAnchor: Option<Array<Byte>> = None
                        IosValidationResult(false, noneAnchor, Some(cause))
                }
        }
    }
}

/// Cached OHOS trust validator plus the DisposableScope that owns its in-memory cache.
public class CachedTrustValidator {
    private let scope: DisposableContainer
    private let validator: ComposeChainTrust<ArrayList<Array<Byte>>, VerificationContext, Array<Byte>>

    public init(
        scope: DisposableContainer,
        validator: ComposeChainTrust<ArrayList<Array<Byte>>, VerificationContext, Array<Byte>>
    ) {
        this.scope = scope
        this.validator = validator
    }

    public func trustAnchors(context: VerificationContext): ArrayList<Array<Byte>> {
        EudiwIosTrust.trustAnchors(this.validator, context)
    }

    public func validate(
        chain: ArrayList<Array<Byte>>,
        context: VerificationContext
    ): IosValidationResult {
        EudiwIosTrust.validate(this.validator, chain, context)
    }

    public func dispose(): Unit {
        this.scope.dispose()
    }
}

func buildLocations(urls: TrustListUrls): SupportedLists<Uri> {
    let eaa = HashMap<String, Uri>()
    match (urls.mdlProviders) {
        case Some(url) => eaa.add(EudiwIosTrust.mdlUseCase, Uri.parse(url))
        case None => ()
    }
    SupportedLists<Uri>(
        pidProviders: optionalUri(urls.pidProviders),
        walletProviders: optionalUri(urls.walletProviders),
        wrpacProviders: optionalUri(urls.wrpacProviders),
        wrprcProviders: optionalUri(urls.wrprcProviders),
        pubEaaProviders: optionalUri(urls.pubEaaProviders),
        qeaProviders: optionalUri(urls.qeaProviders),
        eaaProviders: eaa
    )
}

func buildSvcTypePerCtx(
    mdlProvidersUrl: ?String
): SupportedLists<LotEMeta<VerificationContext>> {
    let baseline = euSupportedLists()
    match (mdlProvidersUrl) {
        case None => baseline
        case Some(_) => withMdlMeta(baseline, mdlMeta())
    }
}

func withMdlMeta(
    baseline: SupportedLists<LotEMeta<VerificationContext>>,
    mdl: LotEMeta<VerificationContext>
): SupportedLists<LotEMeta<VerificationContext>> {
    let eaa = HashMap<String, LotEMeta<VerificationContext>>()
    for ((useCase, meta) in baseline.eaaProviders) {
        eaa.add(useCase, meta)
    }
    eaa.add(EudiwIosTrust.mdlUseCase, mdl)
    SupportedLists<LotEMeta<VerificationContext>>(
        pidProviders: baseline.pidProviders,
        walletProviders: baseline.walletProviders,
        wrpacProviders: baseline.wrpacProviders,
        wrprcProviders: baseline.wrprcProviders,
        pubEaaProviders: baseline.pubEaaProviders,
        qeaProviders: baseline.qeaProviders,
        eaaProviders: eaa
    )
}

func mdlMeta(): LotEMeta<VerificationContext> {
    let map = HashMap<VerificationContext, SvcAndEEProfile>()
    let noneProfile: ?CertificateProfile = None
    map.add(
        VerificationContext.EAA(EudiwIosTrust.mdlUseCase),
        SvcAndEEProfile(Uri.parse(EudiwIosTrust.mdlSvcTypeIssuance), noneProfile)
    )
    map.add(
        VerificationContext.EAAStatus(EudiwIosTrust.mdlUseCase),
        SvcAndEEProfile(Uri.parse(EudiwIosTrust.mdlSvcTypeRevocation), noneProfile)
    )
    LotEMeta<VerificationContext>(map, ServiceDigitalIdentityCertificateType.EndEntityOrCA)
}

func buildLoadLoTEAndPointers(verifyJwtSignature: VerifyJwtSignature): LoadLoTEAndPointers {
    LoadLoTEAndPointers(
        LoTELoadConstraints.DoNotLoadOtherPointers,
        verifyJwtSignature,
        IosLoTEHttpClient.create()
    )
}

func optionalUri(value: ?String): ?Uri {
    match (value) {
        case Some(url) => Some(Uri.parse(url))
        case None => None
    }
}

func putIfPresent(
    map: HashMap<VerificationContext, ArrayList<Array<Byte>>>,
    ctx: VerificationContext,
    ders: ?ArrayList<Array<Byte>>
): Unit {
    match (ders) {
        case Some(list) => map.add(ctx, list)
        case None => ()
    }
}
