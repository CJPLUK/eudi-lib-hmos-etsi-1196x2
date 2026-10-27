package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_eu_profiles

import std.collection.*
import std.time.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model.*

public enum ValueRequirement<T> {
    | Required(T)
    | Absent
}

public enum ServiceTypeIdentifiers {
    | IssuanceAndRevocation(Uri, Uri)
    | OneOrMore(ArrayList<Uri>)
}

public enum ServiceDigitalIdentityCertificateType {
    | EndEntity
    | CA
    | EndEntityOrCA
}

public class EUListAndSchemeInformationProfile {
    public let loteType: Uri
    public let statusDeterminationApproach: Uri
    public let schemeCommunityRules: ArrayList<MultiLanguageURI>
    public let schemeTerritory: CountryCode
    public let maxMonthsUntilNextUpdate: Int64
    public let historicalInformationPeriod: ValueRequirement<HistoricalInformationPeriod>

    public init(
        loteType: Uri,
        statusDeterminationApproach: Uri,
        schemeCommunityRules: ArrayList<MultiLanguageURI>,
        schemeTerritory: CountryCode,
        maxMonthsUntilNextUpdate: Int64,
        historicalInformationPeriod: ValueRequirement<HistoricalInformationPeriod>
    ) {
        this.loteType = loteType
        this.statusDeterminationApproach = statusDeterminationApproach
        this.schemeCommunityRules = schemeCommunityRules
        this.schemeTerritory = schemeTerritory
        this.maxMonthsUntilNextUpdate = maxMonthsUntilNextUpdate
        this.historicalInformationPeriod = historicalInformationPeriod
    }
}

public class EUTrustedEntitiesProfile {
    public let serviceTypeIdentifiers: ServiceTypeIdentifiers
    public let serviceDigitalIdentityMustHaveCertificates: Bool
    public let serviceStatuses: ArrayList<Uri>
    public let serviceDigitalIdentityCertificateType: ServiceDigitalIdentityCertificateType

    public init(
        serviceTypeIdentifiers: ServiceTypeIdentifiers,
        serviceDigitalIdentityMustHaveCertificates: Bool,
        serviceStatuses: ArrayList<Uri>,
        serviceDigitalIdentityCertificateType: ServiceDigitalIdentityCertificateType
    ) {
        this.serviceTypeIdentifiers = serviceTypeIdentifiers
        this.serviceDigitalIdentityMustHaveCertificates = serviceDigitalIdentityMustHaveCertificates
        this.serviceStatuses = serviceStatuses
        this.serviceDigitalIdentityCertificateType = serviceDigitalIdentityCertificateType
    }
}

/// Expectations about an EU-specific LoTE (PID / Wallet / WRPAC / WRPRC / PubEAA / mDL).
public class EUListOfTrustedEntitiesProfile {
    public let listAndSchemeInformation: EUListAndSchemeInformationProfile
    public let trustedEntities: EUTrustedEntitiesProfile

    public init(
        listAndSchemeInformation: EUListAndSchemeInformationProfile,
        trustedEntities: EUTrustedEntitiesProfile
    ) {
        this.listAndSchemeInformation = listAndSchemeInformation
        this.trustedEntities = trustedEntities
    }

    /// Rejects a LoTE that fails schemeInformation or trusted-entity profile checks.
    public func ensureCompliesToProfile(lote: ListOfTrustedEntities): Unit {
        this.checkSchemeInformation(lote)
        this.checkTrustedEntities(lote)
    }

    func checkSchemeInformation(lote: ListOfTrustedEntities): Unit {
        try {
            ensureSchemeCompliesTo(lote.schemeInformation, this.listAndSchemeInformation)
        } catch (e: IllegalStateException) {
            throw IllegalStateException(
                "Violation of ${this.listAndSchemeInformation.loteType.value}: ${e.message}"
            )
        }
    }

