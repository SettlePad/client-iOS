//
//  generalFunctions.swift
//  UOless
//
//  Created by Rob Everhardt on 01/01/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

import Foundation
import UIKit

func JSONStringify(jsonObj: AnyObject) -> String {
    var e: NSError?
    let jsonData = NSJSONSerialization.dataWithJSONObject(
        jsonObj,
        options: NSJSONWritingOptions(0),
        error: &e)
    if (e != nil) {
        return ""
    } else {
        return NSString(data: jsonData!, encoding: NSUTF8StringEncoding)! as String
    }
}

extension Double {
    func format(f: String) -> String {
        return NSString(format: "%\(f)f", self) as String
    }
}

extension String {
    func toDouble() -> Double? {
        return NSNumberFormatter().numberFromString(self)?.doubleValue
    }

    func isEmail() -> Bool {
        let regex = NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}$", options: .CaseInsensitive, error: nil)
        return regex?.firstMatchInString(self, options: nil, range: NSMakeRange(0, count(self))) != nil
    }
}

//Define colors
enum Colors {
    case primary
    case gray
    case success
    case warning
    case danger
    case info
    case black
    
    func textToUIColor() -> UIColor{
        switch (self) {
        case .primary:
            return UIColor(red: 0x1a/255, green: 0x9a/255, blue: 0xcb/255, alpha: 1.0)
        case .gray:
            return UIColor(red: 0x77/255, green: 0x77/255, blue: 0x77/255, alpha: 1.0)
        case .success:
            return UIColor(red: 0x08/255, green: 0x99/255, blue: 0x00/255, alpha: 1.0)
        case .warning:
            return UIColor(red: 0xbd/255, green: 0x62/255, blue: 0x00/255, alpha: 1.0)
        case .danger:
            return UIColor(red: 0xbb/255, green: 0x00/255, blue: 0x05/255, alpha: 1.0)
        case .info:
            return UIColor(red: 0x02/255, green: 0x57/255, blue: 0x77/255, alpha: 1.0)
        case .black:
            return UIColor(red: 0x00/255, green: 0x00/255, blue: 0x00/255, alpha: 1.0)
        }
    }
    
    func backgroundToUIColor() -> UIColor{
        switch (self) {
        case .success:
            return UIColor(red: 0xa1/255, green: 0xee/255, blue: 0x9d/255, alpha: 1.0)
        case .warning:
            return UIColor(red: 0xff/255, green: 0xd5/255, blue: 0xa8/255, alpha: 1.0)
        case .danger:
            return UIColor(red: 0xfe/255, green: 0xa8/255, blue: 0xaa/255, alpha: 1.0)
        case .info:
            return UIColor(red: 0x96/255, green: 0xca/255, blue: 0xde/255, alpha: 1.0)
        default:
            return UIColor.clearColor()
        }
    }
}


class PickerButton: UIButton {
	var modInputView =  UIPickerView()
	var modAccessoryView = UIToolbar()


	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		modAccessoryView.barStyle = UIBarStyle.Default
		modAccessoryView.translucent = true
		modAccessoryView.tintColor = Colors.primary.textToUIColor()
		modAccessoryView.sizeToFit()
		
		//var cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: nil, action: "donePicker")
		var spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
		var doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: nil, action: "donePicker")
		
		modAccessoryView.setItems([spaceButton, spaceButton, doneButton], animated: false)
		modAccessoryView.userInteractionEnabled = true
	}
	
	override var inputView: UIView { get {
		return modInputView
	}}

	override var inputAccessoryView: UIView { get {
		return modAccessoryView
		}}

	
	override func canBecomeFirstResponder() -> Bool {
		return true
		
	}
}




