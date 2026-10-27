package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_platform

import std.collection.*
import std.time.DateTime
import stdx.crypto.common.DerBlob
import stdx.crypto.x509.{X509Certificate, X509Exception}
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.pkix_bridge.{PKIXValidator, PKIXConfiguration, PkixChainValidation, PkixBridgeError}

/// JVM/OHOS PKIX path-validation actual. CERT/CHAIN are DER bytes.
/// Delegates path building to pkix_bridge.PKIXValidator (stdx.crypto.x509).
public class ValidateCertificateChainUsingPKIXJvm <:
    ValidateCertificateChainUsingPKIX<ArrayList<Array<Byte>>, Array<Byte>> {
    private let platform: ConsultationPlatform
    private let validator: PKIXValidator
    private let validationTime: ?DateTime

    public init(
        configuration!: PKIXConfiguration,
        validationTime!: ?DateTime,
        platform!: ConsultationPlatform
    ) {
        this.platform = platform
        this.validator = PKIXValidator(configuration: configuration)
        this.validationTime = validationTime
    }

    public init(configuration!: PKIXConfiguration) {
        this.platform = consultationPlatform()
        this.validator = PKIXValidator(configuration: configuration)
        let noneTime: ?DateTime = None
        this.validationTime = noneTime
    }

    public init() {
        this.platform = consultationPlatform()
        this.validator = PKIXValidator(configuration: JvmSecurity.defaultPkixConfiguration())
        let noneTime: ?DateTime = None
        this.validationTime = noneTime
    }

    public static func defaultInstance(): ValidateCertificateChainUsingPKIXJvm {
        ValidateCertificateChainUsingPKIXJvm()
    }

    public func invoke(
        chain: ArrayList<Array<Byte>>,
        trustAnchors: NonEmptyList<Array<Byte>>
    ): CertificationChainValidation<Array<Byte>> {
        this.platform.runIo({ => this.evaluate(chain, trustAnchors) })
    }

    private func evaluate(
        chain: ArrayList<Array<Byte>>,
        trustAnchors: NonEmptyList<Array<Byte>>
    ): CertificationChainValidation<Array<Byte>> {
        if (chain.size == 0) {
            throw IllegalArgumentException("Chain must not be empty")
        }
        let leaf = chain[0]
        match (tryDecodeStdx(leaf)) {
            case None =>
                return CertificationChainValidation<Array<Byte>>.NotTrusted("Failed to decode DER for leaf")
            case Some(cert) =>
                match (this.validationTime) {
                    case None => ()
                    case Some(at) =>
                        if (at < cert.notBefore || at > cert.notAfter) {
                            return CertificationChainValidation<Array<Byte>>.NotTrusted(
                                "Certificate not valid at requested time"
                            )
                        }
                }
        }

        let intermediates = ArrayList<Array<Byte>>()
        var i: Int64 = 1
        while (i < chain.size) {
            match (tryDecodeStdx(chain[i])) {
                case None =>
                    return CertificationChainValidation<Array<Byte>>.NotTrusted(
                        "Failed to decode DER for intermediate[${i - 1}]"
                    )
                case Some(_) => intermediates.add(chain[i])
            }
            i = i + 1
        }

        var j: Int64 = 0
        while (j < trustAnchors.size()) {
            match (tryDecodeStdx(trustAnchors.get(j))) {
                case None =>
                    return CertificationChainValidation<Array<Byte>>.NotTrusted(
                        "Failed to decode DER for trustAnchor[${j}]"
                    )
                case Some(_) => ()
            }
            j = j + 1
        }

        let outcome = try {
            this.validator.validateCertificateChain(
                leafCertificate: leaf,
                intermediateCertificates: intermediates.toArray(),
                trustAnchors: trustAnchors.items.toArray()
            )
        } catch (e: Exception) {
            return CertificationChainValidation<Array<Byte>>.NotTrusted(e.message)
        }

        match (outcome) {
            case PkixChainValidation.Trusted(matchedDer) =>
                match (findMatchingAnchor(trustAnchors, matchedDer)) {
                    case Some(anchor) => CertificationChainValidation<Array<Byte>>.Trusted(anchor)
                    case None =>
                        CertificationChainValidation<Array<Byte>>.NotTrusted(
                            "Validated chain matched no provided trust anchor"
                        )
                }
            case PkixChainValidation.Failed(err) =>
                CertificationChainValidation<Array<Byte>>.NotTrusted(pkixFailureMessage(err))
        }
    }
}

func tryDecodeStdx(der: Array<Byte>): ?X509Certificate {
    try {
        X509Certificate.decodeFromDer(DerBlob(der))
    } catch (e: X509Exception) {
        None
    } catch (e: Exception) {
        None
    }
}

func findMatchingAnchor(anchors: NonEmptyList<Array<Byte>>, der: Array<Byte>): ?Array<Byte> {
    var i: Int64 = 0
    while (i < anchors.size()) {
        let candidate = anchors.get(i)
        if (derBytesEqual(candidate, der)) {
            return candidate
        }
        i = i + 1
    }
    None
}

func pkixFailureMessage(err: PkixBridgeError): String {
    err.message
}