    func checkTrustedEntities(lote: ListOfTrustedEntities): Unit {
        let errors = ArrayList<String>()
        match (lote.entities) {
            case None => ()
            case Some(entities) =>
                var index: Int64 = 0
                for (entity in entities) {
                    try {
                        ensureTrustedEntity(entity, this.trustedEntities)
                    } catch (e: IllegalStateException) {
                        errors.add("${index}: ${e.message}")
                    }
                    index = index + 1
                }
        }
        if (errors.size != 0) {
            var joined = ""
            var first = true
            for (item in errors) {
                if (first) {
                    joined = item
                    first = false
                } else {
                    joined = joined + ", " + item
                }
            }
            throw IllegalStateException(
                "Violation of ${this.listAndSchemeInformation.loteType.value}, trusted entities errors: ${joined}"
            )
        }
    }
}

public func serviceTypeIdentifierValues(identifiers: ServiceTypeIdentifiers): ArrayList<Uri> {
    let out = ArrayList<Uri>()
    match (identifiers) {
        case ServiceTypeIdentifiers.IssuanceAndRevocation(issuance, revocation) =>
            out.add(issuance)
            out.add(revocation)
        case ServiceTypeIdentifiers.OneOrMore(values) =>
            if (values.size == 0) {
                throw IllegalArgumentException("Service type identifiers cannot be empty")
            }
            for (item in values) {
                out.add(item)
            }
    }
    out
}

func ensureSchemeCompliesTo(
    scheme: ListAndSchemeInformation,
    expected: EUListAndSchemeInformationProfile
): Unit {
    scheme.ensureIsExplicit()
    ensureTypeIs(scheme, expected.loteType)
    ensureStatusDeterminationApproachIs(scheme, expected.statusDeterminationApproach)
    ensureSchemeCommunityRulesIs(scheme, expected.schemeCommunityRules)
    ensureSchemeTerritoryIs(scheme, expected.schemeTerritory)
    ensureHistoricalInformationPeriod(scheme, expected.historicalInformationPeriod)
    ensureNextUpdateIsWithinMonths(scheme, expected.maxMonthsUntilNextUpdate)
}

func ensureTypeIs(scheme: ListAndSchemeInformation, expected: Uri): Unit {
    let actual = Assertions.checkNotNull(scheme.loteType, ETSI19602.LOTE_TYPE)
    if (!uriEquals(actual, expected)) {
        throw IllegalStateException(
            "Invalid ${ETSI19602.LOTE_TYPE}. Expected ${expected.value}, got ${actual.value}"
        )
    }
}

func ensureStatusDeterminationApproachIs(scheme: ListAndSchemeInformation, expected: Uri): Unit {
    let actual = Assertions.checkNotNull(
        scheme.statusDeterminationApproach,
        ETSI19602.STATUS_DETERMINATION_APPROACH
    )
    if (!uriEquals(actual, expected)) {
        throw IllegalStateException(
            "Invalid ${ETSI19602.STATUS_DETERMINATION_APPROACH}. Expected ${expected.value}, got ${actual.value}"
        )
    }
}

func ensureSchemeCommunityRulesIs(
    scheme: ListAndSchemeInformation,
    expected: ArrayList<MultiLanguageURI>
): Unit {
    let actual = Assertions.checkNotNull(
        scheme.schemeTypeCommunityRules,
        ETSI19602.SCHEME_TYPE_COMMUNITY_RULES
    )
    if (actual.size != expected.size || !allCommunityRulesInExpected(actual, expected)) {
        throw IllegalStateException(
            "Invalid ${ETSI19602.SCHEME_TYPE_COMMUNITY_RULES}. Expected ${communityRulesDebug(expected)}, got ${communityRulesArrayDebug(actual)}"
        )
    }
}

