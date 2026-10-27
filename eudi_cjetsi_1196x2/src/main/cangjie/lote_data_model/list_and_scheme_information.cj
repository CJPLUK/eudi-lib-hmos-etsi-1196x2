package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model

import std.collection.*
import stdx.encoding.json.*

public class ListAndSchemeInformation {
    public var versionIdentifier: Int64
    public var sequenceNumber: Int64
    public var loteType: Option<Uri>
    public var schemeOperatorName: Array<MultilanguageString>
    public var schemeOperatorAddress: Option<SchemeOperatorAddress>
    public var schemeName: Option<Array<MultilanguageString>>
    public var schemeInformationURI: Option<Array<MultiLanguageURI>>
    public var statusDeterminationApproach: Option<Uri>
    public var schemeTypeCommunityRules: Option<Array<MultiLanguageURI>>
    public var schemeTerritory: Option<CountryCode>
    public var policyOrLegalNotice: Option<Array<PolicyOrLegalNotice>>
    public var historicalInformationPeriod: Option<HistoricalInformationPeriod>
    public var pointersToOtherLists: Option<Array<OtherLoTEPointer>>
    public var listIssueDateTime: LoTEDateTime
    public var nextUpdate: LoTEDateTime
    public var distributionPoints: Option<Array<Uri>>
    public var schemeExtensions: Option<JsonArray>

    public init(
        versionIdentifier: Int64,
        sequenceNumber: Int64,
        loteType: Option<Uri>,
        schemeOperatorName: Array<MultilanguageString>,
        schemeOperatorAddress: Option<SchemeOperatorAddress>,
        schemeName: Option<Array<MultilanguageString>>,
        schemeInformationURI: Option<Array<MultiLanguageURI>>,
        statusDeterminationApproach: Option<Uri>,
        schemeTypeCommunityRules: Option<Array<MultiLanguageURI>>,
        schemeTerritory: Option<CountryCode>,
        policyOrLegalNotice: Option<Array<PolicyOrLegalNotice>>,
        historicalInformationPeriod: Option<HistoricalInformationPeriod>,
        pointersToOtherLists: Option<Array<OtherLoTEPointer>>,
        listIssueDateTime: LoTEDateTime,
        nextUpdate: LoTEDateTime,
        distributionPoints: Option<Array<Uri>>,
        schemeExtensions: Option<JsonArray>
    ) {
        requireValidVersionIdentifier(versionIdentifier)
        requireValidSequenceNumber(sequenceNumber)
        Assertions.requireNonEmpty(schemeOperatorName, ETSI19602.SCHEME_OPERATOR_NAME)
        Assertions.requireNullOrNonEmpty(schemeName, ETSI19602.SCHEME_NAME)
        Assertions.requireNullOrNonEmpty(schemeInformationURI, ETSI19602.SCHEME_INFORMATION_URI)
        Assertions.requireNullOrNonEmpty(schemeTypeCommunityRules, ETSI19602.SCHEME_TYPE_COMMUNITY_RULES)
        Assertions.requireNullOrNonEmpty(policyOrLegalNotice, ETSI19602.POLICY_OR_LEGAL_NOTICE)
        Assertions.requireNullOrNonEmpty(distributionPoints, ETSI19602.DISTRIBUTION_POINTS)
        match (schemeExtensions) {
            case Some(ext) =>
                if (ext.size() == 0) {
                    throw IllegalArgumentException("${ETSI19602.SCHEME_EXTENSIONS} cannot be empty")
                }
            case None => ()
        }
        this.versionIdentifier = versionIdentifier
        this.sequenceNumber = sequenceNumber
        this.loteType = loteType
        this.schemeOperatorName = schemeOperatorName
        this.schemeOperatorAddress = schemeOperatorAddress
        this.schemeName = schemeName
        this.schemeInformationURI = schemeInformationURI
        this.statusDeterminationApproach = statusDeterminationApproach
        this.schemeTypeCommunityRules = schemeTypeCommunityRules
        this.schemeTerritory = schemeTerritory
        this.policyOrLegalNotice = policyOrLegalNotice
        this.historicalInformationPeriod = historicalInformationPeriod
        this.pointersToOtherLists = pointersToOtherLists
        this.listIssueDateTime = listIssueDateTime
        this.nextUpdate = nextUpdate
        this.distributionPoints = distributionPoints
        this.schemeExtensions = schemeExtensions
    }

