package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model

import std.collection.*
import stdx.crypto.common.*
import stdx.crypto.x509.*

extend ListOfTrustedEntities {
    public func pkiObjsOf(): Array<Array<Byte>> {
        return this.collectPkiBytes({ _ => true })
    }

    public func pkiObjsOf(serviceTypeIdentifier: Uri): Array<Array<Byte>> {
        return this.collectPkiBytes({ info => loteServiceMatchesType(info, serviceTypeIdentifier) })
    }

    public func certificatesOf(serviceTypeIdentifier: Uri): Array<X509Certificate> {
        let bytesList = this.pkiObjsOf(serviceTypeIdentifier)
        let out = ArrayList<X509Certificate>()
        for (bytes in bytesList) {
            out.add(X509Certificate.decodeFromDer(DerBlob(bytes)))
        }
        return Assertions.copyArray(out)
    }

    func collectPkiBytes(predicate: (ServiceInformation) -> Bool): Array<Array<Byte>> {
        let out = ArrayList<Array<Byte>>()
        match (this.entities) {
            case Some(entities) =>
                for (entity in entities) {
                    for (service in entity.services) {
                        let info = service.information
                        if (predicate(info)) {
                            match (info.digitalIdentity.x509Certificates) {
                                case Some(certs) =>
                                    for (pki in certs) {
                                        out.add(pki.value.bytes)
                                    }
                                case None => ()
                            }
                        }
                    }
                }
            case None => ()
        }
        return Assertions.copyArray(out)
    }
}
