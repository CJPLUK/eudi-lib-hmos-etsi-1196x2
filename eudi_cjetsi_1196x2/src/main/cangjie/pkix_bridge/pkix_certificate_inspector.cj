package ohos_app_cangjie_eudi_cjetsi_1196x2.pkix_bridge

import std.collection.HashMap
import stdx.crypto.common.DerBlob
import stdx.crypto.x509.{X509Certificate, PublicKeyAlgorithm}

public class PKIXCertificateInspector {
    public init() {}

    public func getVersion(der: Array<Byte>): Int64 {
        match (tryParse(der)) {
            case Some(cert) => cert.version
            case None => 0
        }
    }

    public func getSerialNumber(der: Array<Byte>): ?Array<Byte> {
        match (tryParse(der)) {
            case Some(cert) => cert.serialNumber
            case None => None
        }
    }

    public func getValidityNotBeforeEpochSeconds(der: Array<Byte>): ?Int64 {
        match (tryParse(der)) {
            case Some(cert) => cert.notBefore.toUnixTimeStamp().toSeconds()
            case None => None
        }
    }

    public func getValidityNotAfterEpochSeconds(der: Array<Byte>): ?Int64 {
        match (tryParse(der)) {
            case Some(cert) => cert.notAfter.toUnixTimeStamp().toSeconds()
            case None => None
        }
    }

    public func getSubject(der: Array<Byte>): ?HashMap<String, String> {
        match (tryParse(der)) {
            case Some(cert) => cert.subject.toOidMap()
            case None => None
        }
    }

    public func getIssuer(der: Array<Byte>): ?HashMap<String, String> {
        match (tryParse(der)) {
            case Some(cert) => cert.issuer.toOidMap()
            case None => None
        }
    }

    public func isSelfSigned(der: Array<Byte>): Bool {
        match (tryParse(der)) {
            case Some(cert) => cert.subject.equalsDn(cert.issuer)
            case None => false
        }
    }

    public func hasExtension(der: Array<Byte>, oid: String): Bool {
        match (tryParse(der)) {
            case Some(cert) =>
                match (cert.findExtension(oid)) {
                    case Some(_) => true
                    case None => false
                }
            case None => false
        }
    }

    public func getExtensionCriticality(der: Array<Byte>): ?HashMap<String, Bool> {
        match (tryParse(der)) {
            case Some(cert) =>
                let dict = HashMap<String, Bool>()
                var i: Int64 = 0
                while (i < cert.extensions.size) {
                    let ext = cert.extensions[i]
                    if (dict.contains(ext.oid)) {
                        dict.remove(ext.oid)
                    }
                    dict.add(ext.oid, ext.critical)
                    i = i + 1
                }
                dict
            case None => None
        }
    }

    public func getKeyUsage(der: Array<Byte>): ?KeyUsageBits {
        match (extensionValue(der, X509Oids.keyUsage)) {
            case Some(bytes) =>
                try {
                    X509ExtensionDecoder.decodeKeyUsage(bytes)
                } catch (e: Exception) {
                    None
                }
            case None => None
        }
    }

    public func getBasicConstraints(der: Array<Byte>): ?BasicConstraintsInfo {
        match (extensionValue(der, X509Oids.basicConstraints)) {
            case Some(bytes) =>
                try {
                    X509ExtensionDecoder.decodeBasicConstraints(bytes)
                } catch (e: Exception) {
                    None
                }
            case None => None
        }
    }

    public func getSubjectAltNames(der: Array<Byte>): ?Array<SubjectAltName> {
        match (extensionValue(der, X509Oids.subjectAltName)) {
            case Some(bytes) =>
                try {
                    X509ExtensionDecoder.decodeSubjectAltName(bytes)
                } catch (e: Exception) {
                    None
                }
            case None => None
        }
    }

    public func getSubjectKeyIdentifier(der: Array<Byte>): ?Array<Byte> {
        match (extensionValue(der, X509Oids.subjectKeyIdentifier)) {
            case Some(bytes) =>
                try {
                    X509ExtensionDecoder.decodeSubjectKeyIdentifier(bytes)
                } catch (e: Exception) {
                    None
                }
            case None => None
        }
    }

    public func getAuthorityKeyIdentifier(der: Array<Byte>): ?AuthorityKeyIdentifierInfo {
        match (extensionValue(der, X509Oids.authorityKeyIdentifier)) {
            case Some(bytes) =>
                try {
                    let aki = X509ExtensionDecoder.decodeAuthorityKeyIdentifier(bytes)
                    match ((aki.keyIdentifier, aki.authorityCertSerialNumber)) {
                        case (None, None) => None
                        case _ => aki
                    }
                } catch (e: Exception) {
                    None
                }
            case None => None
        }
    }