    public static func requireValidVersionIdentifier(value: Int64): Unit {
        if (value != ETSI19602.LOTE_VERSION) {
            throw IllegalArgumentException(
                "Invalid ${ETSI19602.LOTE_VERSION_IDENTIFIER}. Expected ${ETSI19602.LOTE_VERSION}, got ${value}"
            )
        }
    }

    public static func requireValidSequenceNumber(value: Int64): Unit {
        if (value < ETSI19602.INITIAL_SEQUENCE_NUMBER) {
            throw IllegalArgumentException(
                "${ETSI19602.LOTE_SEQUENCE_NUMBER} must be equal or greater than ${ETSI19602.INITIAL_SEQUENCE_NUMBER}, got ${value}"
            )
        }
    }

    public static func implicit(
        sequenceNumber: Int64,
        loteType: Option<Uri>,
        schemeOperatorName: Array<MultilanguageString>,
        schemeOperatorAddress: Option<SchemeOperatorAddress>,
        schemeTerritory: Option<CountryCode>,
        historicalInformationPeriod: Option<HistoricalInformationPeriod>,
        pointerToOtherLote: Option<Array<OtherLoTEPointer>>,
        listIssueDateTime: LoTEDateTime,
        nextUpdate: LoTEDateTime,
        distributionPoints: Option<Array<Uri>>,
        schemeExtensions: Option<JsonArray>
    ): ListAndSchemeInformation {
        return ListAndSchemeInformation(
            ETSI19602.LOTE_VERSION,
            sequenceNumber,
            loteType,
            schemeOperatorName,
            schemeOperatorAddress,
            None,
            None,
            None,
            None,
            schemeTerritory,
            None,
            historicalInformationPeriod,
            pointerToOtherLote,
            listIssueDateTime,
            nextUpdate,
            distributionPoints,
            schemeExtensions
        )
    }

    public static func explicit(
        sequenceNumber: Int64,
        loteType: Uri,
        schemeOperatorName: Array<MultilanguageString>,
        schemeOperatorAddress: SchemeOperatorAddress,
        schemeName: Array<MultilanguageString>,
        schemeInformationURI: Array<MultiLanguageURI>,
        statusDeterminationApproach: Uri,
        schemeTypeCommunityRules: Array<MultiLanguageURI>,
        schemeTerritory: CountryCode,
        policyOrLegalNotice: Array<PolicyOrLegalNotice>,
        historicalInformationPeriod: Option<HistoricalInformationPeriod>,
        pointerToOtherLote: Option<Array<OtherLoTEPointer>>,
        listIssueDateTime: LoTEDateTime,
        nextUpdate: LoTEDateTime,
        distributionPoints: Option<Array<Uri>>,
        schemeExtensions: Option<JsonArray>
    ): ListAndSchemeInformation {
        return ListAndSchemeInformation(
            ETSI19602.LOTE_VERSION,
            sequenceNumber,
            Some(loteType),
            schemeOperatorName,
            Some(schemeOperatorAddress),
            Some(schemeName),
            Some(schemeInformationURI),
            Some(statusDeterminationApproach),
            Some(schemeTypeCommunityRules),
            Some(schemeTerritory),
            Some(policyOrLegalNotice),
            historicalInformationPeriod,
            pointerToOtherLote,
            listIssueDateTime,
            nextUpdate,
            distributionPoints,
            schemeExtensions
        )
    }

    public func ensureIsExplicit(): Unit {
        Assertions.checkNotNull(this.loteType, ETSI19602.LOTE_TYPE)
        Assertions.checkNotNull(this.schemeOperatorAddress, ETSI19602.SCHEME_OPERATOR_ADDRESS)
        Assertions.checkNotNull(this.schemeName, ETSI19602.SCHEME_NAME)
        Assertions.checkNotNull(this.schemeInformationURI, ETSI19602.SCHEME_INFORMATION_URI)
        Assertions.checkNotNull(this.statusDeterminationApproach, ETSI19602.STATUS_DETERMINATION_APPROACH)
        Assertions.checkNotNull(this.schemeTypeCommunityRules, ETSI19602.SCHEME_TYPE_COMMUNITY_RULES)
        Assertions.checkNotNull(this.schemeTerritory, ETSI19602.SCHEME_TERRITORY)
        Assertions.checkNotNull(this.policyOrLegalNotice, ETSI19602.POLICY_OR_LEGAL_NOTICE)
    }

