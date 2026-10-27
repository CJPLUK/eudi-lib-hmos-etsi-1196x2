package ohos_app_cangjie_eudi_cjetsi_1196x2.etsi_trust

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.HashMap

import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation_platform.BundledAnchorMethod


let CERT_A: Array<UInt8> = [0x30u8,0x82u8,0x01u8,0x80u8,0x30u8,0x82u8,0x01u8,0x25u8,0xA0u8,0x03u8,0x02u8,0x01u8,0x02u8,0x02u8,0x14u8,0x01u8,0x7Bu8,0x97u8,0xD5u8,0x67u8,0x69u8,0xE3u8,0x26u8,0x99u8,0xC3u8,0x75u8,0x75u8,0x91u8,0x91u8,0x26u8,0x88u8,0xBAu8,0xC5u8,0xA8u8,0x5Bu8,0x30u8,0x0Au8,0x06u8,0x08u8,0x2Au8,0x86u8,0x48u8,0xCEu8,0x3Du8,0x04u8,0x03u8,0x02u8,0x30u8,0x15u8,0x31u8,0x13u8,0x30u8,0x11u8,0x06u8,0x03u8,0x55u8,0x04u8,0x03u8,0x0Cu8,0x0Au8,0x54u8,0x72u8,0x75u8,0x73u8,0x74u8,0x54u8,0x65u8,0x73u8,0x74u8,0x41u8,0x30u8,0x1Eu8,0x17u8,0x0Du8,0x32u8,0x36u8,0x30u8,0x38u8,0x32u8,0x38u8,0x31u8,0x30u8,0x32u8,0x38u8,0x34u8,0x39u8,0x5Au8,0x17u8,0x0Du8,0x33u8,0x36u8,0x30u8,0x38u8,0x32u8,0x35u8,0x31u8,0x30u8,0x32u8,0x38u8,0x34u8,0x39u8,0x5Au8,0x30u8,0x15u8,0x31u8,0x13u8,0x30u8,0x11u8,0x06u8,0x03u8,0x55u8,0x04u8,0x03u8,0x0Cu8,0x0Au8,0x54u8,0x72u8,0x75u8,0x73u8,0x74u8,0x54u8,0x65u8,0x73u8,0x74u8,0x41u8,0x30u8,0x59u8,0x30u8,0x13u8,0x06u8,0x07u8,0x2Au8,0x86u8,0x48u8,0xCEu8,0x3Du8,0x02u8,0x01u8,0x06u8,0x08u8,0x2Au8,0x86u8,0x48u8,0xCEu8,0x3Du8,0x03u8,0x01u8,0x07u8,0x03u8,0x42u8,0x00u8,0x04u8,0xF1u8,0x99u8,0xCEu8,0xB2u8,0x11u8,0x11u8,0x91u8,0x7Au8,0x3Eu8,0x3Cu8,0x35u8,0xE0u8,0x04u8,0x1Eu8,0x23u8,0x82u8,0x6Du8,0x6Fu8,0x0Bu8,0xF1u8,0xF1u8,0x9Bu8,0x62u8,0xB3u8,0xD9u8,0x15u8,0x79u8,0xE7u8,0x7Cu8,0xE9u8,0x97u8,0xADu8,0x44u8,0x30u8,0x9Bu8,0x73u8,0x8Bu8,0xABu8,0xAAu8,0x5Eu8,0x18u8,0x08u8,0x1Cu8,0x34u8,0x7Du8,0x1Du8,0x7Du8,0xFCu8,0x54u8,0xB7u8,0x9Eu8,0xA2u8,0x20u8,0x39u8,0xBFu8,0x93u8,0x54u8,0x85u8,0xC9u8,0x80u8,0xF3u8,0x2Eu8,0xC6u8,0x15u8,0xA3u8,0x53u8,0x30u8,0x51u8,0x30u8,0x1Du8,0x06u8,0x03u8,0x55u8,0x1Du8,0x0Eu8,0x04u8,0x16u8,0x04u8,0x14u8,0x06u8,0x27u8,0xCAu8,0x89u8,0xA8u8,0xBDu8,0xA8u8,0x1Fu8,0x3Bu8,0x70u8,0x82u8,0x2Au8,0x03u8,0x00u8,0x8Eu8,0x62u8,0x8Fu8,0x66u8,0x8Au8,0x98u8,0x30u8,0x1Fu8,0x06u8,0x03u8,0x55u8,0x1Du8,0x23u8,0x04u8,0x18u8,0x30u8,0x16u8,0x80u8,0x14u8,0x06u8,0x27u8,0xCAu8,0x89u8,0xA8u8,0xBDu8,0xA8u8,0x1Fu8,0x3Bu8,0x70u8,0x82u8,0x2Au8,0x03u8,0x00u8,0x8Eu8,0x62u8,0x8Fu8,0x66u8,0x8Au8,0x98u8,0x30u8,0x0Fu8,0x06u8,0x03u8,0x55u8,0x1Du8,0x13u8,0x01u8,0x01u8,0xFFu8,0x04u8,0x05u8,0x30u8,0x03u8,0x01u8,0x01u8,0xFFu8,0x30u8,0x0Au8,0x06u8,0x08u8,0x2Au8,0x86u8,0x48u8,0xCEu8,0x3Du8,0x04u8,0x03u8,0x02u8,0x03u8,0x49u8,0x00u8,0x30u8,0x46u8,0x02u8,0x21u8,0x00u8,0x91u8,0x3Eu8,0xB8u8,0xDEu8,0xAAu8,0x93u8,0x75u8,0xC9u8,0x28u8,0x42u8,0xD6u8,0xD6u8,0x18u8,0xFBu8,0x9Au8,0x5Au8,0xC0u8,0x1Fu8,0xF5u8,0x25u8,0x03u8,0x63u8,0x2Au8,0xBBu8,0xD7u8,0xA0u8,0x38u8,0x96u8,0x00u8,0xD8u8,0x0Cu8,0x0Du8,0x02u8,0x21u8,0x00u8,0x9Cu8,0x89u8,0x50u8,0x7Du8,0x73u8,0x9Bu8,0x5Cu8,0x1Eu8,0xD0u8,0x0Eu8,0x11u8,0x3Du8,0x1Du8,0x39u8,0x82u8,0x33u8,0x7Bu8,0x65u8,0xBDu8,0xF3u8,0x06u8,0xADu8,0x7Du8,0x00u8,0xA2u8,0xD0u8,0x97u8,0xD5u8,0x93u8,0xC1u8,0x2Bu8,0x4Eu8]
let CERT_B: Array<UInt8> = [0x30u8,0x82u8,0x01u8,0x80u8,0x30u8,0x82u8,0x01u8,0x25u8,0xA0u8,0x03u8,0x02u8,0x01u8,0x02u8,0x02u8,0x14u8,0x16u8,0x49u8,0x58u8,0x0Du8,0xB3u8,0x5Du8,0x06u8,0xF4u8,0xC8u8,0xF7u8,0x56u8,0x96u8,0x2Bu8,0xAEu8,0xFBu8,0x17u8,0x79u8,0xD8u8,0x57u8,0xC5u8,0x30u8,0x0Au8,0x06u8,0x08u8,0x2Au8,0x86u8,0x48u8,0xCEu8,0x3Du8,0x04u8,0x03u8,0x02u8,0x30u8,0x15u8,0x31u8,0x13u8,0x30u8,0x11u8,0x06u8,0x03u8,0x55u8,0x04u8,0x03u8,0x0Cu8,0x0Au8,0x54u8,0x72u8,0x75u8,0x73u8,0x74u8,0x54u8,0x65u8,0x73u8,0x74u8,0x42u8,0x30u8,0x1Eu8,0x17u8,0x0Du8,0x32u8,0x36u8,0x30u8,0x38u8,0x32u8,0x38u8,0x31u8,0x30u8,0x32u8,0x38u8,0x34u8,0x39u8,0x5Au8,0x17u8,0x0Du8,0x33u8,0x36u8,0x30u8,0x38u8,0x32u8,0x35u8,0x31u8,0x30u8,0x32u8,0x38u8,0x34u8,0x39u8,0x5Au8,0x30u8,0x15u8,0x31u8,0x13u8,0x30u8,0x11u8,0x06u8,0x03u8,0x55u8,0x04u8,0x03u8,0x0Cu8,0x0Au8,0x54u8,0x72u8,0x75u8,0x73u8,0x74u8,0x54u8,0x65u8,0x73u8,0x74u8,0x42u8,0x30u8,0x59u8,0x30u8,0x13u8,0x06u8,0x07u8,0x2Au8,0x86u8,0x48u8,0xCEu8,0x3Du8,0x02u8,0x01u8,0x06u8,0x08u8,0x2Au8,0x86u8,0x48u8,0xCEu8,0x3Du8,0x03u8,0x01u8,0x07u8,0x03u8,0x42u8,0x00u8,0x04u8,0x0Cu8,0xFDu8,0x7Eu8,0xEBu8,0xDFu8,0xEBu8,0xEAu8,0xF5u8,0xD3u8,0xCAu8,0x4Eu8,0x5Cu8,0xDAu8,0xC4u8,0x22u8,0x50u8,0xE3u8,0x0Du8,0xA6u8,0x67u8,0x09u8,0xD3u8,0xDCu8,0x2Cu8,0x85u8,0x27u8,0x53u8,0x12u8,0x94u8,0x52u8,0xE5u8,0x5Cu8,0x7Eu8,0x59u8,0x12u8,0x3Bu8,0xF0u8,0xF4u8,0xFBu8,0x6Fu8,0x8Eu8,0xBAu8,0xE9u8,0x51u8,0x6Au8,0xC6u8,0xE7u8,0x0Du8,0x23u8,0xEFu8,0xB0u8,0x42u8,0x97u8,0xE1u8,0x4Fu8,0x0Fu8,0x3Fu8,0xB1u8,0xF9u8,0x04u8,0xC4u8,0x11u8,0x41u8,0xDBu8,0xA3u8,0x53u8,0x30u8,0x51u8,0x30u8,0x1Du8,0x06u8,0x03u8,0x55u8,0x1Du8,0x0Eu8,0x04u8,0x16u8,0x04u8,0x14u8,0x5Fu8,0x84u8,0x22u8,0x82u8,0x8Cu8,0xC6u8,0xA5u8,0x31u8,0xB1u8,0x5Eu8,0x34u8,0xC2u8,0x7Au8,0x3Eu8,0x6Du8,0x61u8,0x2Eu8,0x72u8,0x89u8,0x75u8,0x30u8,0x1Fu8,0x06u8,0x03u8,0x55u8,0x1Du8,0x23u8,0x04u8,0x18u8,0x30u8,0x16u8,0x80u8,0x14u8,0x5Fu8,0x84u8,0x22u8,0x82u8,0x8Cu8,0xC6u8,0xA5u8,0x31u8,0xB1u8,0x5Eu8,0x34u8,0xC2u8,0x7Au8,0x3Eu8,0x6Du8,0x61u8,0x2Eu8,0x72u8,0x89u8,0x75u8,0x30u8,0x0Fu8,0x06u8,0x03u8,0x55u8,0x1Du8,0x13u8,0x01u8,0x01u8,0xFFu8,0x04u8,0x05u8,0x30u8,0x03u8,0x01u8,0x01u8,0xFFu8,0x30u8,0x0Au8,0x06u8,0x08u8,0x2Au8,0x86u8,0x48u8,0xCEu8,0x3Du8,0x04u8,0x03u8,0x02u8,0x03u8,0x49u8,0x00u8,0x30u8,0x46u8,0x02u8,0x21u8,0x00u8,0xC0u8,0x38u8,0xFDu8,0x74u8,0x07u8,0x79u8,0x5Bu8,0x88u8,0x2Cu8,0xABu8,0xDDu8,0x23u8,0xD5u8,0x72u8,0x44u8,0x9Fu8,0xA4u8,0xB1u8,0x8Eu8,0xB4u8,0xC9u8,0x25u8,0x50u8,0x71u8,0x20u8,0x8Eu8,0xE5u8,0x76u8,0x36u8,0x22u8,0x6Bu8,0x22u8,0x02u8,0x21u8,0x00u8,0x80u8,0x6Bu8,0x02u8,0xE7u8,0x0Fu8,0x88u8,0x64u8,0x95u8,0x27u8,0xB0u8,0x6Bu8,0xD5u8,0xB7u8,0x0Eu8,0xE7u8,0xDCu8,0xF4u8,0x90u8,0x3Eu8,0x3Fu8,0x77u8,0xB7u8,0xF6u8,0xFAu8,0x27u8,0x18u8,0xEBu8,0xF6u8,0xFCu8,0x8Du8,0x8Cu8,0x93u8]

