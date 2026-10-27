package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model

import std.collection.*
import stdx.encoding.json.*

public class MultilanguageString {
    public var language: Language
    public var value: String

    public init(language: Language, value: String) {
        Assertions.requireNotBlank(value, ETSI19602.STRING_VALUE)
        if (!MultilingualStringValue.isValid(value)) {
            throw IllegalArgumentException("Invalid ${ETSI19602.STRING_VALUE}")
        }
        this.language = language
        this.value = value
    }

    public static func en(value: String): MultilanguageString {
        return MultilanguageString(Language.english(), value)
    }

    public static func fromJsonObject(obj: JsonObject): MultilanguageString {
        return MultilanguageString(
            Language.fromJsonValue(JsonFields.requireField(obj, ETSI19602.LANG)),
            JsonFields.requireString(obj, ETSI19602.STRING_VALUE)
        )
    }

    public func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.LANG, this.language.toJsonValue())
        obj.put(ETSI19602.STRING_VALUE, JsonString(this.value))
        return obj
    }

    public static func parseArray(arr: JsonArray): Array<MultilanguageString> {
        let out = ArrayList<MultilanguageString>()
        for (i in 0..arr.size()) {
            out.add(fromJsonObject(arr[i].asObject()))
        }
        return Assertions.copyArray(out)
    }

    public static func toJsonArray(items: Array<MultilanguageString>): JsonValue {
        var arr = JsonArray()
        for (item in items) {
            arr = arr.add(item.toJsonValue())
        }
        return arr
    }
}

public class MultilingualStringValue <: ToString {
    public var value: String

    public init(value: String) {
        if (!isValid(value)) {
            throw IllegalArgumentException("Invalid multilingual string")
        }
        this.value = value
    }

    public static func isValid(s: String): Bool {
        let bytes = s.toArray()
        if (bytes.size >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
            return false
        }
        for (r in s.toRuneArray()) {
            if (!isCodePointValid(Int64(UInt32(r)))) {
                return false
            }
        }
        if (s.contains("<") && s.contains(">") && containsHtmlLikeTags(s)) {
            return false
        }
        return true
    }

    public static func containsHtmlLikeTags(s: String): Bool {
        let runes = s.toRuneArray()
        var i: Int64 = 0
        while (i < runes.size) {
            if (runes[i] == r'<') {
                var j = i + 1
                var hasContent = false
                while (j < runes.size && runes[j] != r'>') {
                    hasContent = true
                    j = j + 1
                }
                if (j < runes.size && hasContent) {
                    return true
                }
                i = j
            }
            i = i + 1
        }
        return false
    }

    public static func isCodePointValid(cp: Int64): Bool {
        return !(ISO6429.isControlFunction(cp) || ISO6429.isPrivateUseZone(cp) || ISO6429.isTag(cp))
    }

    public override func toString(): String {
        return this.value
    }
}

public class ISO6429 {
    public static func isControlFunction(cp: Int64): Bool {
        return (cp >= 0 && cp <= 0x1F) || (cp >= 0x80 && cp <= 0x9F)
    }

    public static func isTag(cp: Int64): Bool {
        return cp >= 0xE0000 && cp <= 0xE007F
    }

    public static func isPrivateUseZone(cp: Int64): Bool {
        return (cp >= 0xE000 && cp <= 0xF8FF) ||
            (cp >= 0xF0000 && cp <= 0xFFFFD) ||
            (cp >= 0x100000 && cp <= 0x10FFFD)
    }
}
