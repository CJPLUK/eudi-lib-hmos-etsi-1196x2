package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model

import std.collection.*
import stdx.encoding.json.*

public class TrustedEntity {
    public var information: TrustedEntityInformation
    public var services: Array<TrustedEntityService>

    public init(information: TrustedEntityInformation, services: Array<TrustedEntityService>) {
        Assertions.requireNonEmpty(services, ETSI19602.TRUSTED_ENTITY_SERVICES)
        this.information = information
        this.services = services
    }

    public static func fromJsonObject(obj: JsonObject): TrustedEntity {
        return TrustedEntity(
            TrustedEntityInformation.fromJsonObject(JsonFields.requireObject(obj, ETSI19602.TRUSTED_ENTITY_INFORMATION)),
            TrustedEntityService.parseArray(JsonFields.requireArray(obj, ETSI19602.TRUSTED_ENTITY_SERVICES))
        )
    }

    public func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.TRUSTED_ENTITY_INFORMATION, this.information.toJsonValue())
        obj.put(ETSI19602.TRUSTED_ENTITY_SERVICES, TrustedEntityService.toJsonArray(this.services))
        return obj
    }

    public static func parseArray(arr: JsonArray): Array<TrustedEntity> {
        let out = ArrayList<TrustedEntity>()
        for (i in 0..arr.size()) {
            out.add(fromJsonObject(arr[i].asObject()))
        }
        return Assertions.copyArray(out)
    }

    public static func toJsonArray(items: Array<TrustedEntity>): JsonValue {
        var arr = JsonArray()
        for (item in items) {
            arr = arr.add(item.toJsonValue())
        }
        return arr
    }
}

public class TrustedEntityInformation {
    public var name: Array<MultilanguageString>
    public var address: TEAddress
    public var informationURI: Array<MultiLanguageURI>
    public var tradeName: Option<Array<MultilanguageString>>

    public init(
        name: Array<MultilanguageString>,
        address: TEAddress,
        informationURI: Array<MultiLanguageURI>,
        tradeName: Option<Array<MultilanguageString>>
    ) {
        Assertions.requireNonEmpty(name, ETSI19602.TE_NAME)
        Assertions.requireNonEmpty(informationURI, ETSI19602.TE_INFORMATION_URI)
        Assertions.requireNullOrNonEmpty(tradeName, ETSI19602.TE_TRADE_NAME)
        this.name = name
        this.address = address
        this.informationURI = informationURI
        this.tradeName = tradeName
    }

    public static func fromJsonObject(obj: JsonObject): TrustedEntityInformation {
        let trade: Option<Array<MultilanguageString>> = match (JsonFields.optionalArray(obj, ETSI19602.TE_TRADE_NAME)) {
            case Some(arr) => Some(MultilanguageString.parseArray(arr))
            case None => None
        }
        return TrustedEntityInformation(
            MultilanguageString.parseArray(JsonFields.requireArray(obj, ETSI19602.TE_NAME)),
            TEAddress.fromJsonObject(JsonFields.requireObject(obj, ETSI19602.TE_ADDRESS)),
            MultiLanguageURI.parseArray(JsonFields.requireArray(obj, ETSI19602.TE_INFORMATION_URI)),
            trade
        )
    }

    public func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.TE_NAME, MultilanguageString.toJsonArray(this.name))
        obj.put(ETSI19602.TE_ADDRESS, this.address.toJsonValue())
        obj.put(ETSI19602.TE_INFORMATION_URI, MultiLanguageURI.toJsonArray(this.informationURI))
        match (this.tradeName) {
            case Some(items) => obj.put(ETSI19602.TE_TRADE_NAME, MultilanguageString.toJsonArray(items))
            case None => ()
        }
        return obj
    }
}

public class TEAddress {
    public var postalAddresses: Array<PostalAddress>
    public var electronicAddresses: Array<MultiLanguageURI>

    public init(postalAddresses: Array<PostalAddress>, electronicAddresses: Array<MultiLanguageURI>) {
        Assertions.requireNonEmpty(postalAddresses, ETSI19602.TE_POSTAL_ADDRESS)
        Assertions.requireNonEmpty(electronicAddresses, ETSI19602.TE_ELECTRONIC_ADDRESS)
        this.postalAddresses = postalAddresses
        this.electronicAddresses = electronicAddresses
    }