func ensureSchemeTerritoryIs(scheme: ListAndSchemeInformation, expected: CountryCode): Unit {
    let actual = Assertions.checkNotNull(scheme.schemeTerritory, ETSI19602.SCHEME_TERRITORY)
    if (actual.value != expected.value) {
        throw IllegalStateException(
            "Invalid ${ETSI19602.SCHEME_TERRITORY}. Expected ${expected.value}, got ${actual.value}"
        )
    }
}

func ensureHistoricalInformationPeriod(
    scheme: ListAndSchemeInformation,
    requirement: ValueRequirement<HistoricalInformationPeriod>
): Unit {
    match (requirement) {
        case ValueRequirement.Required(expected) =>
            let actual = Assertions.checkNotNull(
                scheme.historicalInformationPeriod,
                ETSI19602.HISTORICAL_INFORMATION_PERIOD
            )
            if (actual.value != expected.value) {
                throw IllegalStateException(
                    "Invalid ${ETSI19602.HISTORICAL_INFORMATION_PERIOD}. Expected ${expected.value}, got ${actual.value}"
                )
            }
        case ValueRequirement.Absent =>
            Assertions.checkIsNull(scheme.historicalInformationPeriod, ETSI19602.HISTORICAL_INFORMATION_PERIOD)
    }
}

func ensureNextUpdateIsWithinMonths(scheme: ListAndSchemeInformation, months: Int64): Unit {
    let monthsUntilNextUpdate = monthsBetween(scheme.listIssueDateTime, scheme.nextUpdate)
    if (monthsUntilNextUpdate < 0 || monthsUntilNextUpdate > months) {
        throw IllegalStateException(
            "${ETSI19602.NEXT_UPDATE} must be within ${months} months from ${ETSI19602.LIST_ISSUE_DATE_TIME}, got ${monthsUntilNextUpdate} months"
        )
    }
}

func monthsBetween(from: LoTEDateTime, to: LoTEDateTime): Int64 {
    let start = DateTime.parse(from.isoValue)
    let end = DateTime.parse(to.isoValue)
    var months = (end.year - start.year) * 12 + (end.monthValue - start.monthValue)
    if (end.dayOfMonth < start.dayOfMonth) {
        months = months - 1
    }
    months
}

func ensureTrustedEntity(entity: TrustedEntity, profile: EUTrustedEntitiesProfile): Unit {
    for (service in entity.services) {
        ensureServiceInformationCompliesTo(service.information, profile)
        match (service.history) {
            case None => ()
            case Some(history) =>
                for (instance in history) {
                    ensureServiceHistoryCompliesTo(instance, profile)
                }
        }
    }
}

func ensureServiceInformationCompliesTo(
    information: ServiceInformation,
    profile: EUTrustedEntitiesProfile
): Unit {
    ensureServiceTypeIsAnyOf(information.typeIdentifier, profile.serviceTypeIdentifiers)
    ensureDigitalIdentityContainsX509Certificate(
        information.digitalIdentity,
        profile.serviceDigitalIdentityMustHaveCertificates
    )
    ensureServiceStatusIn(information.status, information.statusStartingTime, profile.serviceStatuses)
}

func ensureServiceHistoryCompliesTo(
    instance: ServiceHistoryInstance,
    profile: EUTrustedEntitiesProfile
): Unit {
    ensureServiceTypeIsAnyOf(instance.typeIdentifier, profile.serviceTypeIdentifiers)
    ensureDigitalIdentityContainsX509Certificate(
        instance.digitalIdentity,
        profile.serviceDigitalIdentityMustHaveCertificates
    )
}

func ensureServiceTypeIsAnyOf(typeIdentifier: Option<Uri>, expected: ServiceTypeIdentifiers): Unit {
    let actual = Assertions.checkNotNull(typeIdentifier, ETSI19602.SERVICE_TYPE_IDENTIFIER)
    let allowed = serviceTypeIdentifierValues(expected)
    if (!uriListContains(allowed, actual)) {
        throw IllegalStateException(
            "Invalid ${ETSI19602.SERVICE_TYPE_IDENTIFIER}. Expected one of ${uriListDebug(allowed)}, got ${actual.value}"
        )
    }
}