func pidOnlyMap(): EtsiContextTypeMappings {
    let map = HashMap<String, EtsiContextType>()
    map.add("eu.europa.ec.eudi.pid.1", EtsiContextType.PID)
    return map
}

func wrpacDirect(cert: Array<UInt8>): StaticListTrustSource {
    let map = HashMap<EtsiContextType, Array<Array<UInt8>>>()
    map.add(EtsiContextType.WRPAC, [cert])
    map.add(EtsiContextType.PID, [cert])
    return StaticListTrustSource(map, method: BundledAnchorMethod.DirectTrust)
}

func wrprcDirect(cert: Array<UInt8>): StaticListTrustSource {
    let map = HashMap<EtsiContextType, Array<Array<UInt8>>>()
    map.add(EtsiContextType.WRPRC, [cert])
    return StaticListTrustSource(map, method: BundledAnchorMethod.DirectTrust)
}

@Test
class EtsiTrustManagerTests {

    @TestCase
    func defaultMappingsContainPidAndMdl(): Unit {
        let map = defaultEtsiContextTypeMappings()
        match (map.get("eu.europa.ec.eudi.pid.1")) {
            case Some(EtsiContextType.PID) => @Expect(true, true)
            case _ => @Expect(false, true)
        }
        match (map.get("org.iso.18013.5.1.mDL")) {
            case Some(EtsiContextType.MDL) => @Expect(true, true)
            case _ => @Expect(false, true)
        }
    }

