package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model

import stdx.encoding.json.*

public class Language <: ToString {
    public var value: String

    public init(value: String) {
        Assertions.requireNotBlank(value, ETSI19602.LANG)
        if (!isAlpha2Lower(value)) {
            throw IllegalArgumentException("Invalid ${ETSI19602.LANG}")
        }
        this.value = value
    }

    public static func english(): Language {
        return Language(ETSI19602.LANG_ENGLISH)
    }

    public static func isAlpha2Lower(value: String): Bool {
        let runes = value.toRuneArray()
        if (runes.size != 2) {
            return false
        }
        for (r in runes) {
            if (r < r'a' || r > r'z') {
                return false
            }
        }
        return true
    }

    public static func fromJsonValue(value: JsonValue): Language {
        return Language(value.asString().getValue())
    }

    public func toJsonValue(): JsonValue {
        return JsonString(this.value)
    }

    public override func toString(): String {
        return this.value
    }
}