    public func isExplicit(): Bool {
        try {
            this.ensureIsExplicit()
            return true
        } catch (e: IllegalStateException) {
            return false
        }
    }

    public func ensureIsImplicit(): Unit {
        Assertions.checkIsNull(this.schemeName, ETSI19602.SCHEME_NAME)
        Assertions.checkIsNull(this.schemeInformationURI, ETSI19602.SCHEME_INFORMATION_URI)
        Assertions.checkIsNull(this.statusDeterminationApproach, ETSI19602.STATUS_DETERMINATION_APPROACH)
        Assertions.checkIsNull(this.schemeTypeCommunityRules, ETSI19602.SCHEME_TYPE_COMMUNITY_RULES)
        Assertions.checkIsNull(this.policyOrLegalNotice, ETSI19602.POLICY_OR_LEGAL_NOTICE)
    }

    public func isImplicit(): Bool {
        try {
            this.ensureIsImplicit()
            return true
        } catch (e: IllegalStateException) {
            return false
        }
    }

    public static func fromJsonObject(obj: JsonObject): ListAndSchemeInformation {
        let loteType: Option<Uri> = match (JsonFields.optionalField(obj, ETSI19602.LOTE_TYPE)) {
            case Some(v) => Some(Uri.fromJsonValue(v))
            case None => None
        }
        let address: Option<SchemeOperatorAddress> = match (JsonFields.optionalObject(obj, ETSI19602.SCHEME_OPERATOR_ADDRESS)) {
            case Some(v) => Some(SchemeOperatorAddress.fromJsonObject(v))
            case None => None
        }
        let schemeName: Option<Array<MultilanguageString>> = match (JsonFields.optionalArray(obj, ETSI19602.SCHEME_NAME)) {
            case Some(arr) => Some(MultilanguageString.parseArray(arr))
            case None => None
        }
        let schemeInfo: Option<Array<MultiLanguageURI>> = match (JsonFields.optionalArray(obj, ETSI19602.SCHEME_INFORMATION_URI)) {
            case Some(arr) => Some(MultiLanguageURI.parseArray(arr))
            case None => None
        }
        let approach: Option<Uri> = match (JsonFields.optionalField(obj, ETSI19602.STATUS_DETERMINATION_APPROACH)) {
            case Some(v) => Some(Uri.fromJsonValue(v))
            case None => None
        }
        let rules: Option<Array<MultiLanguageURI>> = match (JsonFields.optionalArray(obj, ETSI19602.SCHEME_TYPE_COMMUNITY_RULES)) {
            case Some(arr) => Some(MultiLanguageURI.parseArray(arr))
            case None => None
        }
        let territory: Option<CountryCode> = match (JsonFields.optionalField(obj, ETSI19602.SCHEME_TERRITORY)) {
            case Some(v) => Some(CountryCode.fromJsonValue(v))
            case None => None
        }
        let policy: Option<Array<PolicyOrLegalNotice>> = match (JsonFields.optionalArray(obj, ETSI19602.POLICY_OR_LEGAL_NOTICE)) {
            case Some(arr) => Some(PolicyOrLegalNotice.parseArray(arr))
            case None => None
        }
        let period: Option<HistoricalInformationPeriod> = match (JsonFields.optionalInt(obj, ETSI19602.HISTORICAL_INFORMATION_PERIOD)) {
            case Some(v) => Some(HistoricalInformationPeriod(v))
            case None => None
        }
        let pointers: Option<Array<OtherLoTEPointer>> = match (JsonFields.optionalArray(obj, ETSI19602.POINTER_TO_OTHER_LOTE)) {
            case Some(arr) => Some(OtherLoTEPointer.parseArray(arr))
            case None => None
        }
        let dist: Option<Array<Uri>> = match (JsonFields.optionalArray(obj, ETSI19602.DISTRIBUTION_POINTS)) {
            case Some(arr) =>
                let out = ArrayList<Uri>()
                for (i in 0..arr.size()) {
                    out.add(Uri.fromJsonValue(arr[i]))
                }
                Some(Assertions.copyArray(out))
            case None => None
        }
        return ListAndSchemeInformation(
            JsonFields.requireInt(obj, ETSI19602.LOTE_VERSION_IDENTIFIER),
            JsonFields.requireInt(obj, ETSI19602.LOTE_SEQUENCE_NUMBER),
            loteType,
            MultilanguageString.parseArray(JsonFields.requireArray(obj, ETSI19602.SCHEME_OPERATOR_NAME)),
            address,
            schemeName,
            schemeInfo,
            approach,
            rules,
            territory,
            policy,
            period,
            pointers,
            LoTEDateTime.fromJsonValue(JsonFields.requireField(obj, ETSI19602.LIST_ISSUE_DATE_TIME)),
            LoTEDateTime.fromJsonValue(JsonFields.requireField(obj, ETSI19602.NEXT_UPDATE)),
            dist,
            JsonFields.optionalArray(obj, ETSI19602.SCHEME_EXTENSIONS)
        )
    }

