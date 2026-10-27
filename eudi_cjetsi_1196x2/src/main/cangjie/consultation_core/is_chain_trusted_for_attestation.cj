package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

import std.collection.*
import std.regex.*

public enum AttestationIdentifier <: Equatable<AttestationIdentifier> & Hashable & ToString {
    | MDoc(String)
    | SDJwtVc(String)

    public func key(): String {
        match (this) {
            case AttestationIdentifier.MDoc(docType) => "mdoc:${docType}"
            case AttestationIdentifier.SDJwtVc(vct) => "sdjwt:${vct}"
        }
    }

    public operator func ==(rhs: AttestationIdentifier): Bool {
        this.key() == rhs.key()
    }

    public operator func !=(rhs: AttestationIdentifier): Bool {
        this.key() != rhs.key()
    }

    public func hashCode(): Int64 {
        this.key().hashCode()
    }

    public override func toString(): String {
        this.key()
    }

    public func predicate(): AttestationIdentifierPredicate {
        AttestationIdentifierPredicate.equalsTo(this)
    }
}

public class AttestationIdentifierPredicate {
    private let testFn: (AttestationIdentifier) -> Bool

    public init(testFn: (AttestationIdentifier) -> Bool) {
        this.testFn = testFn
    }

    public func test(identifier: AttestationIdentifier): Bool {
        this.testFn(identifier)
    }

    public func or(other: AttestationIdentifierPredicate): AttestationIdentifierPredicate {
        AttestationIdentifierPredicate({ identifier: AttestationIdentifier =>
            this.test(identifier) || other.test(identifier)
        })
    }

    public static func none(): AttestationIdentifierPredicate {
        AttestationIdentifierPredicate({ _: AttestationIdentifier => false })
    }

    public static func equalsTo(identifier: AttestationIdentifier): AttestationIdentifierPredicate {
        AttestationIdentifierPredicate({ other: AttestationIdentifier => other == identifier })
    }

    public static func any(identifiers: HashSet<AttestationIdentifier>): AttestationIdentifierPredicate {
        AttestationIdentifierPredicate({ identifier: AttestationIdentifier => identifiers.contains(identifier) })
    }

    public static func mdocMatching(regex: Regex): AttestationIdentifierPredicate {
        AttestationIdentifierPredicate({ identifier: AttestationIdentifier =>
            match (identifier) {
                case AttestationIdentifier.MDoc(docType) => entireMatch(regex, docType)
                case _ => false
            }
        })
    }

    public static func sdJwtVcMatching(regex: Regex): AttestationIdentifierPredicate {
        AttestationIdentifierPredicate({ identifier: AttestationIdentifier =>
            match (identifier) {
                case AttestationIdentifier.SDJwtVc(vct) => entireMatch(regex, vct)
                case _ => false
            }
        })
    }
}

public enum AttestationMatch <: Equatable<AttestationMatch> & ToString {
    | PID
    | PubEAA
    | QEAA
    | EAA(String)

    public func key(): String {
        match (this) {
            case AttestationMatch.PID => "PID"
            case AttestationMatch.PubEAA => "PubEAA"
            case AttestationMatch.QEAA => "QEAA"
            case AttestationMatch.EAA(useCase) => "EAA:${useCase}"
        }
    }

    public operator func ==(rhs: AttestationMatch): Bool {
        this.key() == rhs.key()
    }

    public operator func !=(rhs: AttestationMatch): Bool {
        this.key() != rhs.key()
    }

    public override func toString(): String {
        this.key()
    }
}

public class AttestationClassifications {
    public let pids: AttestationIdentifierPredicate
    public let pubEAAs: AttestationIdentifierPredicate
    public let qEAAs: AttestationIdentifierPredicate
    public let eaAs: HashMap<String, AttestationIdentifierPredicate>

    public init(
        pids!: AttestationIdentifierPredicate = AttestationIdentifierPredicate.none(),
        pubEAAs!: AttestationIdentifierPredicate = AttestationIdentifierPredicate.none(),
        qEAAs!: AttestationIdentifierPredicate = AttestationIdentifierPredicate.none(),
        eaAs!: HashMap<String, AttestationIdentifierPredicate> = HashMap<String, AttestationIdentifierPredicate>()
    ) {
        this.pids = pids
        this.pubEAAs = pubEAAs
        this.qEAAs = qEAAs
        this.eaAs = eaAs
    }

