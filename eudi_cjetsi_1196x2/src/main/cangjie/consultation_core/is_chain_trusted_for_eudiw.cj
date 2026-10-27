package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

import std.collection.*

/// EUDI Wallet verification contexts. Custom/EAA variants carry a use-case string.
public enum VerificationContext <: Equatable<VerificationContext> & Hashable & ToString {
    | WalletProviderAttestation
    | WalletOrKeyStorageStatus
    | PID
    | PIDStatus
    | PubEAA
    | PubEAAStatus
    | QEAA
    | QEAAStatus
    | EAA(String)
    | EAAStatus(String)
    | WalletRelyingPartyRegistrationCertificate
    | WalletRelyingPartyRegistrationCertificateStatus
    | WalletRelyingPartyAccessCertificate
    | Custom(String)

    public func key(): String {
        match (this) {
            case VerificationContext.WalletProviderAttestation => "WalletProviderAttestation"
            case VerificationContext.WalletOrKeyStorageStatus => "WalletOrKeyStorageStatus"
            case VerificationContext.PID => "PID"
            case VerificationContext.PIDStatus => "PIDStatus"
            case VerificationContext.PubEAA => "PubEAA"
            case VerificationContext.PubEAAStatus => "PubEAAStatus"
            case VerificationContext.QEAA => "QEAA"
            case VerificationContext.QEAAStatus => "QEAAStatus"
            case VerificationContext.EAA(useCase) => "EAA:${useCase}"
            case VerificationContext.EAAStatus(useCase) => "EAAStatus:${useCase}"
            case VerificationContext.WalletRelyingPartyRegistrationCertificate =>
                "WalletRelyingPartyRegistrationCertificate"
            case VerificationContext.WalletRelyingPartyRegistrationCertificateStatus =>
                "WalletRelyingPartyRegistrationCertificateStatus"
            case VerificationContext.WalletRelyingPartyAccessCertificate => "WalletRelyingPartyAccessCertificate"
            case VerificationContext.Custom(useCase) => "Custom:${useCase}"
        }
    }

    public operator func ==(rhs: VerificationContext): Bool {
        this.key() == rhs.key()
    }

    public operator func !=(rhs: VerificationContext): Bool {
        this.key() != rhs.key()
    }

    public func hashCode(): Int64 {
        this.key().hashCode()
    }

    public override func toString(): String {
        this.key()
    }
}

/// Orchestrator alias: ComposeChainTrust specialized to VerificationContext.
/// Downstream code injects GetTrustAnchors without knowing LoTE vs LOTL.
public type IsChainTrustedForEUDIW<CHAIN, TRUST_ANCHOR> =
    IsChainTrustedForContextF<CHAIN, VerificationContext, TRUST_ANCHOR>

public class SupportedLists<INFO> {
    public let pidProviders: ?INFO
    public let walletProviders: ?INFO
    public let wrpacProviders: ?INFO
    public let wrprcProviders: ?INFO
    public let pubEaaProviders: ?INFO
    public let qeaProviders: ?INFO
    public let eaaProviders: HashMap<String, INFO>

    public init(
        pidProviders!: ?INFO = None,
        walletProviders!: ?INFO = None,
        wrpacProviders!: ?INFO = None,
        wrprcProviders!: ?INFO = None,
        pubEaaProviders!: ?INFO = None,
        qeaProviders!: ?INFO = None,
        eaaProviders!: HashMap<String, INFO> = HashMap<String, INFO>()
    ) {
        this.pidProviders = pidProviders
        this.walletProviders = walletProviders
        this.wrpacProviders = wrpacProviders
        this.wrprcProviders = wrprcProviders
        this.pubEaaProviders = pubEaaProviders
        this.qeaProviders = qeaProviders
        this.eaaProviders = eaaProviders
    }

    public func toList(): ArrayList<INFO> {
        let out = ArrayList<INFO>()
        addIfSome(out, this.pidProviders)
        addIfSome(out, this.walletProviders)
        addIfSome(out, this.wrpacProviders)
        addIfSome(out, this.wrprcProviders)
        addIfSome(out, this.pubEaaProviders)
        addIfSome(out, this.qeaProviders)
        for ((_, value) in this.eaaProviders) {
            out.add(value)
        }
        out
    }

    public static func combine<L1, L2, L3>(
        s1: SupportedLists<L1>,
        s2: SupportedLists<L2>,
        combineFn: (L1, L2) -> L3
    ): SupportedLists<L3> {
        let eaa = HashMap<String, L3>()
        for ((useCase, l1) in s1.eaaProviders) {
            match (s2.eaaProviders.get(useCase)) {
                case Some(l2) => eaa.add(useCase, combineFn(l1, l2))
                case None => ()
            }
        }
        SupportedLists<L3>(
            pidProviders: combineNullables(s1.pidProviders, s2.pidProviders, combineFn),
            walletProviders: combineNullables(s1.walletProviders, s2.walletProviders, combineFn),
            wrpacProviders: combineNullables(s1.wrpacProviders, s2.wrpacProviders, combineFn),
            wrprcProviders: combineNullables(s1.wrprcProviders, s2.wrprcProviders, combineFn),
            pubEaaProviders: combineNullables(s1.pubEaaProviders, s2.pubEaaProviders, combineFn),
            qeaProviders: combineNullables(s1.qeaProviders, s2.qeaProviders, combineFn),
            eaaProviders: eaa
        )
    }
}

func addIfSome<INFO>(out: ArrayList<INFO>, value: ?INFO): Unit {
    match (value) {
        case Some(item) => out.add(item)
        case None => ()
    }
}

func combineNullables<A, B, C>(a: ?A, b: ?B, combineFn: (A, B) -> C): ?C {
    match (a) {
        case None => None
        case Some(na) =>
            match (b) {
                case None => None
                case Some(nb) => Some(combineFn(na, nb))
            }
    }
}
