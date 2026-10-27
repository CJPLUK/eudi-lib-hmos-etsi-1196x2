package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

/// Platform configuration for consultation I/O scheduling.
/// JVM/OHOS actuals belong to consultation_platform; this package only defines
/// the injection surface and a current-thread default used by the interpreter.
public interface ConsultationPlatform {
    func runIo<T>(work: () -> T): T
}

/// Runs work on the calling thread. Downstream platform features may inject
/// a HarmonyOS worker-thread implementation when constructing validators.
public class DirectConsultationPlatform <: ConsultationPlatform {
    public func runIo<T>(work: () -> T): T {
        work()
    }
}

public var installedConsultationPlatform: ConsultationPlatform = DirectConsultationPlatform()

public func consultationPlatform(): ConsultationPlatform {
    installedConsultationPlatform
}

public func installConsultationPlatform(platform: ConsultationPlatform): Unit {
    installedConsultationPlatform = platform
}
