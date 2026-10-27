package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_dss

import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import std.collection.*
import std.sync.*
import std.time.*
import stdx.encoding.base64.*

/// X.509 trust anchor DER, the native stand-in for `java.security.cert.TrustAnchor`.
public class TrustAnchor {
    public let certificateDer: Array<Byte>

    public init(certificateDer: Array<Byte>) {
        this.certificateDer = certificateDer
    }
}

/// Observable summary of the last LOTL/TL load (Kotlin `lastValidationSummary`).
public class TlValidationSummary {
    public var lotlUrl: String = ""
    public var contextKey: String = ""
    public var processedLotls: Int64 = 0
    public var processedTls: Int64 = 0
    public var certificateCount: Int64 = 0
    public let messages: ArrayList<String> = ArrayList<String>()
}

/// Harmony-native LOTL/TL loader implementing `GetTrustAnchors`.
/// Fetches via `stdx.net.http` (through `ConcurrentCacheDataLoader`) and walks
/// ETSI TS 119 612 XML for `TSLLocation` pointers and `ServiceDigitalIdentity`
/// `X509Certificate` values. Does not port Java DSS.
public class GetTrustAnchorsFromLoTL <: GetTrustAnchors<VerificationContext, TrustAnchor> & Disposable {
    private let lotlUrl: String
    private let dssOptions: DssOptions
    private let loader: ConcurrentCacheDataLoader
    private let mutex = Mutex()
    private var lastSummary: ?TlValidationSummary = None

    public init(lotlUrl!: String, dssOptions!: DssOptions) {
        this.lotlUrl = lotlUrl
        this.dssOptions = dssOptions
        this.loader = ConcurrentCacheDataLoader.fromOptions(dssOptions)
    }

    public init(lotlUrl!: String) {
        let options = DssOptions.Default()
        this.lotlUrl = lotlUrl
        this.dssOptions = options
        this.loader = ConcurrentCacheDataLoader.fromOptions(options)
    }

    public func lastValidationSummary(): ?TlValidationSummary {
        this.lastSummary
    }

    public func invoke(query: VerificationContext): ?NonEmptyList<TrustAnchor> {
        var collected: ?NonEmptyList<TrustAnchor> = None
        synchronized(this.mutex) {
            collected = this.runValidationJob(query)
        }
        collected
    }

    public func dispose(): Unit {
        this.loader.dispose()
    }

    private func runValidationJob(query: VerificationContext): ?NonEmptyList<TrustAnchor> {
        let summary = TlValidationSummary()
        summary.lotlUrl = this.lotlUrl
        summary.contextKey = query.key()
        this.lastSummary = summary

        let lotlBytes = this.loader.get(this.lotlUrl)
        let lotlXml = String.fromUtf8(lotlBytes)
        var lotlRoot: ?XmlElement = None
        try {
            lotlRoot = parseXmlDocument(lotlXml)
        } catch (e: Exception) {
            summary.messages.add("Malformed LOTL XML: ${e.message}")
            if (!this.dssOptions.acceptInvalidListOfTrustedLists) {
                return None
            }
        }
        match (lotlRoot) {
            case None => return None
            case Some(root) => this.collectFromParsedLotl(root, summary)
        }
    }

    private func collectFromParsedLotl(root: XmlElement, summary: TlValidationSummary): ?NonEmptyList<TrustAnchor> {
        if (this.isExpiredTree(root, this.dssOptions.acceptInvalidListOfTrustedLists) &&
            !this.dssOptions.acceptExpiredListOfTrustedLists) {
            summary.messages.add("LOTL expired and acceptExpiredListOfTrustedLists is false")
            return None
        }
        summary.processedLotls = 1

        let anchors = ArrayList<TrustAnchor>()
        let lotlCertsOk = this.appendCertificates(
            root,
            anchors,
            summary,
            "LOTL ${this.lotlUrl}",
            this.dssOptions.acceptInvalidListOfTrustedLists
        )
        if (!lotlCertsOk && !this.dssOptions.acceptInvalidListOfTrustedLists) {
            summary.messages.add(
                "LOTL certificate decode failed and acceptInvalidListOfTrustedLists is false"
            )
            return None
        }

        let visited = HashMap<String, Bool>()
        visited.add(this.lotlUrl, true)
        let pointers = collectTslLocations(root)
        for (pointer in pointers) {
            let tlUrl = trimString(pointer)
            if (!isHttpUrl(tlUrl)) {
                continue
            }
            if (visited.contains(tlUrl)) {
                continue
            }
            visited.add(tlUrl, true)
            this.loadTrustedList(tlUrl, anchors, summary)
        }

        summary.certificateCount = anchors.size
        summary.messages.add("Processed LOTLs: ${summary.processedLotls}")
        summary.messages.add("Processed TLs: ${summary.processedTls}")
        summary.messages.add("Certificates: ${summary.certificateCount}")
        NonEmptyList<TrustAnchor>.nelOrNull(anchors)
    }

