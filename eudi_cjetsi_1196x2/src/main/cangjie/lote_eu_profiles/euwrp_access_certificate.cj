package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_eu_profiles

import std.collection.*
import std.time.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*

/// Wallet Relying Party Access Certificate Profile (ETSI TS 119 411-8).
public func wrpAccessCertificateProfile(
    at!: ?DateTime = None,
    maxShortTermDuration!: Duration = Duration.day * 7
): CertificateProfile {
    certificateProfile({ builder: ProfileBuilder =>
        builder.endEntity()
        builder.keyUsageDigitalSignature()
        builder.wrpacExplicitExtensionCriticality()
        builder.validAt(at)
        builder.policyOneOf(wrpacPolicyOids())
        builder.notSelfSigned()
        builder.version3()
        builder.positiveSerialNumber()
        builder.authorityInformationAccessIfCAIssued()
        builder.requireAuthorityKeyIdentifier()
        builder.validityAssuredShortTerm(maxShortTermDuration)
        builder.wrpacSubjectAlternativeNames()
        builder.crlDistributionPointsIfNoOcspAndNotValAssured()
        builder.publicKey(eudiwSigningPublicKeyOptions())
        builder.requireQcStatementsForPolicy({ policyOid: String => wrpacRequiredQcStatements(policyOid) })
        builder.wrpacSubject()
        builder.issuerLegalPerson()
    })
}

func wrpacPolicyOids(): HashSet<String> {
    HashSet<String>([
        ETSI119411Part8.NCP_N_EUDIWRP,
        ETSI119411Part8.NCP_L_EUDIWRP,
        ETSI119411Part8.QCP_N_EUDIWRP,
        ETSI119411Part8.QCP_L_EUDIWRP
    ])
}

func wrpacRequiredQcStatements(policyOid: String): ArrayList<String> {
    let required = ArrayList<String>()
    if (policyOid == ETSI119411Part8.QCP_N_EUDIWRP) {
        required.add(ETSI319412.QC_COMPLIANCE)
        required.add(ETSI319412.QC_SSCD)
    } else if (policyOid == ETSI119411Part8.QCP_L_EUDIWRP) {
        required.add(ETSI319412.QC_COMPLIANCE)
        required.add(ETSI319412.QC_SSCD)
        required.add(ETSI319412.QC_TYPE)
    }
    required
}

extend ProfileBuilder {
    public func wrpacExplicitExtensionCriticality(): Unit {
        this.extensionCriticalityMust(true, { oid: String => basicConstraintOrKeyUsageOid(oid) })
        this.extensionCriticalityMust(false, { oid: String => !basicConstraintOrKeyUsageOid(oid) })
    }

    public func wrpacSubjectAlternativeNames(): Unit {
        this.subjectAltNames({ subjectAltNames: ?ArrayList<SubjectAlternativeName> =>
            validateSubjectAltNameForWRPAC(subjectAltNames)
        })
    }

    public func wrpacSubject(): Unit {
        this.combineTwo(
            CertificateOp.GetPolicies,
            CertificateOp.GetSubject,
            { a: OpValue, b: OpValue =>
                match (a) {
                    case OpValue.Policies(policies) =>
                        match (b) {
                            case OpValue.Name(subject) => validateSubjectForWRPAC(policies, subject)
                            case _ => profileOpMismatch("GetSubject")
                        }
                    case _ => profileOpMismatch("GetPolicies")
                }
            }
        )
    }
}

func validateSubjectAltNameForWRPAC(
    subjectAltNames: ?ArrayList<SubjectAlternativeName>
): CertificateConstraintEvaluation {
    collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
        var empty = true
        match (subjectAltNames) {
            case None => empty = true
            case Some(items) => empty = items.size == 0
        }
        if (empty) {
            violations.add(CertificateConstraintViolation("Certificate missing subjectAltName extension"))
        } else {
            match (subjectAltNames) {
                case None => ()
                case Some(items) =>
                    if (!hasWrpacContactInfo(items)) {
                        violations.add(CertificateConstraintViolation(
                            "subjectAltName extension missing required contact information (URI, email, or telephone per ETSI TS 119 411-8)"
                        ))
                    }
            }
        }
    })
}

func hasWrpacContactInfo(subjectAltNames: ArrayList<SubjectAlternativeName>): Bool {
    for (san in subjectAltNames) {
        match (san) {
            case SubjectAlternativeName.Uri(_) => return true
            case SubjectAlternativeName.Email(_) => return true
            case SubjectAlternativeName.Telephone(_) => return true
            case _ => ()
        }
    }
    false
}

func validateSubjectForWRPAC(
    policies: ?ArrayList<String>,
    subject: ?DistinguishedName
): CertificateConstraintEvaluation {
    match (policies) {
        case None => CertificateConstraintEvaluation.Met
        case Some(items) =>
            if (items.size == 0) {
                CertificateConstraintEvaluation.Met
            } else {
                let isNaturalPerson = policiesContainAny(items, [
                    ETSI119411Part8.NCP_N_EUDIWRP,
                    ETSI119411Part8.QCP_N_EUDIWRP
                ])
                let isLegalPerson = policiesContainAny(items, [
                    ETSI119411Part8.NCP_L_EUDIWRP,
                    ETSI119411Part8.QCP_L_EUDIWRP
                ])
                if (isNaturalPerson && !isLegalPerson) {
                    CertificateConstraintsEvaluations.naturalPersonDN("Subject", subject)
                } else if (isLegalPerson && !isNaturalPerson) {
                    CertificateConstraintsEvaluations.legalPersonDN("Subject", subject)
                } else {
                    CertificateConstraintEvaluation.Met
                }
            }
    }
}

func policiesContainAny(policies: ArrayList<String>, oids: Array<String>): Bool {
    for (policy in policies) {
        for (oid in oids) {
            if (policy == oid) {
                return true
            }
        }
    }
    false
}
