package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation_platform

import std.collection.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_platform.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.pkix_bridge.PKIXConfiguration

/// Default conversion of a ServiceDigitalIdentity into OHOS trust anchors (DER).
/// Mirrors Kotlin defaultCreateTrustAnchorsIos (NSData of PKIObject.value).
public func defaultCreateTrustAnchorsIos(
    serviceDigitalIdentity: ServiceDigitalIdentity
): ArrayList<Array<Byte>> {
    defaultCreateTrustAnchors(serviceDigitalIdentity)
}

func iosPkix(): ValidateCertificateChainUsingPKIXIos {
    ValidateCertificateChainUsingPKIXIos(
        configuration: PKIXConfiguration(isRevocationEnabled: false)
    )
}

/// Generic iOS-named factory. On OHOS this wraps JVM/stdx actuals, not SecTrust.
public func ios<CTX>(
    loadLoTEAndPointers: LoadLoTEAndPointers,
    svcTypePerCtx: SupportedLists<LotEMeta<CTX>>,
    createTrustAnchors!: (ServiceDigitalIdentity) -> ArrayList<Array<Byte>> = defaultCreateTrustAnchorsIos,
    continueOnProblem!: ContinueOnProblem = ContinueOnProblem.never(),
    directTrust!: ValidateCertificateChain<ArrayList<Array<Byte>>, Array<Byte>> =
        ValidateCertificateChainUsingDirectTrustIos,
    pkix!: ValidateCertificateChain<ArrayList<Array<Byte>>, Array<Byte>> = iosPkix()
): ProvisionTrustAnchorsFromLoTEs<ArrayList<Array<Byte>>, CTX, Array<Byte>, Array<Byte>>
    where CTX <: Equatable<CTX> & Hashable {
    ProvisionTrustAnchorsFromLoTEs<ArrayList<Array<Byte>>, CTX, Array<Byte>, Array<Byte>>(
        loadLoTEAndPointers,
        svcTypePerCtx,
        createTrustAnchors,
        directTrust,
        pkix,
        certificateProfileValidatorIos(),
        endEntityDerOf,
        continueOnProblem: continueOnProblem
    )
}

/// ProvisionTrustAnchorsFromLoTEs.eudiwIos — iOS-named helper kept as an OHOS wrapper
/// around the same DER client as eudiwJvm (no Security.framework).
public func eudiwIos(
    loadLoTEAndPointers: LoadLoTEAndPointers,
    svcTypePerCtx!: SupportedLists<LotEMeta<VerificationContext>> = euSupportedLists(),
    continueOnProblem!: ContinueOnProblem = ContinueOnProblem.never(),
    directTrust!: ValidateCertificateChain<ArrayList<Array<Byte>>, Array<Byte>> =
        ValidateCertificateChainUsingDirectTrustIos,
    pkix!: ValidateCertificateChain<ArrayList<Array<Byte>>, Array<Byte>> = iosPkix()
): ProvisionTrustAnchorsFromLoTEs<ArrayList<Array<Byte>>, VerificationContext, Array<Byte>, Array<Byte>> {
    ProvisionTrustAnchorsFromLoTEs<ArrayList<Array<Byte>>, VerificationContext, Array<Byte>, Array<Byte>>.eudiw(
        loadLoTEAndPointers,
        defaultCreateTrustAnchorsIos,
        directTrust,
        pkix,
        certificateProfileValidatorIos(),
        endEntityDerOf,
        svcTypePerCtx: svcTypePerCtx,
        continueOnProblem: continueOnProblem
    )
}
