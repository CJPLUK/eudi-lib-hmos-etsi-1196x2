package ohos_app_cangjie_eudi_cjetsi_1196x2.etsi_trust

import std.collection.HashMap
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.VerificationContext
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation_platform.EudiwIosTrust

/**
 * iOS `EtsiContextType`. Wallet-kit maps a document type string onto one of
 * these, then `EtsiTrustManager` asks LoTE / bundled anchors for that context.
 */
public enum EtsiContextType <: Equatable<EtsiContextType> & Hashable {
    | PID
    | MDL
    | Wallet
    | WRPAC
    | WRPRC

    public func key(): String {
        match (this) {
            case EtsiContextType.PID => "PID"
            case EtsiContextType.MDL => "mDL"
            case EtsiContextType.Wallet => "Wallet"
            case EtsiContextType.WRPAC => "WRPAC"
            case EtsiContextType.WRPRC => "WRPRC"
        }
    }

    public operator func ==(rhs: EtsiContextType): Bool {
        this.key() == rhs.key()
    }

    public operator func !=(rhs: EtsiContextType): Bool {
        this.key() != rhs.key()
    }

    public func hashCode(): Int64 {
        this.key().hashCode()
    }

    public func verificationContext(): VerificationContext {
        match (this) {
            case EtsiContextType.PID => VerificationContext.PID
            case EtsiContextType.MDL => VerificationContext.EAA(EudiwIosTrust.mdlUseCase)
            case EtsiContextType.Wallet => VerificationContext.WalletProviderAttestation
            case EtsiContextType.WRPAC => VerificationContext.WalletRelyingPartyAccessCertificate
            case EtsiContextType.WRPRC => VerificationContext.WalletRelyingPartyRegistrationCertificate
        }
    }
}

/** iOS `EtsiContextTypeMappings` (`OrderedDictionary<String, EtsiContextType>`). */
public type EtsiContextTypeMappings = HashMap<String, EtsiContextType>

/** iOS `EtsiContextTypeMappings.default`. */
public func defaultEtsiContextTypeMappings(): EtsiContextTypeMappings {
    let map = HashMap<String, EtsiContextType>()
    map.add("eu.europa.ec.eudi.pid.1", EtsiContextType.PID)
    map.add("urn:eudi:pid:1", EtsiContextType.PID)
    map.add("org.iso.18013.5.1.mDL", EtsiContextType.MDL)
    return map
}
