package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_platform

import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*

/// iOS-named profile validator factory. On OHOS this injects CertificateOperationsIos,
/// which delegates to the JVM/stdx actual.
public func certificateProfileValidatorIos(
    operations: CertificateOperations<Array<Byte>>
): CertificateProfileValidator<Array<Byte>> {
    DefaultCertificateProfileValidator<Array<Byte>>.fromOperations(operations)
}

public func certificateProfileValidatorIos(): CertificateProfileValidator<Array<Byte>> {
    DefaultCertificateProfileValidator<Array<Byte>>.fromOperations(CertificateOperationsIos())
}
