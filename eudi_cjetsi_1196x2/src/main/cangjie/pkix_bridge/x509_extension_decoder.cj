package ohos_app_cangjie_eudi_cjetsi_1196x2.pkix_bridge

import std.collection.ArrayList

public class X509ExtensionDecoder {
    public static func decodeKeyUsage(value: Array<Byte>): KeyUsageBits {
        let bits = ASN1Parser.parse(value).bitStringData()
        KeyUsageBits(
            digitalSignature: bitAt(bits, 0),
            nonRepudiation: bitAt(bits, 1),
            keyEncipherment: bitAt(bits, 2),
            dataEncipherment: bitAt(bits, 3),
            keyAgreement: bitAt(bits, 4),
            keyCertSign: bitAt(bits, 5),
            crlSign: bitAt(bits, 6),
            encipherOnly: bitAt(bits, 7),
            decipherOnly: bitAt(bits, 8)
        )
    }

    public static func decodeBasicConstraints(value: Array<Byte>): BasicConstraintsInfo {
        let seq = ASN1Parser.parse(value).sequence()
        var isCa = false
        var pathLen: ?Int64 = None
        var i: Int64 = 0
        while (i < seq.size) {
            let elem = seq[i]
            if (elem.isUniversal(ASN1UniversalTag.boolean)) {
                isCa = elem.boolValue()
            } else if (elem.isUniversal(ASN1UniversalTag.integer)) {
                pathLen = intValueFrom(elem.integerBytes())
            }
            i = i + 1
        }
        BasicConstraintsInfo(isCa: isCa, pathLenConstraint: pathLen)
    }

    public static func decodeSubjectAltName(value: Array<Byte>): Array<SubjectAltName> {
        let seq = ASN1Parser.parse(value).requireConstructed()
        let names = ArrayList<SubjectAltName>()
        var i: Int64 = 0
        while (i < seq.size) {
            match (decodeGeneralName(seq[i])) {
                case Some(name) => names.add(name)
                case None => ()
            }
            i = i + 1
        }
        names.toArray()
    }

    static func decodeGeneralName(element: ASN1Element): ?SubjectAltName {
        match (element.tag) {
            case ContextSpecific(0) =>
                match (element.children()) {
                    case Some(children) where children.size > 0 =>
                        try {
                            OtherName(children[0].objectIdentifier())
                        } catch (e: Exception) {
                            None
                        }
                    case _ => None
                }
            case ContextSpecific(1) =>
                match (element.primitiveBytes()) {
                    case Some(bytes) => Rfc822Name(bytesToLatin1(bytes))
                    case None => None
                }
            case ContextSpecific(2) =>
                match (element.primitiveBytes()) {
                    case Some(bytes) => DnsName(bytesToLatin1(bytes))
                    case None => None
                }
            case ContextSpecific(6) =>
                match (element.primitiveBytes()) {
                    case Some(bytes) => UriName(bytesToLatin1(bytes))
                    case None => None
                }
            case ContextSpecific(7) =>
                match (element.primitiveBytes()) {
                    case Some(bytes) => IpAddress(bytes)
                    case None => None
                }
            case ContextSpecific(8) =>
                match (element.primitiveBytes()) {
                    case Some(bytes) =>
                        try {
                            RegisteredId(decodeOid(bytes))
                        } catch (e: Exception) {
                            None
                        }
                    case None => None
                }
            case _ => None
        }
    }

    public static func decodeAuthorityKeyIdentifier(value: Array<Byte>): AuthorityKeyIdentifierInfo {
        let seq = ASN1Parser.parse(value).requireConstructed()
        var keyId: ?Array<Byte> = None
        var serial: ?Array<Byte> = None
        var i: Int64 = 0
        while (i < seq.size) {
            let elem = seq[i]
            if (elem.isContextSpecific(0)) {
                keyId = elem.primitiveBytes()
            } else if (elem.isContextSpecific(2)) {
                serial = elem.primitiveBytes()
            }
            i = i + 1
        }
        AuthorityKeyIdentifierInfo(keyIdentifier: keyId, authorityCertSerialNumber: serial)
    }

    public static func decodeSubjectKeyIdentifier(value: Array<Byte>): Array<Byte> {
        ASN1Parser.parse(value).octetString()
    }