enum Currency: String {
	case AFN = "AFN"
	case ALL = "ALL"
	case DZD = "DZD"
	case USD = "USD"
	case EUR = "EUR"
	case AOA = "AOA"
	case XCD = "XCD"
	case ARS = "ARS"
	case AMD = "AMD"
	case AWG = "AWG"
	case AUD = "AUD"
	case AZN = "AZN"
	case BSD = "BSD"
	case BHD = "BHD"
	case BDT = "BDT"
	case BBD = "BBD"
	case BYR = "BYR"
	case BZD = "BZD"
	case XOF = "XOF"
	case BMD = "BMD"
	case BTN = "BTN"
	case BOB = "BOB"
	case BAM = "BAM"
	case BWP = "BWP"
	case NOK = "NOK"
	case BRL = "BRL"
	case BND = "BND"
	case BGN = "BGN"
	case BIF = "BIF"
	case KHR = "KHR"
	case XAF = "XAF"
	case CAD = "CAD"
	case CVE = "CVE"
	case KYD = "KYD"
	case CLP = "CLP"
	case CNY = "CNY"
	case COP = "COP"
	case KMF = "KMF"
	case CDF = "CDF"
	case NZD = "NZD"
	case CRC = "CRC"
	case HRK = "HRK"
	case CUP = "CUP"
	case CUC = "CUC"
	case ANG = "ANG"
	case CZK = "CZK"
	case DKK = "DKK"
	case DJF = "DJF"
	case DOP = "DOP"
	case EGP = "EGP"
	case ERN = "ERN"
	case ETB = "ETB"
	case FKP = "FKP"
	case FJD = "FJD"
	case XPF = "XPF"
	case GMD = "GMD"
	case GEL = "GEL"
	case GHS = "GHS"
	case GIP = "GIP"
	case GTQ = "GTQ"
	case GBP = "GBP"
	case GNF = "GNF"
	case GYD = "GYD"
	case HTG = "HTG"
	case HNL = "HNL"
	case HKD = "HKD"
	case HUF = "HUF"
	case ISK = "ISK"
	case INR = "INR"
	case IDR = "IDR"
	case IRR = "IRR"
	case IQD = "IQD"
	case ILS = "ILS"
	case JMD = "JMD"
	case JPY = "JPY"
	case JOD = "JOD"
	case KZT = "KZT"
	case KES = "KES"
	case KPW = "KPW"
	case KRW = "KRW"
	case KWD = "KWD"
	case KGS = "KGS"
	case LAK = "LAK"
	case LVL = "LVL"
	case LBP = "LBP"
	case LSL = "LSL"
	case LRD = "LRD"
	case LYD = "LYD"
	case CHF = "CHF"
	case LTL = "LTL"
	case MOP = "MOP"
	case MKD = "MKD"
	case MGA = "MGA"
	case MWK = "MWK"
	case MYR = "MYR"
	case MVR = "MVR"
	case MRO = "MRO"
	case MUR = "MUR"
	case MXN = "MXN"
	case MDL = "MDL"
	case MNT = "MNT"
	case MAD = "MAD"
	case MZN = "MZN"
	case MMK = "MMK"
	case NAD = "NAD"
	case NPR = "NPR"
	case NIO = "NIO"
	case NGN = "NGN"
	case OMR = "OMR"
	case PKR = "PKR"
	case PAB = "PAB"
	case PGK = "PGK"
	case PYG = "PYG"
	case PEN = "PEN"
	case PHP = "PHP"
	case PLN = "PLN"
	case QAR = "QAR"
	case RON = "RON"
	case RUB = "RUB"
	case RWF = "RWF"
	case SHP = "SHP"
	case WST = "WST"
	case STD = "STD"
	case SAR = "SAR"
	case RSD = "RSD"
	case SCR = "SCR"
	case SLL = "SLL"
	case SGD = "SGD"
	case SBD = "SBD"
	case SOS = "SOS"
	case ZAR = "ZAR"
	case SSP = "SSP"
	case LKR = "LKR"
	case SDG = "SDG"
	case SRD = "SRD"
	case SZL = "SZL"
	case SEK = "SEK"
	case SYP = "SYP"
	case TWD = "TWD"
	case TJS = "TJS"
	case TZS = "TZS"
	case THB = "THB"
	case TOP = "TOP"
	case TTD = "TTD"
	case TND = "TND"
	case TRY = "TRY"
	case TMT = "TMT"
	case UGX = "UGX"
	case UAH = "UAH"
	case AED = "AED"
	case UYU = "UYU"
	case UZS = "UZS"
	case VUV = "VUV"
	case VEF = "VEF"
	case VND = "VND"
	case YER = "YER"
	case ZMW = "ZMW"
	case ZWL = "ZWL"
	
