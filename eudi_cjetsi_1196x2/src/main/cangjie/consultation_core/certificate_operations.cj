package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

import std.collection.*
import std.time.*

/// Expect surface for X.509 field and extension access.
/// Platform actuals (consultation_platform) implement this using stdx.crypto.x509.
public interface CertificateOperations<CERT> {
    func getBasicConstraints(certificate: CERT): BasicConstraintsInfo
    func getQcStatements(certificate: CERT): ArrayList<QCStatementInfo>
    func getKeyUsage(certificate: CERT): ?KeyUsageBits
    func getValidityPeriod(certificate: CERT): ValidityPeriod
    func getCertificatePolicies(certificate: CERT): ?ArrayList<String>
    func isSelfSigned(certificate: CERT): Bool
    func getAiaExtension(certificate: CERT): ?AuthorityInformationAccess
    func getSubject(certificate: CERT): ?DistinguishedName
    func getIssuer(certificate: CERT): ?DistinguishedName
    func getSubjectAltNames(certificate: CERT): ?ArrayList<SubjectAlternativeName>
    func getExtensionCriticality(certificate: CERT): HashMap<String, Bool>
    func getCrlDistributionPoints(certificate: CERT): ArrayList<CrlDistributionPoint>
    func getAuthorityKeyIdentifier(certificate: CERT): ?AuthorityKeyIdentifier
    func getSubjectKeyIdentifier(certificate: CERT): ?Array<UInt8>
    func getSerialNumber(certificate: CERT): SerialNumber
    func getVersion(certificate: CERT): Version
    func getSubjectPublicKeyInfo(certificate: CERT): PublicKeyInfo
    func hasExtension(certificate: CERT, oid: String): Bool
}

/// Algebra of certificate operations (free-monad functor), independent of CERT.
public enum CertificateOp {
    | GetBasicConstraints
    | GetKeyUsage
    | GetValidity
    | GetPolicies
    | CheckSelfSigned
    | GetAia
    | GetQcStatements(String)
    | GetSubject
    | GetIssuer
    | GetSubjectAltNames
    | GetCrlDistributionPoints
    | GetAuthorityKeyIdentifier
    | GetSubjectKeyIdentifier
    | GetSerialNumber
    | GetVersion
    | GetSubjectPublicKeyInfo
    | GetAllQcStatements
    | HasExtension(String)
    | GetExtensionCriticality
    | CombineTwo(CertificateOp, CertificateOp)
    | CombineThree(CertificateOp, CertificateOp, CertificateOp)
}

/// Interpreted result of a CertificateOp, used by constraint evaluators.
public enum OpValue {
    | BasicConstraints(BasicConstraintsInfo)
    | KeyUsage(?KeyUsageBits)
    | Validity(ValidityPeriod)
    | Policies(?ArrayList<String>)
    | Flag(Bool)
    | Aia(?AuthorityInformationAccess)
    | QcStatements(ArrayList<QCStatementInfo>)
    | Name(?DistinguishedName)
    | SubjectAltNames(?ArrayList<SubjectAlternativeName>)
    | CrlDistributionPoints(ArrayList<CrlDistributionPoint>)
    | AuthorityKeyId(?AuthorityKeyIdentifier)
    | SubjectKeyId(?Array<UInt8>)
    | Serial(SerialNumber)
    | CertVersion(Version)
    | PublicKey(PublicKeyInfo)
    | Criticality(HashMap<String, Bool>)
    | Pair(OpValue, OpValue)
    | Triple(OpValue, OpValue, OpValue)
}

public class BasicConstraintsInfo {
    public let isCa: Bool
    public let pathLenConstraint: ?Int64

    public init(isCa: Bool, pathLenConstraint: ?Int64) {
        this.isCa = isCa
        this.pathLenConstraint = pathLenConstraint
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
        digitalSignature!: Bool = false,
        nonRepudiation!: Bool = false,
        keyEncipherment!: Bool = false,
        dataEncipherment!: Bool = false,
        keyAgreement!: Bool = false,
        keyCertSign!: Bool = false,
        crlSign!: Bool = false,
        encipherOnly!: Bool = false,
        decipherOnly!: Bool = false
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

    public func bitNamed(name: String): Bool {
        if (name == "digitalSignature") {
            this.digitalSignature
        } else if (name == "nonRepudiation") {
            this.nonRepudiation
        } else if (name == "keyEncipherment") {
            this.keyEncipherment
        } else if (name == "dataEncipherment") {
            this.dataEncipherment
        } else if (name == "keyAgreement") {
            this.keyAgreement
        } else if (name == "keyCertSign") {
            this.keyCertSign
        } else if (name == "crlSign") {
            this.crlSign
        } else if (name == "encipherOnly") {
            this.encipherOnly
        } else if (name == "decipherOnly") {
            this.decipherOnly
        } else {
            throw IllegalArgumentException("Invalid key usage bit: ${name}")
        }
    }
}

public enum QCStatementInfo {
    | QcType(String)
    | OtherQcStatement(String)

    public func statementId(): String {
        match (this) {
            case QCStatementInfo.QcType(_) => ETSI319412.QC_TYPE
            case QCStatementInfo.OtherQcStatement(id) => id
        }
    }

