package ohos_app_cangjie_eudi_cjetsi_1196x2.pkix_bridge

import std.collection.ArrayList
import std.time.DateTime
import stdx.crypto.common.DerBlob
import stdx.crypto.x509.{X509Certificate, VerifyOption, X509Exception}

public enum PkixChainValidation {
    | Trusted(Array<Byte>)
    | Failed(PkixBridgeError)
}

public class PKIXValidator {
    private let configuration: PKIXConfiguration

    public init(configuration!: PKIXConfiguration) {
        this.configuration = configuration
    }

    public init() {
        this.configuration = PKIXConfiguration()
    }

    public func isRevocationEnabled(): Bool {
        this.configuration.isRevocationEnabled
    }

    /// Validates a certificate chain with the supplied trust anchors only (no system roots).
    /// On success returns the original DER of the matched trust anchor.
    /// `validationTime` maps to `VerifyOption.time` (JVM `PKIXParameters.date`); default None
    /// keeps the stdx `DateTime.now()` default so existing 3-arg callers still compile.
    public func validateCertificateChain(
        leafCertificate!: Array<Byte>,
        intermediateCertificates!: Array<Array<Byte>>,
        trustAnchors!: Array<Array<Byte>>,
        validationTime!: ?DateTime = None
    ): PkixChainValidation {
        if (trustAnchors.size == 0) {
            return Failed(PkixBridgeError.invalidCertificate(reason: "Trust anchors must not be empty"))
        }

        let leaf = match (decodeStdx(leafCertificate, "leaf")) {
            case Some(cert) => cert
            case None => return Failed(PkixBridgeError.invalidCertificate(reason: "Failed to decode DER for leaf"))
        }

        let intermediates = ArrayList<X509Certificate>()
        var i: Int64 = 0
        while (i < intermediateCertificates.size) {
            match (decodeStdx(intermediateCertificates[i], "intermediate[${i}]")) {
                case Some(cert) => intermediates.add(cert)
                case None => return Failed(PkixBridgeError.invalidCertificate(reason: "Failed to decode DER for intermediate[${i}]"))
            }
            i = i + 1
        }

        let anchors = ArrayList<X509Certificate>()
        i = 0
        while (i < trustAnchors.size) {
            match (decodeStdx(trustAnchors[i], "trustAnchor[${i}]")) {
                case Some(cert) => anchors.add(cert)
                case None => return Failed(PkixBridgeError.invalidCertificate(reason: "Failed to decode DER for trustAnchor[${i}]"))
            }
            i = i + 1
        }

        if (this.configuration.isRevocationEnabled) {
            return Failed(PkixBridgeError.notImplemented())
        }

        var opt = VerifyOption()
        opt.dnsName = ""
        opt.roots = anchors.toArray()
        opt.intermediates = intermediates.toArray()
        match (validationTime) {
            case Some(t) => opt.time = t
            case None => ()
        }

        let trusted = try {
            leaf.verify(opt)
        } catch (e: X509Exception) {
            return Failed(PkixBridgeError.trustEvaluationFailed(reason: e.message))
        } catch (e: Exception) {
            return Failed(PkixBridgeError.trustEvaluationFailed(reason: e.message))
        }

        if (!trusted) {
            return Failed(PkixBridgeError.trustEvaluationFailed(reason: ""))
        }

        match (matchedAnchorDer(leaf, intermediates.toArray(), anchors.toArray(), trustAnchors, validationTime)) {
            case Some(der) => Trusted(der)
            case None => Failed(PkixBridgeError.noTrustAnchorMatched())
        }
    }

    static func decodeStdx(der: Array<Byte>, _: String): ?X509Certificate {
        try {
            X509Certificate.decodeFromDer(DerBlob(der))
        } catch (e: Exception) {
            None
        }
    }

    static func matchedAnchorDer(
        leaf: X509Certificate,
        intermediates: Array<X509Certificate>,
        anchors: Array<X509Certificate>,
        originalDers: Array<Array<Byte>>,
        validationTime: ?DateTime
    ): ?Array<Byte> {
        var i: Int64 = 0
        while (i < anchors.size) {
            var one = VerifyOption()
            one.dnsName = ""
            one.roots = [anchors[i]]
            one.intermediates = intermediates
            match (validationTime) {
                case Some(t) => one.time = t
                case None => ()
            }
            let ok = try {
                leaf.verify(one)
            } catch (e: Exception) {
                false
            }
            if (ok) {
                return originalDers[i]
            }
            i = i + 1
        }
        None
    }
}
