package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation

/// Outcome of verifying a LoTE JWT JWS signature.
/// Cryptographic actuals belong to lote_consultation_platform (stdx.crypto).
public enum VerifyJwtSignatureOutcome {
    | Verified(String)
    | NotVerified(Option<Exception>)
}

/// Verifies the JWS signature of a LoTE document.
public interface VerifyJwtSignature {
    func invoke(jwt: String): VerifyJwtSignatureOutcome
}

public class LambdaVerifyJwtSignature <: VerifyJwtSignature {
    private let fn: (String) -> VerifyJwtSignatureOutcome

    public init(fn: (String) -> VerifyJwtSignatureOutcome) {
        this.fn = fn
    }

    public func invoke(jwt: String): VerifyJwtSignatureOutcome {
        this.fn(jwt)
    }
}
