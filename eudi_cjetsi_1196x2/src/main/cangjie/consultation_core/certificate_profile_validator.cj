package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

import std.collection.*

public interface CertificateProfileInterpreter<CERT> {
    func interpret(op: CertificateOp, certificate: CERT): OpValue
}

public interface CertificateProfileValidator<CERT> {
    func validateConstraint(constraint: CertificateConstraint, certificate: CERT): CertificateConstraintEvaluation
    func validate(profile: CertificateProfile, certificate: CERT): CertificateConstraintEvaluation
    func validateAll(
        profile: CertificateProfile,
        certificates: ArrayList<CERT>,
        getCertificateInfo: (CERT) -> String
    ): HashMap<String, CertificateConstraintEvaluation>
    func ensureAllMet(
        profile: CertificateProfile,
        certificates: ArrayList<CERT>,
        getCertificateInfo: (CERT) -> String
    ): Unit
}

public class OperationsCertificateProfileInterpreter<CERT> <: CertificateProfileInterpreter<CERT> {
    private let operations: CertificateOperations<CERT>
    private let platform: ConsultationPlatform

    public init(operations: CertificateOperations<CERT>, platform: ConsultationPlatform) {
        this.operations = operations
        this.platform = platform
    }

    public func interpret(op: CertificateOp, certificate: CERT): OpValue {
        this.platform.runIo({ =>
            interpretCertificateOp(op, certificate, this.operations)
        })
    }
}

public class DefaultCertificateProfileValidator<CERT> <: CertificateProfileValidator<CERT> {
    private let interpreter: CertificateProfileInterpreter<CERT>

    public init(interpreter: CertificateProfileInterpreter<CERT>) {
        this.interpreter = interpreter
    }

    public static func fromOperations(
        operations: CertificateOperations<CERT>
    ): DefaultCertificateProfileValidator<CERT> {
        DefaultCertificateProfileValidator<CERT>(
            OperationsCertificateProfileInterpreter<CERT>(operations, consultationPlatform())
        )
    }

    public static func fromOperationsOn(
        operations: CertificateOperations<CERT>,
        platform: ConsultationPlatform
    ): DefaultCertificateProfileValidator<CERT> {
        DefaultCertificateProfileValidator<CERT>(
            OperationsCertificateProfileInterpreter<CERT>(operations, platform)
        )
    }

    public func validateConstraint(
        constraint: CertificateConstraint,
        certificate: CERT
    ): CertificateConstraintEvaluation {
        constraint.evaluate(this.interpreter.interpret(constraint.op, certificate))
    }

    public func validate(profile: CertificateProfile, certificate: CERT): CertificateConstraintEvaluation {
        let violations = ArrayList<CertificateConstraintViolation>()
        for (constraint in profile.requirements) {
            let evaluated = this.validateConstraint(constraint, certificate)
            if (!evaluationIsMet(evaluated)) {
                let items = evaluationViolations(evaluated)
                for (item in items) {
                    violations.add(item)
                }
            }
        }
        evaluationFromViolations(violations)
    }

    public func validateAll(
        profile: CertificateProfile,
        certificates: ArrayList<CERT>,
        getCertificateInfo: (CERT) -> String
    ): HashMap<String, CertificateConstraintEvaluation> {
        let results = HashMap<String, CertificateConstraintEvaluation>()
        for (certificate in certificates) {
            results.add(getCertificateInfo(certificate), this.validate(profile, certificate))
        }
        results
    }

    public func ensureAllMet(
        profile: CertificateProfile,
        certificates: ArrayList<CERT>,
        getCertificateInfo: (CERT) -> String
    ): Unit {
        let all = this.validateAll(profile, certificates, getCertificateInfo)
        var failedCount: Int64 = 0
        var message = ""
        for ((certInfo, evaluation) in all) {
            match (evaluation) {
                case CertificateConstraintEvaluation.Met => ()
                case CertificateConstraintEvaluation.Violated(items) =>
                    failedCount = failedCount + 1
                    message = message + "- Certificate: ${certInfo}\n- Violations: \n"
                    var index: Int64 = 1
                    for (violation in items) {
                        message = message + "  ${index}. ${violation.reason}\n"
                        index = index + 1
                    }
            }
        }
        if (failedCount > 0) {
            throw Exception("Profile violations on ${failedCount} anchors\n${message}")
        }
    }
}
