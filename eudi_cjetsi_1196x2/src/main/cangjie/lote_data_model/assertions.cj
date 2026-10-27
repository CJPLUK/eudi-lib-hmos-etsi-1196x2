package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model

import std.collection.*
import stdx.encoding.json.*

public class LoTEDecodeException <: Exception {
    public init(message: String) {
        super(message)
    }
}

public class Assertions {
    public static func requireNotBlank(value: String, attributeName: String): Unit {
        if (isBlank(value)) {
            throw IllegalArgumentException("${attributeName} cannot be blank")
        }
    }

    public static func requireNullOrNotBlank(value: Option<String>, attributeName: String): Unit {
        match (value) {
            case Some(text) => requireNotBlank(text, attributeName)
            case None => ()
        }
    }

    public static func requireNonEmpty<T>(list: Array<T>, attributeName: String): Unit {
        if (list.size == 0) {
            throw IllegalArgumentException("${attributeName} cannot be empty")
        }
    }

    public static func requireNullOrNonEmpty<T>(list: Option<Array<T>>, attributeName: String): Unit {
        match (list) {
            case Some(items) => requireNonEmpty(items, attributeName)
            case None => ()
        }
    }

    public static func checkNotNull<T>(value: Option<T>, attributeName: String): T {
        match (value) {
            case Some(item) => return item
            case None => throw IllegalStateException("${attributeName} must be set")
        }
    }

    public static func checkIsNull<T>(value: Option<T>, attributeName: String): Unit {
        match (value) {
            case Some(_) => throw IllegalStateException("${attributeName} must not be set")
            case None => ()
        }
    }

    public static func isBlank(value: String): Bool {
        if (value.isEmpty()) {
            return true
        }
        for (r in value.toRuneArray()) {
            if (r != r' ' && r != r'\t' && r != r'\n' && r != r'\r') {
                return false
            }
        }
        return true
    }

    public static func copyArray<T>(list: ArrayList<T>): Array<T> {
        return Array<T>(list.size, { i => list[i] })
    }
}

public class JsonFields {
    public static func optionalField(obj: JsonObject, key: String): Option<JsonValue> {
        match (obj.get(key)) {
            case Some(v) =>
                match (v.kind()) {
                    case JsonKind.JsNull => return None
                    case _ => return Some(v)
                }
            case None => return None
        }
    }

    public static func requireField(obj: JsonObject, key: String): JsonValue {
        match (optionalField(obj, key)) {
            case Some(v) => return v
            case None => throw LoTEDecodeException("missing required field ${key}")
        }
    }

    public static func requireObject(obj: JsonObject, key: String): JsonObject {
        return requireField(obj, key).asObject()
    }

    public static func optionalObject(obj: JsonObject, key: String): Option<JsonObject> {
        match (optionalField(obj, key)) {
            case Some(v) => return Some(v.asObject())
            case None => return None
        }
    }

    public static func requireString(obj: JsonObject, key: String): String {
        return requireField(obj, key).asString().getValue()
    }

    public static func optionalString(obj: JsonObject, key: String): Option<String> {
        match (optionalField(obj, key)) {
            case Some(v) => return Some(v.asString().getValue())
            case None => return None
        }
    }

    public static func requireInt(obj: JsonObject, key: String): Int64 {
        return requireField(obj, key).asInt().getValue()
    }

    public static func optionalInt(obj: JsonObject, key: String): Option<Int64> {
        match (optionalField(obj, key)) {
            case Some(v) => return Some(v.asInt().getValue())
            case None => return None
        }
    }

    public static func requireArray(obj: JsonObject, key: String): JsonArray {
        return requireField(obj, key).asArray()
    }

    public static func optionalArray(obj: JsonObject, key: String): Option<JsonArray> {
        match (optionalField(obj, key)) {
            case Some(v) => return Some(v.asArray())
            case None => return None
        }
    }

    public static func putOptional(obj: JsonObject, key: String, value: Option<JsonValue>): Unit {
        match (value) {
            case Some(v) => obj.put(key, v)
            case None => ()
        }
    }
}
