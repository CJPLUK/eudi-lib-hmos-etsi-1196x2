# eudi_lib_etsi_1196x2

EU Digital Identity Wallet 的 **ETSI TS 119 6x2** 咨询 / LoTE / PKIX 模块（仓颉 / HarmonyOS）。对应上游 [eudi-lib-kmp-etsi-1196x2](https://github.com/eu-digital-identity-wallet/eudi-lib-kmp-etsi-1196x2)。

命名与 [eudi_lib_sdjwt](https://github.com/CJPLUK/eudi-lib-hmos-sdjwt)、[eudi_lib_x509](https://github.com/CJPLUK/eudi-lib-hmos-x509) 对齐：仓库全小写 `eudi_lib_*`，HAR 为 `eudi_cj*`。

## 仓库结构

```
eudi_lib_etsi_1196x2/
├── eudi_cjetsi_1196x2/            ← HAR（交付单元，pkg ohos_app_cangjie_eudi_cjetsi_1196x2）
│   └── src/main/cangjie/
│       ├── consultation_core/
│       ├── consultation_dss/
│       ├── consultation_platform/
│       ├── lote_consultation/
│       ├── lote_consultation_platform/
│       ├── lote_data_model/
│       ├── lote_eu_profiles/
│       └── pkix_bridge/
└── entry/                         ← 测试面板 HAP（Validate EUDIW chain）
    └── libs/stdx/                 ← stdx 运行时
```

## 下游消费（cjpm path 依赖）

```toml
[dependencies]
  [dependencies.ohos_app_cangjie_eudi_cjetsi_1196x2]
    path = "../third_party/eudi_lib_etsi_1196x2/eudi_cjetsi_1196x2"
```

```cangjie
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation.*
```

## 构建

要求：DevEco Studio（含 OpenHarmony SDK）+ Cangjie SDK。环境变量与命令同团队 lib-packaging-spec，参照 [eudi_lib_sdjwt](https://github.com/CJPLUK/eudi-lib-hmos-sdjwt) README 的「构建」一节。

```bash
cd eudi_cjetsi_1196x2 && cjpm build --target aarch64-linux-ohos
cd ../entry           && cjpm build --target aarch64-linux-ohos
```

## License

[Apache License 2.0](LICENSE)。本项目为 eudi-lib-kmp-etsi-1196x2（© European Commission）的衍生移植，归属与捆绑件声明见 [NOTICE](NOTICE)。
