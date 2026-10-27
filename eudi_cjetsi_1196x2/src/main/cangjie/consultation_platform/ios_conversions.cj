package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_platform

import std.collection.*
import stdx.crypto.common.DerBlob

/// Content equality for DER-encoded certificates (OHOS stand-in for NSData byte compare).
public func derBytesEqual(left: Array<Byte>, right: Array<Byte>): Bool {
    DerBlob(left) == DerBlob(right)
}

public func copyDerBytes(bytes: Array<Byte>): Array<Byte> {
    DerBlob(bytes).body
}

public func derListFromArray(items: Array<Array<Byte>>): ArrayList<Array<Byte>> {
    let out = ArrayList<Array<Byte>>()
    for (item in items) {
        out.add(item)
    }
    out
}

func positiveIntegerBytes(bytes: Array<Byte>): Array<UInt8> {
    if (bytes.size == 0) {
        throw IllegalArgumentException("Serial number must not be empty")
    }
    let out = ArrayList<UInt8>()
    let lead = Int64(bytes[0])
    if ((lead & 0x80) != 0) {
        out.add(0)
    }
    for (b in bytes) {
        out.add(UInt8(b))
    }
    out.toArray()
}

func toUInt8Array(bytes: Array<Byte>): Array<UInt8> {
    let out = ArrayList<UInt8>()
    for (b in bytes) {
        out.add(UInt8(b))
    }
    out.toArray()
}

func stringsToList(items: Array<String>): ArrayList<String> {
    let out = ArrayList<String>()
    for (item in items) {
        out.add(item)
    }
    out
}
