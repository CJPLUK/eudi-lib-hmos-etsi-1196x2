package ohos_app_cangjie_eudi_cjetsi_1196x2.pkix_bridge

/// Path-validation policy. Default matches iOS PKIXConfiguration (revocation off).
public class PKIXConfiguration {
    public let isRevocationEnabled: Bool

    public init(isRevocationEnabled!: Bool) {
        this.isRevocationEnabled = isRevocationEnabled
    }

    public init() {
        this.isRevocationEnabled = false
    }
}
