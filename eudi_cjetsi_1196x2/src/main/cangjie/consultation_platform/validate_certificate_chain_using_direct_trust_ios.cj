package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_platform

import std.collection.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*

/// iOS-named direct-trust validator. On OHOS this reuses the JVM identity actual
/// (subject + serial over DER), not NSData/SecTrust.
public let ValidateCertificateChainUsingDirectTrustIos:
    ValidateCertificateChainUsingDirectTrust<ArrayList<Array<Byte>>, Array<Byte>, X509CertificateIdentify> =
    ValidateCertificateChainUsingDirectTrustJvm
