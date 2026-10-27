package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation

import std.collection.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model.*

/// Hint for how ServiceDigitalIdentity X.509 certificates should be validated.
/// EU list profiles (lote_eu_profiles) own scheme/cert constraint checks; this
/// package only records the validation method used when provisioning anchors.
public enum ServiceDigitalIdentityCertificateType {
    | EndEntity
    | CA
    | EndEntityOrCA
}

public class SvcAndEEProfile {
    public let svcTypeIdentifier: Uri
    public let endEntityProfile: ?CertificateProfile

    public init(svcTypeIdentifier: Uri, endEntityProfile: ?CertificateProfile) {
        this.svcTypeIdentifier = svcTypeIdentifier
        this.endEntityProfile = endEntityProfile
    }
}

public class LotEMeta<CTX> where CTX <: Equatable<CTX> & Hashable {
    public let svcTypePerCtx: HashMap<CTX, SvcAndEEProfile>
    public let serviceDigitalIdentityCertificateType: ServiceDigitalIdentityCertificateType

    public init(
        svcTypePerCtx: HashMap<CTX, SvcAndEEProfile>,
        serviceDigitalIdentityCertificateType: ServiceDigitalIdentityCertificateType
    ) {
        this.svcTypePerCtx = svcTypePerCtx
        this.serviceDigitalIdentityCertificateType = serviceDigitalIdentityCertificateType
    }
}

/// Known EU LoTE service-type mappings onto VerificationContext.
/// End-entity CertificateProfile values are optional so lote_eu_profiles can
/// inject PID/Wallet/WRPAC profiles without this package owning those specs.
public func euSupportedLists(
    pidIssuanceProfile!: ?CertificateProfile = None,
    walletIssuanceProfile!: ?CertificateProfile = None,
    wrpacIssuanceProfile!: ?CertificateProfile = None
): SupportedLists<LotEMeta<VerificationContext>> {
    SupportedLists<LotEMeta<VerificationContext>>(
        pidProviders: Some(issuanceRevocationMeta(
            Some(VerificationContext.PID),
            Some(VerificationContext.PIDStatus),
            ETSI19602.EU_PID_PROVIDERS_SVC_TYPE_ISSUANCE,
            ETSI19602.EU_PID_PROVIDERS_SVC_TYPE_REVOCATION,
            pidIssuanceProfile,
            None,
            ServiceDigitalIdentityCertificateType.EndEntityOrCA
        )),
        walletProviders: Some(issuanceRevocationMeta(
            Some(VerificationContext.WalletProviderAttestation),
            Some(VerificationContext.WalletOrKeyStorageStatus),
            ETSI19602.EU_WALLET_PROVIDERS_SVC_TYPE_ISSUANCE,
            ETSI19602.EU_WALLET_PROVIDERS_SVC_TYPE_REVOCATION,
            walletIssuanceProfile,
            None,
            ServiceDigitalIdentityCertificateType.EndEntityOrCA
        )),
        wrpacProviders: Some(issuanceRevocationMeta(
            Some(VerificationContext.WalletRelyingPartyAccessCertificate),
            None,
            ETSI19602.EU_WRPAC_PROVIDERS_SVC_TYPE_ISSUANCE,
            ETSI19602.EU_WRPAC_PROVIDERS_SVC_TYPE_REVOCATION,
            wrpacIssuanceProfile,
            None,
            ServiceDigitalIdentityCertificateType.CA
        )),
        wrprcProviders: Some(issuanceRevocationMeta(
            Some(VerificationContext.WalletRelyingPartyRegistrationCertificate),
            Some(VerificationContext.WalletRelyingPartyRegistrationCertificateStatus),
            ETSI19602.EU_WRPRC_PROVIDERS_SVC_TYPE_ISSUANCE,
            ETSI19602.EU_WRPRC_PROVIDERS_SVC_TYPE_REVOCATION,
            None,
            None,
            ServiceDigitalIdentityCertificateType.CA
        )),
        pubEaaProviders: None,
        qeaProviders: None
    )
}

func issuanceRevocationMeta(
    issuanceCtx: ?VerificationContext,
    revocationCtx: ?VerificationContext,
    issuanceUri: String,
    revocationUri: String,
    issuanceProfile: ?CertificateProfile,
    revocationProfile: ?CertificateProfile,
    certType: ServiceDigitalIdentityCertificateType
): LotEMeta<VerificationContext> {
    let map = HashMap<VerificationContext, SvcAndEEProfile>()
    match (issuanceCtx) {
        case Some(ctx) =>
            map.add(ctx, SvcAndEEProfile(Uri.parse(issuanceUri), issuanceProfile))
        case None => ()
    }
    match (revocationCtx) {
        case Some(ctx) =>
            map.add(ctx, SvcAndEEProfile(Uri.parse(revocationUri), revocationProfile))
        case None => ()
    }
    LotEMeta<VerificationContext>(map, certType)
}
