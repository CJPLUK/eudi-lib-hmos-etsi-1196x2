package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_platform

import std.collection.*
import stdx.crypto.common.DerBlob
import stdx.crypto.x509.{X509Certificate, PublicKeyAlgorithm, X509Exception}
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.pkix_bridge.{PKIXCertificateInspector, SubjectAltName, QcStatement}

/// JVM/OHOS actual of CertificateOperations over DER-encoded certificates.
/// Field extraction uses stdx.crypto.x509 for decode/validity/SPKI and
/// PKIXCertificateInspector for RFC 5280 / ETSI extensions.
public class CertificateOperationsJvm <: CertificateOperations<Array<Byte>> {
    private let inspector: PKIXCertificateInspector

    public init(inspector: PKIXCertificateInspector) {
        this.inspector = inspector
    }

    public init() {
        this.inspector = PKIXCertificateInspector()
    }

    public func getBasicConstraints(certificate: Array<Byte>): BasicConstraintsInfo {
        match (this.inspector.getBasicConstraints(certificate)) {
            case None => BasicConstraintsInfo(false, None)
            case Some(info) => BasicConstraintsInfo(info.isCa, info.pathLenConstraint)
        }
    }

    public func getQcStatements(certificate: Array<Byte>): ArrayList<QCStatementInfo> {
        let out = ArrayList<QCStatementInfo>()
        match (this.inspector.getQcStatements(certificate)) {
            case None => out
            case Some(raw) =>
                for (stmt in raw) {
                    match (stmt) {
                        case QcStatement.QcType(typeIdentifier) =>
                            out.add(QCStatementInfo.QcType(typeIdentifier))
                        case QcStatement.OtherQc(statementId) =>
                            out.add(QCStatementInfo.OtherQcStatement(statementId))
                    }
                }
                out
        }
    }

    public func getKeyUsage(certificate: Array<Byte>): ?KeyUsageBits {
        match (this.inspector.getKeyUsage(certificate)) {
            case None => None
            case Some(bits) =>
                Some(KeyUsageBits(
                    digitalSignature: bits.digitalSignature,
                    nonRepudiation: bits.nonRepudiation,
                    keyEncipherment: bits.keyEncipherment,
                    dataEncipherment: bits.dataEncipherment,
                    keyAgreement: bits.keyAgreement,
                    keyCertSign: bits.keyCertSign,
                    crlSign: bits.crlSign,
                    encipherOnly: bits.encipherOnly,
                    decipherOnly: bits.decipherOnly
                ))
        }
    }

    public func getValidityPeriod(certificate: Array<Byte>): ValidityPeriod {
        let cert = X509Certificate.decodeFromDer(DerBlob(certificate))
        ValidityPeriod(cert.notBefore, cert.notAfter)
    }

    public func getCertificatePolicies(certificate: Array<Byte>): ?ArrayList<String> {
        match (this.inspector.getCertificatePolicies(certificate)) {
            case None => None
            case Some(oids) => Some(stringsToList(oids))
        }
    }

    public func isSelfSigned(certificate: Array<Byte>): Bool {
        this.inspector.isSelfSigned(certificate)
    }

    public func getAiaExtension(certificate: Array<Byte>): ?AuthorityInformationAccess {
        match (this.inspector.getAuthorityInfoAccess(certificate)) {
            case None => None
            case Some(aia) => Some(AuthorityInformationAccess(aia.caIssuersUri, aia.ocspUri))
        }
    }

    public func getSubject(certificate: Array<Byte>): ?DistinguishedName {
        match (this.inspector.getSubject(certificate)) {
            case None => None
            case Some(attrs) => Some(DistinguishedName(attrs))
        }
    }

    public func getIssuer(certificate: Array<Byte>): ?DistinguishedName {
        match (this.inspector.getIssuer(certificate)) {
            case None => None
            case Some(attrs) => Some(DistinguishedName(attrs))
        }
    }

