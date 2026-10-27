package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

import std.collection.*

/// A list that is guaranteed to contain at least one element.
public class NonEmptyList<T> {
    public let items: ArrayList<T>

    public init(items: ArrayList<T>) {
        if (items.size == 0) {
            throw IllegalArgumentException("Non-empty list expected, but was empty")
        }
        this.items = items
    }

    public static func nelOrNull(items: ArrayList<T>): ?NonEmptyList<T> {
        if (items.size == 0) {
            None
        } else {
            NonEmptyList<T>(items)
        }
    }

    public func size(): Int64 {
        this.items.size
    }

    public func get(index: Int64): T {
        this.items[index]
    }
}
