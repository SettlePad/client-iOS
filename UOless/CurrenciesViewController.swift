//
//  CurrenciesViewController.swift
//  UOless
//
//  Created by Rob Everhardt on 08/01/15.
//  Copyright (c) 2015 UOless. All rights reserved.
//

// See http://www.pumpmybicep.com/2014/07/04/uitableview-sectioning-and-indexing/

import UIKit

class CurrenciesViewController: UITableViewController {
    @IBOutlet var currenciesTableView: UITableView!
    
    var unorderedCurrencies = ["AFN":"Afghani", "ALL":"Lek", "DZD":"Algerian Dinar", "USD":"US Dollar", "EUR":"Euro", "AOA":"Kwanza", "XCD":"East Caribbean Dollar", "ARS":"Argentine Peso", "AMD":"Armenian Dram", "AWG":"Aruban Florin", "AUD":"Australian Dollar", "AZN":"Azerbaijanian Manat", "BSD":"Bahamian Dollar", "BHD":"Bahraini Dinar", "BDT":"Taka", "BBD":"Barbados Dollar", "BYR":"Belarussian Ruble", "BZD":"Belize Dollar", "XOF":"CFA Franc BCEAO", "BMD":"Bermudian Dollar", "BTN":"Ngultrum", "BOB":"Boliviano", "BAM":"Convertible Mark", "BWP":"Pula", "NOK":"Norwegian Krone", "BRL":"Brazilian Real", "BND":"Brunei Dollar", "BGN":"Bulgarian Lev", "BIF":"Burundi Franc", "KHR":"Riel", "XAF":"CFA Franc BEAC", "CAD":"Canadian Dollar", "CVE":"Cape Verde Escudo", "KYD":"Cayman Islands Dollar", "CLP":"Chilean Peso", "CNY":"Yuan Renminbi", "COP":"Colombian Peso", "KMF":"Comoro Franc", "CDF":"Congolais Franc", "NZD":"New Zealand Dollar", "CRC":"Costa Rican Colon", "HRK":"Croatian Kuna", "CUP":"Cuban Peso", "CUC":"Peso Convertible", "ANG":"Netherlands Antillean Guilder", "CZK":"Czech Koruna", "DKK":"Danish Krone", "DJF":"Djibouti Franc", "DOP":"Dominican Peso", "EGP":"Egyptian Pound", "ERN":"Nakfa", "ETB":"Ethiopian Birr", "FKP":"Falkland Islands Pound", "FJD":"Fiji Dollar", "XPF":"CFP Franc", "GMD":"Dalasi", "GEL":"Lari", "GHS":"Ghana Cedi", "GIP":"Gibraltar Pound", "GTQ":"Quetzal", "GBP":"Pound Sterling", "GNF":"Guinea Franc", "GYD":"Guyana Dollar", "HTG":"Gourde", "HNL":"Lempira", "HKD":"Hong Kong Dollar", "HUF":"Forint", "ISK":"Iceland Krona", "INR":"Indian Rupee", "IDR":"Rupiah", "IRR":"Iranian Rial", "IQD":"Iraqi Dinar", "ILS":"New Israeli Sheqel", "JMD":"Jamaican Dollar", "JPY":"Yen", "JOD":"Jordanian Dinar", "KZT":"Tenge", "KES":"Kenyan Shilling", "KPW":"North Korean Won", "KRW":"Won", "KWD":"Kuwaiti Dinar", "KGS":"Som", "LAK":"Kip", "LVL":"Latvian Lats", "LBP":"Lebanese Pound", "LSL":"Loti", "LRD":"Liberian Dollar", "LYD":"Libyan Dinar", "CHF":"Swiss Franc", "LTL":"Lithuanian Litas", "MOP":"Pataca", "MKD":"Denar", "MGA":"Malagasy Ariary", "MWK":"Kwacha", "MYR":"Malaysian Ringgit", "MVR":"Rufiyaa", "MRO":"Ouguiya", "MUR":"Mauritius Rupee", "MXN":"Mexican Peso", "MDL":"Moldovan Leu", "MNT":"Tugrik", "MAD":"Moroccan Dirham", "MZN":"Mozambique Metical", "MMK":"Kyat", "NAD":"Namibia Dollar", "NPR":"Nepalese Rupee", "NIO":"Cordoba Oro", "NGN":"Naira", "OMR":"Rial Omani", "PKR":"Pakistan Rupee", "PAB":"Balboa", "PGK":"Kina", "PYG":"Guarani", "PEN":"Nuevo Sol", "PHP":"Philippine Peso", "PLN":"Zloty", "QAR":"Qatari Rial", "RON":"New Romanian Leu", "RUB":"Russian Ruble", "RWF":"Rwanda Franc", "SHP":"Saint Helena Pound", "WST":"Tala", "STD":"Dobra", "SAR":"Saudi Riyal", "RSD":"Serbian Dinar", "SCR":"Seychelles Rupee", "SLL":"Leone", "SGD":"Singapore Dollar", "SBD":"Solomon Islands Dollar", "SOS":"Somali Shilling", "ZAR":"Rand", "SSP":"South Sudanese Pound", "LKR":"Sri Lanka Rupee", "SDG":"Sudanese Pound", "SRD":"Surinam Dollar", "SZL":"Lilangeni", "SEK":"Swedish Krona", "SYP":"Syrian Pound", "TWD":"New Taiwan Dollar", "TJS":"Somoni", "TZS":"Tanzanian Shilling", "THB":"Baht", "TOP":"Paʻanga", "TTD":"Trinidad and Tobago Dollar", "TND":"Tunisian Dinar", "TRY":"Turkish Lira", "TMT":"Turkmenistan New Manat", "UGX":"Uganda Shilling", "UAH":"Hryvnia", "AED":"UAE Dirham", "UYU":"Peso Uruguayo", "UZS":"Uzbekistan Sum", "VUV":"Vatu", "VEF":"Bolivar Fuerte", "VND":"Dong", "YER":"Yemeni Rial", "ZMW":"New Zambian Kwacha", "ZWL":"Zimbabwe Dollar"] //Copy paste from API
    