	func toLongName() -> String {
		switch (self) {
		case AFN: return "Afghani"
		case ALL: return "Lek"
		case DZD: return "Algerian Dinar"
		case USD: return "US Dollar"
		case EUR: return "Euro"
		case AOA: return "Kwanza"
		case XCD: return "East Caribbean Dollar"
		case ARS: return "Argentine Peso"
		case AMD: return "Armenian Dram"
		case AWG: return "Aruban Florin"
		case AUD: return "Australian Dollar"
		case AZN: return "Azerbaijanian Manat"
		case BSD: return "Bahamian Dollar"
		case BHD: return "Bahraini Dinar"
		case BDT: return "Taka"
		case BBD: return "Barbados Dollar"
		case BYR: return "Belarussian Ruble"
		case BZD: return "Belize Dollar"
		case XOF: return "CFA Franc BCEAO"
		case BMD: return "Bermudian Dollar"
		case BTN: return "Ngultrum"
		case BOB: return "Boliviano"
		case BAM: return "Convertible Mark"
		case BWP: return "Pula"
		case NOK: return "Norwegian Krone"
		case BRL: return "Brazilian Real"
		case BND: return "Brunei Dollar"
		case BGN: return "Bulgarian Lev"
		case BIF: return "Burundi Franc"
		case KHR: return "Riel"
		case XAF: return "CFA Franc BEAC"
		case CAD: return "Canadian Dollar"
		case CVE: return "Cape Verde Escudo"
		case KYD: return "Cayman Islands Dollar"
		case CLP: return "Chilean Peso"
		case CNY: return "Yuan Renminbi"
		case COP: return "Colombian Peso"
		case KMF: return "Comoro Franc"
		case CDF: return "Congolais Franc"
		case NZD: return "New Zealand Dollar"
		case CRC: return "Costa Rican Colon"
		case HRK: return "Croatian Kuna"
		case CUP: return "Cuban Peso"
		case CUC: return "Peso Convertible"
		case ANG: return "Netherlands Antillean Guilder"
		case CZK: return "Czech Koruna"
		case DKK: return "Danish Krone"
		case DJF: return "Djibouti Franc"
		case DOP: return "Dominican Peso"
		case EGP: return "Egyptian Pound"
		case ERN: return "Nakfa"
		case ETB: return "Ethiopian Birr"
		case FKP: return "Falkland Islands Pound"
		case FJD: return "Fiji Dollar"
		case XPF: return "CFP Franc"
		case GMD: return "Dalasi"
		case GEL: return "Lari"
		case GHS: return "Ghana Cedi"
		case GIP: return "Gibraltar Pound"
		case GTQ: return "Quetzal"
		case GBP: return "Pound Sterling"
		case GNF: return "Guinea Franc"
		case GYD: return "Guyana Dollar"
		case HTG: return "Gourde"
		case HNL: return "Lempira"
		case HKD: return "Hong Kong Dollar"
		case HUF: return "Forint"
		case ISK: return "Iceland Krona"
		case INR: return "Indian Rupee"
		case IDR: return "Rupiah"
		case IRR: return "Iranian Rial"
		case IQD: return "Iraqi Dinar"
		case ILS: return "New Israeli Sheqel"
		case JMD: return "Jamaican Dollar"
		case JPY: return "Yen"
		case JOD: return "Jordanian Dinar"
		case KZT: return "Tenge"
		case KES: return "Kenyan Shilling"
		case KPW: return "North Korean Won"
		case KRW: return "Won"
		case KWD: return "Kuwaiti Dinar"
		case KGS: return "Som"
		case LAK: return "Kip"
		case LVL: return "Latvian Lats"
		case LBP: return "Lebanese Pound"
		case LSL: return "Loti"
		case LRD: return "Liberian Dollar"
		case LYD: return "Libyan Dinar"
		case CHF: return "Swiss Franc"
		case LTL: return "Lithuanian Litas"
		case MOP: return "Pataca"
		case MKD: return "Denar"
		case MGA: return "Malagasy Ariary"
		case MWK: return "Kwacha"
		case MYR: return "Malaysian Ringgit"
		case MVR: return "Rufiyaa"
		case MRO: return "Ouguiya"
		case MUR: return "Mauritius Rupee"
		case MXN: return "Mexican Peso"
		case MDL: return "Moldovan Leu"
		case MNT: return "Tugrik"
		case MAD: return "Moroccan Dirham"
		case MZN: return "Mozambique Metical"
		case MMK: return "Kyat"
		case NAD: return "Namibia Dollar"
		case NPR: return "Nepalese Rupee"
		case NIO: return "Cordoba Oro"
		case NGN: return "Naira"
		case OMR: return "Rial Omani"
		case PKR: return "Pakistan Rupee"
		case PAB: return "Balboa"
		case PGK: return "Kina"
		case PYG: return "Guarani"
		case PEN: return "Nuevo Sol"
		case PHP: return "Philippine Peso"
		case PLN: return "Zloty"
		case QAR: return "Qatari Rial"
		case RON: return "New Romanian Leu"
		case RUB: return "Russian Ruble"
		case RWF: return "Rwanda Franc"
		case SHP: return "Saint Helena Pound"
		case WST: return "Tala"
		case STD: return "Dobra"
		case SAR: return "Saudi Riyal"
		case RSD: return "Serbian Dinar"
		case SCR: return "Seychelles Rupee"
		case SLL: return "Leone"
		case SGD: return "Singapore Dollar"
		case SBD: return "Solomon Islands Dollar"
		case SOS: return "Somali Shilling"
		case ZAR: return "Rand"
		case SSP: return "South Sudanese Pound"
		case LKR: return "Sri Lanka Rupee"
		case SDG: return "Sudanese Pound"
		case SRD: return "Surinam Dollar"
		case SZL: return "Lilangeni"
		case SEK: return "Swedish Krona"
		case SYP: return "Syrian Pound"
		case TWD: return "New Taiwan Dollar"
		case TJS: return "Somoni"
		case TZS: return "Tanzanian Shilling"
		case THB: return "Baht"
		case TOP: return "Paʻanga"
		case TTD: return "Trinidad and Tobago Dollar"
		case TND: return "Tunisian Dinar"
		case TRY: return "Turkish Lira"
		case TMT: return "Turkmenistan New Manat"
		case UGX: return "Uganda Shilling"
		case UAH: return "Hryvnia"
		case AED: return "UAE Dirham"
		case UYU: return "Peso Uruguayo"
		case UZS: return "Uzbekistan Sum"
		case VUV: return "Vatu"
		case VEF: return "Bolivar Fuerte"
		case VND: return "Dong"
		case YER: return "Yemeni Rial"
		case ZMW: return "New Zambian Kwacha"
		case ZWL: return "Zimbabwe Dollar"
		default: return "unknown"
		}
	}
	