    public func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.LOTE_VERSION_IDENTIFIER, JsonInt(this.versionIdentifier))
        obj.put(ETSI19602.LOTE_SEQUENCE_NUMBER, JsonInt(this.sequenceNumber))
        match (this.loteType) {
            case Some(v) => obj.put(ETSI19602.LOTE_TYPE, v.toJsonValue())
            case None => ()
        }
        obj.put(ETSI19602.SCHEME_OPERATOR_NAME, MultilanguageString.toJsonArray(this.schemeOperatorName))
        match (this.schemeOperatorAddress) {
            case Some(v) => obj.put(ETSI19602.SCHEME_OPERATOR_ADDRESS, v.toJsonValue())
            case None => ()
        }
        match (this.schemeName) {
            case Some(items) => obj.put(ETSI19602.SCHEME_NAME, MultilanguageString.toJsonArray(items))
            case None => ()
        }
        match (this.schemeInformationURI) {
            case Some(items) => obj.put(ETSI19602.SCHEME_INFORMATION_URI, MultiLanguageURI.toJsonArray(items))
            case None => ()
        }
        match (this.statusDeterminationApproach) {
            case Some(v) => obj.put(ETSI19602.STATUS_DETERMINATION_APPROACH, v.toJsonValue())
            case None => ()
        }
        match (this.schemeTypeCommunityRules) {
            case Some(items) => obj.put(ETSI19602.SCHEME_TYPE_COMMUNITY_RULES, MultiLanguageURI.toJsonArray(items))
            case None => ()
        }
        match (this.schemeTerritory) {
            case Some(v) => obj.put(ETSI19602.SCHEME_TERRITORY, v.toJsonValue())
            case None => ()
        }
        match (this.policyOrLegalNotice) {
            case Some(items) => obj.put(ETSI19602.POLICY_OR_LEGAL_NOTICE, PolicyOrLegalNotice.toJsonArray(items))
            case None => ()
        }
        match (this.historicalInformationPeriod) {
            case Some(v) => obj.put(ETSI19602.HISTORICAL_INFORMATION_PERIOD, JsonInt(v.value))
            case None => ()
        }
        match (this.pointersToOtherLists) {
            case Some(items) => obj.put(ETSI19602.POINTER_TO_OTHER_LOTE, OtherLoTEPointer.toJsonArray(items))
            case None => ()
        }
        obj.put(ETSI19602.LIST_ISSUE_DATE_TIME, this.listIssueDateTime.toJsonValue())
        obj.put(ETSI19602.NEXT_UPDATE, this.nextUpdate.toJsonValue())
        match (this.distributionPoints) {
            case Some(items) =>
                var arr = JsonArray()
                for (item in items) {
                    arr = arr.add(item.toJsonValue())
                }
                obj.put(ETSI19602.DISTRIBUTION_POINTS, arr)
            case None => ()
        }
        match (this.schemeExtensions) {
            case Some(ext) => obj.put(ETSI19602.SCHEME_EXTENSIONS, ext)
            case None => ()
        }
        return obj
    }
}

public class SchemeOperatorAddress {
    public var postalAddresses: Array<PostalAddress>
    public var electronicAddresses: Array<MultiLanguageURI>

