package ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core

import std.collection.*
import std.regex.*

/// Constants from ETSI EN 319 412-1 (certificate policy requirements).
public class ETSI319412Part1 {
    public static let ATTR_ORGANIZATION_IDENTIFIER: String = "2.5.4.97"
    public static let ATTR_COMMON_NAME: String = "2.5.4.3"
    public static let ATTR_COUNTRY_NAME: String = "2.5.4.6"
    public static let ATTR_ORGANIZATION_NAME: String = "2.5.4.10"
    public static let EXT_ETSI_VAL_ASSURED_ST_CERTS: String = "0.4.0.194121.2.1"
    public static let EXT_NO_REVOCATION_AVAIL: String = "2.5.29.56"
    public static let OID_ETSI_QCP_BASE: String = "0.4.0.194121.1"
    public static let OID_ETSI_NCP_BASE: String = "0.4.0.194121.1.1"
    public static let ORG_ID_TYPE_VAT: String = "VAT"
    public static let ORG_ID_TYPE_NTR: String = "NTR"
    public static let ORG_ID_TYPE_PSD: String = "PSD"
    public static let ORG_ID_TYPE_LEI: String = "LEI"
    public static let ORG_ID_TYPE_EOR: String = "EOR"
    public static let ORG_ID_TYPE_EXC: String = "EXC"
    public static let NAT_ID_TYPE_PAS: String = "PAS"
    public static let NAT_ID_TYPE_IDC: String = "IDC"
    public static let NAT_ID_TYPE_PNO: String = "PNO"
    public static let NAT_ID_TYPE_TAX: String = "TAX"
    public static let NAT_ID_TYPE_TIN: String = "TIN"
    public static let ORG_ID_SEPARATOR: String = "-"
    public static let ORG_ID_TYPE_PREFIX_LENGTH: Int64 = 3
    public static let ORG_ID_COUNTRY_CODE_LENGTH: Int64 = 2

    public static func orgIdPattern(): Regex {
        Regex(#"^([A-Z]{3})[A-Z]{2}-.+$"#)
    }

    public static func validOrgIdTypes(): HashSet<String> {
        HashSet<String>([
            ETSI319412Part1.ORG_ID_TYPE_VAT,
            ETSI319412Part1.ORG_ID_TYPE_NTR,
            ETSI319412Part1.ORG_ID_TYPE_PSD,
            ETSI319412Part1.ORG_ID_TYPE_LEI,
            ETSI319412Part1.ORG_ID_TYPE_EOR,
            ETSI319412Part1.ORG_ID_TYPE_EXC
        ])
    }

    public static func validNatIdTypes(): HashSet<String> {
        HashSet<String>([
            ETSI319412Part1.NAT_ID_TYPE_PAS,
            ETSI319412Part1.NAT_ID_TYPE_IDC,
            ETSI319412Part1.NAT_ID_TYPE_PNO,
            ETSI319412Part1.NAT_ID_TYPE_TAX,
            ETSI319412Part1.NAT_ID_TYPE_TIN
        ])
    }
}
