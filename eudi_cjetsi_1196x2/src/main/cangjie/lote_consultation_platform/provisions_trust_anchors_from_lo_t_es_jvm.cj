package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation_platform

import std.collection.*
import std.crypto.digest.Digest
import stdx.crypto.common.DerBlob
import stdx.crypto.digest.{SHA256, SHA384, SHA512}
import stdx.crypto.keys.{ECDSAPublicKey, PadOption, RSAPublicKey}
import stdx.crypto.x509.{PublicKeyAlgorithm, X509Certificate, X509Exception}
import stdx.encoding.base64.*
import stdx.encoding.json.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_platform.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.pkix_bridge.{PKIXConfiguration, PKIXValidator, PkixChainValidation}

/// OHOS stand-in for JVM TrustAnchor: raw DER of each ServiceDigitalIdentity X.509.
public func defaultCreateTrustAnchors(
    serviceDigitalIdentity: ServiceDigitalIdentity
): ArrayList<Array<Byte>> {
    let out = ArrayList<Array<Byte>>()
    match (serviceDigitalIdentity.x509Certificates) {
        case None => out
        case Some(certs) =>
            for (pki in certs) {
                out.add(pki.value.bytes)
            }
            out
    }
}

func endEntityDerOf(chain: ArrayList<Array<Byte>>): Array<Byte> {
    if (chain.size == 0) {
        throw IllegalArgumentException("Chain cannot be empty")
    }
    chain[0]
}

/// Generic JVM/OHOS factory for ProvisionTrustAnchorsFromLoTEs over DER chains.
public func jvm<CTX>(
    loadLoTEAndPointers: LoadLoTEAndPointers,
    svcTypePerCtx: SupportedLists<LotEMeta<CTX>>,
    createTrustAnchors!: (ServiceDigitalIdentity) -> ArrayList<Array<Byte>> = defaultCreateTrustAnchors,
    continueOnProblem!: ContinueOnProblem = ContinueOnProblem.never(),
    directTrust!: ValidateCertificateChain<ArrayList<Array<Byte>>, Array<Byte>> =
        ValidateCertificateChainUsingDirectTrustJvm,
    pkix!: ValidateCertificateChain<ArrayList<Array<Byte>>, Array<Byte>> =
        ValidateCertificateChainUsingPKIXJvm.defaultInstance()
): ProvisionTrustAnchorsFromLoTEs<ArrayList<Array<Byte>>, CTX, Array<Byte>, Array<Byte>>
    where CTX <: Equatable<CTX> & Hashable {
    ProvisionTrustAnchorsFromLoTEs<ArrayList<Array<Byte>>, CTX, Array<Byte>, Array<Byte>>(
        loadLoTEAndPointers,
        svcTypePerCtx,
        createTrustAnchors,
        directTrust,
        pkix,
        certificateProfileValidatorJvm(),
        endEntityDerOf,
        continueOnProblem: continueOnProblem
    )
}

/// ProvisionTrustAnchorsFromLoTEs.eudiwJvm — EUDIW composition helper for JVM/OHOS.
/// Wires Download/verify (via the supplied LoadLoTEAndPointers) into the common
/// ProvisionTrustAnchorsFromLoTEs.eudiw factory using stdx.net.http + stdx.crypto types.
public func eudiwJvm(
    loadLoTEAndPointers: LoadLoTEAndPointers,
    svcTypePerCtx!: SupportedLists<LotEMeta<VerificationContext>> = euSupportedLists(),
    continueOnProblem!: ContinueOnProblem = ContinueOnProblem.never(),
    directTrust!: ValidateCertificateChain<ArrayList<Array<Byte>>, Array<Byte>> =
        ValidateCertificateChainUsingDirectTrustJvm,
    pkix!: ValidateCertificateChain<ArrayList<Array<Byte>>, Array<Byte>> =
        ValidateCertificateChainUsingPKIXJvm.defaultInstance()
): ProvisionTrustAnchorsFromLoTEs<ArrayList<Array<Byte>>, VerificationContext, Array<Byte>, Array<Byte>> {
    ProvisionTrustAnchorsFromLoTEs<ArrayList<Array<Byte>>, VerificationContext, Array<Byte>, Array<Byte>>.eudiw(
        loadLoTEAndPointers,
        defaultCreateTrustAnchors,
        directTrust,
        pkix,
        certificateProfileValidatorJvm(),
        endEntityDerOf,
        svcTypePerCtx: svcTypePerCtx,
        continueOnProblem: continueOnProblem
    )
}

