package ohos_app_cangjie_eudi_cjetsi_1196x2.etsi_trust

/**
 * iOS `TrustPolicy` outcome for one `validateCertTrustPath` result.
 *
 * Trusted → Pass. Untrusted + Warning → Warn (log, do not reject).
 * Untrusted + Enforce → Fail (reject).
 */
public enum TrustPolicyDecision {
    | Pass
    | Warn(String)
    | Fail(String)
}

public func decideTrustPolicy(
    trusted: Bool,
    failureReason: ?String,
    policy: TrustPolicy,
    untrustedMessage: String
): TrustPolicyDecision {
    if (trusted) {
        return TrustPolicyDecision.Pass
    }
    let msg = match (failureReason) {
        case Some(reason) => "${untrustedMessage}: ${reason}"
        case None => untrustedMessage
    }
    match (policy) {
        case TrustPolicy.Warning => TrustPolicyDecision.Warn(msg)
        case TrustPolicy.Enforce => TrustPolicyDecision.Fail(msg)
    }
}