    private func loadTrustedList(
        tlUrl: String,
        anchors: ArrayList<TrustAnchor>,
        summary: TlValidationSummary
    ): Unit {
        try {
            let tlBytes = this.loader.get(tlUrl)
            let tlXml = String.fromUtf8(tlBytes)
            var tlRoot: ?XmlElement = None
            try {
                tlRoot = parseXmlDocument(tlXml)
            } catch (pe: Exception) {
                summary.messages.add("Malformed TL ${tlUrl}: ${pe.message}")
                if (!this.dssOptions.acceptInvalidTrustedList) {
                    return
                }
                return
            }
            match (tlRoot) {
                case None => return
                case Some(tlTree) =>
                    if (this.isExpiredTree(tlTree, this.dssOptions.acceptInvalidTrustedList) &&
                        !this.dssOptions.acceptExpiredTrustedList) {
                        summary.messages.add("Skipped expired TL ${tlUrl}")
                        return
                    }
                    let certsOk = this.appendCertificates(
                        tlTree,
                        anchors,
                        summary,
                        "TL ${tlUrl}",
                        this.dssOptions.acceptInvalidTrustedList
                    )
                    if (!certsOk && !this.dssOptions.acceptInvalidTrustedList) {
                        summary.messages.add(
                            "Skipped TL ${tlUrl}: certificate decode failed and acceptInvalidTrustedList is false"
                        )
                        return
                    }
                    summary.processedTls = summary.processedTls + 1
            }
        } catch (e: Exception) {
            summary.messages.add("Failed TL ${tlUrl}: ${e.message}")
            if (!this.dssOptions.acceptInvalidTrustedList) {
                return
            }
        }
    }

    /// Returns true when every certificate in the document decoded.
    /// On decode failure the failure is recorded on `summary.messages`.
    /// When `acceptInvalid` is false, no anchors from this document are added.
    private func appendCertificates(
        root: XmlElement,
        anchors: ArrayList<TrustAnchor>,
        summary: TlValidationSummary,
        sourceLabel: String,
        acceptInvalid: Bool
    ): Bool {
        let encoded = collectServiceDigitalIdentityCertificates(root)
        let decoded = ArrayList<TrustAnchor>()
        var allOk = true
        for (raw in encoded) {
            let stripped = stripWhitespace(raw)
            if (stripped.size == 0) {
                continue
            }
            match (fromBase64String(stripped)) {
                case Some(der) =>
                    if (der.size > 0) {
                        decoded.add(TrustAnchor(der))
                    }
                case None =>
                    summary.messages.add("Failed to decode X509Certificate in ${sourceLabel}")
                    allOk = false
            }
        }
        if (allOk || acceptInvalid) {
            for (anchor in decoded) {
                anchors.add(anchor)
            }
        }
        allOk
    }

    private func isExpiredTree(root: XmlElement, acceptInvalid: Bool): Bool {
        let candidates = collectNextUpdateDateTimes(root)
        if (candidates.size == 0) {
            return false
        }
        let now = DateTime.nowUTC()
        for (iso in candidates) {
            try {
                let next = DateTime.parse(trimString(iso))
                if (now.compare(next) == Ordering.GT) {
                    return true
                }
            } catch (e: Exception) {
                if (!acceptInvalid) {
                    return true
                }
            }
        }
        false
    }
}

