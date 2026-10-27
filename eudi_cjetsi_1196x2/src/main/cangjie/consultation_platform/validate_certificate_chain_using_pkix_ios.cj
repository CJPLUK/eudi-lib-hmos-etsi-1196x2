package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_platform

import std.collection.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.pkix_bridge.PKIXConfiguration

/// iOS-named PKIX validator. On OHOS this wraps ValidateCertificateChainUsingPKIXJvm
/// (stdx.crypto.x509 / PKIXValidator), not Security.framework SecTrust.
public class ValidateCertificateChainUsingPKIXIos <:
    ValidateCertificateChainUsingPKIX<ArrayList<Array<Byte>>, Array<Byte>> {
    private let inner: ValidateCertificateChainUsingPKIXJvm

    public init(configuration!: PKIXConfiguration) {
        this.inner = ValidateCertificateChainUsingPKIXJvm(configuration: configuration)
    }

    public init() {
        this.inner = ValidateCertificateChainUsingPKIXJvm()
    }

    public func invoke(
        chain: ArrayList<Array<Byte>>,
        trustAnchors: NonEmptyList<Array<Byte>>
    ): CertificationChainValidation<Array<Byte>> {
        this.inner.invoke(chain, trustAnchors)
    }
}