func ensureDigitalIdentityContainsX509Certificate(
    digitalIdentity: ServiceDigitalIdentity,
    mustContainX509Certificates: Bool
): Unit {
    if (mustContainX509Certificates) {
        Assertions.checkNotNull(digitalIdentity.x509Certificates, ETSI19602.X509_CERTIFICATES)
    }
}

func ensureServiceStatusIn(
    status: Option<Uri>,
    statusStartingTime: Option<LoTEDateTime>,
    statuses: ArrayList<Uri>
): Unit {
    if (statuses.size == 0) {
        Assertions.checkIsNull(status, ETSI19602.SERVICE_STATUS)
        Assertions.checkIsNull(statusStartingTime, ETSI19602.STATUS_STARTING_TIME)
    } else {
        let actual = Assertions.checkNotNull(status, ETSI19602.SERVICE_STATUS)
        Assertions.checkNotNull(statusStartingTime, ETSI19602.STATUS_STARTING_TIME)
        if (!uriListContains(statuses, actual)) {
            throw IllegalStateException(
                "Invalid ${ETSI19602.SERVICE_STATUS}. Expected one of ${uriListDebug(statuses)}, got ${actual.value}"
            )
        }
    }
}

func uriEquals(left: Uri, right: Uri): Bool {
    left.value == right.value
}

func uriListContains(items: ArrayList<Uri>, value: Uri): Bool {
    for (item in items) {
        if (uriEquals(item, value)) {
            return true
        }
    }
    false
}

func uriListDebug(items: ArrayList<Uri>): String {
    var out = "["
    var first = true
    for (item in items) {
        if (first) {
            out = out + item.value
            first = false
        } else {
            out = out + ", " + item.value
        }
    }
    out + "]"
}

func multiLanguageUriEquals(left: MultiLanguageURI, right: MultiLanguageURI): Bool {
    left.language.value == right.language.value && uriEquals(left.value, right.value)
}

func allCommunityRulesInExpected(
    actual: Array<MultiLanguageURI>,
    expected: ArrayList<MultiLanguageURI>
): Bool {
    for (item in actual) {
        var found = false
        for (rule in expected) {
            if (multiLanguageUriEquals(item, rule)) {
                found = true
            }
        }
        if (!found) {
            return false
        }
    }
    true
}

func communityRulesDebug(items: ArrayList<MultiLanguageURI>): String {
    var out = "["
    var first = true
    for (item in items) {
        let piece = "${item.language.value}:${item.value.value}"
        if (first) {
            out = out + piece
            first = false
        } else {
            out = out + ", " + piece
        }
    }
    out + "]"
}

func communityRulesArrayDebug(items: Array<MultiLanguageURI>): String {
    var out = "["
    var first = true
    for (item in items) {
        let piece = "${item.language.value}:${item.value.value}"
        if (first) {
            out = out + piece
            first = false
        } else {
            out = out + ", " + piece
        }
    }
    out + "]"
}

func singleEnglishRule(uriValue: String): ArrayList<MultiLanguageURI> {
    let rules = ArrayList<MultiLanguageURI>()
    rules.add(MultiLanguageURI.en(Uri.parse(uriValue)))
    rules
}

func emptyUriList(): ArrayList<Uri> {
    ArrayList<Uri>()
}

/// Classify a LoTE ServiceDigitalIdentity certificate as CA (cA=TRUE) vs end-entity.
/// Probe is basicConstraints only — not the EE signing or CA provider profiles.
func loteIdentityIsCA<CERT>(
    validator: CertificateProfileValidator<CERT>,
    certificate: CERT
): Bool {
    let noPathLen: ?Int64 = None
    let probe = certificateProfile({ builder: ProfileBuilder =>
        builder.ca(noPathLen)
    })
    evaluationIsMet(validator.validate(probe, certificate))
}
