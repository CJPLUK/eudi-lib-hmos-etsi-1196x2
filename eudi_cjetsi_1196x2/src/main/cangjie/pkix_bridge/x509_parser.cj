package ohos_app_cangjie_eudi_cjetsi_1196x2.pkix_bridge

import std.collection.ArrayList

public class X509Parser {
    public static func parse(der: Array<Byte>): X509ParsedCertificate {
        let cert = ASN1Parser.parse(der)
        let topChildren = cert.sequence()
        if (topChildren.size == 0) {
            throw ASN1Error("Certificate SEQUENCE is empty")
        }
        let tbsChildren = topChildren[0].sequence()
        var idx: Int64 = 0

        var version: Int64 = 0
        if (idx < tbsChildren.size && tbsChildren[idx].isContextSpecific(0)) {
            let wrapper = tbsChildren[idx]
            let inner = wrapper.requireConstructed()
            if (inner.size == 0) {
                throw ASN1Error("Empty version wrapper")
            }
            let intBytes = inner[0].integerBytes()
            if (intBytes.size > 0) {
                version = byteValue(intBytes, 0)
            }
            idx = idx + 1
        }

        if (idx >= tbsChildren.size) {
            throw ASN1Error("Missing serialNumber")
        }
        let serial = tbsChildren[idx].integerBytes()
        idx = idx + 1

        if (idx >= tbsChildren.size) {
            throw ASN1Error("Missing signatureAlgorithm")
        }
        let sigAlgChildren = tbsChildren[idx].sequence()
        if (sigAlgChildren.size == 0) {
            throw ASN1Error("Missing signatureAlgorithm OID")
        }
        let sigAlgOid = sigAlgChildren[0].objectIdentifier()
        idx = idx + 1

        if (idx >= tbsChildren.size) {
            throw ASN1Error("Missing issuer")
        }
        let issuer = parseName(tbsChildren[idx])
        idx = idx + 1

        if (idx >= tbsChildren.size) {
            throw ASN1Error("Missing validity")
        }
        let validityChildren = tbsChildren[idx].sequence()
        if (validityChildren.size < 2) {
            throw ASN1Error("Validity SEQUENCE must have 2 fields")
        }
        let notBefore = validityChildren[0].anyTime()
        let notAfter = validityChildren[1].anyTime()
        idx = idx + 1

        if (idx >= tbsChildren.size) {
            throw ASN1Error("Missing subject")
        }
        let subject = parseName(tbsChildren[idx])
        idx = idx + 1

        if (idx >= tbsChildren.size) {
            throw ASN1Error("Missing subjectPublicKeyInfo")
        }
        let spki = tbsChildren[idx]
        idx = idx + 1

        while (idx < tbsChildren.size) {
            if (tbsChildren[idx].isContextSpecific(1) || tbsChildren[idx].isContextSpecific(2)) {
                idx = idx + 1
            } else {
                break
            }
        }

        let extensions = ArrayList<X509Extension>()
        if (idx < tbsChildren.size && tbsChildren[idx].isContextSpecific(3)) {
            let wrapper = tbsChildren[idx]
            let inner = wrapper.requireConstructed()
            if (inner.size == 0) {
                throw ASN1Error("Empty extensions wrapper")
            }
            let extElements = inner[0].sequence()
            var e: Int64 = 0
            while (e < extElements.size) {
                extensions.add(parseExtension(extElements[e]))
                e = e + 1
            }
        }

        X509ParsedCertificate(
            version: version,
            serialNumber: serial,
            signatureAlgorithmOid: sigAlgOid,
            issuer: issuer,
            notBefore: notBefore,
            notAfter: notAfter,
            subject: subject,
            subjectPublicKeyInfo: spki,
            extensions: extensions.toArray()
        )
    }

    public static func parseName(element: ASN1Element): X509DistinguishedName {
        let rdnSequence = element.sequence()
        let attributes = ArrayList<X509DnAttribute>()
        var r: Int64 = 0
        while (r < rdnSequence.size) {
            let atvs = rdnSequence[r].setOf()
            var a: Int64 = 0
            while (a < atvs.size) {
                let pair = atvs[a].requireConstructed()
                if (pair.size >= 2) {
                    let attrOid = pair[0].objectIdentifier()
                    let value = pair[1].directoryString()
                    attributes.add(X509DnAttribute(oid: attrOid, value: value))
                }
                a = a + 1
            }
            r = r + 1
        }
        X509DistinguishedName(attributes.toArray())
    }

    static func parseExtension(element: ASN1Element): X509Extension {
        let children = element.sequence()
        if (children.size < 2) {
            throw ASN1Error("Extension SEQUENCE must have >=2 fields")
        }
        let oid = children[0].objectIdentifier()
        if (children.size == 2) {
            return X509Extension(oid: oid, critical: false, valueBytes: children[1].octetString())
        }
        X509Extension(
            oid: oid,
            critical: children[1].boolValue(),
            valueBytes: children[2].octetString()
        )
    }
}
