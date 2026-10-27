package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_dss

import std.unittest.*
import std.unittest.testmacro.*

func sampleTslXml(pointer: String, withCert: Bool): String {
    var ptr = ""
    if (!pointer.isEmpty()) {
        ptr = "<OtherTSLPointer><TSLLocation>" + pointer + "</TSLLocation></OtherTSLPointer>"
    }
    var cert = ""
    if (withCert) {
        cert = "<ServiceDigitalIdentity><X509Certificate>MAMCAQA=</X509Certificate></ServiceDigitalIdentity>"
    }
    return "<TrustServiceStatusList xmlns:tsl=\"http://uri.etsi.org/02231/v2#\">" +
        ptr +
        "<TSPService><ServiceInformation>" +
        "<tsl:ServiceTypeIdentifier>http://uri.etsi.org/TrstSvc/Svctype/CA/QC</tsl:ServiceTypeIdentifier>" +
        cert +
        "</ServiceInformation></TSPService></TrustServiceStatusList>"
}

@Test
class XmlLotlParseTest {
    @TestCase
    func parsesPointerAndCertificate(): Unit {
        let root = parseXmlDocument(sampleTslXml("https://child.tsl", true))
        let ptrs = collectTslLocations(root)
        let certs = collectServiceDigitalIdentityCertificates(root)
        @Expect(ptrs.size, 1)
        @Expect(ptrs[0], "https://child.tsl")
        @Expect(certs.size, 1)
    }
}