    var selectedIndexPath: NSIndexPath?

    
    /* type to represent table items
    `section` stores a `UITableView` section */
    class Currency: NSObject {
        let name: String
        let abbrev: String
        var section: Int?
        
        init(name: String, abbrev: String) {
            self.name = name
            self.abbrev = abbrev
        }
    }
    
    // custom type to represent table sections
    class Section {
        var currencies: [Currency] = []
        
        func addCurrency(currency: Currency) {
            self.currencies.append(currency)
        }
    }
    
    // `UIKit` convenience class for sectioning a table
    let collation = UILocalizedIndexedCollation.currentCollation()
        as UILocalizedIndexedCollation
    
    // table sections
    var sections: [Section] {
        // return if already initialized
        if self._sections != nil {
            return self._sections!
        }
        
        // create currencies from the currency dictionary
        var currencies: [Currency] = []
        for (abbrev, name) in unorderedCurrencies {
            var currency = Currency(name: name, abbrev: abbrev)
            currency.section = self.collation.sectionForObject(currency, collationStringSelector: "name")
            currencies.append(currency)
        }
        
        // create empty sections
        var sections = [Section]()
        for i in 0..<self.collation.sectionIndexTitles.count {
            sections.append(Section())
        }
        
        // put each currency in a section
        for currency in currencies {
            sections[currency.section!].addCurrency(currency)
        }
        
        // sort each section
        for section in sections {
            section.currencies = self.collation.sortedArrayFromArray(section.currencies, collationStringSelector: "name") as [Currency]
        }
                
        self._sections = sections
        
        return self._sections!
    }
    var _sections: [Section]?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        //Move to selected currency
        for (sectionindex, section) in enumerate(sections) {
            for (rowindex, currency) in enumerate(section.currencies) {
                if currency.abbrev == user?.defaultCurrency {
                    selectedIndexPath = NSIndexPath(forRow:rowindex, inSection:sectionindex)
                }
            }
        }

        
        if selectedIndexPath != nil {
            dispatch_async(dispatch_get_main_queue(), {
                self.currenciesTableView.scrollToRowAtIndexPath(self.selectedIndexPath!, atScrollPosition: UITableViewScrollPosition.Top, animated: false)
            })
        }
    }
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return self.sections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return self.sections[section].currencies.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CurrencyCell", forIndexPath: indexPath) as UITableViewCell
        
        // Configure the cell...
        let currency = self.sections[indexPath.section].currencies[indexPath.row]
        cell.textLabel?.text = currency.name

        //Determine whether the selected index path
        if currency.abbrev == user?.defaultCurrency {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    /* section headers appear above each `UITableView` section */
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String {
            // do not display empty `Section`s
            if !self.sections[section].currencies.isEmpty {
                return self.collation.sectionTitles[section] as String
            }
            return "" //Only works correct if table style is plain, otherwise height of the next section header will be too big
    }
    /* section index titles displayed to the right of the `UITableView` */
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject] {
            return self.collation.sectionIndexTitles
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
            return self.collation.sectionForSectionIndexTitleAtIndex(index)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        //Other row is selected - need to deselect it
        if let index = selectedIndexPath {
            let cell = tableView.cellForRowAtIndexPath(index)
            cell?.accessoryType = .None
        }
        
        //Update currency
        selectedIndexPath = indexPath
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        let currency = self.sections[indexPath.section].currencies[indexPath.row]

        user?.defaultCurrency = currency.abbrev
        cell?.accessoryType = .Checkmark
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
