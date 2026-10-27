package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

import std.collection.*

public class CertificateConstraintViolation {
    public let reason: String

    public init(reason: String) {
        this.reason = reason
    }
}

public enum CertificateConstraintEvaluation {
    | Met
    | Violated(ArrayList<CertificateConstraintViolation>)
}

public func evaluationIsMet(evaluation: CertificateConstraintEvaluation): Bool {
    match (evaluation) {
        case CertificateConstraintEvaluation.Met => true
        case CertificateConstraintEvaluation.Violated(_) => false
    }
}

public func evaluationViolations(evaluation: CertificateConstraintEvaluation): ArrayList<CertificateConstraintViolation> {
    match (evaluation) {
        case CertificateConstraintEvaluation.Met => ArrayList<CertificateConstraintViolation>()
        case CertificateConstraintEvaluation.Violated(items) => items
    }
}

public func evaluationFromViolations(
    violations: ArrayList<CertificateConstraintViolation>
): CertificateConstraintEvaluation {
    if (violations.size == 0) {
        CertificateConstraintEvaluation.Met
    } else {
        CertificateConstraintEvaluation.Violated(violations)
    }
}

public func collectEvaluation(
    build: (ArrayList<CertificateConstraintViolation>) -> Unit
): CertificateConstraintEvaluation {
    let violations = ArrayList<CertificateConstraintViolation>()
    build(violations)
    evaluationFromViolations(violations)
}

public class CertificateConstraint {
    public let op: CertificateOp
    public let evaluate: (OpValue) -> CertificateConstraintEvaluation

    public init(op: CertificateOp, evaluate: (OpValue) -> CertificateConstraintEvaluation) {
        this.op = op
        this.evaluate = evaluate
    }
}

public class CertificateProfile {
    public let requirements: ArrayList<CertificateConstraint>

    public init(requirements: ArrayList<CertificateConstraint>) {
        this.requirements = requirements
    }
}

public class ProfileBuilder {
    public let requirements = ArrayList<CertificateConstraint>()

    public func addConstraint(constraint: CertificateConstraint): Unit {
        this.requirements.add(constraint)
    }