    public static func fromJsonObject(obj: JsonObject): TEAddress {
        return TEAddress(
            PostalAddress.parseArray(JsonFields.requireArray(obj, ETSI19602.TE_POSTAL_ADDRESS)),
            MultiLanguageURI.parseArray(JsonFields.requireArray(obj, ETSI19602.TE_ELECTRONIC_ADDRESS))
        )
    }

    public func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.TE_POSTAL_ADDRESS, PostalAddress.toJsonArray(this.postalAddresses))
        obj.put(ETSI19602.TE_ELECTRONIC_ADDRESS, MultiLanguageURI.toJsonArray(this.electronicAddresses))
        return obj
    }
}

public class TrustedEntityService {
    public var information: ServiceInformation
    public var history: Option<Array<ServiceHistoryInstance>>

    public init(information: ServiceInformation, history: Option<Array<ServiceHistoryInstance>>) {
        Assertions.requireNullOrNonEmpty(history, ETSI19602.SERVICE_HISTORY)
        this.information = information
        this.history = history
    }

    public static func fromJsonObject(obj: JsonObject): TrustedEntityService {
        let history: Option<Array<ServiceHistoryInstance>> = match (JsonFields.optionalArray(obj, ETSI19602.SERVICE_HISTORY)) {
            case Some(arr) => Some(ServiceHistoryInstance.parseArray(arr))
            case None => None
        }
        return TrustedEntityService(
            ServiceInformation.fromJsonObject(JsonFields.requireObject(obj, ETSI19602.SERVICE_INFORMATION)),
            history
        )
    }

    public func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.SERVICE_INFORMATION, this.information.toJsonValue())
        match (this.history) {
            case Some(items) => obj.put(ETSI19602.SERVICE_HISTORY, ServiceHistoryInstance.toJsonArray(items))
            case None => ()
        }
        return obj
    }

    public static func parseArray(arr: JsonArray): Array<TrustedEntityService> {
        let out = ArrayList<TrustedEntityService>()
        for (i in 0..arr.size()) {
            out.add(fromJsonObject(arr[i].asObject()))
        }
        return Assertions.copyArray(out)
    }

    public static func toJsonArray(items: Array<TrustedEntityService>): JsonValue {
        var arr = JsonArray()
        for (item in items) {
            arr = arr.add(item.toJsonValue())
        }
        return arr
    }
}

public class ServiceInformation {
    public var name: Array<MultilanguageString>
    public var digitalIdentity: ServiceDigitalIdentity
    public var typeIdentifier: Option<Uri>
    public var status: Option<Uri>
    public var statusStartingTime: Option<LoTEDateTime>
    public var schemeServiceDefinitionURI: Option<Array<MultiLanguageURI>>
    public var supplyPoints: Option<Array<ServiceSupplyPointURI>>
    public var definitionURI: Option<Array<MultiLanguageURI>>
    public var informationExtensions: Option<JsonArray>

    public init(
        name: Array<MultilanguageString>,
        digitalIdentity: ServiceDigitalIdentity,
        typeIdentifier: Option<Uri>,
        status: Option<Uri>,
        statusStartingTime: Option<LoTEDateTime>,
        schemeServiceDefinitionURI: Option<Array<MultiLanguageURI>>,
        supplyPoints: Option<Array<ServiceSupplyPointURI>>,
        definitionURI: Option<Array<MultiLanguageURI>>,
        informationExtensions: Option<JsonArray>
    ) {
        Assertions.requireNonEmpty(name, ETSI19602.SERVICE_NAME)
        Assertions.requireNullOrNonEmpty(supplyPoints, ETSI19602.SERVICE_SUPPLY_POINTS)
        Assertions.requireNullOrNonEmpty(schemeServiceDefinitionURI, ETSI19602.SCHEME_SERVICE_DEFINITION_URI)
        Assertions.requireNullOrNonEmpty(definitionURI, ETSI19602.SERVICE_DEFINITION_URI)
        match (informationExtensions) {
            case Some(ext) =>
                if (ext.size() == 0) {
                    throw IllegalArgumentException("${ETSI19602.SERVICE_INFORMATION_EXTENSIONS} cannot be empty")
                }
            case None => ()
        }
        this.name = name
        this.digitalIdentity = digitalIdentity
        this.typeIdentifier = typeIdentifier
        this.status = status
        this.statusStartingTime = statusStartingTime
        this.schemeServiceDefinitionURI = schemeServiceDefinitionURI
        this.supplyPoints = supplyPoints
        this.definitionURI = definitionURI
        this.informationExtensions = informationExtensions
    }