    public init(postalAddresses: Array<PostalAddress>, electronicAddresses: Array<MultiLanguageURI>) {
        Assertions.requireNonEmpty(postalAddresses, ETSI19602.SCHEME_OPERATOR_POSTAL_ADDRESS)
        Assertions.requireNonEmpty(electronicAddresses, ETSI19602.SCHEME_OPERATOR_ELECTRONIC_ADDRESS)
        this.postalAddresses = postalAddresses
        this.electronicAddresses = electronicAddresses
    }

    public static func fromJsonObject(obj: JsonObject): SchemeOperatorAddress {
        return SchemeOperatorAddress(
            PostalAddress.parseArray(JsonFields.requireArray(obj, ETSI19602.SCHEME_OPERATOR_POSTAL_ADDRESS)),
            MultiLanguageURI.parseArray(JsonFields.requireArray(obj, ETSI19602.SCHEME_OPERATOR_ELECTRONIC_ADDRESS))
        )
    }

    public func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.SCHEME_OPERATOR_POSTAL_ADDRESS, PostalAddress.toJsonArray(this.postalAddresses))
        obj.put(ETSI19602.SCHEME_OPERATOR_ELECTRONIC_ADDRESS, MultiLanguageURI.toJsonArray(this.electronicAddresses))
        return obj
    }
}

public open class PolicyOrLegalNotice {
    public open func toJsonValue(): JsonValue {
        throw IllegalArgumentException("Invalid policy or legal notice")
    }

    public static func fromJsonObject(obj: JsonObject): PolicyOrLegalNotice {
        if (obj.containsKey(ETSI19602.LOTE_POLICY)) {
            return LoTEPolicy(MultiLanguageURI.fromJsonObject(JsonFields.requireObject(obj, ETSI19602.LOTE_POLICY)))
        }
        if (obj.containsKey(ETSI19602.LOTE_LEGAL_NOTICE)) {
            return LoTELegalNotice(JsonFields.requireString(obj, ETSI19602.LOTE_LEGAL_NOTICE))
        }
        throw IllegalArgumentException("Invalid policy or legal notice")
    }

    public static func parseArray(arr: JsonArray): Array<PolicyOrLegalNotice> {
        let out = ArrayList<PolicyOrLegalNotice>()
        for (i in 0..arr.size()) {
            out.add(fromJsonObject(arr[i].asObject()))
        }
        return Assertions.copyArray(out)
    }

    public static func toJsonArray(items: Array<PolicyOrLegalNotice>): JsonValue {
        var arr = JsonArray()
        for (item in items) {
            arr = arr.add(item.toJsonValue())
        }
        return arr
    }
}

public class LoTEPolicy <: PolicyOrLegalNotice {
    public var policy: MultiLanguageURI

    public init(policy: MultiLanguageURI) {
        this.policy = policy
    }

    public override func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.LOTE_POLICY, this.policy.toJsonValue())
        return obj
    }
}

public class LoTELegalNotice <: PolicyOrLegalNotice {
    public var legalNotice: String

    public init(legalNotice: String) {
        this.legalNotice = legalNotice
    }

    public override func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.LOTE_LEGAL_NOTICE, JsonString(this.legalNotice))
        return obj
    }
}

public class HistoricalInformationPeriod {
    public var value: Int64

    public init(value: Int64) {
        this.value = value
    }
}

public class OtherLoTEPointer {
    public var location: Uri
    public var serviceDigitalIdentities: Array<ServiceDigitalIdentity>
    public var qualifiers: Array<LoTEQualifier>

    public init(
        location: Uri,
        serviceDigitalIdentities: Array<ServiceDigitalIdentity>,
        qualifiers: Array<LoTEQualifier>
    ) {
        Assertions.requireNonEmpty(serviceDigitalIdentities, ETSI19602.SERVICE_DIGITAL_IDENTITIES)
        Assertions.requireNonEmpty(qualifiers, ETSI19602.LOTE_QUALIFIERS)
        this.location = location
        this.serviceDigitalIdentities = serviceDigitalIdentities
        this.qualifiers = qualifiers
    }

    public static func fromJsonObject(obj: JsonObject): OtherLoTEPointer {
        return OtherLoTEPointer(
            Uri.fromJsonValue(JsonFields.requireField(obj, ETSI19602.LOTE_LOCATION)),
            ServiceDigitalIdentity.parseArray(JsonFields.requireArray(obj, ETSI19602.SERVICE_DIGITAL_IDENTITIES)),
            LoTEQualifier.parseArray(JsonFields.requireArray(obj, ETSI19602.LOTE_QUALIFIERS))
        )
    }

