package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_platform

import std.collection.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.pkix_bridge.PKIXCertificateInspector

/// iOS-named CertificateOperations. On OHOS this is a thin wrapper around
/// CertificateOperationsJvm (stdx.crypto.x509), not a SecTrust port.
public class CertificateOperationsIos <: CertificateOperations<Array<Byte>> {
    private let inner: CertificateOperationsJvm

    public init(inspector: PKIXCertificateInspector) {
        this.inner = CertificateOperationsJvm(inspector)
    }

    public init() {
        this.inner = CertificateOperationsJvm()
    }

    public func getBasicConstraints(certificate: Array<Byte>): BasicConstraintsInfo {
        this.inner.getBasicConstraints(certificate)
    }

    public func getQcStatements(certificate: Array<Byte>): ArrayList<QCStatementInfo> {
        this.inner.getQcStatements(certificate)
    }

    public func getKeyUsage(certificate: Array<Byte>): ?KeyUsageBits {
        this.inner.getKeyUsage(certificate)
    }

    public func getValidityPeriod(certificate: Array<Byte>): ValidityPeriod {
        this.inner.getValidityPeriod(certificate)
    }

    public func getCertificatePolicies(certificate: Array<Byte>): ?ArrayList<String> {
        this.inner.getCertificatePolicies(certificate)
    }

    public func isSelfSigned(certificate: Array<Byte>): Bool {
        this.inner.isSelfSigned(certificate)
    }

    public func getAiaExtension(certificate: Array<Byte>): ?AuthorityInformationAccess {
        this.inner.getAiaExtension(certificate)
    }

    public func getSubject(certificate: Array<Byte>): ?DistinguishedName {
        this.inner.getSubject(certificate)
    }

    public func getIssuer(certificate: Array<Byte>): ?DistinguishedName {
        this.inner.getIssuer(certificate)
    }

    public func getSubjectAltNames(certificate: Array<Byte>): ?ArrayList<SubjectAlternativeName> {
        this.inner.getSubjectAltNames(certificate)
    }

    public func getExtensionCriticality(certificate: Array<Byte>): HashMap<String, Bool> {
        this.inner.getExtensionCriticality(certificate)
    }

    public func getCrlDistributionPoints(certificate: Array<Byte>): ArrayList<CrlDistributionPoint> {
        this.inner.getCrlDistributionPoints(certificate)
    }

    public func getAuthorityKeyIdentifier(certificate: Array<Byte>): ?AuthorityKeyIdentifier {
        this.inner.getAuthorityKeyIdentifier(certificate)
    }

    public func getSubjectKeyIdentifier(certificate: Array<Byte>): ?Array<UInt8> {
        this.inner.getSubjectKeyIdentifier(certificate)
    }

    public func getSerialNumber(certificate: Array<Byte>): SerialNumber {
        this.inner.getSerialNumber(certificate)
    }

    public func getVersion(certificate: Array<Byte>): Version {
        this.inner.getVersion(certificate)
    }

    public func getSubjectPublicKeyInfo(certificate: Array<Byte>): PublicKeyInfo {
        this.inner.getSubjectPublicKeyInfo(certificate)
    }

    public func hasExtension(certificate: Array<Byte>, oid: String): Bool {
        this.inner.hasExtension(certificate, oid)
    }
}
