package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_eu_profiles

import std.collection.*
import std.time.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*

/// PID Provider Signing/Sealing Certificate Profile per ETSI TS 119 412-6.
public func pidSigningCertificateProfile(at!: ?DateTime = None): CertificateProfile {
    certificateProfile({ builder: ProfileBuilder =>
        builder.version3()
        builder.endEntity()
        builder.mandatoryQcType(ETSI119412Part6.ID_ETSI_QCT_PID)
        builder.keyUsageDigitalSignature()
        builder.pidProviderExplicitExtensionCriticality()
        builder.validAt(at)
        builder.policyIsPresent()
        builder.authorityInformationAccessIfCAIssued()
        builder.positiveSerialNumber()
        builder.publicKey(eudiwSigningPublicKeyOptions())
        builder.pidProviderIssuerAndSubject()
        builder.requireSubjectKeyIdentifier()
    })
}

func eudiwSigningPublicKeyOptions(): PublicKeyAlgorithmOptions {
    let options = ArrayList<AlgorithmRequirement>()
    options.add(AlgorithmRequirement.rsa2048())
    options.add(AlgorithmRequirement.ec256())
    options.add(AlgorithmRequirement.ecdsa256())
    PublicKeyAlgorithmOptions.of(options)
}

func profileOpMismatch(opName: String): CertificateConstraintEvaluation {
    let violations = ArrayList<CertificateConstraintViolation>()
    violations.add(CertificateConstraintViolation("Combined operation produced unexpected OpValue for ${opName}"))
    CertificateConstraintEvaluation.Violated(violations)
}

func basicConstraintOrKeyUsageOid(oid: String): Bool {
    oid == RFC5280.EXT_BASIC_CONSTRAINTS || oid == RFC5280.EXT_KEY_USAGE
}

extend ProfileBuilder {
    /// ETSI TS 119 412-6, PID-4.1-02
    public func pidProviderExplicitExtensionCriticality(): Unit {
        this.extensionCriticalityMust(true, { oid: String => basicConstraintOrKeyUsageOid(oid) })
        this.extensionCriticalityMust(false, { oid: String => !basicConstraintOrKeyUsageOid(oid) })
    }

    /// ETSI TS 119 412-6, PID-4.2-01 / PID-4.3-01 / PID-4.3-02
    public func pidProviderIssuerAndSubject(): Unit {
        this.combineThree(
            CertificateOp.CheckSelfSigned,
            CertificateOp.GetIssuer,
            CertificateOp.GetSubject,
            { a: OpValue, b: OpValue, c: OpValue =>
                match (a) {
                    case OpValue.Flag(isSelfSigned) =>
                        match (b) {
                            case OpValue.Name(issuer) =>
                                match (c) {
                                    case OpValue.Name(subject) =>
                                        evaluatePidProviderIssuerAndSubject(isSelfSigned, issuer, subject)
                                    case _ => profileOpMismatch("GetSubject")
                                }
                            case _ => profileOpMismatch("GetIssuer")
                        }
                    case _ => profileOpMismatch("CheckSelfSigned")
                }
            }
        )
    }
}

func evaluatePidProviderIssuerAndSubject(
    isSelfSigned: Bool,
    issuer: ?DistinguishedName,
    subject: ?DistinguishedName
): CertificateConstraintEvaluation {
    let presence = collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
        match (issuer) {
            case None => violations.add(CertificateConstraintsEvaluations.missingDN("Issuer"))
            case Some(_) => ()
        }
        match (subject) {
            case None => violations.add(CertificateConstraintsEvaluations.missingDN("Subject"))
            case Some(_) => ()
        }
    })
    if (!evaluationIsMet(presence)) {
        return presence
    }
    match (issuer) {
        case None => presence
        case Some(issuerDn) =>
            match (subject) {
                case None => presence
                case Some(subjectDn) =>
                    if (isSelfSigned) {
                        evaluateSelfSignedPidDn(issuerDn, subjectDn)
                    } else {
                        mergeEvaluations(
                            validateLegalOrNaturalPerson("Issuer", Some(issuerDn)),
                            validateLegalOrNaturalPerson("Subject", Some(subjectDn))
                        )
                    }
            }
    }
}

func evaluateSelfSignedPidDn(
    issuerDn: DistinguishedName,
    subjectDn: DistinguishedName
): CertificateConstraintEvaluation {
    collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
        if (!distinguishedNamesEqual(issuerDn, subjectDn)) {
            violations.add(CertificateConstraintViolation(
                "Self-signed certificate must have the same issuer and subject"
            ))
        }
        let subjectEval = validateLegalOrNaturalPerson("Subject", Some(subjectDn))
        for (item in evaluationViolations(subjectEval)) {
            violations.add(item)
        }
    })
}

public func validateLegalOrNaturalPerson(
    attribute: String,
    dn: ?DistinguishedName
): CertificateConstraintEvaluation {
    match (dn) {
        case None =>
            let violations = ArrayList<CertificateConstraintViolation>()
            violations.add(CertificateConstraintsEvaluations.missingDN(attribute))
            CertificateConstraintEvaluation.Violated(violations)
        case Some(name) =>
            match (name.organization()) {
                case Some(_) => CertificateConstraintsEvaluations.legalPersonDN(attribute, Some(name))
                case None => CertificateConstraintsEvaluations.naturalPersonDN(attribute, Some(name))
            }
    }
}

func distinguishedNamesEqual(left: DistinguishedName, right: DistinguishedName): Bool {
    for ((k, v) in left.attributes) {
        match (right.attributes.get(k)) {
            case None => return false
            case Some(other) =>
                if (other != v) {
                    return false
                }
        }
    }
    for ((k, _) in right.attributes) {
        if (!left.attributes.contains(k)) {
            return false
        }
    }
    true
}

func mergeEvaluations(
    first: CertificateConstraintEvaluation,
    second: CertificateConstraintEvaluation
): CertificateConstraintEvaluation {
    collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
        for (item in evaluationViolations(first)) {
            violations.add(item)
        }
        for (item in evaluationViolations(second)) {
            violations.add(item)
        }
    })
}