    public func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.LOTE_LOCATION, this.location.toJsonValue())
        obj.put(ETSI19602.SERVICE_DIGITAL_IDENTITIES, ServiceDigitalIdentity.toJsonArray(this.serviceDigitalIdentities))
        obj.put(ETSI19602.LOTE_QUALIFIERS, LoTEQualifier.toJsonArray(this.qualifiers))
        return obj
    }

    public static func parseArray(arr: JsonArray): Array<OtherLoTEPointer> {
        let out = ArrayList<OtherLoTEPointer>()
        for (i in 0..arr.size()) {
            out.add(fromJsonObject(arr[i].asObject()))
        }
        return Assertions.copyArray(out)
    }

    public static func toJsonArray(items: Array<OtherLoTEPointer>): JsonValue {
        var arr = JsonArray()
        for (item in items) {
            arr = arr.add(item.toJsonValue())
        }
        return arr
    }
}

public class LoTEQualifier {
    public var loteType: Uri
    public var schemeOperatorName: Array<MultilanguageString>
    public var schemeTypeCommunityRules: Option<Array<MultiLanguageURI>>
    public var schemeTerritory: Option<CountryCode>
    public var mimeType: String

    public init(
        loteType: Uri,
        schemeOperatorName: Array<MultilanguageString>,
        schemeTypeCommunityRules: Option<Array<MultiLanguageURI>>,
        schemeTerritory: Option<CountryCode>,
        mimeType: String
    ) {
        Assertions.requireNonEmpty(schemeOperatorName, ETSI19602.SCHEME_OPERATOR_NAME)
        Assertions.requireNotBlank(mimeType, ETSI19602.MIME_TYPE)
        this.loteType = loteType
        this.schemeOperatorName = schemeOperatorName
        this.schemeTypeCommunityRules = schemeTypeCommunityRules
        this.schemeTerritory = schemeTerritory
        this.mimeType = mimeType
    }

    public static func fromJsonObject(obj: JsonObject): LoTEQualifier {
        let rules: Option<Array<MultiLanguageURI>> = match (JsonFields.optionalArray(obj, ETSI19602.SCHEME_TYPE_COMMUNITY_RULES)) {
            case Some(arr) => Some(MultiLanguageURI.parseArray(arr))
            case None => None
        }
        let territory: Option<CountryCode> = match (JsonFields.optionalField(obj, ETSI19602.SCHEME_TERRITORY)) {
            case Some(v) => Some(CountryCode.fromJsonValue(v))
            case None => None
        }
        return LoTEQualifier(
            Uri.fromJsonValue(JsonFields.requireField(obj, ETSI19602.LOTE_TYPE)),
            MultilanguageString.parseArray(JsonFields.requireArray(obj, ETSI19602.SCHEME_OPERATOR_NAME)),
            rules,
            territory,
            JsonFields.requireString(obj, ETSI19602.MIME_TYPE)
        )
    }

    public func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.LOTE_TYPE, this.loteType.toJsonValue())
        obj.put(ETSI19602.SCHEME_OPERATOR_NAME, MultilanguageString.toJsonArray(this.schemeOperatorName))
        match (this.schemeTypeCommunityRules) {
            case Some(items) => obj.put(ETSI19602.SCHEME_TYPE_COMMUNITY_RULES, MultiLanguageURI.toJsonArray(items))
            case None => ()
        }
        match (this.schemeTerritory) {
            case Some(v) => obj.put(ETSI19602.SCHEME_TERRITORY, v.toJsonValue())
            case None => ()
        }
        obj.put(ETSI19602.MIME_TYPE, JsonString(this.mimeType))
        return obj
    }

    public static func parseArray(arr: JsonArray): Array<LoTEQualifier> {
        let out = ArrayList<LoTEQualifier>()
        for (i in 0..arr.size()) {
            out.add(fromJsonObject(arr[i].asObject()))
        }
        return Assertions.copyArray(out)
    }

    public static func toJsonArray(items: Array<LoTEQualifier>): JsonValue {
        var arr = JsonArray()
        for (item in items) {
            arr = arr.add(item.toJsonValue())
        }
        return arr
    }
}