    @TestCase
    func accessManagerWithoutMappingsUsesWrpac(): Unit {
        let mgr = EtsiTrustManager(TrustSource.StaticList(wrpacDirect(CERT_A)))
        match (mgr.getVerificationContext()) {
            case Some(ctx) => @Expect(ctx.key(), "WalletRelyingPartyAccessCertificate")
            case None => @Expect(false, true)
        }
    }

    @TestCase
    func unknownDocTypeHasNoContext(): Unit {
        let source = TrustSource.StaticList(
            wrpacDirect(CERT_A).withContextTypeMappings(Some(pidOnlyMap()))
        )
        let mgr = EtsiTrustManager(source)
        mgr.docType = Some("org.iso.18013.5.1.mDL")
        match (mgr.getVerificationContext()) {
            case None => @Expect(true, true)
            case Some(_) => @Expect(false, true)
        }
    }

    @TestCase
    func unknownDocTypeFallsBackToStaticList(): Unit {
        let primary = TrustSource.StaticList(
            wrpacDirect(CERT_A).withContextTypeMappings(Some(pidOnlyMap()))
        )
        let fallback = EtsiTrustManager(TrustSource.StaticList(wrpacDirect(CERT_B)))
        let mgr = EtsiTrustManager(primary, fallback: Some(fallback))
        mgr.docType = Some("org.iso.18013.5.1.mDL")
        let (ok, _) = mgr.validateCertTrustPath([CERT_B])
        @Expect(ok, true)
        let (bad, _) = mgr.validateCertTrustPath([CERT_A])
        @Expect(bad, false)
    }