    public func semanticOid(): String {
        match (this) {
            case QCStatementInfo.QcType(typeIdentifier) => typeIdentifier
            case QCStatementInfo.OtherQcStatement(id) => id
        }
    }
}

public class ValidityPeriod {
    public let notBefore: DateTime
    public let notAfter: DateTime

    public init(notBefore: DateTime, notAfter: DateTime) {
        this.notBefore = notBefore
        this.notAfter = notAfter
    }
}

public class AuthorityInformationAccess {
    public let caIssuersUri: ?String
    public let ocspUri: ?String

    public init(caIssuersUri: ?String, ocspUri: ?String) {
        this.caIssuersUri = caIssuersUri
        this.ocspUri = ocspUri
    }
}

public class X500OIDs {
    public static let COMMON_NAME: String = "2.5.4.3"
    public static let SERIAL_NUMBER: String = "2.5.4.5"
    public static let COUNTRY: String = "2.5.4.6"
    public static let LOCALITY: String = "2.5.4.7"
    public static let STATE: String = "2.5.4.8"
    public static let STREET: String = "2.5.4.9"
    public static let ORGANIZATION: String = "2.5.4.10"
    public static let ORG_UNIT: String = "2.5.4.11"
    public static let SURNAME: String = "2.5.4.4"
    public static let GIVEN_NAME: String = "2.5.4.42"
    public static let PSEUDONYM: String = "2.5.4.65"
    public static let ORG_IDENTIFIER: String = "2.5.4.97"
}

public class DistinguishedName {
    public let attributes: HashMap<String, String>

    public init(attributes: HashMap<String, String>) {
        this.attributes = attributes
    }

    public func attr(oid: String): ?String {
        this.attributes.get(oid)
    }

    public func commonName(): ?String {
        this.attr(X500OIDs.COMMON_NAME)
    }

    public func serialNumber(): ?String {
        this.attr(X500OIDs.SERIAL_NUMBER)
    }

    public func country(): ?String {
        this.attr(X500OIDs.COUNTRY)
    }

    public func locality(): ?String {
        this.attr(X500OIDs.LOCALITY)
    }

    public func state(): ?String {
        this.attr(X500OIDs.STATE)
    }

    public func street(): ?String {
        this.attr(X500OIDs.STREET)
    }

    public func organization(): ?String {
        this.attr(X500OIDs.ORGANIZATION)
    }

    public func organizationUnit(): ?String {
        this.attr(X500OIDs.ORG_UNIT)
    }

    public func surname(): ?String {
        this.attr(X500OIDs.SURNAME)
    }

    public func givenName(): ?String {
        this.attr(X500OIDs.GIVEN_NAME)
    }

    public func pseudonym(): ?String {
        this.attr(X500OIDs.PSEUDONYM)
    }

    public func organizationIdentifier(): ?String {
        this.attr(X500OIDs.ORG_IDENTIFIER)
    }

    public func hasAttribute(oid: String): Bool {
        this.attributes.contains(oid)
    }
}

public class SerialNumber {
    public let value: Array<UInt8>

    public init(value: Array<UInt8>) {
        if (value.size == 0) {
            throw IllegalArgumentException("Serial number must not be empty")
        }
        let msb = Int64(value[0])
        if ((msb & 0x80) != 0) {
            throw IllegalArgumentException("Serial number must be positive (MSB must be 0)")
        }
        this.value = value
    }
}

public class Version {
    public let value: Int64

    public init(value: Int64) {
        if (value < 0) {
            throw IllegalArgumentException("Version must be non-negative")
        }
        this.value = value
    }

    public func versionName(): String {
        if (this.value == 0) {
            "v1"
        } else if (this.value == 1) {
            "v2"
        } else if (this.value == 2) {
            "v3"
        } else {
            "v${this.value + 1}"
        }
    }

    public func isV3(): Bool {
        this.value == 2
    }
}

public class AlgorithmRequirement {
    public let algorithm: String
    public let minimumKeySize: Int64

    public init(algorithm: String, minimumKeySize: Int64) {
        this.algorithm = algorithm
        this.minimumKeySize = minimumKeySize
    }

    public static func rsa2048(): AlgorithmRequirement {
        AlgorithmRequirement("RSA", 2048)
    }

    public static func ec256(): AlgorithmRequirement {
        AlgorithmRequirement("EC", 256)
    }

    public static func ecdsa256(): AlgorithmRequirement {
        AlgorithmRequirement("ECDSA", 256)
    }
}

public class PublicKeyAlgorithmOptions {
    public let algorithmOptions: ArrayList<AlgorithmRequirement>

    public init(algorithmOptions: ArrayList<AlgorithmRequirement>) {
        this.algorithmOptions = algorithmOptions
    }

    public static func of(algorithmOptions: ArrayList<AlgorithmRequirement>): PublicKeyAlgorithmOptions {
        PublicKeyAlgorithmOptions(algorithmOptions)
    }
}

public class PublicKeyInfo {
    public let algorithm: String
    public let keySize: ?Int64
    public let parameters: ?Array<UInt8>