    public func matchIdentifier(identifier: AttestationIdentifier): ArrayList<AttestationMatch> {
        let matches = ArrayList<AttestationMatch>()
        if (this.pids.test(identifier)) {
            matches.add(AttestationMatch.PID)
        }
        if (this.pubEAAs.test(identifier)) {
            matches.add(AttestationMatch.PubEAA)
        }
        if (this.qEAAs.test(identifier)) {
            matches.add(AttestationMatch.QEAA)
        }
        for ((useCase, predicate) in this.eaAs) {
            if (predicate.test(identifier)) {
                matches.add(AttestationMatch.EAA(useCase))
            }
        }
        matches
    }

    public func classify(identifier: AttestationIdentifier): ?AttestationMatch {
        let matches = this.matchIdentifier(identifier)
        if (matches.size > 1) {
            throw Exception("AttestationIdentifier ${identifier.toString()} matches multiple predicates")
        }
        if (matches.size == 0) {
            None
        } else {
            matches[0]
        }
    }
}

/// Maps attestation identifiers onto VerificationContext, then delegates to IsChainTrustedForEUDIW.
public class IsChainTrustedForAttestation<CHAIN, TRUST_ANCHOR> {
    private let isChainTrustedForEUDIW: IsChainTrustedForEUDIW<CHAIN, TRUST_ANCHOR>
    private let classifications: AttestationClassifications

    public init(
        isChainTrustedForEUDIW: IsChainTrustedForEUDIW<CHAIN, TRUST_ANCHOR>,
        classifications: AttestationClassifications
    ) {
        this.isChainTrustedForEUDIW = isChainTrustedForEUDIW
        this.classifications = classifications
    }

    public func issuance(
        chain: CHAIN,
        identifier: AttestationIdentifier
    ): ?CertificationChainValidation<TRUST_ANCHOR> {
        match (this.issuanceOf(identifier)) {
            case None => None
            case Some(ctx) => this.isChainTrustedForEUDIW.invoke(chain, ctx)
        }
    }

    public func revocation(
        chain: CHAIN,
        identifier: AttestationIdentifier
    ): ?CertificationChainValidation<TRUST_ANCHOR> {
        match (this.revocationContextOf(identifier)) {
            case None => None
            case Some(ctx) => this.isChainTrustedForEUDIW.invoke(chain, ctx)
        }
    }

    private func issuanceOf(identifier: AttestationIdentifier): ?VerificationContext {
        match (this.classifications.classify(identifier)) {
            case None => None
            case Some(matched) => Some(foldIssuance(matched))
        }
    }

    private func revocationContextOf(identifier: AttestationIdentifier): ?VerificationContext {
        match (this.classifications.classify(identifier)) {
            case None => None
            case Some(matched) => Some(foldRevocation(matched))
        }
    }
}

func foldIssuance(matched: AttestationMatch): VerificationContext {
    match (matched) {
        case AttestationMatch.PID => VerificationContext.PID
        case AttestationMatch.PubEAA => VerificationContext.PubEAA
        case AttestationMatch.QEAA => VerificationContext.QEAA
        case AttestationMatch.EAA(useCase) => VerificationContext.EAA(useCase)
    }
}

func foldRevocation(matched: AttestationMatch): VerificationContext {
    match (matched) {
        case AttestationMatch.PID => VerificationContext.PIDStatus
        case AttestationMatch.PubEAA => VerificationContext.PubEAAStatus
        case AttestationMatch.QEAA => VerificationContext.QEAAStatus
        case AttestationMatch.EAA(useCase) => VerificationContext.EAAStatus(useCase)
    }
}

func entireMatch(regex: Regex, input: String): Bool {
    match (regex.find(input, group: true)) {
        case None => false
        case Some(md) =>
            let pos = md.matchPosition()
            pos.start == 0 && pos.end == input.size
    }
}