/// Real JWS verifier using stdx.crypto (RSA PKCS1 / ECDSA + SHA-2).
///
/// Signing key comes from the JWS `x5c` leaf and/or `trustedSignerCertificates`.
/// Unknown alg, missing key material, or a failed signature is NotVerified (D-100).
/// Architecture jwt_unverified: the iOS-test always-accept verifier is not compiled here.
public class StdxCryptoJwtSignature <: VerifyJwtSignature {
    private let trustedSignerCertificates: ArrayList<Array<Byte>>

    public init(trustedSignerCertificates!: ArrayList<Array<Byte>> = ArrayList<Array<Byte>>()) {
        this.trustedSignerCertificates = trustedSignerCertificates
    }

    public init() {
        this.trustedSignerCertificates = ArrayList<Array<Byte>>()
    }

    public func invoke(jwt: String): VerifyJwtSignatureOutcome {
        try {
            let parsed = parseJwsForVerify(jwt)
            let alg = JsonFields.requireString(parsed.header, "alg").toAsciiUpper()
            let signingCerts = this.resolveSigningCertificates(parsed.header)
            if (signingCerts.size == 0) {
                return VerifyJwtSignatureOutcome.NotVerified(
                    Some(IllegalArgumentException("JWT has no x5c and no trusted signer certificates"))
                )
            }
            var i: Int64 = 0
            while (i < signingCerts.size) {
                if (verifyJwsWithCertificate(alg, parsed.signingInput, parsed.signature, signingCerts[i])) {
                    return VerifyJwtSignatureOutcome.Verified(jwt)
                }
                i = i + 1
            }
            VerifyJwtSignatureOutcome.NotVerified(
                Some(IllegalArgumentException("JWT signature did not verify"))
            )
        } catch (e: Exception) {
            VerifyJwtSignatureOutcome.NotVerified(Some(e))
        }
    }

    private func resolveSigningCertificates(header: JsonObject): ArrayList<Array<Byte>> {
        let fromHeader = x5cCertificates(header)
        if (fromHeader.size == 0) {
            return copyDerList(this.trustedSignerCertificates)
        }
        let leaf = fromHeader[0]
        if (this.trustedSignerCertificates.size == 0) {
            return copyDerList(fromHeader)
        }
        if (!this.leafIsTrusted(leaf, fromHeader)) {
            throw IllegalArgumentException("x5c leaf is not trusted by the configured signer certificates")
        }
        copyDerList(fromHeader)
    }

    private func leafIsTrusted(leaf: Array<Byte>, chain: ArrayList<Array<Byte>>): Bool {
        for (trusted in this.trustedSignerCertificates) {
            if (derEqual(leaf, trusted)) {
                return true
            }
        }
        let intermediates = ArrayList<Array<Byte>>()
        var i: Int64 = 1
        while (i < chain.size) {
            intermediates.add(chain[i])
            i = i + 1
        }
        let validator = PKIXValidator(configuration: PKIXConfiguration(isRevocationEnabled: false))
        let outcome = validator.validateCertificateChain(
            leafCertificate: leaf,
            intermediateCertificates: arrayListToByteArrays(intermediates),
            trustAnchors: arrayListToByteArrays(this.trustedSignerCertificates)
        )
        match (outcome) {
            case PkixChainValidation.Trusted(_) => true
            case PkixChainValidation.Failed(_) => false
        }
    }
}

class JwsVerifyParts {
    public let header: JsonObject
    public let signingInput: Array<Byte>
    public let signature: Array<Byte>

