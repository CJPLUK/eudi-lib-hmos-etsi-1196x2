package ohos_app_cangjie_eudi_cjetsi_1196x2.pkix_bridge

import std.collection.ArrayList

class Asn1Cursor {
    public let data: Array<Byte>
    public var offset: Int64

    public init(data: Array<Byte>, offset: Int64) {
        this.data = data
        this.offset = offset
    }
}

public class ASN1Parser {
    public static func parse(data: Array<Byte>): ASN1Element {
        let cursor = Asn1Cursor(data, 0)
        let element = parseElement(cursor)
        if (cursor.offset != data.size) {
            throw ASN1Error("trailingBytes ${data.size - cursor.offset}")
        }
        element
    }

    public static func parseAll(data: Array<Byte>): Array<ASN1Element> {
        let cursor = Asn1Cursor(data, 0)
        let elements = ArrayList<ASN1Element>()
        while (cursor.offset < data.size) {
            elements.add(parseElement(cursor))
        }
        collectElements(elements)
    }

    static func parseElement(cursor: Asn1Cursor): ASN1Element {
        let (tag, constructedFlag) = parseTag(cursor)
        let length = parseLength(cursor)
        if (cursor.offset + length > cursor.data.size) {
            throw ASN1Error("unexpectedEnd")
        }
        let valueBytes = sliceBytes(cursor.data, cursor.offset, length)
        cursor.offset = cursor.offset + length
        if (constructedFlag == 1) {
            return ASN1Element(tag, true, Constructed(parseAll(valueBytes)))
        }
        ASN1Element(tag, false, Primitive(valueBytes))
    }

    static func parseTag(cursor: Asn1Cursor): (ASN1Tag, Int64) {
        if (cursor.offset >= cursor.data.size) {
            throw ASN1Error("unexpectedEnd")
        }
        let first = byteValue(cursor.data, cursor.offset)
        cursor.offset = cursor.offset + 1
        let classBits = (first & 0xC0) >> 6
        let constructedFlag: Int64 = if ((first & 0x20) != 0) { 1 } else { 0 }
        var tagNumber: Int64 = first & 0x1F
        if (tagNumber == 0x1F) {
            tagNumber = 0
            var bytesRead: Int64 = 0
            while (true) {
                if (cursor.offset >= cursor.data.size) {
                    throw ASN1Error("unexpectedEnd")
                }
                let b = byteValue(cursor.data, cursor.offset)
                cursor.offset = cursor.offset + 1
                bytesRead = bytesRead + 1
                if (bytesRead > 4) {
                    throw ASN1Error("tagNumberTooLarge")
                }
                tagNumber = (tagNumber << 7) | (b & 0x7F)
                if ((b & 0x80) == 0) {
                    break
                }
            }
        }
        let tag = match (classBits) {
            case 0 => Universal(tagNumber)
            case 1 => Application(tagNumber)
            case 2 => ContextSpecific(tagNumber)
            case 3 => Private(tagNumber)
            case _ => throw ASN1Error("unexpectedEnd")
        }
        (tag, constructedFlag)
    }

    static func parseLength(cursor: Asn1Cursor): Int64 {
        if (cursor.offset >= cursor.data.size) {
            throw ASN1Error("unexpectedEnd")
        }
        let first = byteValue(cursor.data, cursor.offset)
        cursor.offset = cursor.offset + 1
        if (first < 0x80) {
            return first
        }
        if (first == 0x80) {
            throw ASN1Error("indefiniteLength")
        }
        let byteCount = first & 0x7F
        if (byteCount > 8) {
            throw ASN1Error("lengthTooLarge")
        }
        if (cursor.offset + byteCount > cursor.data.size) {
            throw ASN1Error("unexpectedEnd")
        }
        var length: Int64 = 0
        var i: Int64 = 0
        while (i < byteCount) {
            length = (length << 8) | byteValue(cursor.data, cursor.offset)
            cursor.offset = cursor.offset + 1
            i = i + 1
        }
        if (byteCount == 1 && length < 128) {
            throw ASN1Error("nonCanonicalLength")
        }
        length
    }
}
