package ohos_app_cangjie_eudi_cjetsi_1196x2.etsi_trust

/**
 * iOS `CertificateTrustValidator`. `docType` lives on the implementing class
 * (`EtsiTrustManager.docType`) because Cangjie interfaces cannot carry stored
 * mutable properties.
 */
public interface CertificateTrustValidator {
    func createCertTrustPath(chain: Array<Array<UInt8>>): ?Array<Array<UInt8>>
    func validateCertTrustPath(chain: Array<Array<UInt8>>): (Bool, ?String)
}

/** Result of `validateCertTrustPath`. */
public class CertTrustPathResult {
    public let isTrusted: Bool
    public let failureReason: ?String

    public init(isTrusted: Bool, failureReason: ?String) {
        this.isTrusted = isTrusted
        this.failureReason = failureReason
    }
}
