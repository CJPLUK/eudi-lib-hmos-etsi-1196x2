package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation

import std.collection.*
import std.io.*
import std.time.*
import stdx.net.http.*
import stdx.net.tls.TlsClientConfig
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model.*

public enum LoadLoTEOutcome {
    | Loaded(String)
    | NotFound(Option<Exception>)
}

/// Functional loader for a single LoTE document (JWT text).
public interface LoadLoTE {
    func invoke(uri: Uri): LoadLoTEOutcome
}

/// HTTP GET of a LoTE JWT from a remote location via stdx.net.http.
public class DownloadSingleLoTE <: LoadLoTE {
    private let parseJwt: ParseJwt

    public init() {
        this.parseJwt = ParseJwt()
    }

    public init(parseJwt: ParseJwt) {
        this.parseJwt = parseJwt
    }

    public func invoke(uri: Uri): LoadLoTEOutcome {
        consultationPlatform().runIo({ =>
            this.getJwt(uri)
        })
    }

    /// IC hook `parse_lote`: turn a downloaded JWT body into ListOfTrustedEntities.
    public func parseLoTE(jwt: String): ListOfTrustedEntities {
        match (this.parseJwt.invoke(jwt)) {
            case ParseJwtOutcome.Parsed(_, claims) => claims.listOfTrustedEntities
            case ParseJwtOutcome.ParseFailed(cause) =>
                match (cause) {
                    case Some(e) => throw e
                    case None => throw IllegalArgumentException("Failed to parse LoTE JWT")
                }
        }
    }

    private func getJwt(uri: Uri): LoadLoTEOutcome {
        let client = ClientBuilder()
            .tlsConfig(TlsClientConfig())
            .readTimeout(Duration.second * 10)
            .writeTimeout(Duration.second * 10)
            .build()
        try {
            let req = HttpRequestBuilder()
                .get()
                .url(uri.value)
                .header("Accept", "application/jwt, application/jose+json, */*")
                .build()
            let resp = client.send(req)
            try {
                let status = Int64(resp.status)
                if (status == 200) {
                    let body = String.fromUtf8(readStreamToEnd(resp.body))
                    LoadLoTEOutcome.Loaded(body)
                } else if (status == 404) {
                    LoadLoTEOutcome.NotFound(None)
                } else {
                    throw IllegalStateException("Unexpected response status: ${status}")
                }
            } finally {
                resp.close()
            }
        } finally {
            client.close()
        }
    }
}

func readStreamToEnd(input: InputStream): Array<Byte> {
    let buf = Array<Byte>(4096, repeat: 0)
    let result = ArrayList<Byte>()
    var len = input.read(buf)
    while (len > 0) {
        var i: Int64 = 0
        while (i < len) {
            result.add(buf[i])
            i = i + 1
        }
        len = input.read(buf)
    }
    Array<Byte>(result.size, { idx => result[idx] })
}
