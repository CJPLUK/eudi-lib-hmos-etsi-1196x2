package ohos_app_cangjie_entry

import kit.AbilityKit.AbilityStage
import kit.PerformanceAnalysisKit.Hilog
import ohos_app_cangjie_entry.app_shell.*

class MyAbilityStage <: AbilityStage {
    public override func onCreate(): Unit {
        Hilog.info(1, "Cangjie", "MyAbilityStage onCreated.")
        try {
            app_composition()
            Hilog.info(1, "Cangjie", "EUDIW LoTE composition registered")
        } catch (e: Exception) {
            Hilog.info(1, "Cangjie", "EUDIW composition failed: ${e.message}")
        }
    }
}