    public func getSubjectAltNames(certificate: Array<Byte>): ?ArrayList<SubjectAlternativeName> {
        match (this.inspector.getSubjectAltNames(certificate)) {
            case None => None
            case Some(names) =>
                let out = ArrayList<SubjectAlternativeName>()
                for (name in names) {
                    match (name) {
                        case SubjectAltName.DnsName(dns) =>
                            out.add(SubjectAlternativeName.DNSName(dns))
                        case SubjectAltName.Rfc822Name(email) =>
                            out.add(SubjectAlternativeName.Email(email))
                        case SubjectAltName.UriName(uri) =>
                            out.add(SubjectAlternativeName.Uri(uri))
                        case SubjectAltName.IpAddress(addr) =>
                            out.add(SubjectAlternativeName.IPAddress(toUInt8Array(addr)))
                        case SubjectAltName.RegisteredId(oid) =>
                            out.add(SubjectAlternativeName.RegisteredId(oid))
                        case SubjectAltName.OtherName(value) =>
                            out.add(SubjectAlternativeName.OtherName("otherName", value))
                    }
                }
                Some(out)
        }
    }

    public func getExtensionCriticality(certificate: Array<Byte>): HashMap<String, Bool> {
        match (this.inspector.getExtensionCriticality(certificate)) {
            case None => HashMap<String, Bool>()
            case Some(map) => map
        }
    }

    public func getCrlDistributionPoints(certificate: Array<Byte>): ArrayList<CrlDistributionPoint> {
        let out = ArrayList<CrlDistributionPoint>()
        match (this.inspector.getCrlDistributionPoints(certificate)) {
            case None => out
            case Some(uris) =>
                for (uri in uris) {
                    let noneIssuer: ?ArrayList<String> = None
                    out.add(CrlDistributionPoint(uri, noneIssuer))
                }
                out
        }
    }

    public func getAuthorityKeyIdentifier(certificate: Array<Byte>): ?AuthorityKeyIdentifier {
        match (this.inspector.getAuthorityKeyIdentifier(certificate)) {
            case None => None
            case Some(aki) =>
                let keyId: ?Array<UInt8> = match (aki.keyIdentifier) {
                    case None => None
                    case Some(bytes) => Some(toUInt8Array(bytes))
                }
                let serial: ?Array<UInt8> = match (aki.authorityCertSerialNumber) {
                    case None => None
                    case Some(bytes) => Some(toUInt8Array(bytes))
                }
                let noneIssuer: ?ArrayList<String> = None
                Some(AuthorityKeyIdentifier(keyId, noneIssuer, serial))
        }
    }

    public func getSubjectKeyIdentifier(certificate: Array<Byte>): ?Array<UInt8> {
        match (this.inspector.getSubjectKeyIdentifier(certificate)) {
            case None => None
            case Some(bytes) => Some(toUInt8Array(bytes))
        }
    }

    public func getSerialNumber(certificate: Array<Byte>): SerialNumber {
        match (this.inspector.getSerialNumber(certificate)) {
            case None => throw IllegalArgumentException("Certificate is missing serial number")
            case Some(bytes) => SerialNumber(positiveIntegerBytes(bytes))
        }
    }

    public func getVersion(certificate: Array<Byte>): Version {
        Version(this.inspector.getVersion(certificate))
    }

    public func getSubjectPublicKeyInfo(certificate: Array<Byte>): PublicKeyInfo {
        match (this.inspector.getPublicKeyInfo(certificate)) {
            case Some(info) =>
                let noneParams: ?Array<UInt8> = None
                PublicKeyInfo(info.algorithm, info.keySize, noneParams)
            case None =>
                try {
                    let cert = X509Certificate.decodeFromDer(DerBlob(certificate))
                    let algorithm = match (cert.publicKeyAlgorithm) {
                        case PublicKeyAlgorithm.RSA => "RSA"
                        case PublicKeyAlgorithm.ECDSA => "EC"
                        case PublicKeyAlgorithm.DSA => "DSA"
                        case PublicKeyAlgorithm.UnknownPublicKeyAlgorithm => "UNKNOWN"
                    }
                    let noneSize: ?Int64 = None
                    let noneParams: ?Array<UInt8> = None
                    PublicKeyInfo(algorithm, noneSize, noneParams)
                } catch (e: X509Exception) {
                    let noneSize: ?Int64 = None
                    let noneParams: ?Array<UInt8> = None
                    PublicKeyInfo("UNKNOWN", noneSize, noneParams)
                } catch (e: Exception) {
                    let noneSize: ?Int64 = None
                    let noneParams: ?Array<UInt8> = None
                    PublicKeyInfo("UNKNOWN", noneSize, noneParams)
                }
        }
    }

    public func hasExtension(certificate: Array<Byte>, oid: String): Bool {
        this.inspector.hasExtension(certificate, oid)
    }
}
