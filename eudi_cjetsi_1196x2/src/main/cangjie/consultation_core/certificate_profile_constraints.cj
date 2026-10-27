package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

import std.collection.*
import std.time.*

extend ProfileBuilder {
    public func endEntity(): Unit {
        this.basicConstraints({ constraints: BasicConstraintsInfo =>
            CertificateConstraintsEvaluations.isEndEntity(constraints)
        })
    }

    public func ca(maxPathLen: ?Int64): Unit {
        this.basicConstraints({ constraints: BasicConstraintsInfo =>
            CertificateConstraintsEvaluations.isCA(constraints, maxPathLen)
        })
    }

    public func mandatoryQcType(qcType: String): Unit {
        this.qcStatements(qcType, { statements: ArrayList<QCStatementInfo> =>
            CertificateConstraintsEvaluations.mandatoryQcType(statements, qcType)
        })
    }

    public func keyUsageDigitalSignature(): Unit {
        this.mandatoryKeyUsage("digitalSignature")
    }

    public func keyUsageCertSign(): Unit {
        this.mandatoryKeyUsage("keyCertSign")
    }

    public func mandatoryKeyUsage(requiredKeyUsage: String): Unit {
        this.keyUsage({ keyUsage: ?KeyUsageBits =>
            CertificateConstraintsEvaluations.mandatoryKeyUsage(keyUsage, requiredKeyUsage)
        })
    }

    public func validAt(time: ?DateTime): Unit {
        this.validity({ period: ValidityPeriod =>
            CertificateConstraintsEvaluations.validAt(period, time)
        })
    }

    public func extensionCriticalityMust(
        mustBeCritical: Bool,
        filter: (String) -> Bool
    ): Unit {
        this.extensionCriticality({ extension: HashMap<String, Bool> =>
            CertificateConstraintsEvaluations.checkCriticalExtension(extension, mustBeCritical, filter)
        })
    }

    public func policyOneOf(oids: HashSet<String>): Unit {
        this.policies({ policiesInfo: ?ArrayList<String> =>
            CertificateConstraintsEvaluations.policyOneOf(policiesInfo, oids)
        })
    }

    public func policyIsPresent(): Unit {
        this.policies({ policiesInfo: ?ArrayList<String> =>
            CertificateConstraintsEvaluations.policyIsPresent(policiesInfo)
        })
    }

    public func authorityInformationAccessIfCAIssued(): Unit {
        this.combineTwo(
            CertificateOp.GetAia,
            CertificateOp.CheckSelfSigned,
            { a: OpValue, b: OpValue =>
                match (a) {
                    case OpValue.Aia(aiaInfo) =>
                        match (b) {
                            case OpValue.Flag(selfSigned) =>
                                CertificateConstraintsEvaluations.aiaForCaIssued(aiaInfo, selfSigned)
                            case _ => mismatchCombine("CheckSelfSigned")
                        }
                    case _ => mismatchCombine("GetAia")
                }
            }
        )
    }

    public func notSelfSigned(): Unit {
        this.selfSigned({ isSelfSigned: Bool =>
            CertificateConstraintsEvaluations.notSelfSigned(isSelfSigned)
        })
    }

    public func isVersion(expectedVersion: Int64): Unit {
        this.version({ version: Version =>
            CertificateConstraintsEvaluations.isVersion(version, expectedVersion)
        })
    }

    public func version3(): Unit {
        this.isVersion(2)
    }

    public func positiveSerialNumber(): Unit {
        this.serialNumber({ serialNumber: SerialNumber =>
            CertificateConstraintsEvaluations.positiveSerialNumber(serialNumber)
        })
    }

    public func subjectNaturalPerson(): Unit {
        this.subject({ subject: ?DistinguishedName =>
            CertificateConstraintsEvaluations.naturalPersonDN("Subject", subject)
        })
    }

    public func subjectLegalPerson(): Unit {
        this.subject({ subject: ?DistinguishedName =>
            CertificateConstraintsEvaluations.legalPersonDN("Subject", subject)
        })
    }

    public func issuerNaturalPerson(): Unit {
        this.issuer({ issuer: ?DistinguishedName =>
            CertificateConstraintsEvaluations.naturalPersonDN("Issuer", issuer)
        })
    }

    public func issuerLegalPerson(): Unit {
        this.issuer({ issuer: ?DistinguishedName =>
            CertificateConstraintsEvaluations.legalPersonDN("Issuer", issuer)
        })
    }

    public func requireSubjectAltName(): Unit {
        this.subjectAltNames({ sanInfo: ?ArrayList<SubjectAlternativeName> =>
            CertificateConstraintsEvaluations.subjectAltName(sanInfo)
        })
    }

    public func requireAuthorityKeyIdentifier(): Unit {
        this.authorityKeyIdentifier({ aki: ?AuthorityKeyIdentifier =>
            CertificateConstraintsEvaluations.authorityKeyIdentifier(aki)
        })
    }

    public func requireSubjectKeyIdentifier(): Unit {
        this.subjectKeyIdentifier({ ski: ?Array<UInt8> =>
            CertificateConstraintsEvaluations.subjectKeyIdentifier(ski)
        })
    }

    public func crlDistributionPointsIfNoOcspAndNotValAssured(): Unit {
        this.combineThree(
            CertificateOp.GetCrlDistributionPoints,
            CertificateOp.GetAia,
            CertificateOp.GetAllQcStatements,
            { a: OpValue, b: OpValue, c: OpValue =>
                match (a) {
                    case OpValue.CrlDistributionPoints(crldp) =>
                        match (b) {
                            case OpValue.Aia(aiaInfo) =>
                                match (c) {
                                    case OpValue.QcStatements(qcStatements) =>
                                        CertificateConstraintsEvaluations
                                            .evaluateCrlDistributionPointsIfNoOcspAndNotValAssured(
                                                crldp,
                                                aiaInfo,
                                                qcStatements
                                            )
                                    case _ => mismatchCombine("GetAllQcStatements")
                                }
                            case _ => mismatchCombine("GetAia")
                        }
                    case _ => mismatchCombine("GetCrlDistributionPoints")
                }
            }
        )
    }

    public func requireCrlDistributionPoints(): Unit {
        this.crlDistributionPoints({ crldp: ArrayList<CrlDistributionPoint> =>
            CertificateConstraintsEvaluations.evaluateCrlDistributionPoints(crldp)
        })
    }

    public func requireQcStatementsForPolicy(rules: (String) -> ArrayList<String>): Unit {
        this.combineTwo(
            CertificateOp.GetPolicies,
            CertificateOp.GetAllQcStatements,
            { a: OpValue, b: OpValue =>
                match (a) {
                    case OpValue.Policies(policiesInfo) =>
                        match (b) {
                            case OpValue.QcStatements(qcStatements) =>
                                CertificateConstraintsEvaluations.evaluateQcStatementsForPolicy(
                                    policiesInfo,
                                    qcStatements,
                                    rules
                                )
                            case _ => mismatchCombine("GetAllQcStatements")
                        }
                    case _ => mismatchCombine("GetPolicies")
                }
            }
        )
    }

    public func publicKey(options: PublicKeyAlgorithmOptions): Unit {
        this.subjectPublicKeyInfo({ pkInfo: PublicKeyInfo =>
            CertificateConstraintsEvaluations.evaluatePublicKey(pkInfo, options)
        })
    }

    public func validityAssuredShortTerm(maxShortTermDuration: Duration): Unit {
        this.combineThree(
            CertificateOp.GetValidity,
            CertificateOp.GetAllQcStatements,
            CertificateOp.HasExtension(ETSI319412Part1.EXT_NO_REVOCATION_AVAIL),
            { a: OpValue, b: OpValue, c: OpValue =>
                match (a) {
                    case OpValue.Validity(validity) =>
                        match (b) {
                            case OpValue.QcStatements(qcStatements) =>
                                match (c) {
                                    case OpValue.Flag(hasNoRevAvail) =>
                                        CertificateConstraintsEvaluations.evaluateValidityAssuredShortTerm(
                                            maxShortTermDuration,
                                            validity,
                                            qcStatements,
                                            hasNoRevAvail
                                        )
                                    case _ => mismatchCombine("HasExtension")
                                }
                            case _ => mismatchCombine("GetAllQcStatements")
                        }
                    case _ => mismatchCombine("GetValidity")
                }
            }
        )
    }
}

func mismatchCombine(opName: String): CertificateConstraintEvaluation {
    let violations = ArrayList<CertificateConstraintViolation>()
    violations.add(CertificateConstraintViolation("Combined operation produced unexpected OpValue for ${opName}"))
    CertificateConstraintEvaluation.Violated(violations)
}