    public static func fromJsonObject(obj: JsonObject): ServiceInformation {
        let typeId: Option<Uri> = match (JsonFields.optionalField(obj, ETSI19602.SERVICE_TYPE_IDENTIFIER)) {
            case Some(v) => Some(Uri.fromJsonValue(v))
            case None => None
        }
        let status: Option<Uri> = match (JsonFields.optionalField(obj, ETSI19602.SERVICE_STATUS)) {
            case Some(v) => Some(Uri.fromJsonValue(v))
            case None => None
        }
        let start: Option<LoTEDateTime> = match (JsonFields.optionalField(obj, ETSI19602.STATUS_STARTING_TIME)) {
            case Some(v) => Some(LoTEDateTime.fromJsonValue(v))
            case None => None
        }
        let schemeDef: Option<Array<MultiLanguageURI>> = match (JsonFields.optionalArray(obj, ETSI19602.SCHEME_SERVICE_DEFINITION_URI)) {
            case Some(arr) => Some(MultiLanguageURI.parseArray(arr))
            case None => None
        }
        let supply: Option<Array<ServiceSupplyPointURI>> = match (JsonFields.optionalArray(obj, ETSI19602.SERVICE_SUPPLY_POINTS)) {
            case Some(arr) => Some(ServiceSupplyPointURI.parseArray(arr))
            case None => None
        }
        let defUri: Option<Array<MultiLanguageURI>> = match (JsonFields.optionalArray(obj, ETSI19602.SERVICE_DEFINITION_URI)) {
            case Some(arr) => Some(MultiLanguageURI.parseArray(arr))
            case None => None
        }
        return ServiceInformation(
            MultilanguageString.parseArray(JsonFields.requireArray(obj, ETSI19602.SERVICE_NAME)),
            ServiceDigitalIdentity.fromJsonObject(JsonFields.requireObject(obj, ETSI19602.SERVICE_DIGITAL_IDENTITY)),
            typeId,
            status,
            start,
            schemeDef,
            supply,
            defUri,
            JsonFields.optionalArray(obj, ETSI19602.SERVICE_INFORMATION_EXTENSIONS)
        )
    }

    public func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.SERVICE_NAME, MultilanguageString.toJsonArray(this.name))
        obj.put(ETSI19602.SERVICE_DIGITAL_IDENTITY, this.digitalIdentity.toJsonValue())
        match (this.typeIdentifier) {
            case Some(v) => obj.put(ETSI19602.SERVICE_TYPE_IDENTIFIER, v.toJsonValue())
            case None => ()
        }
        match (this.status) {
            case Some(v) => obj.put(ETSI19602.SERVICE_STATUS, v.toJsonValue())
            case None => ()
        }
        match (this.statusStartingTime) {
            case Some(v) => obj.put(ETSI19602.STATUS_STARTING_TIME, v.toJsonValue())
            case None => ()
        }
        match (this.schemeServiceDefinitionURI) {
            case Some(items) => obj.put(ETSI19602.SCHEME_SERVICE_DEFINITION_URI, MultiLanguageURI.toJsonArray(items))
            case None => ()
        }
        match (this.supplyPoints) {
            case Some(items) => obj.put(ETSI19602.SERVICE_SUPPLY_POINTS, ServiceSupplyPointURI.toJsonArray(items))
            case None => ()
        }
        match (this.definitionURI) {
            case Some(items) => obj.put(ETSI19602.SERVICE_DEFINITION_URI, MultiLanguageURI.toJsonArray(items))
            case None => ()
        }
        match (this.informationExtensions) {
            case Some(ext) => obj.put(ETSI19602.SERVICE_INFORMATION_EXTENSIONS, ext)
            case None => ()
        }
        return obj
    }
}

public class ServiceHistoryInstance {
    public var name: Array<MultilanguageString>
    public var digitalIdentity: ServiceDigitalIdentity
    public var status: Uri
    public var statusStartingTime: LoTEDateTime
    public var typeIdentifier: Option<Uri>
    public var informationExtensions: Option<JsonArray>

    public init(
        name: Array<MultilanguageString>,
        digitalIdentity: ServiceDigitalIdentity,
        status: Uri,
        statusStartingTime: LoTEDateTime,
        typeIdentifier: Option<Uri>,
        informationExtensions: Option<JsonArray>
    ) {
        Assertions.requireNonEmpty(name, ETSI19602.SERVICE_NAME)
        match (informationExtensions) {
            case Some(ext) =>
                if (ext.size() == 0) {
                    throw IllegalArgumentException("${ETSI19602.SERVICE_INFORMATION_EXTENSIONS} cannot be empty")
                }
            case None => ()
        }
        this.name = name
        this.digitalIdentity = digitalIdentity
        this.status = status
        this.statusStartingTime = statusStartingTime
        this.typeIdentifier = typeIdentifier
        this.informationExtensions = informationExtensions
    }

