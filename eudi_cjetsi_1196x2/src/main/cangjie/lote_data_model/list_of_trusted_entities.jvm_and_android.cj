package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model

func loteServiceMatchesType(information: ServiceInformation, serviceTypeIdentifier: Uri): Bool {
    match (information.typeIdentifier) {
        case Some(tid) => return tid.value == serviceTypeIdentifier.value
        case None => return false
    }
}