    @TestCase
    func directTrustPinsExactEndEntity(): Unit {
        let mgr = EtsiTrustManager(TrustSource.StaticList(wrpacDirect(CERT_A)))
        let (ok, _) = mgr.validateCertTrustPath([CERT_A])
        @Expect(ok, true)
        let (bad, _) = mgr.validateCertTrustPath([CERT_B])
        @Expect(bad, false)
    }

    @TestCase
    func createPathAppendsMatchedAnchor(): Unit {
        let mgr = EtsiTrustManager(TrustSource.StaticList(wrpacDirect(CERT_A)))
        match (mgr.createCertTrustPath([CERT_A])) {
            case None => @Expect(false, true)
            case Some(path) => @Expect(path.size >= 1, true)
        }
        match (mgr.createCertTrustPath([CERT_B])) {
            case None => @Expect(true, true)
            case Some(_) => @Expect(false, true)
        }
    }

    @TestCase
    func emptyChainCannotBeEvaluated(): Unit {
        let mgr = EtsiTrustManager(TrustSource.StaticList(wrpacDirect(CERT_A)))
        let empty = Array<Array<UInt8>>(0, repeat: Array<UInt8>())
        let (ok, reason) = mgr.validateCertTrustPath(empty)
        @Expect(ok, false)
        match (reason) {
            case Some(_) => @Expect(true, true)
            case None => @Expect(false, true)
        }
    }

