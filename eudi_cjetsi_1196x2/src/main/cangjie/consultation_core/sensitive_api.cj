package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

/// Marker for APIs that can bypass security checks if misconfigured.
/// Kotlin source uses @RequiresOptIn(SensitiveApi); Cangjie callers should treat
/// `or`, `recoverWith`, and GetTrustAnchorsWithAlternative as sensitive.
public class SensitiveApi {
    public static let message: String =
        "This API is sensitive and can potentially bypass security checks if misconfigured."
}
