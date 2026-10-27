package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model

import stdx.encoding.json.*

public class ListOfTrustedEntities {
    public var schemeInformation: ListAndSchemeInformation
    public var entities: Option<Array<TrustedEntity>>

    public init(schemeInformation: ListAndSchemeInformation, entities: Option<Array<TrustedEntity>>) {
        Assertions.requireNullOrNonEmpty(entities, ETSI19602.TRUSTED_ENTITIES_LIST)
        this.schemeInformation = schemeInformation
        this.entities = entities
    }

    public static func fromJson(json: String): ListOfTrustedEntities {
        try {
            let root = JsonValue.fromStr(json).asObject()
            if (root.containsKey(ETSI19602.LOTE)) {
                return fromJsonObject(JsonFields.requireObject(root, ETSI19602.LOTE))
            }
            return fromJsonObject(root)
        } catch (e: LoTEDecodeException) {
            throw e
        } catch (e: Exception) {
            throw LoTEDecodeException("malformed_json: ${e.message}")
        }
    }

    public static func fromJsonObject(obj: JsonObject): ListOfTrustedEntities {
        let entities: Option<Array<TrustedEntity>> = match (JsonFields.optionalArray(obj, ETSI19602.TRUSTED_ENTITIES_LIST)) {
            case Some(arr) => Some(TrustedEntity.parseArray(arr))
            case None => None
        }
        return ListOfTrustedEntities(
            ListAndSchemeInformation.fromJsonObject(JsonFields.requireObject(obj, ETSI19602.LIST_AND_SCHEME_INFORMATION)),
            entities
        )
    }

    public func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.LIST_AND_SCHEME_INFORMATION, this.schemeInformation.toJsonValue())
        match (this.entities) {
            case Some(items) => obj.put(ETSI19602.TRUSTED_ENTITIES_LIST, TrustedEntity.toJsonArray(items))
            case None => ()
        }
        return obj
    }

    public func toJson(): String {
        return this.toJsonValue().toString()
    }
}

public class ListOfTrustedEntitiesClaims {
    public var listOfTrustedEntities: ListOfTrustedEntities

    public init(listOfTrustedEntities: ListOfTrustedEntities) {
        this.listOfTrustedEntities = listOfTrustedEntities
    }

    public static func fromJson(json: String): ListOfTrustedEntitiesClaims {
        try {
            let root = JsonValue.fromStr(json).asObject()
            return ListOfTrustedEntitiesClaims(
                ListOfTrustedEntities.fromJsonObject(JsonFields.requireObject(root, ETSI19602.LOTE))
            )
        } catch (e: LoTEDecodeException) {
            throw e
        } catch (e: Exception) {
            throw LoTEDecodeException("malformed_json: ${e.message}")
        }
    }

    public func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.LOTE, this.listOfTrustedEntities.toJsonValue())
        return obj
    }

    public func toJson(): String {
        return this.toJsonValue().toString()
    }
}
