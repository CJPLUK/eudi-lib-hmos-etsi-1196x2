package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_platform

import std.collection.*
import stdx.crypto.common.DerBlob
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.pkix_bridge.PKIXCertificateInspector

/// Subject + serial identity, matching JVM X509CertificateIdentify.
public class X509CertificateIdentify <: Equatable<X509CertificateIdentify> {
    public let subject: HashMap<String, String>
    public let serialNumber: Array<Byte>

    public init(subject: HashMap<String, String>, serialNumber: Array<Byte>) {
        this.subject = subject
        this.serialNumber = serialNumber
    }

    public operator func ==(rhs: X509CertificateIdentify): Bool {
        if (!dnMapsEqual(this.subject, rhs.subject)) {
            return false
        }
        DerBlob(this.serialNumber) == DerBlob(rhs.serialNumber)
    }

    public operator func !=(rhs: X509CertificateIdentify): Bool {
        !(this == rhs)
    }
}

public func identityOfDer(der: Array<Byte>): X509CertificateIdentify {
    let inspector = PKIXCertificateInspector()
    let subject = match (inspector.getSubject(der)) {
        case Some(attrs) => attrs
        case None => HashMap<String, String>()
    }
    let serial = match (inspector.getSerialNumber(der)) {
        case Some(bytes) => bytes
        case None => Array<Byte>()
    }
    X509CertificateIdentify(subject, serial)
}

func dnMapsEqual(left: HashMap<String, String>, right: HashMap<String, String>): Bool {
    for ((k, v) in left) {
        match (right.get(k)) {
            case None => return false
            case Some(other) =>
                if (other != v) {
                    return false
                }
        }
    }
    for ((k, _) in right) {
        if (!left.contains(k)) {
            return false
        }
    }
    true
}

func headCertificateIdOf(chain: ArrayList<Array<Byte>>): X509CertificateIdentify {
    if (chain.size == 0) {
        throw IllegalArgumentException("Chain cannot be empty")
    }
    identityOfDer(chain[0])
}

func trustAnchorCertificateIdOf(anchor: Array<Byte>): X509CertificateIdentify {
    identityOfDer(anchor)
}

/// Direct-trust validator: leaf identity must equal a trust-anchor identity.
public let ValidateCertificateChainUsingDirectTrustJvm:
    ValidateCertificateChainUsingDirectTrust<ArrayList<Array<Byte>>, Array<Byte>, X509CertificateIdentify> =
    ValidateCertificateChainUsingDirectTrust<ArrayList<Array<Byte>>, Array<Byte>, X509CertificateIdentify>(
        { chain: ArrayList<Array<Byte>> => headCertificateIdOf(chain) },
        { anchor: Array<Byte> => trustAnchorCertificateIdOf(anchor) }
    )
