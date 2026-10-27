package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model

import std.collection.*
import stdx.encoding.json.*

public class ServiceDigitalIdentity {
    public var x509Certificates: Option<Array<PKIObject>>
    public var x509SubjectNames: Option<Array<String>>
    public var publicKeyValues: Option<Array<JsonObject>>
    public var x509SKIs: Option<Array<ByteArraySerializedInBase64>>
    public var otherIds: Option<Array<String>>

    public init(
        x509Certificates: Option<Array<PKIObject>>,
        x509SubjectNames: Option<Array<String>>,
        publicKeyValues: Option<Array<JsonObject>>,
        x509SKIs: Option<Array<ByteArraySerializedInBase64>>,
        otherIds: Option<Array<String>>
    ) {
        Assertions.requireNullOrNonEmpty(x509Certificates, ETSI19602.X509_CERTIFICATES)
        Assertions.requireNullOrNonEmpty(x509SubjectNames, ETSI19602.X509_SUBJECT_NAMES)
        Assertions.requireNullOrNonEmpty(publicKeyValues, ETSI19602.PUBLIC_KEY_VALUES)
        Assertions.requireNullOrNonEmpty(x509SKIs, ETSI19602.X509_SKIS)
        Assertions.requireNullOrNonEmpty(otherIds, ETSI19602.OTHER_IDS)
        this.x509Certificates = x509Certificates
        this.x509SubjectNames = x509SubjectNames
        this.publicKeyValues = publicKeyValues
        this.x509SKIs = x509SKIs
        this.otherIds = otherIds
    }

    public static func fromJsonObject(obj: JsonObject): ServiceDigitalIdentity {
        return ServiceDigitalIdentity(
            parsePkiArray(JsonFields.optionalArray(obj, ETSI19602.X509_CERTIFICATES)),
            parseStringArray(JsonFields.optionalArray(obj, ETSI19602.X509_SUBJECT_NAMES)),
            parseObjectArray(JsonFields.optionalArray(obj, ETSI19602.PUBLIC_KEY_VALUES)),
            parseSkiArray(JsonFields.optionalArray(obj, ETSI19602.X509_SKIS)),
            parseStringArray(JsonFields.optionalArray(obj, ETSI19602.OTHER_IDS))
        )
    }

    public func toJsonValue(): JsonValue {
        let obj = JsonObject()
        match (this.x509Certificates) {
            case Some(items) => obj.put(ETSI19602.X509_CERTIFICATES, PKIObject.toJsonArray(items))
            case None => ()
        }
        match (this.x509SubjectNames) {
            case Some(items) => obj.put(ETSI19602.X509_SUBJECT_NAMES, stringArrayToJson(items))
            case None => ()
        }
        match (this.publicKeyValues) {
            case Some(items) => obj.put(ETSI19602.PUBLIC_KEY_VALUES, objectArrayToJson(items))
            case None => ()
        }
        match (this.x509SKIs) {
            case Some(items) => obj.put(ETSI19602.X509_SKIS, skiArrayToJson(items))
            case None => ()
        }
        match (this.otherIds) {
            case Some(items) => obj.put(ETSI19602.OTHER_IDS, stringArrayToJson(items))
            case None => ()
        }
        return obj
    }

    public static func parseArray(arr: JsonArray): Array<ServiceDigitalIdentity> {
        let out = ArrayList<ServiceDigitalIdentity>()
        for (i in 0..arr.size()) {
            out.add(fromJsonObject(arr[i].asObject()))
        }
        return Assertions.copyArray(out)
    }

    public static func toJsonArray(items: Array<ServiceDigitalIdentity>): JsonValue {
        var arr = JsonArray()
        for (item in items) {
            arr = arr.add(item.toJsonValue())
        }
        return arr
    }

    static func parsePkiArray(arr: Option<JsonArray>): Option<Array<PKIObject>> {
        match (arr) {
            case Some(values) => return Some(PKIObject.parseArray(values))
            case None => return None
        }
    }

    static func parseStringArray(arr: Option<JsonArray>): Option<Array<String>> {
        match (arr) {
            case Some(values) =>
                let out = ArrayList<String>()
                for (i in 0..values.size()) {
                    out.add(values[i].asString().getValue())
                }
                return Some(Assertions.copyArray(out))
            case None => return None
        }
    }

    static func parseObjectArray(arr: Option<JsonArray>): Option<Array<JsonObject>> {
        match (arr) {
            case Some(values) =>
                let out = ArrayList<JsonObject>()
                for (i in 0..values.size()) {
                    out.add(values[i].asObject())
                }
                return Some(Assertions.copyArray(out))
            case None => return None
        }
    }

    static func parseSkiArray(arr: Option<JsonArray>): Option<Array<ByteArraySerializedInBase64>> {
        match (arr) {
            case Some(values) =>
                let out = ArrayList<ByteArraySerializedInBase64>()
                for (i in 0..values.size()) {
                    out.add(ByteArraySerializedInBase64.fromJsonValue(values[i]))
                }
                return Some(Assertions.copyArray(out))
            case None => return None
        }
    }

    static func stringArrayToJson(items: Array<String>): JsonValue {
        var arr = JsonArray()
        for (item in items) {
            arr = arr.add(JsonString(item))
        }
        return arr
    }

    static func objectArrayToJson(items: Array<JsonObject>): JsonValue {
        var arr = JsonArray()
        for (item in items) {
            arr = arr.add(item)
        }
        return arr
    }

    static func skiArrayToJson(items: Array<ByteArraySerializedInBase64>): JsonValue {
        var arr = JsonArray()
        for (item in items) {
            arr = arr.add(item.toJsonValue())
        }
        return arr
    }
}

public class PKIObject {
    public var value: ByteArraySerializedInBase64
    public var encoding: Option<Uri>
    public var specRef: Option<String>

    public init(value: ByteArraySerializedInBase64, encoding: Option<Uri>, specRef: Option<String>) {
        this.value = value
        this.encoding = encoding
        this.specRef = specRef
    }

    public static func fromJsonObject(obj: JsonObject): PKIObject {
        let encoding: Option<Uri> = match (JsonFields.optionalField(obj, ETSI19602.PKI_OB_ENCODING)) {
            case Some(v) => Some(Uri.fromJsonValue(v))
            case None => None
        }
        return PKIObject(
            ByteArraySerializedInBase64.fromJsonValue(JsonFields.requireField(obj, ETSI19602.PKI_OB_VAL)),
            encoding,
            JsonFields.optionalString(obj, ETSI19602.PKI_OB_SPEC_REF)
        )
    }

    public func toJsonValue(): JsonValue {
        let obj = JsonObject()
        obj.put(ETSI19602.PKI_OB_VAL, this.value.toJsonValue())
        match (this.encoding) {
            case Some(v) => obj.put(ETSI19602.PKI_OB_ENCODING, v.toJsonValue())
            case None => ()
        }
        match (this.specRef) {
            case Some(v) => obj.put(ETSI19602.PKI_OB_SPEC_REF, JsonString(v))
            case None => ()
        }
        return obj
    }

    public static func parseArray(arr: JsonArray): Array<PKIObject> {
        let out = ArrayList<PKIObject>()
        for (i in 0..arr.size()) {
            out.add(fromJsonObject(arr[i].asObject()))
        }
        return Assertions.copyArray(out)
    }

    public static func toJsonArray(items: Array<PKIObject>): JsonValue {
        var arr = JsonArray()
        for (item in items) {
            arr = arr.add(item.toJsonValue())
        }
        return arr
    }
}
