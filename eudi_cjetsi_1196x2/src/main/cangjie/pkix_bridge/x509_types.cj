package ohos_app_cangjie_eudi_cjetsi_1196x2.pkix_bridge

import std.collection.HashMap
import std.time.DateTime

public class X509Oids {
    public static let keyUsage: String = "2.5.29.15"
    public static let subjectAltName: String = "2.5.29.17"
    public static let basicConstraints: String = "2.5.29.19"
    public static let crlDistributionPoints: String = "2.5.29.31"
    public static let certificatePolicies: String = "2.5.29.32"
    public static let authorityKeyIdentifier: String = "2.5.29.35"
    public static let subjectKeyIdentifier: String = "2.5.29.14"
    public static let authorityInformationAccess: String = "1.3.6.1.5.5.7.1.1"
    public static let qcStatements: String = "1.3.6.1.5.5.7.1.3"
    public static let aiaCaIssuers: String = "1.3.6.1.5.5.7.48.2"
    public static let aiaOcsp: String = "1.3.6.1.5.5.7.48.1"
    public static let etsiQcsQcType: String = "0.4.0.1862.1.6"
    public static let rsaEncryption: String = "1.2.840.113549.1.1.1"
    public static let ecPublicKey: String = "1.2.840.10045.2.1"
    public static let dsa: String = "1.2.840.10040.4.1"
    public static let secp256r1: String = "1.2.840.10045.3.1.7"
    public static let secp384r1: String = "1.3.132.0.34"
    public static let secp521r1: String = "1.3.132.0.35"
}

public class X509DnAttribute {
    public let oid: String
    public let value: String

    public init(oid!: String, value!: String) {
        this.oid = oid
        this.value = value
    }
}

public class X509DistinguishedName {
    public let attributes: Array<X509DnAttribute>

    public init(attributes: Array<X509DnAttribute>) {
        this.attributes = attributes
    }

    public func equalsDn(other: X509DistinguishedName): Bool {
        if (this.attributes.size != other.attributes.size) {
            return false
        }
        var i: Int64 = 0
        while (i < this.attributes.size) {
            if (this.attributes[i].oid != other.attributes[i].oid || this.attributes[i].value != other.attributes[i].value) {
                return false
            }
            i = i + 1
        }
        true
    }

    public func toOidMap(): HashMap<String, String> {
        let dict = HashMap<String, String>()
        var i: Int64 = 0
        while (i < this.attributes.size) {
            let attr = this.attributes[i]
            if (dict.contains(attr.oid)) {
                dict.remove(attr.oid)
            }
            dict.add(attr.oid, attr.value)
            i = i + 1
        }
        dict
    }
}

public class X509Extension {
    public let oid: String
    public let critical: Bool
    public let valueBytes: Array<Byte>

    public init(oid!: String, critical!: Bool, valueBytes!: Array<Byte>) {
        this.oid = oid
        this.critical = critical
        this.valueBytes = valueBytes
    }
}

public class X509ParsedCertificate {
    public let version: Int64
    public let serialNumber: Array<Byte>
    public let signatureAlgorithmOid: String
    public let issuer: X509DistinguishedName
    public let notBefore: DateTime
    public let notAfter: DateTime
    public let subject: X509DistinguishedName
    public let subjectPublicKeyInfo: ASN1Element
    public let extensions: Array<X509Extension>

    public init(
        version!: Int64,
        serialNumber!: Array<Byte>,
        signatureAlgorithmOid!: String,
        issuer!: X509DistinguishedName,
        notBefore!: DateTime,
        notAfter!: DateTime,
        subject!: X509DistinguishedName,
        subjectPublicKeyInfo!: ASN1Element,
        extensions!: Array<X509Extension>
    ) {
        this.version = version
        this.serialNumber = serialNumber
        this.signatureAlgorithmOid = signatureAlgorithmOid
        this.issuer = issuer
        this.notBefore = notBefore
        this.notAfter = notAfter
        this.subject = subject
        this.subjectPublicKeyInfo = subjectPublicKeyInfo
        this.extensions = extensions
    }

    public func findExtension(oid: String): ?X509Extension {
        var i: Int64 = 0
        while (i < this.extensions.size) {
            if (this.extensions[i].oid == oid) {
                return this.extensions[i]
            }
            i = i + 1
        }
        None
    }
}

public class KeyUsageBits {
    public let digitalSignature: Bool
    public let nonRepudiation: Bool
    public let keyEncipherment: Bool
    public let dataEncipherment: Bool
    public let keyAgreement: Bool
    public let keyCertSign: Bool
    public let crlSign: Bool
    public let encipherOnly: Bool
    public let decipherOnly: Bool

    public init(
        digitalSignature!: Bool,
        nonRepudiation!: Bool,
        keyEncipherment!: Bool,
        dataEncipherment!: Bool,
        keyAgreement!: Bool,
        keyCertSign!: Bool,
        crlSign!: Bool,
        encipherOnly!: Bool,
        decipherOnly!: Bool
    ) {
        this.digitalSignature = digitalSignature
        this.nonRepudiation = nonRepudiation
        this.keyEncipherment = keyEncipherment
        this.dataEncipherment = dataEncipherment
        this.keyAgreement = keyAgreement
        this.keyCertSign = keyCertSign
        this.crlSign = crlSign
        this.encipherOnly = encipherOnly
        this.decipherOnly = decipherOnly
    }
}

public class BasicConstraintsInfo {
    public let isCa: Bool
    public let pathLenConstraint: ?Int64

    public init(isCa!: Bool, pathLenConstraint!: ?Int64) {
        this.isCa = isCa
        this.pathLenConstraint = pathLenConstraint
    }
}

public enum SubjectAltName {
    | DnsName(String)
    | Rfc822Name(String)
    | UriName(String)
    | IpAddress(Array<Byte>)
    | RegisteredId(String)
    | OtherName(String)
}

public class AuthorityKeyIdentifierInfo {
    public let keyIdentifier: ?Array<Byte>
    public let authorityCertSerialNumber: ?Array<Byte>

    public init(keyIdentifier!: ?Array<Byte>, authorityCertSerialNumber!: ?Array<Byte>) {
        this.keyIdentifier = keyIdentifier
        this.authorityCertSerialNumber = authorityCertSerialNumber
    }
}

public class AuthorityInformationAccessInfo {
    public let caIssuersUri: ?String
    public let ocspUri: ?String

    public init(caIssuersUri!: ?String, ocspUri!: ?String) {
        this.caIssuersUri = caIssuersUri
        this.ocspUri = ocspUri
    }
}

public enum QcStatement {
    | QcType(String)
    | OtherQc(String)
}

public class PublicKeyInfo {
    public let algorithm: String
    public let keySize: ?Int64

    public init(algorithm!: String, keySize!: ?Int64) {
        this.algorithm = algorithm
        this.keySize = keySize
    }
}
