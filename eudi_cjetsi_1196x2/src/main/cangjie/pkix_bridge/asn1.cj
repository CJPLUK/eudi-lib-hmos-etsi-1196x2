package ohos_app_cangjie_eudi_cjetsi_1196x2.pkix_bridge

import std.collection.ArrayList

public enum ASN1Tag {
    | Universal(Int64)
    | Application(Int64)
    | ContextSpecific(Int64)
    | Private(Int64)
}

public class ASN1UniversalTag {
    public static let boolean: Int64 = 0x01
    public static let integer: Int64 = 0x02
    public static let bitString: Int64 = 0x03
    public static let octetString: Int64 = 0x04
    public static let nullTag: Int64 = 0x05
    public static let objectIdentifier: Int64 = 0x06
    public static let utf8String: Int64 = 0x0C
    public static let printableString: Int64 = 0x13
    public static let teletexString: Int64 = 0x14
    public static let ia5String: Int64 = 0x16
    public static let utcTime: Int64 = 0x17
    public static let generalizedTime: Int64 = 0x18
    public static let bmpString: Int64 = 0x1E
    public static let sequence: Int64 = 0x10
    public static let setTag: Int64 = 0x11
}

public enum ASN1Content {
    | Primitive(Array<Byte>)
    | Constructed(Array<ASN1Element>)
}

public class ASN1Element {
    public let tag: ASN1Tag
    public let constructed: Bool
    public let content: ASN1Content

    public init(tag: ASN1Tag, constructed: Bool, content: ASN1Content) {
        this.tag = tag
        this.constructed = constructed
        this.content = content
    }

    public func primitiveBytes(): ?Array<Byte> {
        match (this.content) {
            case Primitive(data) => data
            case Constructed(_) => None
        }
    }

    public func children(): ?Array<ASN1Element> {
        match (this.content) {
            case Constructed(elements) => elements
            case Primitive(_) => None
        }
    }

    public func isUniversal(tagNumber: Int64): Bool {
        match (this.tag) {
            case Universal(n) => n == tagNumber
            case _ => false
        }
    }

    public func isContextSpecific(tagNumber: Int64): Bool {
        match (this.tag) {
            case ContextSpecific(n) => n == tagNumber
            case _ => false
        }
    }
}

public class ASN1Error <: Exception {
    public init(reason: String) {
        super(reason)
    }
}

func byteValue(data: Array<Byte>, index: Int64): Int64 {
    Int64(data[index]) & 0xFF
}

func sliceBytes(data: Array<Byte>, start: Int64, length: Int64): Array<Byte> {
    Array<Byte>(length, { i => data[start + i] })
}

func bytesEqual(left: Array<Byte>, right: Array<Byte>): Bool {
    if (left.size != right.size) {
        return false
    }
    var i: Int64 = 0
    while (i < left.size) {
        if (byteValue(left, i) != byteValue(right, i)) {
            return false
        }
        i = i + 1
    }
    true
}

func dropFirstByte(data: Array<Byte>): Array<Byte> {
    if (data.size <= 1) {
        return Array<Byte>()
    }
    sliceBytes(data, 1, data.size - 1)
}

func joinOid(components: Array<Int64>): String {
    if (components.size == 0) {
        return ""
    }
    var result = "${components[0]}"
    var i: Int64 = 1
    while (i < components.size) {
        result = result + "." + "${components[i]}"
        i = i + 1
    }
    result
}

func collectElements(list: ArrayList<ASN1Element>): Array<ASN1Element> {
    list.toArray()
}
