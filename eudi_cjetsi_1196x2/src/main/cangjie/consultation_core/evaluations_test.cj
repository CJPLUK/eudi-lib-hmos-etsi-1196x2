package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

import std.collection.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

func legalDn(): DistinguishedName {
    let attrs = HashMap<String, String>()
    attrs.add(X500OIDs.COUNTRY, "BE")
    attrs.add(X500OIDs.ORGANIZATION, "Acme")
    attrs.add(X500OIDs.COMMON_NAME, "Acme NV")
    attrs.add(X500OIDs.ORG_IDENTIFIER, "VATBE-0123456789")
    DistinguishedName(attrs)
}

func naturalDn(): DistinguishedName {
    let attrs = HashMap<String, String>()
    attrs.add(X500OIDs.COUNTRY, "BE")
    attrs.add(X500OIDs.COMMON_NAME, "Jane Doe")
    attrs.add(X500OIDs.GIVEN_NAME, "Jane")
    attrs.add(X500OIDs.SURNAME, "Doe")
    attrs.add(X500OIDs.SERIAL_NUMBER, "IDCBE-12345")
    DistinguishedName(attrs)
}

@Test
class Etsi319412OrgIdTest {
    @TestCase
    func acceptsVatAndNtr(): Unit {
        @Expect(CertificateConstraintsEvaluations.isValidOrgId("VATBE-0123456789"), true)
        @Expect(CertificateConstraintsEvaluations.isValidOrgId("NTRDE-HRB123"), true)
        @Expect(CertificateConstraintsEvaluations.isValidOrgId("XXXBE-0123"), false)
        @Expect(CertificateConstraintsEvaluations.isValidOrgId("vatBE-0123"), false)
        @Expect(CertificateConstraintsEvaluations.isValidOrgId("VATBE0123"), false)
    }

    @TestCase
    func naturalPersonId(): Unit {
        @Expect(CertificateConstraintsEvaluations.isValidNaturalPersonId("PASBE-AB123"), true)
        @Expect(CertificateConstraintsEvaluations.isValidNaturalPersonId("IDCFR-99"), true)
        @Expect(CertificateConstraintsEvaluations.isValidNaturalPersonId("VATBE-1"), false)
    }

    @TestCase
    func endEntityAndCa(): Unit {
        let ee = BasicConstraintsInfo(false, Option<Int64>.None)
        let ca = BasicConstraintsInfo(true, Option<Int64>.Some(0))
        @Expect(evaluationIsMet(CertificateConstraintsEvaluations.isEndEntity(ee)), true)
        @Expect(evaluationIsMet(CertificateConstraintsEvaluations.isEndEntity(ca)), false)
        @Expect(evaluationIsMet(CertificateConstraintsEvaluations.isCA(ca, Option<Int64>.Some(1))), true)
        @Expect(evaluationIsMet(CertificateConstraintsEvaluations.isCA(ee, Option<Int64>.None)), false)
    }

    @TestCase
    func legalPersonDnMet(): Unit {
        @Expect(evaluationIsMet(CertificateConstraintsEvaluations.legalPersonDN("subject", Some(legalDn()))), true)
    }

    @TestCase
    func naturalPersonDnMet(): Unit {
        @Expect(evaluationIsMet(CertificateConstraintsEvaluations.naturalPersonDN("subject", Some(naturalDn()))), true)
    }

    @TestCase
    func keyUsageDigitalSignature(): Unit {
        let bits = KeyUsageBits(digitalSignature: true)
        @Expect(evaluationIsMet(CertificateConstraintsEvaluations.mandatoryKeyUsage(Some(bits), "digitalSignature")), true)
        @Expect(evaluationIsMet(CertificateConstraintsEvaluations.mandatoryKeyUsage(Some(bits), "keyCertSign")), false)
        @Expect(evaluationIsMet(CertificateConstraintsEvaluations.mandatoryKeyUsage(Option<KeyUsageBits>.None, "digitalSignature")), false)
    }

    @TestCase
    func validAtWindow(): Unit {
        let period = ValidityPeriod(
            DateTime.parse("2026-01-01T00:00:00Z"),
            DateTime.parse("2026-12-31T00:00:00Z")
        )
        @Expect(evaluationIsMet(CertificateConstraintsEvaluations.validAt(period, Some(DateTime.parse("2026-06-01T00:00:00Z")))), true)
        @Expect(evaluationIsMet(CertificateConstraintsEvaluations.validAt(period, Some(DateTime.parse("2025-12-31T00:00:00Z")))), false)
    }

    @TestCase
    func qcTypeAndPolicy(): Unit {
        let stmts = ArrayList<QCStatementInfo>()
        stmts.add(QCStatementInfo.QcType(ETSI319412.QC_COMPLIANCE))
        @Expect(evaluationIsMet(CertificateConstraintsEvaluations.mandatoryQcType(stmts, ETSI319412.QC_COMPLIANCE)), true)
        @Expect(evaluationIsMet(CertificateConstraintsEvaluations.mandatoryQcType(stmts, ETSI319412.QC_SSCD)), false)
        let policies = ArrayList<String>()
        policies.add("1.2.3")
        let oids = HashSet<String>(["1.2.3", "9.9.9"])
        @Expect(evaluationIsMet(CertificateConstraintsEvaluations.policyOneOf(Some(policies), oids)), true)
        @Expect(evaluationIsMet(CertificateConstraintsEvaluations.policyIsPresent(Some(ArrayList<String>()))), false)
    }

    @TestCase
    func nonEmptyListRejectsEmpty(): Unit {
        match (NonEmptyList<Array<Byte>>.nelOrNull(ArrayList<Array<Byte>>())) {
            case None => @Expect(true, true)
            case Some(_) => @Expect(false, true)
        }
    }
}
