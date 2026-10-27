package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model

import std.collection.*
import stdx.encoding.json.*

public class MultiLanguageURI {
    public var language: Language
    public var value: Uri

    public init(language: Language, value: Uri) {
        this.language = language
        this.value = value
    }

    public static func en(value: Uri): MultiLanguageURI {
        return MultiLanguageURI(Language.english(), value)
    }

    public static func fromJsonObject(obj: JsonObject): MultiLanguageURI {
        return MultiLanguageURI(
            Language.fromJsonValue(JsonFields.requireField(obj, ETSI19602.LANG)),
            Uri.fromJsonValue(JsonFields.requireField(obj, ETSI19602.URI_VALUE))
        )
    }

    public func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.LANG, this.language.toJsonValue())
        obj.put(ETSI19602.URI_VALUE, this.value.toJsonValue())
        return obj
    }

    public static func parseArray(arr: JsonArray): Array<MultiLanguageURI> {
        let out = ArrayList<MultiLanguageURI>()
        for (i in 0..arr.size()) {
            out.add(fromJsonObject(arr[i].asObject()))
        }
        return Assertions.copyArray(out)
    }

    public static func toJsonArray(items: Array<MultiLanguageURI>): JsonValue {
        var arr = JsonArray()
        for (item in items) {
            arr = arr.add(item.toJsonValue())
        }
        return arr
    }
}
