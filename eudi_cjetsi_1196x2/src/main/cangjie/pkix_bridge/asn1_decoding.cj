package ohos_app_cangjie_eudi_cjetsi_1196x2.pkix_bridge

import std.collection.ArrayList
import std.time.DateTime

extend ASN1Element {
    public func requirePrimitive(): Array<Byte> {
        match (this.primitiveBytes()) {
            case Some(data) => data
            case None => throw ASN1Error("primitiveExpected")
        }
    }

    public func requireConstructed(): Array<ASN1Element> {
        match (this.children()) {
            case Some(elements) => elements
            case None => throw ASN1Error("constructedExpected")
        }
    }

    public func requireUniversal(tagNumber: Int64): Unit {
        if (!this.isUniversal(tagNumber)) {
            throw ASN1Error("unexpectedTag expected universal ${tagNumber} actual ${this.tagDescription()}")
        }
    }

    public func sequence(): Array<ASN1Element> {
        this.requireUniversal(ASN1UniversalTag.sequence)
        if (!this.constructed) {
            throw ASN1Error("constructedExpected")
        }
        this.requireConstructed()
    }

    public func setOf(): Array<ASN1Element> {
        this.requireUniversal(ASN1UniversalTag.setTag)
        if (!this.constructed) {
            throw ASN1Error("constructedExpected")
        }
        this.requireConstructed()
    }

    public func boolValue(): Bool {
        this.requireUniversal(ASN1UniversalTag.boolean)
        let bytes = this.requirePrimitive()
        if (bytes.size != 1) {
            throw ASN1Error("BOOLEAN must be one byte, got ${bytes.size}")
        }
        let v = byteValue(bytes, 0)
        if (v == 0x00) {
            return false
        }
        if (v == 0xFF) {
            return true
        }
        throw ASN1Error("DER BOOLEAN must be 0x00 or 0xFF")
    }

    public func integerBytes(): Array<Byte> {
        this.requireUniversal(ASN1UniversalTag.integer)
        this.requirePrimitive()
    }

    public func octetString(): Array<Byte> {
        this.requireUniversal(ASN1UniversalTag.octetString)
        this.requirePrimitive()
    }

    public func bitStringData(): Array<Byte> {
        this.requireUniversal(ASN1UniversalTag.bitString)
        let bytes = this.requirePrimitive()
        if (bytes.size == 0) {
            throw ASN1Error("BIT STRING is empty")
        }
        let unused = byteValue(bytes, 0)
        if (unused > 7) {
            throw ASN1Error("BIT STRING unused-bits must be 0..7, got ${unused}")
        }
        dropFirstByte(bytes)
    }

    public func objectIdentifier(): String {
        this.requireUniversal(ASN1UniversalTag.objectIdentifier)
        decodeOid(this.requirePrimitive())
    }

    public func directoryString(): String {
        match (this.tag) {
            case Universal(n) where n == ASN1UniversalTag.utf8String => this.utf8String()
            case Universal(n) where n == ASN1UniversalTag.printableString => this.asciiString("PrintableString")
            case Universal(n) where n == ASN1UniversalTag.ia5String => this.asciiString("IA5String")
            case Universal(n) where n == ASN1UniversalTag.bmpString => this.bmpString()
            case Universal(n) where n == ASN1UniversalTag.teletexString => bytesToLatin1(this.requirePrimitive())
            case _ => throw ASN1Error("unexpected string tag ${this.tagDescription()}")
        }
    }

    public func utf8String(): String {
        this.requireUniversal(ASN1UniversalTag.utf8String)
        stringFromUtf8(this.requirePrimitive())
    }

    public func asciiString(_: String): String {
        bytesToLatin1(this.requirePrimitive())
    }

    public func bmpString(): String {
        this.requireUniversal(ASN1UniversalTag.bmpString)
        decodeBmp(this.requirePrimitive())
    }

    public func anyTime(): DateTime {
        match (this.tag) {
            case Universal(n) where n == ASN1UniversalTag.utcTime => parseUtcTime(this.asciiTime("UTCTime"))
            case Universal(n) where n == ASN1UniversalTag.generalizedTime => parseGeneralizedTime(this.asciiTime("GeneralizedTime"))
            case _ => throw ASN1Error("unexpected time tag ${this.tagDescription()}")
        }
    }

    public func asciiTime(_: String): String {
        bytesToLatin1(this.requirePrimitive())
    }

    public func tagDescription(): String {
        match (this.tag) {
            case Universal(n) => "UNIVERSAL ${n}"
            case Application(n) => "APPLICATION ${n}"
            case ContextSpecific(n) => "CONTEXT ${n}"
            case Private(n) => "PRIVATE ${n}"
        }
    }
}

