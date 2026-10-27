package ohos_app_cangjie_eudi_cjetsi_1196x2.etsi_trust

import std.collection.ArrayList

func u8ToBytes(src: Array<UInt8>): Array<Byte> {
    Array<Byte>(src.size, { idx => src[idx] })
}

func bytesToU8(src: Array<Byte>): Array<UInt8> {
    let out = Array<UInt8>(src.size, repeat: 0u8)
    var i: Int64 = 0
    while (i < src.size) {
        out[i] = UInt8(src[i])
        i = i + 1
    }
    return out
}

func derEqualU8(a: Array<UInt8>, b: Array<Byte>): Bool {
    if (a.size != b.size) {
        return false
    }
    var i: Int64 = 0
    while (i < a.size) {
        if (UInt8(b[i]) != a[i]) {
            return false
        }
        i = i + 1
    }
    return true
}

func chainToByteList(chain: Array<Array<UInt8>>): ArrayList<Array<Byte>> {
    let out = ArrayList<Array<Byte>>()
    for (der in chain) {
        out.add(u8ToBytes(der))
    }
    return out
}
