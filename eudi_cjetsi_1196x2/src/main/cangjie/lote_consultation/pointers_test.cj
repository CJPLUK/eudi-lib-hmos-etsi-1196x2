package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*
import stdx.encoding.base64.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model.*

class MemoryLoteLoader <: LoadLoTE {
    private let bodies: HashMap<String, String>
    public init(bodies: HashMap<String, String>) {
        this.bodies = bodies
    }
    public func invoke(uri: Uri): LoadLoTEOutcome {
        match (this.bodies.get(uri.value)) {
            case Some(body) => LoadLoTEOutcome.Loaded(body)
            case None => LoadLoTEOutcome.NotFound(Option<Exception>.None)
        }
    }
}

func alwaysVerify(): VerifyJwtSignature {
    return LambdaVerifyJwtSignature({ jwt: String => VerifyJwtSignatureOutcome.Verified(jwt) })
}

func b64url(text: String): String {
    let std = toBase64String(text.toArray())
    let bytes = std.toArray()
    var out = ""
    for (c in bytes) {
        if (c == b'+') {
            out = out + "-"
        } else if (c == b'/') {
            out = out + "_"
        } else if (c != b'=') {
            out = out + String.fromUtf8([c])
        }
    }
    return out
}

func compactJwt(payloadJson: String): String {
    return b64url("{\"alg\":\"none\"}") + "." + b64url(payloadJson) + ".e"
}

func lotePayload(pointer: String): String {
    var ptr = ""
    if (!pointer.isEmpty()) {
        ptr = "\"PointerToOtherLoTE\":[{\"LoTELocation\":\"" + pointer +
            "\",\"ServiceDigitalIdentities\":[{\"X509Certificates\":[{\"val\":\"MAMCAQA=\"}]}]," +
            "\"LoTEQualifiers\":[{\"LoTEType\":\"http://uri.etsi.org/19602/LoTEType/EUPIDProvidersList\"," +
            "\"SchemeOperatorName\":[{\"lang\":\"en\",\"value\":\"Test\"}],\"MimeType\":\"application/jwt\"}]}],"
    }
    return "{\"LoTE\":{\"ListAndSchemeInformation\":{" +
        "\"LoTEVersionIdentifier\":1,\"LoTESequenceNumber\":1," +
        "\"SchemeOperatorName\":[{\"lang\":\"en\",\"value\":\"Test\"}]," +
        "\"ListIssueDateTime\":\"2026-01-01T00:00:00Z\"," +
        "\"NextUpdate\":\"2027-01-01T00:00:00Z\"," +
        ptr +
        "\"LoTEType\":\"http://uri.etsi.org/19602/LoTEType/EUPIDProvidersList\"" +
        "}}}"
}

@Test
class LoadLoteAndPointersTest {
    @TestCase
    func loadsChildPointer(): Unit {
        let bodies = HashMap<String, String>()
        bodies.add("https://root", compactJwt(lotePayload("https://child")))
        bodies.add("https://child", compactJwt(lotePayload("")))
        let walker = LoadLoTEAndPointers(
            LoTELoadConstraints.LoadOtherPointers(1, 3, 16),
            alwaysVerify(),
            MemoryLoteLoader(bodies)
        )
        let events = walker.invoke(Uri.parse("https://root"))
        let collected = LoTELoadResult.collect(events, continueOnProblem: ContinueOnProblem.always())
        var loaded = 0
        match (collected.loadedMain()) {
            case Some(_) => loaded = loaded + 1
            case None => ()
        }
        loaded = loaded + collected.loadedOthers().size
        @Expect(loaded, 2)
        @Expect(collected.problems.size, 0)
    }

    @TestCase
    func detectsCircularUri(): Unit {
        let bodies = HashMap<String, String>()
        bodies.add("https://a", compactJwt(lotePayload("https://b")))
        bodies.add("https://b", compactJwt(lotePayload("https://a")))
        let walker = LoadLoTEAndPointers(
            LoTELoadConstraints.LoadOtherPointers(1, 5, 16),
            alwaysVerify(),
            MemoryLoteLoader(bodies)
        )
        let events = walker.invoke(Uri.parse("https://a"))
        var circular = false
        for (ev in events) {
            match (ev) {
                case LoadLoTEEvent.CircularReferenceDetected(uri) =>
                    if (uri.value == "https://a") {
                        circular = true
                    }
                case _ => ()
            }
        }
        @Expect(circular, true)
    }

    @TestCase
    func respectsMaxDepth(): Unit {
        let bodies = HashMap<String, String>()
        bodies.add("https://a", compactJwt(lotePayload("https://b")))
        bodies.add("https://b", compactJwt(lotePayload("https://c")))
        bodies.add("https://c", compactJwt(lotePayload("")))
        let walker = LoadLoTEAndPointers(
            LoTELoadConstraints.LoadOtherPointers(1, 1, 16),
            alwaysVerify(),
            MemoryLoteLoader(bodies)
        )
        let events = walker.invoke(Uri.parse("https://a"))
        var maxDepth = false
        for (ev in events) {
            match (ev) {
                case LoadLoTEEvent.MaxDepthReached(uri, _) =>
                    if (uri.value == "https://c") {
                        maxDepth = true
                    }
                case _ => ()
            }
        }
        let collected = LoTELoadResult.collect(events, continueOnProblem: ContinueOnProblem.always())
        @Expect(collected.loadedOthers().size, 1)
        @Expect(maxDepth, true)
    }

    @TestCase
    func flattenedJwsJsonParses(): Unit {
        let payload = lotePayload("")
        let json = "{\"protected\":\"" + b64url("{\"alg\":\"none\"}") +
            "\",\"payload\":\"" + b64url(payload) + "\",\"signature\":\"e\"}"
        match (ParseJwt().invoke(json)) {
            case ParseJwtOutcome.Parsed(_, _) => @Expect(true, true)
            case ParseJwtOutcome.ParseFailed(_) => @Expect(false, true)
        }
    }
}
