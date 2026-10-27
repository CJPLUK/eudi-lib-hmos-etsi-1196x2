package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model

import stdx.encoding.json.*

public class ByteArraySerializedInBase64 {
    public var bytes: Array<Byte>

    public init(bytes: Array<Byte>) {
        this.bytes = bytes
    }

    public static func fromBase64(encoded: String): ByteArraySerializedInBase64 {
        return ByteArraySerializedInBase64(Base64KSerializer.decode(encoded))
    }

    public func toBase64(): String {
        return Base64KSerializer.encode(this.bytes)
    }

    public static func fromJsonValue(value: JsonValue): ByteArraySerializedInBase64 {
        return fromBase64(value.asString().getValue())
    }

    public func toJsonValue(): JsonValue {
        return JsonString(this.toBase64())
    }
}
