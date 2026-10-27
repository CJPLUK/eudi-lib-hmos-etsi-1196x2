package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_platform

import std.time.DateTime
import ohos_app_cangjie_eudi_cjetsi_1196x2.pkix_bridge.PKIXConfiguration

/// OHOS stand-in for JVM CertificateFactory / CertPathValidator providers.
/// Path validation is implemented with stdx.crypto.x509 via PKIXValidator;
/// these helpers only carry PKIXParameters-equivalent switches.
public class JvmSecurity {
    /// JVM default PKIX customization enables revocation (RFC 5280 §6.3).
    /// stdx has no OCSP/CRL switch, so PKIXValidator fail-closes when this is true (D-100).
    public static func defaultPkixConfiguration(): PKIXConfiguration {
        PKIXConfiguration(isRevocationEnabled: true)
    }

    public static func withRevocationEnabled(enabled: Bool): PKIXConfiguration {
        PKIXConfiguration(isRevocationEnabled: enabled)
    }

    /// Validation instant for VerifyOption.time (JVM PKIXParameters.date).
    public static func withValidationDate(at: DateTime): DateTime {
        at
    }
}
