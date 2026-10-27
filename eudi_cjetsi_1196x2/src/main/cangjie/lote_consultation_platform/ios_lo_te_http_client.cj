package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation_platform

import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation.DownloadSingleLoTE

/// Builds LoTE HTTP loaders for OHOS.
///
/// Kotlin/iOS uses Ktor Darwin (NSURLSession). HarmonyOS has no Darwin engine;
/// this factory returns DownloadSingleLoTE, which already GETs via stdx.net.http
/// (ClientBuilder + HttpRequestBuilder).
public class IosLoTEHttpClient {
    public static func create(): DownloadSingleLoTE {
        DownloadSingleLoTE()
    }
}
