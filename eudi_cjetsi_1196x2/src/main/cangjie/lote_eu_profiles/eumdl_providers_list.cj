package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_eu_profiles

import std.collection.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation.LoadedLoTE
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model.*

/// mDL Providers List Specification URIs.
public class EUMDLProvidersListSpec {
    public static let LOTE_TYPE: String = "http://trust.ec.europa.eu/lists/mDL/mDLProvidersListType"
    public static let STATUS_DETERMINATION_APPROACH: String =
        "http://trust.ec.europa.eu/lists/mDL/mDLProvidersListStatusDetn"
    public static let SCHEME_COMMUNITY_RULES: String = "http://trust.ec.europa.eu/lists/mDL/schemerules"
    public static let SVC_TYPE_ISSUANCE: String = "http://trust.ec.europa.eu/lists/mDL/SvcType/Issuance"
    public static let SVC_TYPE_REVOCATION: String = "http://trust.ec.europa.eu/lists/mDL/SvcType/Revocation"
    public static let SVC_TYPE_ISSUANCE_2: String = "http://uri.etsi.org/19602/SvcType/mDL/Issuance"
}

public let EUMDLProvidersList: EUListOfTrustedEntitiesProfile = EUListOfTrustedEntitiesProfile(
    EUListAndSchemeInformationProfile(
        Uri.parse(EUMDLProvidersListSpec.LOTE_TYPE),
        Uri.parse(EUMDLProvidersListSpec.STATUS_DETERMINATION_APPROACH),
        singleEnglishRule(EUMDLProvidersListSpec.SCHEME_COMMUNITY_RULES),
        CountryCode.eu(),
        6,
        ValueRequirement<HistoricalInformationPeriod>.Absent
    ),
    EUTrustedEntitiesProfile(
        ServiceTypeIdentifiers.IssuanceAndRevocation(
            Uri.parse(EUMDLProvidersListSpec.SVC_TYPE_ISSUANCE),
            Uri.parse(EUMDLProvidersListSpec.SVC_TYPE_REVOCATION)
        ),
        true,
        emptyUriList(),
        ServiceDigitalIdentityCertificateType.EndEntityOrCA
    )
)

public func eumdlProvidersProfileCheck<TRUST_ANCHOR>(
    loaded: LoadedLoTE,
    createTrustAnchors: (ServiceDigitalIdentity) -> ArrayList<TRUST_ANCHOR>
): ArrayList<TRUST_ANCHOR> {
    EUMDLProvidersList.ensureCompliesToProfile(loaded.list)
    loaded.trustAnchorsFor(
        Uri.parse(EUMDLProvidersListSpec.SVC_TYPE_ISSUANCE),
        createTrustAnchors
    )
}