    public static func decodeCrlDistributionPoints(value: Array<Byte>): Array<String> {
        let seq = ASN1Parser.parse(value).requireConstructed()
        let uris = ArrayList<String>()
        var d: Int64 = 0
        while (d < seq.size) {
            match (seq[d].children()) {
                case Some(dpChildren) =>
                    var c: Int64 = 0
                    while (c < dpChildren.size) {
                        let child = dpChildren[c]
                        if (child.isContextSpecific(0)) {
                            match (child.children()) {
                                case Some(nameAlternatives) => collectCrlUris(nameAlternatives, uris)
                                case None => ()
                            }
                        }
                        c = c + 1
                    }
                case None => ()
            }
            d = d + 1
        }
        uris.toArray()
    }

    static func collectCrlUris(nameAlternatives: Array<ASN1Element>, uris: ArrayList<String>): Unit {
        var n: Int64 = 0
        while (n < nameAlternatives.size) {
            let name = nameAlternatives[n]
            if (name.isContextSpecific(0)) {
                match (name.children()) {
                    case Some(generalNames) =>
                        var g: Int64 = 0
                        while (g < generalNames.size) {
                            let gn = generalNames[g]
                            if (gn.isContextSpecific(6)) {
                                match (gn.primitiveBytes()) {
                                    case Some(bytes) => uris.add(bytesToLatin1(bytes))
                                    case None => ()
                                }
                            }
                            g = g + 1
                        }
                    case None => ()
                }
            }
            n = n + 1
        }
    }

    public static func decodeAuthorityInformationAccess(value: Array<Byte>): AuthorityInformationAccessInfo {
        let seq = ASN1Parser.parse(value).requireConstructed()
        var caIssuersUri: ?String = None
        var ocspUri: ?String = None
        var i: Int64 = 0
        while (i < seq.size) {
            let children = seq[i].requireConstructed()
            if (children.size >= 2) {
                let method = children[0].objectIdentifier()
                let location = children[1]
                if (location.isContextSpecific(6)) {
                    match (location.primitiveBytes()) {
                        case Some(bytes) =>
                            let uri = bytesToLatin1(bytes)
                            if (method == X509Oids.aiaCaIssuers) {
                                caIssuersUri = uri
                            } else if (method == X509Oids.aiaOcsp) {
                                ocspUri = uri
                            }
                        case None => ()
                    }
                }
            }
            i = i + 1
        }
        AuthorityInformationAccessInfo(caIssuersUri: caIssuersUri, ocspUri: ocspUri)
    }

    public static func decodeCertificatePolicies(value: Array<Byte>): Array<String> {
        let seq = ASN1Parser.parse(value).requireConstructed()
        let oids = ArrayList<String>()
        var i: Int64 = 0
        while (i < seq.size) {
            let children = seq[i].requireConstructed()
            if (children.size > 0) {
                oids.add(children[0].objectIdentifier())
            }
            i = i + 1
        }
        oids.toArray()
    }

    public static func decodeQcStatements(value: Array<Byte>): Array<QcStatement> {
        let seq = ASN1Parser.parse(value).requireConstructed()
        let result = ArrayList<QcStatement>()
        var i: Int64 = 0
        while (i < seq.size) {
            let children = seq[i].requireConstructed()
            if (children.size > 0) {
                let stmtId = children[0].objectIdentifier()
                if (stmtId == X509Oids.etsiQcsQcType && children.size >= 2) {
                    let typeSeq = children[1].requireConstructed()
                    var t: Int64 = 0
                    while (t < typeSeq.size) {
                        try {
                            result.add(QcType(typeSeq[t].objectIdentifier()))
                        } catch (e: Exception) {
                            ()
                        }
                        t = t + 1
                    }
                } else {
                    result.add(OtherQc(stmtId))
                }
            }
            i = i + 1
        }
        result.toArray()
    }

    static func bitAt(bits: Array<Byte>, index: Int64): Bool {
        let byteIndex = index / 8
        let bitIndex = index % 8
        if (byteIndex >= bits.size) {
            return false
        }
        let mask: Int64 = 0x80 >> bitIndex
        (byteValue(bits, byteIndex) & mask) != 0
    }

    static func intValueFrom(bytes: Array<Byte>): ?Int64 {
        if (bytes.size == 0 || bytes.size > 8) {
            return None
        }
        var result: Int64 = 0
        let isNegative = (byteValue(bytes, 0) & 0x80) != 0
        var i: Int64 = 0
        while (i < bytes.size) {
            result = (result << 8) | byteValue(bytes, i)
            i = i + 1
        }
        if (isNegative) {
            let bitCount = bytes.size * 8
            result = result - (1 << bitCount)
        }
        result
    }
}
