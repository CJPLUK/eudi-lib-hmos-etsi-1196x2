package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_eu_profiles

import std.collection.*
import std.time.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*

public func walletProviderSigningCertificateProfile(at!: ?DateTime = None): CertificateProfile {
    certificateProfile({ builder: ProfileBuilder =>
        builder.endEntity()
        builder.version3()
        builder.mandatoryQcType(ETSI119412Part6.ID_ETSI_QCT_WAL)
        builder.keyUsageDigitalSignature()
        builder.walletProviderExplicitExtensionCriticality()
        builder.validAt(at)
        builder.policyIsPresent()
        builder.authorityInformationAccessIfCAIssued()
        builder.positiveSerialNumber()
        builder.publicKey(eudiwSigningPublicKeyOptions())
        builder.pidProviderIssuerAndSubject()
        builder.requireSubjectKeyIdentifier()
    })
}

extend ProfileBuilder {
    public func walletProviderExplicitExtensionCriticality(): Unit {
        this.extensionCriticalityMust(true, { oid: String => basicConstraintOrKeyUsageOid(oid) })
        this.extensionCriticalityMust(false, { oid: String => !basicConstraintOrKeyUsageOid(oid) })
    }
}