    public func basicConstraints(evaluate: (BasicConstraintsInfo) -> CertificateConstraintEvaluation): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.GetBasicConstraints,
            { value: OpValue =>
                match (value) {
                    case OpValue.BasicConstraints(info) => evaluate(info)
                    case _ => mismatchEvaluation("GetBasicConstraints")
                }
            }
        ))
    }

    public func keyUsage(evaluate: (?KeyUsageBits) -> CertificateConstraintEvaluation): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.GetKeyUsage,
            { value: OpValue =>
                match (value) {
                    case OpValue.KeyUsage(bits) => evaluate(bits)
                    case _ => mismatchEvaluation("GetKeyUsage")
                }
            }
        ))
    }

    public func validity(evaluate: (ValidityPeriod) -> CertificateConstraintEvaluation): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.GetValidity,
            { value: OpValue =>
                match (value) {
                    case OpValue.Validity(period) => evaluate(period)
                    case _ => mismatchEvaluation("GetValidity")
                }
            }
        ))
    }

    public func policies(evaluate: (?ArrayList<String>) -> CertificateConstraintEvaluation): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.GetPolicies,
            { value: OpValue =>
                match (value) {
                    case OpValue.Policies(items) => evaluate(items)
                    case _ => mismatchEvaluation("GetPolicies")
                }
            }
        ))
    }

    public func selfSigned(evaluate: (Bool) -> CertificateConstraintEvaluation): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.CheckSelfSigned,
            { value: OpValue =>
                match (value) {
                    case OpValue.Flag(flag) => evaluate(flag)
                    case _ => mismatchEvaluation("CheckSelfSigned")
                }
            }
        ))
    }

    public func aia(evaluate: (?AuthorityInformationAccess) -> CertificateConstraintEvaluation): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.GetAia,
            { value: OpValue =>
                match (value) {
                    case OpValue.Aia(info) => evaluate(info)
                    case _ => mismatchEvaluation("GetAia")
                }
            }
        ))
    }

    public func qcStatements(
        qcType: String,
        evaluate: (ArrayList<QCStatementInfo>) -> CertificateConstraintEvaluation
    ): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.GetQcStatements(qcType),
            { value: OpValue =>
                match (value) {
                    case OpValue.QcStatements(items) => evaluate(items)
                    case _ => mismatchEvaluation("GetQcStatements")
                }
            }
        ))
    }

    public func subject(evaluate: (?DistinguishedName) -> CertificateConstraintEvaluation): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.GetSubject,
            { value: OpValue =>
                match (value) {
                    case OpValue.Name(name) => evaluate(name)
                    case _ => mismatchEvaluation("GetSubject")
                }
            }
        ))
    }

    public func issuer(evaluate: (?DistinguishedName) -> CertificateConstraintEvaluation): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.GetIssuer,
            { value: OpValue =>
                match (value) {
                    case OpValue.Name(name) => evaluate(name)
                    case _ => mismatchEvaluation("GetIssuer")
                }
            }
        ))
    }

    public func subjectAltNames(
        evaluate: (?ArrayList<SubjectAlternativeName>) -> CertificateConstraintEvaluation
    ): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.GetSubjectAltNames,
            { value: OpValue =>
                match (value) {
                    case OpValue.SubjectAltNames(items) => evaluate(items)
                    case _ => mismatchEvaluation("GetSubjectAltNames")
                }
            }
        ))
    }

    public func crlDistributionPoints(
        evaluate: (ArrayList<CrlDistributionPoint>) -> CertificateConstraintEvaluation
    ): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.GetCrlDistributionPoints,
            { value: OpValue =>
                match (value) {
                    case OpValue.CrlDistributionPoints(items) => evaluate(items)
                    case _ => mismatchEvaluation("GetCrlDistributionPoints")
                }
            }
        ))
    }

    public func authorityKeyIdentifier(
        evaluate: (?AuthorityKeyIdentifier) -> CertificateConstraintEvaluation
    ): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.GetAuthorityKeyIdentifier,
            { value: OpValue =>
                match (value) {
                    case OpValue.AuthorityKeyId(aki) => evaluate(aki)
                    case _ => mismatchEvaluation("GetAuthorityKeyIdentifier")
                }
            }
        ))
    }

    public func subjectKeyIdentifier(evaluate: (?Array<UInt8>) -> CertificateConstraintEvaluation): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.GetSubjectKeyIdentifier,
            { value: OpValue =>
                match (value) {
                    case OpValue.SubjectKeyId(ski) => evaluate(ski)
                    case _ => mismatchEvaluation("GetSubjectKeyIdentifier")
                }
            }
        ))
    }

    public func serialNumber(evaluate: (SerialNumber) -> CertificateConstraintEvaluation): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.GetSerialNumber,
            { value: OpValue =>
                match (value) {
                    case OpValue.Serial(sn) => evaluate(sn)
                    case _ => mismatchEvaluation("GetSerialNumber")
                }
            }
        ))
    }

    public func version(evaluate: (Version) -> CertificateConstraintEvaluation): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.GetVersion,
            { value: OpValue =>
                match (value) {
                    case OpValue.CertVersion(ver) => evaluate(ver)
                    case _ => mismatchEvaluation("GetVersion")
                }
            }
        ))
    }

    public func subjectPublicKeyInfo(check: (PublicKeyInfo) -> CertificateConstraintEvaluation): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.GetSubjectPublicKeyInfo,
            { value: OpValue =>
                match (value) {
                    case OpValue.PublicKey(info) => check(info)
                    case _ => mismatchEvaluation("GetSubjectPublicKeyInfo")
                }
            }
        ))
    }

    public func extensionCriticality(check: (HashMap<String, Bool>) -> CertificateConstraintEvaluation): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.GetExtensionCriticality,
            { value: OpValue =>
                match (value) {
                    case OpValue.Criticality(map) => check(map)
                    case _ => mismatchEvaluation("GetExtensionCriticality")
                }
            }
        ))
    }

    public func combineTwo(
        first: CertificateOp,
        second: CertificateOp,
        evaluate: (OpValue, OpValue) -> CertificateConstraintEvaluation
    ): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.CombineTwo(first, second),
            { value: OpValue =>
                match (value) {
                    case OpValue.Pair(a, b) => evaluate(a, b)
                    case _ => mismatchEvaluation("CombineTwo")
                }
            }
        ))
    }

    public func combineThree(
        first: CertificateOp,
        second: CertificateOp,
        third: CertificateOp,
        evaluate: (OpValue, OpValue, OpValue) -> CertificateConstraintEvaluation
    ): Unit {
        this.addConstraint(CertificateConstraint(
            CertificateOp.CombineThree(first, second, third),
            { value: OpValue =>
                match (value) {
                    case OpValue.Triple(a, b, c) => evaluate(a, b, c)
                    case _ => mismatchEvaluation("CombineThree")
                }
            }
        ))
    }

    public func toProfile(): CertificateProfile {
        let copy = ArrayList<CertificateConstraint>()
        for (item in this.requirements) {
            copy.add(item)
        }
        CertificateProfile(copy)
    }
}

public func certificateProfile(builder: (ProfileBuilder) -> Unit): CertificateProfile {
    let profileBuilder = ProfileBuilder()
    builder(profileBuilder)
    profileBuilder.toProfile()
}

func mismatchEvaluation(opName: String): CertificateConstraintEvaluation {
    let violations = ArrayList<CertificateConstraintViolation>()
    violations.add(CertificateConstraintViolation("Interpreter produced unexpected OpValue for ${opName}"))
    CertificateConstraintEvaluation.Violated(violations)
}
