package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model

import stdx.encoding.json.*

public class CountryCode <: ToString {
    public var value: String

    public init(value: String) {
        Assertions.requireNotBlank(value, "Country code")
        if (!isAllCapitalLetters(value)) {
            throw IllegalArgumentException("Country code must be all capital letters")
        }
        this.value = value
    }

    public static func eu(): CountryCode {
        return iso3166(ETSI19602.COUNTRY_CODE_EU)
    }

    public static func iso3166(value: String): CountryCode {
        let runes = value.toRuneArray()
        if (runes.size != ETSI19602.COUNTRY_CODE_SIZE || !isAllCapitalLetters(value)) {
            throw IllegalArgumentException("Invalid ISO 3166-1 alpha-2 code: ${value}")
        }
        return CountryCode(value)
    }

    public static func isAllCapitalLetters(value: String): Bool {
        if (value.isEmpty()) {
            return false
        }
        for (r in value.toRuneArray()) {
            if (r < r'A' || r > r'Z') {
                return false
            }
        }
        return true
    }

    public static func fromJsonValue(value: JsonValue): CountryCode {
        return CountryCode(value.asString().getValue())
    }

    public func toJsonValue(): JsonValue {
        return JsonString(this.value)
    }

    public override func toString(): String {
        return this.value
    }
}
