package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_eu_profiles

import std.collection.*
import std.time.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation.LoadedLoTE
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model.*

/// PID providers LoTE profile (CIR 2024/2980 Article 5(2) / ETSI TS 119 602 Annex D).
public let EUPIDProvidersList: EUListOfTrustedEntitiesProfile = EUListOfTrustedEntitiesProfile(
    EUListAndSchemeInformationProfile(
        Uri.parse(ETSI19602.EU_PID_PROVIDERS_LOTE),
        Uri.parse(ETSI19602.EU_PID_PROVIDERS_STATUS_DETERMINATION_APPROACH),
        singleEnglishRule(ETSI19602.EU_PID_PROVIDERS_SCHEME_COMMUNITY_RULES),
        CountryCode.eu(),
        6,
        ValueRequirement<HistoricalInformationPeriod>.Absent
    ),
    EUTrustedEntitiesProfile(
        ServiceTypeIdentifiers.IssuanceAndRevocation(
            Uri.parse(ETSI19602.EU_PID_PROVIDERS_SVC_TYPE_ISSUANCE),
            Uri.parse(ETSI19602.EU_PID_PROVIDERS_SVC_TYPE_REVOCATION)
        ),
        true,
        emptyUriList(),
        ServiceDigitalIdentityCertificateType.EndEntityOrCA
    )
)

/// CA certificate constraints when the PID LoTE publishes a trust-anchor CA (PKIX).
public func pidProviderCACertificateProfile(
    at!: ?DateTime = None,
    maxPathLen!: ?Int64 = None
): CertificateProfile {
    certificateProfile({ builder: ProfileBuilder =>
        builder.ca(maxPathLen)
        builder.keyUsageCertSign()
        builder.validAt(at)
    })
}

/// Hook `profile_check`: scheme/entity checks, then EE vs CA identity dispatch, then LoadedLoTE.trustAnchorsFor.
public func eupidProvidersProfileCheck<CERT, TRUST_ANCHOR>(
    loaded: LoadedLoTE,
    validator: CertificateProfileValidator<CERT>,
    certificatesFromIdentity: (ServiceDigitalIdentity) -> ArrayList<CERT>,
    getCertificateInfo: (CERT) -> String,
    createTrustAnchors: (ServiceDigitalIdentity) -> ArrayList<TRUST_ANCHOR>,
    at!: ?DateTime = None
): ArrayList<TRUST_ANCHOR> {
    EUPIDProvidersList.ensureCompliesToProfile(loaded.list)
    let issuance = Uri.parse(ETSI19602.EU_PID_PROVIDERS_SVC_TYPE_ISSUANCE)
    let endEntityCerts = ArrayList<CERT>()
    let caCerts = ArrayList<CERT>()
    for (service in loaded.servicesOfType(issuance)) {
        let parsed = certificatesFromIdentity(service.information.digitalIdentity)
        for (certificate in parsed) {
            if (loteIdentityIsCA(validator, certificate)) {
                caCerts.add(certificate)
            } else {
                endEntityCerts.add(certificate)
            }
        }
    }
    validator.ensureAllMet(pidSigningCertificateProfile(at: at), endEntityCerts, getCertificateInfo)
    validator.ensureAllMet(pidProviderCACertificateProfile(at: at), caCerts, getCertificateInfo)
    loaded.trustAnchorsFor(issuance, createTrustAnchors)
}
