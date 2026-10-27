package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model

import std.collection.*
import stdx.encoding.json.*

public class PostalAddress {
    public var language: Language
    public var streetAddress: String
    public var country: CountryCode
    public var locality: Option<String>
    public var stateOrProvince: Option<String>
    public var postalCode: Option<String>

    public init(
        language: Language,
        streetAddress: String,
        country: CountryCode,
        locality: Option<String>,
        stateOrProvince: Option<String>,
        postalCode: Option<String>
    ) {
        Assertions.requireNotBlank(streetAddress, ETSI19602.POSTAL_ADDRESS_STREET_ADDRESS)
        this.language = language
        this.streetAddress = streetAddress
        this.country = country
        this.locality = locality
        this.stateOrProvince = stateOrProvince
        this.postalCode = postalCode
    }

    public static func fromJsonObject(obj: JsonObject): PostalAddress {
        return PostalAddress(
            Language.fromJsonValue(JsonFields.requireField(obj, ETSI19602.LANG)),
            JsonFields.requireString(obj, ETSI19602.POSTAL_ADDRESS_STREET_ADDRESS),
            CountryCode.fromJsonValue(JsonFields.requireField(obj, ETSI19602.POSTAL_ADDRESS_COUNTRY)),
            JsonFields.optionalString(obj, ETSI19602.POSTAL_ADDRESS_LOCALITY),
            JsonFields.optionalString(obj, ETSI19602.POSTAL_ADDRESS_STATE_OR_PROVINCE),
            JsonFields.optionalString(obj, ETSI19602.POSTAL_ADDRESS_POSTAL_CODE)
        )
    }

    public func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.LANG, this.language.toJsonValue())
        obj.put(ETSI19602.POSTAL_ADDRESS_STREET_ADDRESS, JsonString(this.streetAddress))
        obj.put(ETSI19602.POSTAL_ADDRESS_COUNTRY, this.country.toJsonValue())
        match (this.locality) {
            case Some(v) => obj.put(ETSI19602.POSTAL_ADDRESS_LOCALITY, JsonString(v))
            case None => ()
        }
        match (this.stateOrProvince) {
            case Some(v) => obj.put(ETSI19602.POSTAL_ADDRESS_STATE_OR_PROVINCE, JsonString(v))
            case None => ()
        }
        match (this.postalCode) {
            case Some(v) => obj.put(ETSI19602.POSTAL_ADDRESS_POSTAL_CODE, JsonString(v))
            case None => ()
        }
        return obj
    }

    public static func parseArray(arr: JsonArray): Array<PostalAddress> {
        let out = ArrayList<PostalAddress>()
        for (i in 0..arr.size()) {
            out.add(fromJsonObject(arr[i].asObject()))
        }
        return Assertions.copyArray(out)
    }

    public static func toJsonArray(items: Array<PostalAddress>): JsonValue {
        var arr = JsonArray()
        for (item in items) {
            arr = arr.add(item.toJsonValue())
        }
        return arr
    }
}