class XmlElement {
    public let localName: String
    public let prefix: String
    public let children: ArrayList<XmlElement>
    public var directText: String = ""

    public init(localName: String, prefix: String) {
        this.localName = localName
        this.prefix = prefix
        this.children = ArrayList<XmlElement>()
        this.directText = ""
    }
}

/// Document walker for ETSI TS 119 612 LOTL/TL XML.
/// stdx.encoding.xml is not available; this walker handles comments, CDATA,
/// predefined/numeric entities, namespaces (local-name), and nested text.
class XmlReader {
    private let runes: Array<Rune>
    private let length: Int64
    private var pos: Int64

    public init(xml: String) {
        this.runes = xml.toRuneArray()
        this.length = this.runes.size
        this.pos = 0
    }

    public func parseRoot(): XmlElement {
        if (!this.atEnd() && this.runes[this.pos] == r'\u{FEFF}') {
            this.pos = this.pos + 1
        }
        this.skipMisc()
        if (this.atEnd() || this.runes[this.pos] != r'<') {
            throw Exception("Malformed XML: missing root element")
        }
        if (this.startsWithLiteral("</")) {
            throw Exception("Malformed XML: unexpected end tag")
        }
        let root = this.parseElement()
        this.skipMisc()
        if (!this.atEnd()) {
            throw Exception("Malformed XML: trailing content after root")
        }
        root
    }

    private func parseElement(): XmlElement {
        if (this.atEnd() || this.runes[this.pos] != r'<') {
            throw Exception("Malformed XML: expected start tag")
        }
        this.pos = this.pos + 1
        let qname = this.readName()
        let local = xmlLocalNameOf(qname)
        let prefix = xmlPrefixOf(qname)
        let el = XmlElement(local, prefix)
        this.skipWhitespace()
        while (!this.atEnd()) {
            if (this.startsWithLiteral("/>")) {
                this.pos = this.pos + 2
                return el
            }
            if (this.runes[this.pos] == r'>') {
                this.pos = this.pos + 1
                this.parseContents(el)
                return el
            }
            this.skipAttribute()
            this.skipWhitespace()
        }
        throw Exception("Malformed XML: unclosed start tag")
    }

    private func parseContents(el: XmlElement): Unit {
        let text = StringBuilder()
        while (true) {
            if (this.atEnd()) {
                throw Exception("Malformed XML: unclosed element ${el.localName}")
            }
            if (this.startsWithLiteral("<!--")) {
                this.skipComment()
            } else if (this.startsWithLiteral("<![CDATA[")) {
                text.append(this.readCdata())
            } else if (this.startsWithLiteral("<?")) {
                this.skipPi()
            } else if (this.startsWithLiteral("</")) {
                this.pos = this.pos + 2
                let endName = this.readName()
                this.skipWhitespace()
                if (this.atEnd() || this.runes[this.pos] != r'>') {
                    throw Exception("Malformed XML: expected > after end tag")
                }
                this.pos = this.pos + 1
                let endLocal = xmlLocalNameOf(endName)
                if (endLocal != el.localName) {
                    throw Exception("Malformed XML: mismatched end tag ${endLocal}")
                }
                el.directText = text.toString()
                return
            } else if (this.runes[this.pos] == r'<') {
                let child = this.parseElement()
                el.children.add(child)
            } else {
                text.append(this.readTextChunk())
            }
        }
    }

    private func skipMisc(): Unit {
        while (true) {
            this.skipWhitespace()
            if (this.atEnd()) {
                return
            }
            if (this.startsWithLiteral("<!--")) {
                this.skipComment()
            } else if (this.startsWithLiteral("<?")) {
                this.skipPi()
            } else if (this.startsWithLiteral("<!DOCTYPE")) {
                this.skipDoctype()
            } else {
                return
            }
        }
    }

    private func skipComment(): Unit {
        this.consumeLiteral("<!--")
        while (!this.atEnd()) {
            if (this.startsWithLiteral("-->")) {
                this.pos = this.pos + 3
                return
            }
            this.pos = this.pos + 1
        }
        throw Exception("Malformed XML: unclosed comment")
    }