    public func getCertificatePolicies(der: Array<Byte>): ?Array<String> {
        match (extensionValue(der, X509Oids.certificatePolicies)) {
            case Some(bytes) =>
                try {
                    X509ExtensionDecoder.decodeCertificatePolicies(bytes)
                } catch (e: Exception) {
                    None
                }
            case None => None
        }
    }

    public func getCrlDistributionPoints(der: Array<Byte>): ?Array<String> {
        match (extensionValue(der, X509Oids.crlDistributionPoints)) {
            case Some(bytes) =>
                try {
                    X509ExtensionDecoder.decodeCrlDistributionPoints(bytes)
                } catch (e: Exception) {
                    None
                }
            case None => None
        }
    }

    public func getAuthorityInfoAccess(der: Array<Byte>): ?AuthorityInformationAccessInfo {
        match (extensionValue(der, X509Oids.authorityInformationAccess)) {
            case Some(bytes) =>
                try {
                    let aia = X509ExtensionDecoder.decodeAuthorityInformationAccess(bytes)
                    match ((aia.caIssuersUri, aia.ocspUri)) {
                        case (None, None) => None
                        case _ => aia
                    }
                } catch (e: Exception) {
                    None
                }
            case None => None
        }
    }

    public func getQcStatements(der: Array<Byte>): ?Array<QcStatement> {
        match (extensionValue(der, X509Oids.qcStatements)) {
            case Some(bytes) =>
                try {
                    X509ExtensionDecoder.decodeQcStatements(bytes)
                } catch (e: Exception) {
                    None
                }
            case None => None
        }
    }

    public func getPublicKeyInfo(der: Array<Byte>): ?PublicKeyInfo {
        try {
            let stdxCert = X509Certificate.decodeFromDer(DerBlob(der))
            let algorithm = match (stdxCert.publicKeyAlgorithm) {
                case PublicKeyAlgorithm.RSA => "RSA"
                case PublicKeyAlgorithm.ECDSA => "EC"
                case PublicKeyAlgorithm.DSA => "DSA"
                case PublicKeyAlgorithm.UnknownPublicKeyAlgorithm => "UNKNOWN"
            }
            let parsed = X509Parser.parse(der)
            let keySize = spkiKeySize(parsed.subjectPublicKeyInfo, algorithm)
            PublicKeyInfo(algorithm: algorithm, keySize: keySize)
        } catch (e: Exception) {
            None
        }
    }

    static func tryParse(der: Array<Byte>): ?X509ParsedCertificate {
        try {
            X509Parser.parse(der)
        } catch (e: Exception) {
            None
        }
    }

    static func extensionValue(der: Array<Byte>, oid: String): ?Array<Byte> {
        match (tryParse(der)) {
            case Some(cert) =>
                match (cert.findExtension(oid)) {
                    case Some(ext) => ext.valueBytes
                    case None => None
                }
            case None => None
        }
    }

    static func spkiKeySize(spki: ASN1Element, algorithm: String): ?Int64 {
        try {
            let children = spki.sequence()
            if (children.size < 2) {
                return None
            }
            if (algorithm == "RSA") {
                let bits = children[1].bitStringData()
                let rsa = ASN1Parser.parse(bits).sequence()
                if (rsa.size == 0) {
                    return None
                }
                return integerBitLength(rsa[0].integerBytes())
            }
            if (algorithm == "EC") {
                let algId = children[0].sequence()
                if (algId.size >= 2) {
                    let curve = algId[1].objectIdentifier()
                    if (curve == X509Oids.secp256r1) {
                        return 256
                    }
                    if (curve == X509Oids.secp384r1) {
                        return 384
                    }
                    if (curve == X509Oids.secp521r1) {
                        return 521
                    }
                }
                return None
            }
            None
        } catch (e: Exception) {
            None
        }
    }

    static func integerBitLength(bytes: Array<Byte>): ?Int64 {
        if (bytes.size == 0) {
            return None
        }
        var i: Int64 = 0
        while (i < bytes.size && byteValue(bytes, i) == 0) {
            i = i + 1
        }
        if (i >= bytes.size) {
            return 0
        }
        var bits = (bytes.size - i) * 8
        var v = byteValue(bytes, i)
        while (v > 0 && (v & 0x80) == 0) {
            bits = bits - 1
            v = v << 1
        }
        bits
    }
}
