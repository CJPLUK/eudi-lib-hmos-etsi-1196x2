package ohos_app_cangjie_entry

import std.collection.*
import kit.ArkUI.LengthProp
import kit.ArkUI.Column
import kit.ArkUI.Row
import kit.ArkUI.Text
import kit.ArkUI.Button
import kit.ArkUI.CustomView
import kit.ArkUI.CJEntry
import kit.ArkUI.loadNativeView
import kit.ArkUI.FontWeight
import kit.ArkUI.SubscriberManager
import kit.ArkUI.ObservedProperty
import kit.ArkUI.LocalStorage
import kit.ArkUI.UIThread
import kit.ArkUI.TextAlign
import ohos.arkui.state_macro_manage.Entry
import ohos.arkui.state_macro_manage.Component
import ohos.arkui.state_macro_manage.State
import ohos_app_cangjie_entry.app_shell.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*

@Entry
@Component
class EntryView {
    @State
    var message: String = "EUDIW demo"

    @State
    var statusText: String = "Tap Validate to invoke IsChainTrustedForEUDIW"

    func build() {
        Row {
            Column {
                Text(this.message)
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .width(100.percent)
                    .textAlign(TextAlign.Start)
                Button("Validate EUDIW chain")
                    .onClick({
                        evt => this.runDemoValidate()
                    })
                    .margin(16.vp)
                    .width(100.percent)
                Text(this.statusText)
                    .fontSize(16)
                    .width(100.percent)
                    .textAlign(TextAlign.Start)
            }.width(100.percent)
        }.height(100.percent)
    }

    func runDemoValidate(): Unit {
        spawn {
            =>
            let result = this.invokeEudiwDemo()
            spawn(UIThread) {
                =>
                this.statusText = result
            }
        }
    }

    /// Demo hook `demo_validate`: compose LoTE-backed IsChainTrustedForEUDIW and invoke it.
    func invokeEudiwDemo(): String {
        try {
            let validator: IsChainTrustedForEUDIW<ArrayList<Array<Byte>>, Array<Byte>> = app_composition()
            match (validator.invoke(demoUntrustedChain(), VerificationContext.PID)) {
                case None => "No LoTE-provisioned validator/anchors for PID"
                case Some(outcome) =>
                    match (outcome) {
                        case CertificationChainValidation.Trusted(_) =>
                            "Trusted"
                        case CertificationChainValidation.NotTrusted(cause) =>
                            "Not trusted: ${cause}"
                    }
            }
        } catch (e: Exception) {
            "Network or load error: ${e.message}"
        }
    }
}
