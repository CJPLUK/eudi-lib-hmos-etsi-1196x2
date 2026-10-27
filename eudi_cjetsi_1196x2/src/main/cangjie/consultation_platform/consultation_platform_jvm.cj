package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_platform

import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*

/// JVM/OHOS ConsultationPlatform. HarmonyOS has no Dispatchers.IO; work runs on the
/// calling thread, matching DirectConsultationPlatform. Callers may install this
/// instance via installConsultationPlatform.
public class ConsultationPlatformJvm <: ConsultationPlatform {
    public init() {}

    public func runIo<T>(work: () -> T): T {
        work()
    }
}

public func consultationPlatformJvm(): ConsultationPlatform {
    ConsultationPlatformJvm()
}

public func certificateProfileValidatorJvm(
    operations: CertificateOperations<Array<Byte>>
): CertificateProfileValidator<Array<Byte>> {
    DefaultCertificateProfileValidator<Array<Byte>>.fromOperations(operations)
}

public func certificateProfileValidatorJvm(): CertificateProfileValidator<Array<Byte>> {
    DefaultCertificateProfileValidator<Array<Byte>>.fromOperations(CertificateOperationsJvm())
}
