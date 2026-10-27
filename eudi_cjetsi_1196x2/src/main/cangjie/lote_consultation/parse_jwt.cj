package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation

import stdx.encoding.base64.*
import stdx.encoding.json.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model.*

public enum ParseJwtOutcome {
    | Parsed(JsonObject, ListOfTrustedEntitiesClaims)
    | ParseFailed(Option<Exception>)
}

/// Parses a LoTE JWT in compact JWS form, flattened JWS JSON, or general JWS JSON.
public class ParseJwt {
    public func invoke(jwt: String): ParseJwtOutcome {
        let compact = parseCompactJwt(jwt)
        match (compact) {
            case ParseJwtOutcome.Parsed(_, _) => compact
            case ParseJwtOutcome.ParseFailed(firstCause) =>
                let jsonForm = parseJwsJson(jwt)
                match (jsonForm) {
                    case ParseJwtOutcome.Parsed(_, _) => jsonForm
                    case ParseJwtOutcome.ParseFailed(secondCause) =>
                        ParseJwtOutcome.ParseFailed(Some(combinedParseError(firstCause, secondCause)))
                }
        }
    }
}

func combinedParseError(first: Option<Exception>, second: Option<Exception>): IllegalArgumentException {
    var msg = "Failed to parse JWT to the expected payload"
    match (first) {
        case Some(e) => msg = msg + "; compact: ${e}"
        case None => ()
    }
    match (second) {
        case Some(e) => msg = msg + "; jws-json: ${e}"
        case None => ()
    }
    IllegalArgumentException(msg)
}

func parseCompactJwt(jwt: String): ParseJwtOutcome {
    try {
        let trimmed = jwt.trimAscii()
        if (trimmed.isEmpty()) {
            throw IllegalArgumentException("Input must not be empty")
        }
        let parts = trimmed.split(".")
        if (parts.size != 3) {
            throw IllegalArgumentException("Input must be a JWS in compact form")
        }
        let header = decodeJwtJsonObject(parts[0])
        let payload = decodeJwtPayload(parts[1])
        ParseJwtOutcome.Parsed(header, payload)
    } catch (e: Exception) {
        ParseJwtOutcome.ParseFailed(Some(e))
    }
}

func parseJwsJson(jwt: String): ParseJwtOutcome {
    try {
        let root = JsonValue.fromStr(jwt.trimAscii()).asObject()
        let payloadB64 = JsonFields.requireString(root, "payload")
        match (JsonFields.optionalString(root, "protected")) {
            case Some(prot) =>
                let header = decodeJwtJsonObject(prot)
                let payload = decodeJwtPayload(payloadB64)
                return ParseJwtOutcome.Parsed(header, payload)
            case None => ()
        }
        let signatures = JsonFields.requireArray(root, "signatures")
        if (signatures.size() == 0) {
            throw IllegalArgumentException("Signatures must not be empty")
        }
        let firstSig = signatures[0].asObject()
        let protectedB64 = JsonFields.requireString(firstSig, "protected")
        let header = decodeJwtJsonObject(protectedB64)
        let payload = decodeJwtPayload(payloadB64)
        ParseJwtOutcome.Parsed(header, payload)
    } catch (e: Exception) {
        ParseJwtOutcome.ParseFailed(Some(e))
    }
}

func decodeJwtJsonObject(base64Url: String): JsonObject {
    JsonValue.fromStr(decodeBase64UrlToUtf8(base64Url)).asObject()
}

func decodeJwtPayload(base64Url: String): ListOfTrustedEntitiesClaims {
    ListOfTrustedEntitiesClaims.fromJson(decodeBase64UrlToUtf8(base64Url))
}

/// stdx.encoding.base64 exposes standard Base64 only; JWT uses base64url without padding.
func decodeBase64UrlToUtf8(encoded: String): String {
    var s = encoded.replace("-", "+").replace("_", "/")
    let rem = s.size % 4
    if (rem == 2) {
        s = s + "=="
    } else if (rem == 3) {
        s = s + "="
    } else if (rem == 1) {
        throw IllegalArgumentException("Invalid base64url length")
    }
    match (fromBase64String(s)) {
        case Some(bytes) => String.fromUtf8(bytes)
        case None => throw IllegalArgumentException("Failed to base64url decode JWT part")
    }
}
