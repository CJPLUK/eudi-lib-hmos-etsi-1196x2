package ohos_app_cangjie_eudi_cjetsi_1196x2.etsi_trust

/**
 * iOS `TrustSource`. `EtsiTrustManager` is built from one of these.
 */
public enum TrustSource {
    | Etsi(EtsiTrustSource)
    | StaticList(StaticListTrustSource)

    public func contextTypeMappings(): ?EtsiContextTypeMappings {
        match (this) {
            case TrustSource.Etsi(source) => source.contextTypeMappings
            case TrustSource.StaticList(source) => source.contextTypeMappings
        }
    }

    public func withContextTypeMappings(mappings: ?EtsiContextTypeMappings): TrustSource {
        match (this) {
            case TrustSource.Etsi(source) =>
                TrustSource.Etsi(source.withContextTypeMappings(mappings))
            case TrustSource.StaticList(source) =>
                TrustSource.StaticList(source.withContextTypeMappings(mappings))
        }
    }
}
