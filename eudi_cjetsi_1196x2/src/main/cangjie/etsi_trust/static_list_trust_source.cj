package ohos_app_cangjie_eudi_cjetsi_1196x2.etsi_trust

import std.collection.ArrayList
import std.collection.HashMap
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation_platform.BundledAnchorMethod
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation_platform.BundledAnchors

/**
 * iOS `StaticListTrustSource` — bundled DER anchors, no LoTE download.
 */
public class StaticListTrustSource {
    public let anchorsPerContext: HashMap<EtsiContextType, Array<Array<UInt8>>>
    public let method: BundledAnchorMethod
    public let contextTypeMappings: ?EtsiContextTypeMappings

    public init(
        anchorsPerContext: HashMap<EtsiContextType, Array<Array<UInt8>>>,
        method!: BundledAnchorMethod = BundledAnchorMethod.PKIX,
        contextTypeMappings!: ?EtsiContextTypeMappings = None
    ) {
        this.anchorsPerContext = anchorsPerContext
        this.method = method
        this.contextTypeMappings = contextTypeMappings
    }

    /**
     * iOS convenience: one root list copied onto PID / mDL / Wallet / WRPAC.
     * WRPRC roots are seeded separately (registration chains are signed by
     * WRPRC Provider CAs, not the shared reader/issuer roots); an empty
     * `wrprcRootsDer` leaves the WRPRC context unconfigured so a fallback
     * source can still be consulted.
     */
    public static func withRootCertificates(
        rootCertificates: Array<Array<UInt8>>,
        method!: BundledAnchorMethod = BundledAnchorMethod.PKIX,
        contextTypeMappings!: ?EtsiContextTypeMappings = None,
        wrprcRootsDer!: Array<Array<UInt8>> = Array<Array<UInt8>>()
    ): StaticListTrustSource {
        let map = HashMap<EtsiContextType, Array<Array<UInt8>>>()
        map.add(EtsiContextType.PID, rootCertificates)
        map.add(EtsiContextType.MDL, rootCertificates)
        map.add(EtsiContextType.Wallet, rootCertificates)
        map.add(EtsiContextType.WRPAC, rootCertificates)
        if (wrprcRootsDer.size > 0) {
            map.add(EtsiContextType.WRPRC, wrprcRootsDer)
        }
        StaticListTrustSource(
            map,
            method: method,
            contextTypeMappings: contextTypeMappings
        )
    }

    public func withContextTypeMappings(mappings: ?EtsiContextTypeMappings): StaticListTrustSource {
        StaticListTrustSource(
            this.anchorsPerContext,
            method: this.method,
            contextTypeMappings: mappings
        )
    }

    public func bundledAnchors(): BundledAnchors {
        let anchors = BundledAnchors()
        for ((ctx, certs) in this.anchorsPerContext) {
            let ders = u8ChainsToByteList(certs)
            match (ctx) {
                case EtsiContextType.PID => anchors.pid = Some(ders)
                case EtsiContextType.MDL => anchors.mdl = Some(ders)
                case EtsiContextType.Wallet => anchors.wallet = Some(ders)
                case EtsiContextType.WRPAC => anchors.wrpac = Some(ders)
                case EtsiContextType.WRPRC => anchors.wrprc = Some(ders)
            }
        }
        return anchors
    }
}

func u8ChainsToByteList(certs: Array<Array<UInt8>>): ArrayList<Array<Byte>> {
    let out = ArrayList<Array<Byte>>()
    for (der in certs) {
        out.add(u8ToBytes(der))
    }
    return out
}