    @TestCase
    func trustAnchorsDerReturnsPinnedCert(): Unit {
        let mgr = EtsiTrustManager(TrustSource.StaticList(wrpacDirect(CERT_A)))
        let anchors = mgr.trustAnchorsDer()
        @Expect(anchors.size, 1)
        @Expect(anchors[0].size, CERT_A.size)
    }

    @TestCase
    func trustConfigurationSplitsIssuerAndAccess(): Unit {
        let staticSrc = TrustSource.StaticList(wrpacDirect(CERT_A))
        let cfg = TrustConfiguration(
            staticSrc,
            defaultPolicy: TrustPolicy.Warning,
            requireSignedMetadata: true,
            statusTrustPolicy: TrustPolicy.Warning
        )
        match (cfg.policyFor("eu.europa.ec.eudi.pid.1")) {
            case TrustPolicy.Warning => @Expect(true, true)
            case TrustPolicy.Enforce => @Expect(false, true)
        }
        cfg.issuerTrustManager.docType = Some("eu.europa.ec.eudi.pid.1")
        match (cfg.issuerTrustManager.getVerificationContext()) {
            case Some(ctx) => @Expect(ctx.key(), "PID")
            case None => @Expect(false, true)
        }
        match (cfg.accessTrustManager.getVerificationContext()) {
            case Some(ctx) => @Expect(ctx.key(), "WalletRelyingPartyAccessCertificate")
            case None => @Expect(false, true)
        }
        let (ok, _) = cfg.accessTrustManager.validateCertTrustPath([CERT_A])
        @Expect(ok, true)
    }

    @TestCase
    func registrationManagerUsesWrprcContext(): Unit {
        let staticSrc = TrustSource.StaticList(wrprcDirect(CERT_A))
        let cfg = TrustConfiguration(
            staticSrc,
            defaultPolicy: TrustPolicy.Warning
        )
        match (cfg.registrationTrustManager.getVerificationContext()) {
            case Some(ctx) => @Expect(ctx.key(), "WalletRelyingPartyRegistrationCertificate")
            case None => @Expect(false, true)
        }
        let (ok, _) = cfg.registrationTrustManager.validateCertTrustPath([CERT_A])
        @Expect(ok, true)
        let (bad, _) = cfg.registrationTrustManager.validateCertTrustPath([CERT_B])
        @Expect(bad, false)
    }

    @TestCase
    func wrprcPoliciesDefaultToVpWarningVciEnforce(): Unit {
        let cfg = TrustConfiguration(TrustSource.StaticList(wrpacDirect(CERT_A)))
        match (cfg.wrprcVpTrustPolicy) {
            case TrustPolicy.Warning => @Expect(true, true)
            case TrustPolicy.Enforce => @Expect(false, true)
        }
        match (cfg.wrprcVciTrustPolicy) {
            case TrustPolicy.Enforce => @Expect(true, true)
            case TrustPolicy.Warning => @Expect(false, true)
        }
    }