    private func skipPi(): Unit {
        this.consumeLiteral("<?")
        while (!this.atEnd()) {
            if (this.startsWithLiteral("?>")) {
                this.pos = this.pos + 2
                return
            }
            this.pos = this.pos + 1
        }
        throw Exception("Malformed XML: unclosed processing instruction")
    }

    private func skipDoctype(): Unit {
        this.consumeLiteral("<!DOCTYPE")
        var depth: Int64 = 0
        while (!this.atEnd()) {
            let ch = this.runes[this.pos]
            this.pos = this.pos + 1
            if (ch == r'[') {
                depth = depth + 1
            } else if (ch == r']') {
                if (depth > 0) {
                    depth = depth - 1
                }
            } else if (ch == r'>' && depth == 0) {
                return
            }
        }
        throw Exception("Malformed XML: unclosed DOCTYPE")
    }

    private func readCdata(): String {
        this.consumeLiteral("<![CDATA[")
        let sb = StringBuilder()
        while (!this.atEnd()) {
            if (this.startsWithLiteral("]]>")) {
                this.pos = this.pos + 3
                return sb.toString()
            }
            sb.append(this.runes[this.pos])
            this.pos = this.pos + 1
        }
        throw Exception("Malformed XML: unclosed CDATA")
    }

    private func skipAttribute(): Unit {
        let _ = this.readName()
        this.skipWhitespace()
        if (this.atEnd() || this.runes[this.pos] != r'=') {
            throw Exception("Malformed XML: expected = in attribute")
        }
        this.pos = this.pos + 1
        this.skipWhitespace()
        this.skipQuoted()
    }

    private func skipQuoted(): Unit {
        if (this.atEnd()) {
            throw Exception("Malformed XML: expected quoted attribute")
        }
        let q = this.runes[this.pos]
        if (q != r'"' && q != r'\'') {
            throw Exception("Malformed XML: expected quoted attribute")
        }
        this.pos = this.pos + 1
        while (!this.atEnd()) {
            if (this.runes[this.pos] == q) {
                this.pos = this.pos + 1
                return
            }
            this.pos = this.pos + 1
        }
        throw Exception("Malformed XML: unclosed attribute value")
    }

    private func readTextChunk(): String {
        let sb = StringBuilder()
        while (!this.atEnd() && this.runes[this.pos] != r'<') {
            if (this.runes[this.pos] == r'&') {
                sb.append(this.readEntity())
            } else {
                sb.append(this.runes[this.pos])
                this.pos = this.pos + 1
            }
        }
        sb.toString()
    }

    private func readEntity(): Rune {
        this.consumeLiteral("&")
        if (this.startsWithLiteral("#x") || this.startsWithLiteral("#X")) {
            this.pos = this.pos + 2
            var code: Int64 = 0
            var digits: Int64 = 0
            while (!this.atEnd() && this.runes[this.pos] != r';') {
                code = code * 16 + xmlHexVal(this.runes[this.pos])
                digits = digits + 1
                this.pos = this.pos + 1
                if (digits > 8) {
                    throw Exception("Malformed XML: numeric character reference too long")
                }
            }
            this.expectSemicolon()
            if (digits == 0) {
                throw Exception("Malformed XML: empty numeric character reference")
            }
            return xmlRuneFromCode(code)
        }
        if (this.startsWithLiteral("#")) {
            this.pos = this.pos + 1
            var code: Int64 = 0
            var digits: Int64 = 0
            while (!this.atEnd() && this.runes[this.pos] != r';') {
                let r = this.runes[this.pos]
                if (r < r'0' || r > r'9') {
                    throw Exception("Malformed XML: invalid decimal character reference")
                }
                code = code * 10 + Int64(UInt32(r) - UInt32(r'0'))
                digits = digits + 1
                this.pos = this.pos + 1
                if (digits > 10) {
                    throw Exception("Malformed XML: numeric character reference too long")
                }
            }
            this.expectSemicolon()
            if (digits == 0) {
                throw Exception("Malformed XML: empty numeric character reference")
            }
            return xmlRuneFromCode(code)
        }
        let nameStart = this.pos
        while (!this.atEnd() && this.runes[this.pos] != r';') {
            this.pos = this.pos + 1
        }
        let name = runesSliceToString(this.runes, nameStart, this.pos)
        this.expectSemicolon()
        if (name == "amp") {
            return r'&'
        }
        if (name == "lt") {
            return r'<'
        }
        if (name == "gt") {
            return r'>'
        }
        if (name == "quot") {
            return r'"'
        }
        if (name == "apos") {
            return r'\''
        }
        throw Exception("Malformed XML: undeclared entity ${name}")
    }

