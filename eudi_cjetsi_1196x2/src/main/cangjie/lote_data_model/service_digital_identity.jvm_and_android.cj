package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model

import stdx.crypto.common.*

func derBlobOfPkiObject(pki: PKIObject): DerBlob {
    return DerBlob(pki.value.bytes)
}