    @TestCase
    func withRootCertificatesSeedsWrprcSeparately(): Unit {
        let unseeded = StaticListTrustSource.withRootCertificates([CERT_A])
        match (unseeded.anchorsPerContext.get(EtsiContextType.WRPRC)) {
            case None => @Expect(true, true)
            case Some(_) => @Expect(false, true)
        }
        let seeded = StaticListTrustSource.withRootCertificates(
            [CERT_A],
            method: BundledAnchorMethod.DirectTrust,
            wrprcRootsDer: [CERT_B]
        )
        match (seeded.anchorsPerContext.get(EtsiContextType.WRPRC)) {
            case Some(roots) =>
                @Expect(roots.size, 1)
                @Expect(roots[0].size, CERT_B.size)
            case None => @Expect(false, true)
        }
        let cfg = TrustConfiguration(TrustSource.StaticList(seeded))
        let (ok, _) = cfg.registrationTrustManager.validateCertTrustPath([CERT_B])
        @Expect(ok, true)
        let (bad, _) = cfg.registrationTrustManager.validateCertTrustPath([CERT_A])
        @Expect(bad, false)
    }

    @TestCase
    func registrationManagerFallsBackWhenPrimaryHasNoWrprc(): Unit {
        let primary = TrustSource.StaticList(wrpacDirect(CERT_A))
        let cfg = TrustConfiguration(
            primary,
            fallbackTrustSource: Some(TrustSource.StaticList(wrprcDirect(CERT_B))),
            defaultPolicy: TrustPolicy.Warning
        )
        let anchors = cfg.registrationTrustManager.trustAnchorsDer()
        @Expect(anchors.size, 1)
        @Expect(anchors[0].size, CERT_B.size)
        let (ok, _) = cfg.registrationTrustManager.validateCertTrustPath([CERT_B])
        @Expect(ok, true)
    }

    @TestCase
    func accessManagerFallsBackWhenPrimaryHasNoWrpac(): Unit {
        let pidOnly = HashMap<EtsiContextType, Array<Array<UInt8>>>()
        pidOnly.add(EtsiContextType.PID, [CERT_A])
        let primary = TrustSource.StaticList(
            StaticListTrustSource(pidOnly, method: BundledAnchorMethod.DirectTrust)
        )
        let cfg = TrustConfiguration(
            primary,
            fallbackTrustSource: Some(TrustSource.StaticList(wrpacDirect(CERT_B))),
            defaultPolicy: TrustPolicy.Warning
        )
        let anchors = cfg.accessTrustManager.trustAnchorsDer()
        @Expect(anchors.size, 1)
        @Expect(anchors[0].size, CERT_B.size)
        let (ok, _) = cfg.accessTrustManager.validateCertTrustPath([CERT_B])
        @Expect(ok, true)
    }

    @TestCase
    func decideTrustPolicyPassesWhenTrusted(): Unit {
        match (decideTrustPolicy(true, None, TrustPolicy.Enforce, "untrusted")) {
            case TrustPolicyDecision.Pass => @Expect(true, true)
            case _ => @Expect(false, true)
        }
    }

    @TestCase
    func decideTrustPolicyWarnsUnderWarning(): Unit {
        match (decideTrustPolicy(false, Some("bad"), TrustPolicy.Warning, "Issued SD-JWT issuer certificate chain is not trusted")) {
            case TrustPolicyDecision.Warn(msg) =>
                @Expect(msg, "Issued SD-JWT issuer certificate chain is not trusted: bad")
            case _ => @Expect(false, true)
        }
    }

    @TestCase
    func decideTrustPolicyFailsUnderEnforce(): Unit {
        match (decideTrustPolicy(false, None, TrustPolicy.Enforce, "The issuer certificate chain is not trusted")) {
            case TrustPolicyDecision.Fail(msg) =>
                @Expect(msg, "The issuer certificate chain is not trusted")
            case _ => @Expect(false, true)
        }
    }

    @TestCase
    func withContextTypeMappingsReplacesMap(): Unit {
        let etsi = EtsiTrustSource(
            pidProviders: Some("https://example.test/pid"),
            wrpacProviders: Some("https://example.test/wrpac")
        )
        let mapped = etsi.withContextTypeMappings(Some(pidOnlyMap()))
        match (mapped.contextTypeMappings) {
            case Some(m) =>
                match (m.get("eu.europa.ec.eudi.pid.1")) {
                    case Some(EtsiContextType.PID) => @Expect(true, true)
                    case _ => @Expect(false, true)
                }
            case None => @Expect(false, true)
        }
        match (mapped.pidProviders) {
            case Some(url) => @Expect(url, "https://example.test/pid")
            case None => @Expect(false, true)
        }
    }
}