    public static func fromJsonObject(obj: JsonObject): ServiceHistoryInstance {
        let typeId: Option<Uri> = match (JsonFields.optionalField(obj, ETSI19602.SERVICE_TYPE_IDENTIFIER)) {
            case Some(v) => Some(Uri.fromJsonValue(v))
            case None => None
        }
        return ServiceHistoryInstance(
            MultilanguageString.parseArray(JsonFields.requireArray(obj, ETSI19602.SERVICE_NAME)),
            ServiceDigitalIdentity.fromJsonObject(JsonFields.requireObject(obj, ETSI19602.SERVICE_DIGITAL_IDENTITY)),
            Uri.fromJsonValue(JsonFields.requireField(obj, ETSI19602.SERVICE_STATUS)),
            LoTEDateTime.fromJsonValue(JsonFields.requireField(obj, ETSI19602.STATUS_STARTING_TIME)),
            typeId,
            JsonFields.optionalArray(obj, ETSI19602.SERVICE_INFORMATION_EXTENSIONS)
        )
    }

    public func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.SERVICE_NAME, MultilanguageString.toJsonArray(this.name))
        obj.put(ETSI19602.SERVICE_DIGITAL_IDENTITY, this.digitalIdentity.toJsonValue())
        obj.put(ETSI19602.SERVICE_STATUS, this.status.toJsonValue())
        obj.put(ETSI19602.STATUS_STARTING_TIME, this.statusStartingTime.toJsonValue())
        match (this.typeIdentifier) {
            case Some(v) => obj.put(ETSI19602.SERVICE_TYPE_IDENTIFIER, v.toJsonValue())
            case None => ()
        }
        match (this.informationExtensions) {
            case Some(ext) => obj.put(ETSI19602.SERVICE_INFORMATION_EXTENSIONS, ext)
            case None => ()
        }
        return obj
    }

    public static func parseArray(arr: JsonArray): Array<ServiceHistoryInstance> {
        let out = ArrayList<ServiceHistoryInstance>()
        for (i in 0..arr.size()) {
            out.add(fromJsonObject(arr[i].asObject()))
        }
        return Assertions.copyArray(out)
    }

    public static func toJsonArray(items: Array<ServiceHistoryInstance>): JsonValue {
        var arr = JsonArray()
        for (item in items) {
            arr = arr.add(item.toJsonValue())
        }
        return arr
    }
}

public class ServiceSupplyPointURI {
    public var uriValue: Uri
    public var serviceType: Option<Uri>

    public init(uriValue: Uri, serviceType: Option<Uri>) {
        this.uriValue = uriValue
        this.serviceType = serviceType
    }

    public static func fromJsonObject(obj: JsonObject): ServiceSupplyPointURI {
        let serviceType: Option<Uri> = match (JsonFields.optionalField(obj, ETSI19602.SERVICE_SUPPLY_POINT_URI_TYPE)) {
            case Some(v) => Some(Uri.fromJsonValue(v))
            case None => None
        }
        return ServiceSupplyPointURI(
            Uri.fromJsonValue(JsonFields.requireField(obj, ETSI19602.SERVICE_SUPPLY_POINT_URI_VALUE)),
            serviceType
        )
    }

    public func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.SERVICE_SUPPLY_POINT_URI_VALUE, this.uriValue.toJsonValue())
        match (this.serviceType) {
            case Some(v) => obj.put(ETSI19602.SERVICE_SUPPLY_POINT_URI_TYPE, v.toJsonValue())
            case None => ()
        }
        return obj
    }

    public static func parseArray(arr: JsonArray): Array<ServiceSupplyPointURI> {
        let out = ArrayList<ServiceSupplyPointURI>()
        for (i in 0..arr.size()) {
            out.add(fromJsonObject(arr[i].asObject()))
        }
        return Assertions.copyArray(out)
    }

    public static func toJsonArray(items: Array<ServiceSupplyPointURI>): JsonValue {
        var arr = JsonArray()
        for (item in items) {
            arr = arr.add(item.toJsonValue())
        }
        return arr
    }
}
