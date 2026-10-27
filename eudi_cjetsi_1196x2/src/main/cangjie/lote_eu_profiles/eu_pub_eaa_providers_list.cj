package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_eu_profiles

import std.collection.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation.LoadedLoTE
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model.*

public let EUPubEAAProvidersList: EUListOfTrustedEntitiesProfile = EUListOfTrustedEntitiesProfile(
    EUListAndSchemeInformationProfile(
        Uri.parse(ETSI19602.EU_PUB_EAA_PROVIDERS_LOTE),
        Uri.parse(ETSI19602.EU_PUB_EAA_PROVIDERS_STATUS_DETERMINATION_APPROACH),
        singleEnglishRule(ETSI19602.EU_PUB_EAA_PROVIDERS_SCHEME_COMMUNITY_RULES),
        CountryCode.eu(),
        6,
        ValueRequirement<HistoricalInformationPeriod>.Absent
    ),
    EUTrustedEntitiesProfile(
        ServiceTypeIdentifiers.IssuanceAndRevocation(
            Uri.parse(ETSI19602.EU_PUB_EAA_PROVIDERS_SVC_TYPE_ISSUANCE),
            Uri.parse(ETSI19602.EU_PUB_EAA_PROVIDERS_SVC_TYPE_REVOCATION)
        ),
        false,
        pubEaaServiceStatuses(),
        ServiceDigitalIdentityCertificateType.EndEntityOrCA
    )
)

func pubEaaServiceStatuses(): ArrayList<Uri> {
    let statuses = ArrayList<Uri>()
    statuses.add(Uri.parse("http://uri.etsi.org/19602/PubEAAProvidersList/SvcStatus/notified"))
    statuses.add(Uri.parse("http://uri.etsi.org/19602/PubEAAProvidersList/SvcStatus/withdrawn"))
    statuses
}

public func pubEaaProvidersProfileCheck<TRUST_ANCHOR>(
    loaded: LoadedLoTE,
    createTrustAnchors: (ServiceDigitalIdentity) -> ArrayList<TRUST_ANCHOR>
): ArrayList<TRUST_ANCHOR> {
    EUPubEAAProvidersList.ensureCompliesToProfile(loaded.list)
    loaded.trustAnchorsFor(
        Uri.parse(ETSI19602.EU_PUB_EAA_PROVIDERS_SVC_TYPE_ISSUANCE),
        createTrustAnchors
    )
}