    public init(algorithm: String, keySize: ?Int64, parameters: ?Array<UInt8>) {
        this.algorithm = algorithm
        this.keySize = keySize
        this.parameters = parameters
    }

    public func isAlgorithm(algorithms: Array<String>): Bool {
        let upper = this.algorithm.toAsciiUpper()
        for (name in algorithms) {
            if (upper == name.toAsciiUpper()) {
                return true
            }
        }
        false
    }

    public func hasMinimumKeySize(minSize: Int64): Bool {
        match (this.keySize) {
            case Some(size) => size >= minSize
            case None => false
        }
    }
}

public enum SubjectAlternativeName {
    | Uri(String)
    | Email(String)
    | Telephone(String)
    | DNSName(String)
    | IPAddress(Array<UInt8>)
    | RegisteredId(String)
    | OtherName(String, String)
}

public class AuthorityKeyIdentifier {
    public let keyIdentifier: ?Array<UInt8>
    public let authorityCertIssuer: ?ArrayList<String>
    public let authorityCertSerialNumber: ?Array<UInt8>

    public init(
        keyIdentifier: ?Array<UInt8>,
        authorityCertIssuer: ?ArrayList<String>,
        authorityCertSerialNumber: ?Array<UInt8>
    ) {
        this.keyIdentifier = keyIdentifier
        this.authorityCertIssuer = authorityCertIssuer
        this.authorityCertSerialNumber = authorityCertSerialNumber
    }
}

public class CrlDistributionPoint {
    public let distributionPointUri: ?String
    public let crlIssuer: ?ArrayList<String>

    public init(distributionPointUri: ?String, crlIssuer: ?ArrayList<String>) {
        this.distributionPointUri = distributionPointUri
        this.crlIssuer = crlIssuer
    }
}

/// Interprets CertificateOp against a certificate using injected CertificateOperations.
public func interpretCertificateOp<CERT>(
    op: CertificateOp,
    certificate: CERT,
    operations: CertificateOperations<CERT>
): OpValue {
    match (op) {
        case CertificateOp.GetBasicConstraints =>
            OpValue.BasicConstraints(operations.getBasicConstraints(certificate))
        case CertificateOp.GetKeyUsage =>
            OpValue.KeyUsage(operations.getKeyUsage(certificate))
        case CertificateOp.GetValidity =>
            OpValue.Validity(operations.getValidityPeriod(certificate))
        case CertificateOp.GetPolicies =>
            OpValue.Policies(operations.getCertificatePolicies(certificate))
        case CertificateOp.CheckSelfSigned =>
            OpValue.Flag(operations.isSelfSigned(certificate))
        case CertificateOp.GetAia =>
            OpValue.Aia(operations.getAiaExtension(certificate))
        case CertificateOp.GetQcStatements(qcType) =>
            let all = operations.getQcStatements(certificate)
            let filtered = ArrayList<QCStatementInfo>()
            for (stmt in all) {
                if (stmt.semanticOid() == qcType) {
                    filtered.add(stmt)
                }
            }
            OpValue.QcStatements(filtered)
        case CertificateOp.GetSubject =>
            OpValue.Name(operations.getSubject(certificate))
        case CertificateOp.GetIssuer =>
            OpValue.Name(operations.getIssuer(certificate))
        case CertificateOp.GetSubjectAltNames =>
            OpValue.SubjectAltNames(operations.getSubjectAltNames(certificate))
        case CertificateOp.GetCrlDistributionPoints =>
            OpValue.CrlDistributionPoints(operations.getCrlDistributionPoints(certificate))
        case CertificateOp.GetAuthorityKeyIdentifier =>
            OpValue.AuthorityKeyId(operations.getAuthorityKeyIdentifier(certificate))
        case CertificateOp.GetSubjectKeyIdentifier =>
            OpValue.SubjectKeyId(operations.getSubjectKeyIdentifier(certificate))
        case CertificateOp.GetSerialNumber =>
            OpValue.Serial(operations.getSerialNumber(certificate))
        case CertificateOp.GetVersion =>
            OpValue.CertVersion(operations.getVersion(certificate))
        case CertificateOp.GetSubjectPublicKeyInfo =>
            OpValue.PublicKey(operations.getSubjectPublicKeyInfo(certificate))
        case CertificateOp.GetAllQcStatements =>
            OpValue.QcStatements(operations.getQcStatements(certificate))
        case CertificateOp.HasExtension(oid) =>
            OpValue.Flag(operations.hasExtension(certificate, oid))
        case CertificateOp.GetExtensionCriticality =>
            OpValue.Criticality(operations.getExtensionCriticality(certificate))
        case CertificateOp.CombineTwo(first, second) =>
            OpValue.Pair(
                interpretCertificateOp(first, certificate, operations),
                interpretCertificateOp(second, certificate, operations)
            )
        case CertificateOp.CombineThree(first, second, third) =>
            OpValue.Triple(
                interpretCertificateOp(first, certificate, operations),
                interpretCertificateOp(second, certificate, operations),
                interpretCertificateOp(third, certificate, operations)
            )
    }
}