    public init(header: JsonObject, signingInput: Array<Byte>, signature: Array<Byte>) {
        this.header = header
        this.signingInput = signingInput
        this.signature = signature
    }
}

func parseJwsForVerify(jwt: String): JwsVerifyParts {
    let trimmed = jwt.trimAscii()
    if (trimmed.isEmpty()) {
        throw IllegalArgumentException("Input must not be empty")
    }
    let compact = tryParseCompactJws(trimmed)
    match (compact) {
        case Some(parts) => parts
        case None => parseJwsJsonForVerify(trimmed)
    }
}

func tryParseCompactJws(jwt: String): Option<JwsVerifyParts> {
    let parts = jwt.split(".")
    if (parts.size != 3) {
        return None
    }
    let header = JsonValue.fromStr(decodeBase64UrlToUtf8(parts[0])).asObject()
    let signingInput = (parts[0] + "." + parts[1]).toArray()
    Some(JwsVerifyParts(header, signingInput, decodeBase64Url(parts[2])))
}

func parseJwsJsonForVerify(jwt: String): JwsVerifyParts {
    let root = JsonValue.fromStr(jwt).asObject()
    let payloadB64 = JsonFields.requireString(root, "payload")
    match (JsonFields.optionalString(root, "protected")) {
        case Some(protectedB64) =>
            let signatureB64 = JsonFields.requireString(root, "signature")
            return jwsVerifyPartsFromProtected(protectedB64, payloadB64, signatureB64)
        case None => ()
    }
    let signatures = JsonFields.requireArray(root, "signatures")
    if (signatures.size() == 0) {
        throw IllegalArgumentException("Signatures must not be empty")
    }
    let firstSig = signatures[0].asObject()
    let protectedB64 = JsonFields.requireString(firstSig, "protected")
    let signatureB64 = JsonFields.requireString(firstSig, "signature")
    jwsVerifyPartsFromProtected(protectedB64, payloadB64, signatureB64)
}

func jwsVerifyPartsFromProtected(protectedB64: String, payloadB64: String, signatureB64: String): JwsVerifyParts {
    let header = JsonValue.fromStr(decodeBase64UrlToUtf8(protectedB64)).asObject()
    let signingInput = (protectedB64 + "." + payloadB64).toArray()
    JwsVerifyParts(header, signingInput, decodeBase64Url(signatureB64))
}

func x5cCertificates(header: JsonObject): ArrayList<Array<Byte>> {
    let out = ArrayList<Array<Byte>>()
    match (JsonFields.optionalArray(header, "x5c")) {
        case None => out
        case Some(arr) =>
            var i: Int64 = 0
            while (i < arr.size()) {
                let encoded = arr[i].asString().getValue()
                match (fromBase64String(encoded)) {
                    case Some(der) => out.add(der)
                    case None => throw IllegalArgumentException("Failed to decode x5c certificate")
                }
                i = i + 1
            }
            out
    }
}

func verifyJwsWithCertificate(
    alg: String,
    signingInput: Array<Byte>,
    signature: Array<Byte>,
    certDer: Array<Byte>
): Bool {
    let cert = try {
        X509Certificate.decodeFromDer(DerBlob(certDer))
    } catch (e: X509Exception) {
        return false
    } catch (e: Exception) {
        return false
    }
    let pubDer = cert.publicKey.encodeToDer()
    if (alg == "RS256" || alg == "RS384" || alg == "RS512") {
        verifyRsaPkcs1(alg, signingInput, signature, pubDer, cert.publicKeyAlgorithm)
    } else if (alg == "ES256" || alg == "ES384" || alg == "ES512") {
        verifyEcdsa(alg, signingInput, signature, pubDer, cert.publicKeyAlgorithm)
    } else {
        false
    }
}

