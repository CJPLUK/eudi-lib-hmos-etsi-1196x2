package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model

import std.time.*
import stdx.encoding.json.*

public class LoTEDateTime <: ToString {
    public var isoValue: String

    public init(isoValue: String) {
        Assertions.requireNotBlank(isoValue, "LoTEDateTime")
        DateTime.parse(isoValue)
        this.isoValue = isoValue
    }

    public static func fromJsonValue(value: JsonValue): LoTEDateTime {
        return LoTEDateTime(value.asString().getValue())
    }

    public func toJsonValue(): JsonValue {
        return JsonString(this.isoValue)
    }

    public override func toString(): String {
        return this.isoValue
    }
}
