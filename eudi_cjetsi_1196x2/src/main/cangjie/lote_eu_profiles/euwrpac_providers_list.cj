package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_eu_profiles

import std.collection.*
import std.time.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation.LoadedLoTE
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model.*

public let EUWRPACProvidersList: EUListOfTrustedEntitiesProfile = EUListOfTrustedEntitiesProfile(
    EUListAndSchemeInformationProfile(
        Uri.parse(ETSI19602.EU_WRPAC_PROVIDERS_LOTE),
        Uri.parse(ETSI19602.EU_WRPAC_PROVIDERS_STATUS_DETERMINATION_APPROACH),
        singleEnglishRule(ETSI19602.EU_WRPAC_PROVIDERS_SCHEME_COMMUNITY_RULES),
        CountryCode.eu(),
        6,
        ValueRequirement<HistoricalInformationPeriod>.Absent
    ),
    EUTrustedEntitiesProfile(
        ServiceTypeIdentifiers.IssuanceAndRevocation(
            Uri.parse(ETSI19602.EU_WRPAC_PROVIDERS_SVC_TYPE_ISSUANCE),
            Uri.parse(ETSI19602.EU_WRPAC_PROVIDERS_SVC_TYPE_REVOCATION)
        ),
        true,
        emptyUriList(),
        ServiceDigitalIdentityCertificateType.CA
    )
)

/// WRPAC Provider CA constraints (LoTE CA) per ETSI TS 119 411-8.
public func wrpacProviderCertificateProfile(
    at!: ?DateTime = None,
    maxPathLen!: ?Int64 = None
): CertificateProfile {
    certificateProfile({ builder: ProfileBuilder =>
        builder.ca(maxPathLen)
        builder.keyUsageCertSign()
        builder.validAt(at)
        builder.policyIsPresent()
    })
}

public func wrpacProvidersProfileCheck<CERT, TRUST_ANCHOR>(
    loaded: LoadedLoTE,
    validator: CertificateProfileValidator<CERT>,
    certificatesFromIdentity: (ServiceDigitalIdentity) -> ArrayList<CERT>,
    getCertificateInfo: (CERT) -> String,
    createTrustAnchors: (ServiceDigitalIdentity) -> ArrayList<TRUST_ANCHOR>,
    at!: ?DateTime = None
): ArrayList<TRUST_ANCHOR> {
    EUWRPACProvidersList.ensureCompliesToProfile(loaded.list)
    let issuance = Uri.parse(ETSI19602.EU_WRPAC_PROVIDERS_SVC_TYPE_ISSUANCE)
    let providerCerts = ArrayList<CERT>()
    for (service in loaded.servicesOfType(issuance)) {
        let parsed = certificatesFromIdentity(service.information.digitalIdentity)
        for (certificate in parsed) {
            providerCerts.add(certificate)
        }
    }
    validator.ensureAllMet(wrpacProviderCertificateProfile(at: at), providerCerts, getCertificateInfo)
    loaded.trustAnchorsFor(issuance, createTrustAnchors)
}
