package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model

import stdx.encoding.base64.*

public class Base64KSerializer {
    public static func encode(bytes: Array<Byte>): String {
        return toBase64String(bytes)
    }

    public static func decode(encoded: String): Array<Byte> {
        match (fromBase64String(encoded)) {
            case Some(bytes) => return bytes
            case None => throw LoTEDecodeException("Failed to base64 decode")
        }
    }
}
