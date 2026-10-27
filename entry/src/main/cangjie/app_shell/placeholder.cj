package ohos_app_cangjie_entry.app_shell

import std.collection.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation_platform.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_eu_profiles.*

/// KMM umbrella analogue (`Placeholder.kt`). HarmonyOS demo composition lives here.
public class Placeholder {}

var composedEudiwTrust: Option<ComposeChainTrust<ArrayList<Array<Byte>>, VerificationContext, Array<Byte>>> =
    None

/// Process-scoped EUDIW trust handle: LoTE-provisioned anchors via eudiwJvm.
/// Network I/O happens later on invoke, not at composition time.
public func app_composition(): IsChainTrustedForEUDIW<ArrayList<Array<Byte>>, Array<Byte>> {
    match (composedEudiwTrust) {
        case Some(existing) => existing
        case None =>
            let created = composeEudiwFromLote()
            composedEudiwTrust = Some(created)
            created
    }
}

func composeEudiwFromLote(): ComposeChainTrust<ArrayList<Array<Byte>>, VerificationContext, Array<Byte>> {
    let verify: VerifyJwtSignature = StdxCryptoJwtSignature(
        trustedSignerCertificates: ArrayList<Array<Byte>>()
    )
    let load = LoadLoTEAndPointers(
        LoTELoadConstraints.DoNotLoadOtherPointers,
        verify,
        IosLoTEHttpClient.create()
    )
    let provisioner = eudiwJvm(
        load,
        svcTypePerCtx: euSupportedLists(
            pidIssuanceProfile: Some(pidSigningCertificateProfile()),
            walletIssuanceProfile: Some(walletProviderSigningCertificateProfile()),
            wrpacIssuanceProfile: Some(wrpAccessCertificateProfile())
        )
    )
    provisioner.nonCached(eudiwDemoLoteLocations())
}

func eudiwDemoLoteLocations(): SupportedLists<Uri> {
    SupportedLists<Uri>(
        pidProviders: Some(Uri.parse("https://trustedlist.serviceproviders.eudiw.dev/LOTE/json/PIDProviders.jwt")),
        walletProviders: Some(
            Uri.parse("https://trustedlist.serviceproviders.eudiw.dev/LOTE/json/WalletProviders.jwt")
        ),
        wrpacProviders: Some(
            Uri.parse("https://trustedlist.serviceproviders.eudiw.dev/LOTE/json/WRPACProviders.jwt")
        ),
        wrprcProviders: Some(
            Uri.parse("https://trustedlist.serviceproviders.eudiw.dev/LOTE/json/WRPRCProviders.jwt")
        )
    )
}

/// Dummy DER leaf: decode/path checks fail-closed (D-100), never treated as Trusted.
public func demoUntrustedChain(): ArrayList<Array<Byte>> {
    let chain = ArrayList<Array<Byte>>()
    chain.add(Array<Byte>(1, repeat: 0))
    chain
}
