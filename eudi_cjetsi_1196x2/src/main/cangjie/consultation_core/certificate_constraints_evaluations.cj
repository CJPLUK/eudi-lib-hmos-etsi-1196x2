package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

import std.collection.*
import std.regex.*
import std.time.*

public class CertificateConstraintsEvaluations {
    public static func isEndEntity(constraints: BasicConstraintsInfo): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            if (constraints.isCa) {
                violations.add(CertificateConstraintsEvaluations.certificateTypeMismatch("end-entity", "CA"))
            }
        })
    }

    public static func isCA(
        constraints: BasicConstraintsInfo,
        maxPathLen: ?Int64
    ): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            if (!constraints.isCa) {
                violations.add(CertificateConstraintsEvaluations.certificateTypeMismatch("CA", "end-entity"))
            }
            if (constraints.isCa) {
                match (maxPathLen) {
                    case None => ()
                    case Some(maxLen) =>
                        match (constraints.pathLenConstraint) {
                            case None =>
                                violations.add(CertificateConstraintsEvaluations.caCertificateMissingPathLenConstraint())
                            case Some(actual) =>
                                if (actual > maxLen) {
                                    violations.add(
                                        CertificateConstraintsEvaluations.certificatePathLenExceedsMaximum(maxLen, actual)
                                    )
                                }
                        }
                }
            }
        })
    }

    public static func mandatoryQcType(
        statements: ArrayList<QCStatementInfo>,
        qcType: String
    ): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            if (statements.size == 0) {
                violations.add(CertificateConstraintsEvaluations.certificateDoesNotContainAnyQCStatement())
            } else if (!CertificateConstraintsEvaluations.containsQcType(statements, qcType)) {
                violations.add(
                    CertificateConstraintsEvaluations.certificateDoesNotContainRequiredQCStatement(qcType, statements)
                )
            }
        })
    }

    public static func mandatoryKeyUsage(
        keyUsage: ?KeyUsageBits,
        requiredKeyUsage: String
    ): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            match (keyUsage) {
                case None =>
                    violations.add(CertificateConstraintsEvaluations.certificateDoesNotContainKeyUsage())
                case Some(bits) =>
                    if (!bits.bitNamed(requiredKeyUsage)) {
                        violations.add(CertificateConstraintsEvaluations.certificateMissingKeyUsage(requiredKeyUsage))
                    }
            }
        })
    }

    public static func validAt(period: ValidityPeriod, time: ?DateTime): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            let validationTime = match (time) {
                case Some(t) => t
                case None => DateTime.nowUTC()
            }
            match (validationTime.compare(period.notBefore)) {
                case Ordering.LT =>
                    violations.add(CertificateConstraintViolation(
                        "Certificate is not yet valid. Valid from: ${period.notBefore.toString()}, current time: ${validationTime.toString()}"
                    ))
                case _ => ()
            }
            match (validationTime.compare(period.notAfter)) {
                case Ordering.GT =>
                    violations.add(CertificateConstraintViolation(
                        "Certificate has expired. Valid until: ${period.notAfter.toString()}, current time: ${validationTime.toString()}"
                    ))
                case _ => ()
            }
        })
    }

    public static func policyOneOf(
        policies: ?ArrayList<String>,
        oids: HashSet<String>
    ): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            match (policies) {
                case None =>
                    violations.add(CertificateConstraintsEvaluations.certificateDoesNotContainPolicies(oids))
                case Some(items) =>
                    if (items.size == 0) {
                        violations.add(CertificateConstraintsEvaluations.certificateDoesNotContainPolicies(oids))
                    } else if (!CertificateConstraintsEvaluations.policiesIntersect(items, oids)) {
                        violations.add(CertificateConstraintsEvaluations.certificateDoesNotContainAnyPolicy(items, oids))
                    }
            }
        })
    }

    public static func policyIsPresent(policies: ?ArrayList<String>): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            var missing = true
            match (policies) {
                case None => missing = true
                case Some(items) => missing = items.size == 0
            }
            if (missing) {
                violations.add(CertificateConstraintsEvaluations.missingCertificatePoliciesExtension())
            }
        })
    }

    public static func aiaForCaIssued(
        aia: ?AuthorityInformationAccess,
        isSelfSigned: Bool
    ): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            if (!isSelfSigned) {
                match (aia) {
                    case None =>
                        violations.add(CertificateConstraintsEvaluations.caIssuedCertificateMissingAiaExtension())
                    case Some(info) =>
                        match (info.caIssuersUri) {
                            case None =>
                                violations.add(CertificateConstraintsEvaluations.aiaMissingIdAdCaIssuersAccessMethod())
                            case Some(_) => ()
                        }
                }
            }
        })
    }

    public static func notSelfSigned(isSelfSigned: Bool): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            if (isSelfSigned) {
                violations.add(CertificateConstraintsEvaluations.selfSignedCertificateNotAllowed())
            }
        })
    }

    public static func isVersion(version: Version, expectedVersion: Int64): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            if (version.value != expectedVersion) {
                violations.add(
                    CertificateConstraintsEvaluations.certificateVersionMismatch(expectedVersion, version.value)
                )
            }
        })
    }

    public static func positiveSerialNumber(serialNumber: SerialNumber): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            if (serialNumber.value.size == 0) {
                violations.add(CertificateConstraintsEvaluations.serialNumberNotPositive())
            } else if ((Int64(serialNumber.value[0]) & 0x80) != 0) {
                violations.add(CertificateConstraintsEvaluations.serialNumberNotPositive())
            }
        })
    }

    public static func naturalPersonDN(
        attribute: String,
        subject: ?DistinguishedName
    ): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            match (subject) {
                case None =>
                    violations.add(CertificateConstraintsEvaluations.missingDN(attribute))
                case Some(dn) =>
                    if (isBlankOption(dn.country())) {
                        violations.add(CertificateConstraintsEvaluations.missingCountryName(attribute))
                    }
                    let hasName = !isBlankOption(dn.givenName()) ||
                        !isBlankOption(dn.surname()) ||
                        !isBlankOption(dn.pseudonym())
                    if (!hasName) {
                        violations.add(CertificateConstraintsEvaluations.missingPersonalName(attribute))
                    }
                    if (isBlankOption(dn.commonName())) {
                        violations.add(CertificateConstraintsEvaluations.missingCommonName(attribute))
                    }
                    match (dn.serialNumber()) {
                        case None =>
                            violations.add(CertificateConstraintsEvaluations.missingSerialNumber(attribute))
                        case Some(sn) =>
                            if (isBlankString(sn)) {
                                violations.add(CertificateConstraintsEvaluations.missingSerialNumber(attribute))
                            } else if (!CertificateConstraintsEvaluations.isValidNaturalPersonId(sn)) {
                                violations.add(CertificateConstraintsEvaluations.serialNumberInvalidFormat(attribute))
                            }
                    }
            }
        })
    }

    public static func legalPersonDN(
        attribute: String,
        dn: ?DistinguishedName
    ): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            match (dn) {
                case None =>
                    violations.add(CertificateConstraintsEvaluations.missingDN(attribute))
                case Some(name) =>
                    if (isBlankOption(name.country())) {
                        violations.add(CertificateConstraintsEvaluations.missingCountryName(attribute))
                    }
                    if (isBlankOption(name.organization())) {
                        violations.add(CertificateConstraintsEvaluations.missingOrganizationName(attribute))
                    }
                    if (isBlankOption(name.commonName())) {
                        violations.add(CertificateConstraintsEvaluations.missingCommonName(attribute))
                    }
                    match (name.organizationIdentifier()) {
                        case None => ()
                        case Some(orgId) =>
                            if (!isBlankString(orgId) && !CertificateConstraintsEvaluations.isValidOrgId(orgId)) {
                                violations.add(CertificateConstraintsEvaluations.organizationIdentifierInvalidFormat())
                            }
                    }
            }
        })
    }

    public static func isValidOrgId(orgId: String): Bool {
        match (ETSI319412Part1.orgIdPattern().find(orgId, group: true)) {
            case None => false
            case Some(md) =>
                let identityType = md.matchString(1)
                ETSI319412Part1.validOrgIdTypes().contains(identityType)
        }
    }

    public static func isValidNaturalPersonId(serialNumber: String): Bool {
        match (ETSI319412Part1.orgIdPattern().find(serialNumber, group: true)) {
            case None => false
            case Some(md) =>
                let identityType = md.matchString(1)
                ETSI319412Part1.validNatIdTypes().contains(identityType)
        }
    }

    public static func subjectAltName(san: ?ArrayList<SubjectAlternativeName>): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            var missing = true
            match (san) {
                case None => missing = true
                case Some(items) => missing = items.size == 0
            }
            if (missing) {
                violations.add(CertificateConstraintsEvaluations.missingSubjectAltName())
            }
        })
    }

    public static func authorityKeyIdentifier(aki: ?AuthorityKeyIdentifier): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            match (aki) {
                case None => violations.add(CertificateConstraintsEvaluations.missingAuthorityKeyIdentifier())
                case Some(_) => ()
            }
        })
    }

    public static func subjectKeyIdentifier(ski: ?Array<UInt8>): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            match (ski) {
                case None => violations.add(CertificateConstraintsEvaluations.missingSubjectKeyIdentifier())
                case Some(_) => ()
            }
        })
    }

    public static func evaluateCrlDistributionPointsIfNoOcspAndNotValAssured(
        crldp: ArrayList<CrlDistributionPoint>,
        aia: ?AuthorityInformationAccess,
        qcStatements: ArrayList<QCStatementInfo>
    ): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            var hasOcsp = false
            match (aia) {
                case None => hasOcsp = false
                case Some(info) =>
                    match (info.ocspUri) {
                        case Some(_) => hasOcsp = true
                        case None => hasOcsp = false
                    }
            }
            if (!hasOcsp) {
                let isValAssured = CertificateConstraintsEvaluations.containsQcType(
                    qcStatements,
                    ETSI319412Part1.EXT_ETSI_VAL_ASSURED_ST_CERTS
                )
                if (!isValAssured) {
                    if (crldp.size == 0 || allCrlUriBlank(crldp)) {
                        violations.add(CertificateConstraintsEvaluations.missingCrlDistributionPointsWhenNoOcsp())
                    }
                }
            }
        })
    }

    public static func evaluateCrlDistributionPoints(
        crldp: ArrayList<CrlDistributionPoint>
    ): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            if (crldp.size == 0 || allCrlUriBlank(crldp)) {
                violations.add(CertificateConstraintsEvaluations.missingCrlDistributionPoints())
            }
        })
    }

    public static func evaluateQcStatementsForPolicy(
        policies: ?ArrayList<String>,
        qcStatements: ArrayList<QCStatementInfo>,
        rules: (String) -> ArrayList<String>
    ): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            let required = HashSet<String>()
            match (policies) {
                case None => ()
                case Some(items) =>
                    for (policy in items) {
                        let needed = rules(policy)
                        for (oid in needed) {
                            required.add(oid)
                        }
                    }
            }
            for (requiredType in required) {
                if (!CertificateConstraintsEvaluations.containsQcType(qcStatements, requiredType)) {
                    violations.add(
                        CertificateConstraintsEvaluations.certificateDoesNotContainRequiredQCStatement(
                            requiredType,
                            qcStatements
                        )
                    )
                }
            }
        })
    }

    public static func evaluatePublicKey(
        pkInfo: PublicKeyInfo,
        options: PublicKeyAlgorithmOptions
    ): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            var compliant = false
            for (req in options.algorithmOptions) {
                let algoMatch = pkInfo.isAlgorithm([req.algorithm])
                var sizeOk = true
                match (pkInfo.keySize) {
                    case None => sizeOk = true
                    case Some(size) => sizeOk = size >= req.minimumKeySize
                }
                if (algoMatch && sizeOk) {
                    compliant = true
                }
            }
            if (!compliant) {
                violations.add(CertificateConstraintsEvaluations.publicKeyNotCompliant(pkInfo, options))
            }
        })
    }

    public static func checkCriticalExtension(
        extensionsCriticality: HashMap<String, Bool>,
        mustBeCritical: Bool,
        filter: (String) -> Bool
    ): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            for ((oid, isCritical) in extensionsCriticality) {
                if (filter(oid) && isCritical != mustBeCritical) {
                    let reason = if (mustBeCritical) {
                        "Extension ${oid} must be marked critical but is not"
                    } else {
                        "Extension ${oid} must not be marked critical but is marked critical"
                    }
                    violations.add(CertificateConstraintViolation(reason))
                }
            }
        })
    }

    public static func evaluateValidityAssuredShortTerm(
        maxShortTermDuration: Duration,
        validity: ValidityPeriod,
        qcStatements: ArrayList<QCStatementInfo>,
        hasNoRevAvail: Bool
    ): CertificateConstraintEvaluation {
        collectEvaluation({ violations: ArrayList<CertificateConstraintViolation> =>
            let isValAssured = CertificateConstraintsEvaluations.containsQcType(
                qcStatements,
                ETSI319412Part1.EXT_ETSI_VAL_ASSURED_ST_CERTS
            )
            if (isValAssured) {
                let duration = validity.notAfter.toUnixTimeStamp() - validity.notBefore.toUnixTimeStamp()
                match (duration.compare(maxShortTermDuration)) {
                    case Ordering.GT =>
                        violations.add(
                            CertificateConstraintsEvaluations.invalidValidityPeriodForValidityAssured(duration)
                        )
                    case _ => ()
                }
                if (!hasNoRevAvail) {
                    violations.add(CertificateConstraintsEvaluations.missingNoRevocationAvailForValidityAssured())
                }
            }
        })
    }

    public static func invalidValidityPeriodForValidityAssured(duration: Duration): CertificateConstraintViolation {
        CertificateConstraintViolation(
            "Validity-assured certificate must be short-term (<= 7 days). Actual: ${duration.toString()}"
        )
    }

    public static func missingNoRevocationAvailForValidityAssured(): CertificateConstraintViolation {
        CertificateConstraintViolation(
            "Validity-assured certificate must include noRevocationAvail extension (RFC 9608)"
        )
    }

    public static func certificateTypeMismatch(expected: String, actual: String): CertificateConstraintViolation {
        CertificateConstraintViolation("Certificate type mismatch: expected ${expected} but was ${actual}")
    }

    public static func certificatePathLenExceedsMaximum(
        maxPathLen: Int64,
        actualPathLen: Int64
    ): CertificateConstraintViolation {
        CertificateConstraintViolation(
            "CA certificate pathLenConstraint (${actualPathLen}) exceeds maximum allowed (${maxPathLen})"
        )
    }

    public static func certificateDoesNotContainAnyQCStatement(): CertificateConstraintViolation {
        CertificateConstraintViolation("Certificate does not contain any QCStatement")
    }

    public static func certificateDoesNotContainRequiredQCStatement(
        qcType: String,
        statements: ArrayList<QCStatementInfo>
    ): CertificateConstraintViolation {
        var statementsStr = ""
        var first = true
        for (stmt in statements) {
            if (!first) {
                statementsStr = statementsStr + ", "
            }
            statementsStr = statementsStr + stmt.semanticOid()
            first = false
        }
        CertificateConstraintViolation(
            "Certificate does not contain required QCStatement type '${qcType}'.Available: ${statementsStr}"
        )
    }

    public static func certificateDoesNotContainKeyUsage(): CertificateConstraintViolation {
        CertificateConstraintViolation("Certificate does not contain keyUsage extension")
    }

    public static func caCertificateMissingPathLenConstraint(): CertificateConstraintViolation {
        CertificateConstraintViolation("CA certificate missing pathLenConstraint")
    }

    public static func certificateMissingKeyUsage(keyUsage: String): CertificateConstraintViolation {
        CertificateConstraintViolation("Certificate keyUsage missing required bits: ${keyUsage}")
    }

    public static func keyUsageNotMarkedCritical(): CertificateConstraintViolation {
        CertificateConstraintViolation("KeyUsage extension must be marked critical per RFC 5280 clause 4.2")
    }

    public static func certificateDoesNotContainAnyPolicy(
        policies: ArrayList<String>,
        oids: HashSet<String>
    ): CertificateConstraintViolation {
        CertificateConstraintViolation(
            "Certificate policies [${joinStrings(policies)}] do not match any of the required policies: ${joinSet(oids)}"
        )
    }

    public static func certificateDoesNotContainPolicies(oids: HashSet<String>): CertificateConstraintViolation {
        if (oids.size == 0) {
            CertificateConstraintViolation("Certificate does not contain any certificate policies")
        } else {
            CertificateConstraintViolation(
                "Certificate does not contain any certificate policiesRequired one of: ${joinSet(oids)}"
            )
        }
    }

    public static func missingCertificatePoliciesExtension(): CertificateConstraintViolation {
        CertificateConstraintViolation(
            "Certificate does not contain certificatePolicies extension. Per EN 319 412-2 §4.3.3, the certificatePolicies extension shall be present with at least one TSP-defined policy OID."
        )
    }

    public static func caIssuedCertificateMissingAiaExtension(): CertificateConstraintViolation {
        CertificateConstraintViolation(
            "CA-issued certificate missing Authority Information Access (AIA) extension"
        )
    }

    public static func aiaMissingIdAdCaIssuersAccessMethod(): CertificateConstraintViolation {
        CertificateConstraintViolation("AIA extension missing id-ad-caIssuers access method (CA certificate URI)")
    }

    public static func selfSignedCertificateNotAllowed(): CertificateConstraintViolation {
        CertificateConstraintViolation(
            "Self-signed certificate not allowed. Certificate must be issued by a trusted CA."
        )
    }

    public static func certificateVersionMismatch(expected: Int64, actual: Int64): CertificateConstraintViolation {
        CertificateConstraintViolation(
            "Certificate version mismatch: expected v${expected + 1} but was v${actual + 1}"
        )
    }

    public static func serialNumberNotPositive(): CertificateConstraintViolation {
        CertificateConstraintViolation("Certificate serial number must be positive per RFC 5280")
    }

    public static func missingDN(attribute: String): CertificateConstraintViolation {
        CertificateConstraintViolation("Certificate ${attribute} DN is missing")
    }

    public static func missingCountryName(attribute: String): CertificateConstraintViolation {
        CertificateConstraintViolation(
            "${attribute} DN missing required countryName attribute (per ETSI EN 319 412-2/3)"
        )
    }

    public static func missingPersonalName(attribute: String): CertificateConstraintViolation {
        CertificateConstraintViolation(
            "${attribute} DN missing required personal name attribute (givenName, surname, or pseudonym per ETSI EN 319 412-2)"
        )
    }

    public static func missingCommonName(attribute: String): CertificateConstraintViolation {
        CertificateConstraintViolation("${attribute} DN missing required commonName attribute")
    }

    public static func missingOrganizationName(attribute: String): CertificateConstraintViolation {
        CertificateConstraintViolation(
            "${attribute} DN missing required organizationName attribute (per ETSI EN 319 412-3)"
        )
    }

    public static func missingOrganizationIdentifier(attribute: String): CertificateConstraintViolation {
        CertificateConstraintViolation(
            "${attribute} DN missing required organizationIdentifier attribute (per ETSI EN 319 412-3)"
        )
    }

    public static func missingSerialNumber(attribute: String): CertificateConstraintViolation {
        CertificateConstraintViolation(
            "${attribute} DN missing required serialNumber attribute (per ETSI EN 319 412-2)"
        )
    }

    public static func issuerMissingSerialNumber(): CertificateConstraintViolation {
        CertificateConstraintViolation("Issuer DN missing required serialNumber attribute (per ETSI EN 319 412-2)")
    }

    public static func serialNumberInvalidFormat(attribute: String): CertificateConstraintViolation {
        CertificateConstraintViolation(
            "${attribute} DN serialNumber has invalid format. Expected: TYPE+CC-identifier (per EN 319 412-1 clause 5.1.3)"
        )
    }

    public static func organizationIdentifierInvalidFormat(): CertificateConstraintViolation {
        CertificateConstraintViolation(
            "organizationIdentifier has invalid format. Expected: TYPE+CC-identifier (per EN 319 412-1 clause 5.1.4)"
        )
    }

    public static func missingSubjectAltName(): CertificateConstraintViolation {
        CertificateConstraintViolation("Certificate missing subjectAltName extension")
    }

    public static func missingAuthorityKeyIdentifier(): CertificateConstraintViolation {
        CertificateConstraintViolation("Certificate missing authorityKeyIdentifier extension (per ETSI EN 319 412-2)")
    }

    public static func missingSubjectKeyIdentifier(): CertificateConstraintViolation {
        CertificateConstraintViolation("Certificate missing subjectKeyIdentifier extension")
    }

    public static func missingCrlDistributionPoints(): CertificateConstraintViolation {
        CertificateConstraintViolation("Certificate missing CRL distribution points extension")
    }

    public static func missingCrlDistributionPointsWhenNoOcsp(): CertificateConstraintViolation {
        CertificateConstraintViolation(
            "Certificate missing CRL distribution points (required when no OCSP responder available per ETSI EN 319 412-2)"
        )
    }

    public static func publicKeyNotCompliant(
        pkInfo: PublicKeyInfo,
        options: PublicKeyAlgorithmOptions
    ): CertificateConstraintViolation {
        var optionsStr = ""
        var first = true
        for (req in options.algorithmOptions) {
            if (!first) {
                optionsStr = optionsStr + ", "
            }
            optionsStr = optionsStr + "${req.algorithm} >= ${req.minimumKeySize} bits"
            first = false
        }
        let sizeStr = match (pkInfo.keySize) {
            case Some(s) => s.toString()
            case None => "none"
        }
        CertificateConstraintViolation(
            "Public key (algorithm=${pkInfo.algorithm}, size=${sizeStr}) does not satisfy any of the required options: ${optionsStr}"
        )
    }

    static func containsQcType(statements: ArrayList<QCStatementInfo>, qcType: String): Bool {
        for (stmt in statements) {
            if (stmt.semanticOid() == qcType) {
                return true
            }
        }
        false
    }

    static func policiesIntersect(policies: ArrayList<String>, oids: HashSet<String>): Bool {
        for (policy in policies) {
            if (oids.contains(policy)) {
                return true
            }
        }
        false
    }
}

func isBlankString(s: String): Bool {
    for (ch in s) {
        if (ch != 32u8 && ch != 9u8 && ch != 10u8 && ch != 13u8) {
            return false
        }
    }
    true
}

func isBlankOption(s: ?String): Bool {
    match (s) {
        case None => true
        case Some(v) => isBlankString(v)
    }
}

func allCrlUriBlank(crldp: ArrayList<CrlDistributionPoint>): Bool {
    for (item in crldp) {
        match (item.distributionPointUri) {
            case None => ()
            case Some(uri) =>
                if (!isBlankString(uri)) {
                    return false
                }
        }
    }
    true
}

func joinStrings(items: ArrayList<String>): String {
    var out = ""
    var first = true
    for (item in items) {
        if (!first) {
            out = out + ", "
        }
        out = out + item
        first = false
    }
    out
}

func joinSet(items: HashSet<String>): String {
    var out = ""
    var first = true
    for (item in items) {
        if (!first) {
            out = out + ", "
        }
        out = out + item
        first = false
    }
    out
}
