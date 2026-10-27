package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model

import stdx.crypto.x509.*

extend PKIObject {
    public func x509Certificate(): X509Certificate {
        return X509Certificate.decodeFromDer(derBlobOfPkiObject(this))
    }
}