    private func expectSemicolon(): Unit {
        if (this.atEnd() || this.runes[this.pos] != r';') {
            throw Exception("Malformed XML: unterminated entity")
        }
        this.pos = this.pos + 1
    }

    private func readName(): String {
        if (this.atEnd() || !isXmlNameStart(this.runes[this.pos])) {
            throw Exception("Malformed XML: expected name")
        }
        let start = this.pos
        this.pos = this.pos + 1
        while (!this.atEnd() && isXmlNameChar(this.runes[this.pos])) {
            this.pos = this.pos + 1
        }
        runesSliceToString(this.runes, start, this.pos)
    }

    private func skipWhitespace(): Unit {
        while (!this.atEnd()) {
            let ch = this.runes[this.pos]
            if (ch == r' ' || ch == r'\t' || ch == r'\n' || ch == r'\r') {
                this.pos = this.pos + 1
            } else {
                return
            }
        }
    }

    private func startsWithLiteral(lit: String): Bool {
        let needle = lit.toRuneArray()
        if (this.pos + needle.size > this.length) {
            return false
        }
        var i: Int64 = 0
        while (i < needle.size) {
            if (this.runes[this.pos + i] != needle[i]) {
                return false
            }
            i = i + 1
        }
        true
    }

    private func consumeLiteral(lit: String): Unit {
        if (!this.startsWithLiteral(lit)) {
            throw Exception("Malformed XML: expected ${lit}")
        }
        this.pos = this.pos + lit.toRuneArray().size
    }

    private func atEnd(): Bool {
        this.pos >= this.length
    }
}

func parseXmlDocument(xml: String): XmlElement {
    let reader = XmlReader(xml)
    reader.parseRoot()
}

func collectTslLocations(root: XmlElement): ArrayList<String> {
    let out = ArrayList<String>()
    walkTslLocations(root, out)
    out
}

func walkTslLocations(el: XmlElement, out: ArrayList<String>): Unit {
    if (el.localName == "TSLLocation") {
        let text = trimString(xmlConcatenatedText(el))
        if (text.size > 0) {
            out.add(text)
        }
        return
    }
    for (child in el.children) {
        walkTslLocations(child, out)
    }
}

func collectServiceDigitalIdentityCertificates(root: XmlElement): ArrayList<String> {
    let out = ArrayList<String>()
    walkServiceCerts(root, false, false, out)
    out
}

func walkServiceCerts(
    el: XmlElement,
    inServiceDigitalIdentity: Bool,
    inKeyInfoOrSignature: Bool,
    out: ArrayList<String>
): Unit {
    let nextSdi = inServiceDigitalIdentity || el.localName == "ServiceDigitalIdentity"
    let nextDs = inKeyInfoOrSignature || el.localName == "KeyInfo" || el.localName == "Signature"
    if (el.localName == "X509Certificate" && inServiceDigitalIdentity && !inKeyInfoOrSignature) {
        let text = trimString(xmlConcatenatedText(el))
        if (text.size > 0) {
            out.add(text)
        }
    }
    for (child in el.children) {
        walkServiceCerts(child, nextSdi, nextDs, out)
    }
}

func collectNextUpdateDateTimes(root: XmlElement): ArrayList<String> {
    let out = ArrayList<String>()
    walkNextUpdate(root, out)
    out
}

