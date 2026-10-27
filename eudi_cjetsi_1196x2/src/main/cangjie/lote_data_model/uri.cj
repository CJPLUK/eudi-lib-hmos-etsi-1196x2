package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model

import stdx.encoding.json.*

public class Uri <: ToString {
    public var value: String

    public init(value: String) {
        this.value = value
    }

    public static func parse(value: String): Uri {
        Assertions.requireNotBlank(value, "Uri")
        return Uri(value)
    }

    public static func fromJsonValue(value: JsonValue): Uri {
        return parse(value.asString().getValue())
    }

    public func toJsonValue(): JsonValue {
        return JsonString(this.value)
    }

    public override func toString(): String {
        return this.value
    }
}

public class LoTEType {
    public static func of(value: String): Uri {
        return Uri.parse("${ETSI19602.LOTE_TYPE_URI}/${value}")
    }
}
