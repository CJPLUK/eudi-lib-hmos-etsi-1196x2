package ohos_app_cangjie_eudi_cjetsi_1196x2.pkix_bridge

/// PKIX bridge failure, matching the iOS PKIXBridgeError codes for consultation_platform.
public class PkixBridgeError <: Exception {
    public let code: Int64

    public init(code!: Int64, message!: String) {
        super(message)
        this.code = code
    }

    public static func notImplemented(): PkixBridgeError {
        PkixBridgeError(code: -1, message: "Operation not implemented")
    }

    public static func invalidCertificate(reason!: String): PkixBridgeError {
        PkixBridgeError(code: 1, message: "Invalid certificate: ${reason}")
    }

    public static func emptyChain(): PkixBridgeError {
        PkixBridgeError(code: 2, message: "Certificate chain is empty")
    }

    public static func noTrustAnchorMatched(): PkixBridgeError {
        PkixBridgeError(code: 3, message: "Validated chain did not match any provided trust anchor")
    }

    public static func trustEvaluationFailed(reason!: String): PkixBridgeError {
        if (reason.size == 0) {
            return PkixBridgeError(code: 4, message: "Trust evaluation failed")
        }
        PkixBridgeError(code: 4, message: "Trust evaluation failed: ${reason}")
    }

    public static func asn1ParseFailure(reason!: String): PkixBridgeError {
        PkixBridgeError(code: 5, message: "ASN.1 parse failure: ${reason}")
    }
}