func walkNextUpdate(el: XmlElement, out: ArrayList<String>): Unit {
    if (el.localName == "NextUpdate") {
        var found = false
        for (child in el.children) {
            if (child.localName == "dateTime") {
                let iso = trimString(xmlConcatenatedText(child))
                if (iso.size > 0) {
                    out.add(iso)
                    found = true
                }
            }
        }
        if (!found) {
            let text = trimString(xmlConcatenatedText(el))
            if (text.size > 0) {
                out.add(text)
            }
        }
        return
    }
    for (child in el.children) {
        walkNextUpdate(child, out)
    }
}

func xmlConcatenatedText(el: XmlElement): String {
    let sb = StringBuilder()
    sb.append(el.directText)
    for (child in el.children) {
        sb.append(xmlConcatenatedText(child))
    }
    sb.toString()
}

func xmlLocalNameOf(qname: String): String {
    let runes = qname.toRuneArray()
    var colon: Int64 = -1
    var i: Int64 = 0
    while (i < runes.size) {
        if (runes[i] == r':') {
            colon = i
        }
        i = i + 1
    }
    if (colon < 0 || colon >= runes.size - 1) {
        qname
    } else {
        runesSliceToString(runes, colon + 1, runes.size)
    }
}

func xmlPrefixOf(qname: String): String {
    let runes = qname.toRuneArray()
    var colon: Int64 = -1
    var i: Int64 = 0
    while (i < runes.size) {
        if (runes[i] == r':') {
            colon = i
        }
        i = i + 1
    }
    if (colon <= 0) {
        ""
    } else {
        runesSliceToString(runes, 0, colon)
    }
}

func runesSliceToString(runes: Array<Rune>, start: Int64, endExclusive: Int64): String {
    let sb = StringBuilder()
    var i = start
    while (i < endExclusive) {
        sb.append(runes[i])
        i = i + 1
    }
    sb.toString()
}

func isXmlNameStart(r: Rune): Bool {
    r == r':' || r == r'_' || (r >= r'A' && r <= r'Z') || (r >= r'a' && r <= r'z')
}

func isXmlNameChar(r: Rune): Bool {
    isXmlNameStart(r) || (r >= r'0' && r <= r'9') || r == r'-' || r == r'.'
}

func xmlHexVal(r: Rune): Int64 {
    if (r >= r'0' && r <= r'9') {
        return Int64(UInt32(r) - UInt32(r'0'))
    }
    if (r >= r'a' && r <= r'f') {
        return Int64(UInt32(r) - UInt32(r'a')) + 10
    }
    if (r >= r'A' && r <= r'F') {
        return Int64(UInt32(r) - UInt32(r'A')) + 10
    }
    throw Exception("Malformed XML: invalid numeric character reference")
}

func xmlRuneFromCode(code: Int64): Rune {
    if (code < 0 || code > 1114111) {
        throw Exception("Malformed XML: character reference out of range")
    }
    if (code >= 55296 && code <= 57343) {
        throw Exception("Malformed XML: surrogate character reference")
    }
    Rune(UInt32(code))
}

func isHttpUrl(url: String): Bool {
    stringStartsWith(url, "http://") || stringStartsWith(url, "https://")
}

func stripWhitespace(text: String): String {
    let sb = StringBuilder()
    for (r in text.toRuneArray()) {
        if (r != r' ' && r != r'\t' && r != r'\n' && r != r'\r') {
            sb.append(r)
        }
    }
    sb.toString()
}

func isWsByte(b: Byte): Bool {
    let n = Int64(b) & 0xFF
    n == 32 || n == 9 || n == 10 || n == 13
}

func trimString(s: String): String {
    let bytes = s.toArray()
    var start: Int64 = 0
    var end: Int64 = bytes.size
    while (start < end && isWsByte(bytes[start])) {
        start = start + 1
    }
    while (end > start && isWsByte(bytes[end - 1])) {
        end = end - 1
    }
    if (start >= end) {
        ""
    } else {
        let from = start
        let len = end - start
        String.fromUtf8(Array<Byte>(len, { i => bytes[from + i] }))
    }
}

func stringStartsWith(s: String, prefix: String): Bool {
    let left = s.toArray()
    let right = prefix.toArray()
    if (left.size < right.size) {
        return false
    }
    var i: Int64 = 0
    while (i < right.size) {
        if (left[i] != right[i]) {
            return false
        }
        i = i + 1
    }
    true
}