func decodeOid(bytes: Array<Byte>): String {
    if (bytes.size == 0) {
        throw ASN1Error("empty OID")
    }
    let components = ArrayList<Int64>()
    let firstByte = byteValue(bytes, 0)
    if (firstByte < 80) {
        components.add(firstByte / 40)
        components.add(firstByte % 40)
    } else {
        components.add(2)
        components.add(firstByte - 80)
    }
    var value: Int64 = 0
    var inProgress = false
    var i: Int64 = 1
    while (i < bytes.size) {
        let b = byteValue(bytes, i)
        value = (value << 7) | (b & 0x7F)
        inProgress = true
        if ((b & 0x80) == 0) {
            components.add(value)
            value = 0
            inProgress = false
        }
        i = i + 1
    }
    if (inProgress) {
        throw ASN1Error("truncated OID encoding")
    }
    joinOid(components.toArray())
}

func parseTwoDigits(s: Array<Byte>, start: Int64): Int64 {
    let d0 = byteValue(s, start) - 48
    let d1 = byteValue(s, start + 1) - 48
    if (d0 < 0 || d0 > 9 || d1 < 0 || d1 > 9) {
        throw ASN1Error("time field not numeric")
    }
    d0 * 10 + d1
}

func parseFourDigits(s: Array<Byte>, start: Int64): Int64 {
    parseTwoDigits(s, start) * 100 + parseTwoDigits(s, start + 2)
}

func parseUtcTime(s: String): DateTime {
    let bytes = s.toArray()
    if (bytes.size != 13 || byteValue(bytes, 12) != 90) {
        throw ASN1Error("UTCTime must be 13 chars YYMMDDHHMMSSZ, got '${s}'")
    }
    let yy = parseTwoDigits(bytes, 0)
    let fullYear = if (yy < 50) { 2000 + yy } else { 1900 + yy }
    DateTime.ofUTC(
        year: fullYear,
        month: parseTwoDigits(bytes, 2),
        dayOfMonth: parseTwoDigits(bytes, 4),
        hour: parseTwoDigits(bytes, 6),
        minute: parseTwoDigits(bytes, 8),
        second: parseTwoDigits(bytes, 10)
    )
}

func parseGeneralizedTime(s: String): DateTime {
    let bytes = s.toArray()
    if (bytes.size != 15 || byteValue(bytes, 14) != 90) {
        throw ASN1Error("GeneralizedTime (cert validity) must be 15 chars YYYYMMDDHHMMSSZ, got '${s}'")
    }
    DateTime.ofUTC(
        year: parseFourDigits(bytes, 0),
        month: parseTwoDigits(bytes, 4),
        dayOfMonth: parseTwoDigits(bytes, 6),
        hour: parseTwoDigits(bytes, 8),
        minute: parseTwoDigits(bytes, 10),
        second: parseTwoDigits(bytes, 12)
    )
}

func stringFromUtf8(bytes: Array<Byte>): String {
    String.fromUtf8(bytes)
}

func bytesToLatin1(bytes: Array<Byte>): String {
    var result = ""
    var i: Int64 = 0
    while (i < bytes.size) {
        result = result + "${Rune(UInt32(byteValue(bytes, i)))}"
        i = i + 1
    }
    result
}

func decodeBmp(bytes: Array<Byte>): String {
    if ((bytes.size % 2) != 0) {
        throw ASN1Error("invalid BMPString")
    }
    var result = ""
    var i: Int64 = 0
    while (i < bytes.size) {
        let code = (byteValue(bytes, i) << 8) | byteValue(bytes, i + 1)
        result = result + "${Rune(UInt32(code))}"
        i = i + 2
    }
    result
}