	static let allValues = [AFN,ALL,DZD,USD,EUR,AOA,XCD,ARS,AMD,AWG,AUD,AZN,BSD,BHD,BDT,BBD,BYR,BZD,XOF,BMD,BTN,BOB,BAM,BWP,NOK,BRL,BND,BGN,BIF,KHR,XAF,CAD,CVE,KYD,CLP,CNY,COP,KMF,CDF,NZD,CRC,HRK,CUP,CUC,ANG,CZK,DKK,DJF,DOP,EGP,ERN,ETB,FKP,FJD,XPF,GMD,GEL,GHS,GIP,GTQ,GBP,GNF,GYD,HTG,HNL,HKD,HUF,ISK,INR,IDR,IRR,IQD,ILS,JMD,JPY,JOD,KZT,KES,KPW,KRW,KWD,KGS,LAK,LVL,LBP,LSL,LRD,LYD,CHF,LTL,MOP,MKD,MGA,MWK,MYR,MVR,MRO,MUR,MXN,MDL,MNT,MAD,MZN,MMK,NAD,NPR,NIO,NGN,OMR,PKR,PAB,PGK,PYG,PEN,PHP,PLN,QAR,RON,RUB,RWF,SHP,WST,STD,SAR,RSD,SCR,SLL,SGD,SBD,SOS,ZAR,SSP,LKR,SDG,SRD,SZL,SEK,SYP,TWD,TJS,TZS,THB,TOP,TTD,TND,TRY,TMT,UGX,UAH,AED,UYU,UZS,VUV,VEF,VND,YER,ZMW,ZWL]
}