func verifyRsaPkcs1(
    alg: String,
    signingInput: Array<Byte>,
    signature: Array<Byte>,
    pubDer: DerBlob,
    keyAlg: PublicKeyAlgorithm
): Bool {
    if (keyAlg != PublicKeyAlgorithm.RSA) {
        return false
    }
    let rsa = try {
        RSAPublicKey.decodeDer(pubDer)
    } catch (e: Exception) {
        return false
    }
    match (sha2ForAlg(alg)) {
        case None => false
        case Some(digestAlg) =>
            digestAlg.write(signingInput)
            let digest = digestAlg.finish()
            match (sha2ForAlg(alg)) {
                case None => false
                case Some(verifyAlg) =>
                    try {
                        rsa.verify(verifyAlg, digest, signature, padType: PadOption.PKCS1)
                    } catch (e: Exception) {
                        false
                    }
            }
    }
}

func verifyEcdsa(
    alg: String,
    signingInput: Array<Byte>,
    signature: Array<Byte>,
    pubDer: DerBlob,
    keyAlg: PublicKeyAlgorithm
): Bool {
    if (keyAlg != PublicKeyAlgorithm.ECDSA) {
        return false
    }
    let ecdsa = try {
        ECDSAPublicKey.decodeDer(pubDer)
    } catch (e: Exception) {
        return false
    }
    let hasher = sha2ForAlg(alg)
    match (hasher) {
        case None => false
        case Some(digestAlg) =>
            digestAlg.write(signingInput)
            let digest = digestAlg.finish()
            let derSig = joseEcdsaToDer(signature)
            try {
                ecdsa.verify(digest, derSig)
            } catch (e: Exception) {
                false
            }
    }
}

func sha2ForAlg(alg: String): Option<Digest> {
    if (alg == "RS256" || alg == "ES256") {
        let h: Digest = SHA256()
        Some(h)
    } else if (alg == "RS384" || alg == "ES384") {
        let h: Digest = SHA384()
        Some(h)
    } else if (alg == "RS512" || alg == "ES512") {
        let h: Digest = SHA512()
        Some(h)
    } else {
        None
    }
}

/// JWS ECDSA signatures are R||S (IEEE P1363 / RFC 7518); stdx ECDSA verify expects DER.
/// Exactly 64/96/132 bytes are always converted — first-byte 0x30 is a valid R high byte.
/// Already-DER SEQUENCE of two INTEGERs is passed through only when the length is not a JWS size.
func joseEcdsaToDer(signature: Array<Byte>): Array<Byte> {
    if (signature.size == 64 || signature.size == 96 || signature.size == 132) {
        return p1363ConcatToDer(signature)
    }
    if (isDerEcdsaIntegerSequence(signature)) {
        return signature
    }
    throw IllegalArgumentException("Unexpected ECDSA JWS signature length: ${signature.size}")
}

func p1363ConcatToDer(signature: Array<Byte>): Array<Byte> {
    let coordLen = signature.size / 2
    let r = encodeDerInteger(copyRange(signature, 0, coordLen))
    let s = encodeDerInteger(copyRange(signature, coordLen, coordLen))
    let bodyLen = r.size + s.size
    let out = ArrayList<Byte>()
    out.add(UInt8(0x30))
    appendDerLength(out, bodyLen)
    for (b in r) {
        out.add(b)
    }
    for (b in s) {
        out.add(b)
    }
    Array<Byte>(out.size, { idx => out[idx] })
}

class DerReadCursor {
    public let data: Array<Byte>
    public var offset: Int64

    public init(data: Array<Byte>, offset: Int64) {
        this.data = data
        this.offset = offset
    }
}

func derByte(data: Array<Byte>, index: Int64): Int64 {
    Int64(data[index]) & 0xFF
}

func isDerEcdsaIntegerSequence(sig: Array<Byte>): Bool {
    if (sig.size < 8 || derByte(sig, 0) != 0x30) {
        return false
    }
    try {
        let cursor = DerReadCursor(sig, 1)
        let bodyLen = readDerLength(cursor)
        let bodyEnd = cursor.offset + bodyLen
        if (bodyEnd != sig.size) {
            return false
        }
        skipDerInteger(cursor)
        skipDerInteger(cursor)
        cursor.offset == sig.size
    } catch (e: Exception) {
        false
    }
}

