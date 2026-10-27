package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_platform

import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*

/// iOS-named ConsultationPlatform. On OHOS this wraps the JVM/OHOS actual
/// (no Dispatchers.Default / SecTrust).
public class ConsultationPlatformIos <: ConsultationPlatform {
    private let inner: ConsultationPlatformJvm

    public init() {
        this.inner = ConsultationPlatformJvm()
    }

    public func runIo<T>(work: () -> T): T {
        this.inner.runIo(work)
    }
}

public func consultationPlatformIos(): ConsultationPlatform {
    ConsultationPlatformIos()
}