func readDerLength(cursor: DerReadCursor): Int64 {
    if (cursor.offset >= cursor.data.size) {
        throw IllegalArgumentException("truncated DER length")
    }
    let first = derByte(cursor.data, cursor.offset)
    cursor.offset = cursor.offset + 1
    if (first < 0x80) {
        return first
    }
    if (first == 0x80) {
        throw IllegalArgumentException("indefinite DER length")
    }
    let byteCount = first & 0x7F
    if (byteCount == 0 || byteCount > 8) {
        throw IllegalArgumentException("invalid DER length")
    }
    if (cursor.offset + byteCount > cursor.data.size) {
        throw IllegalArgumentException("truncated DER length")
    }
    var length: Int64 = 0
    var i: Int64 = 0
    while (i < byteCount) {
        length = (length << 8) | derByte(cursor.data, cursor.offset)
        cursor.offset = cursor.offset + 1
        i = i + 1
    }
    if (byteCount == 1 && length < 128) {
        throw IllegalArgumentException("non-canonical DER length")
    }
    length
}

func skipDerInteger(cursor: DerReadCursor): Unit {
    if (cursor.offset >= cursor.data.size || derByte(cursor.data, cursor.offset) != 0x02) {
        throw IllegalArgumentException("expected DER INTEGER")
    }
    cursor.offset = cursor.offset + 1
    let contentLen = readDerLength(cursor)
    if (contentLen < 1 || cursor.offset + contentLen > cursor.data.size) {
        throw IllegalArgumentException("truncated DER INTEGER")
    }
    cursor.offset = cursor.offset + contentLen
}

func encodeDerInteger(raw: Array<Byte>): Array<Byte> {
    var start: Int64 = 0
    while (start < raw.size - 1 && Int64(raw[start]) == 0) {
        start = start + 1
    }
    let lead = Int64(raw[start])
    let pad = (lead & 0x80) != 0
    let contentLen = (raw.size - start) + (if (pad) {
        1
    } else {
        0
    })
    let out = ArrayList<Byte>()
    out.add(UInt8(0x02))
    appendDerLength(out, contentLen)
    if (pad) {
        out.add(UInt8(0))
    }
    var i = start
    while (i < raw.size) {
        out.add(raw[i])
        i = i + 1
    }
    Array<Byte>(out.size, { idx => out[idx] })
}

func appendDerLength(out: ArrayList<Byte>, length: Int64): Unit {
    if (length < 0) {
        throw IllegalArgumentException("Negative DER length")
    }
    if (length < 128) {
        out.add(UInt8(length))
    } else {
        var nbytes: Int64 = 0
        var tmp = length
        while (tmp > 0) {
            nbytes = nbytes + 1
            tmp = tmp >> 8
        }
        if (nbytes == 0) {
            nbytes = 1
        }
        if (nbytes > 8) {
            throw IllegalArgumentException("DER length too large")
        }
        out.add(UInt8(0x80 + nbytes))
        var shift = (nbytes - 1) * 8
        while (shift >= 0) {
            let byteVal = (length >> shift) & 0xFF
            out.add(UInt8(byteVal))
            shift = shift - 8
        }
    }
}

func copyRange(src: Array<Byte>, start: Int64, len: Int64): Array<Byte> {
    Array<Byte>(len, { i => src[start + i] })
}

func decodeBase64UrlToUtf8(encoded: String): String {
    String.fromUtf8(decodeBase64Url(encoded))
}

func decodeBase64Url(encoded: String): Array<Byte> {
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
        case Some(bytes) => bytes
        case None => throw IllegalArgumentException("Failed to base64url decode")
    }
}

func derEqual(left: Array<Byte>, right: Array<Byte>): Bool {
    DerBlob(left) == DerBlob(right)
}

func copyDerList(src: ArrayList<Array<Byte>>): ArrayList<Array<Byte>> {
    let out = ArrayList<Array<Byte>>()
    for (item in src) {
        out.add(item)
    }
    out
}

func arrayListToByteArrays(list: ArrayList<Array<Byte>>): Array<Array<Byte>> {
    Array<Array<Byte>>(list.size, { i => list[i] })
}
