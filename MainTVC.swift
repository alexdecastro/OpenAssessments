//
//  MainTVC.swift
//  OpenAssessments
//
//  Created by Alex DeCastro on 5/18/19.
//  Copyright © 2019 UCSD. All rights reserved.
//

import UIKit

extension Dictionary {
    func percentEscaped() -> String {
        return map { (key, value) in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
            }
            .joined(separator: "&")
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}

class MainTVC: UITableViewController, ChildVCDelegate, MillisecondVCDelegate, KsadsVCDelegate {
    
    // input
    var site: String?
    var username: String?
    var email: String?
    @IBOutlet weak var loginInfoLabel: UILabel!
    
    @IBOutlet weak var firstBarcodeLabel: UILabel!
    
    @IBOutlet weak var secondBarcodeTableViewCell: UITableViewCell!
    @IBOutlet weak var secondBarcodeButtonLabel: UILabel!
    @IBOutlet weak var secondBarcodeLabel: UILabel!
    
    @IBOutlet weak var barcodeMatchTableViewCell: UITableViewCell!
    @IBOutlet weak var barcodeMatchLabel: UILabel!
    
    @IBOutlet weak var selectedVisitLabel: UILabel!
    
    @IBOutlet weak var redcapTableViewCell: UITableViewCell!
    @IBOutlet weak var redcapButtonLabel: UILabel!
    
    private var segueIdentifier: String?
    
    private let tokenDictionary = ["TEST": "<Tokens Not Shown>"]
    
    private let visitDictionary =
        ["baseline_year_1_arm_1": "Baseline (Year 1)",
         "6_month_follow_up_arm_1": "6 month Follow up (Year 0.5)",
         "1_year_follow_up_y_arm_1": "1 Year Follow up (Year 2)",
         "18_month_follow_up_arm_1": "18 month Follow up (Year 2.5)",
         "2_year_follow_up_y_arm_1": "2 Year Follow up (Year 3)",
         "30_month_follow_up_arm_1": "30 month Follow up (Year 3.5)",
         "3_year_follow_up_y_arm_1": "3 Year Follow up (Year 4)",
         "42_month_follow_up_arm_1": "42 month Follow up (Year 4.5)",
         "4_year_follow_up_y_arm_1": "4 Year Follow up (Year 5)",
         "54_month_follow_up_arm_1": "54 month Follow up (Year 5.5)",
         "5_year_follow_up_y_arm_1": "5 Year Follow up (Year 6)"]
    
    private var hideTasks = true
    
    private var pGUID: String?
    private func setpGUID(newValue: String?) {
        pGUID = newValue
        if let n = newValue {
            barcodeMatchLabel.text = "pGUID: \(n)"
            barcodeMatchLabel.textColor = view.tintColor
            barcodeMatchLabel.backgroundColor = UIColor.init(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.25)
        } else {
            barcodeMatchLabel.text = "No pGUID"
            barcodeMatchLabel.textColor = UIColor.gray
            barcodeMatchLabel.backgroundColor = UIColor.white
        }
    }
    
    private var selectedVisit: String?
    private func setSelectedVisit(newValue: String?) {
        selectedVisit = newValue
        if let n = newValue,
            let text = visitDictionary[n] {
            selectedVisitLabel.text = "Visit: \(text)"
            selectedVisitLabel.textColor = UIColor.black
            selectedVisitLabel.backgroundColor = UIColor.white
            enableTaskButtons(enable: true)
        } else {
            selectedVisitLabel.text = "No visit"
            selectedVisitLabel.textColor = UIColor.gray
            selectedVisitLabel.backgroundColor = UIColor.white
            enableTaskButtons(enable: false)
        }
    }
    
    // Enable buttons to open tasks
    private func enableTaskButtons(enable: Bool) {
        self.hideTasks = !enable
        self.barcodeMatchTableViewCell.isUserInteractionEnabled = enable
        self.redcapTableViewCell.isUserInteractionEnabled = enable
        if (enable) {
            redcapButtonLabel.textColor = view.tintColor
        } else {
            redcapButtonLabel.textColor = UIColor.gray
        }
        DispatchQueue.main.async { self.tableView.reloadData() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let site = self.site else {
            print("ERROR: MainTVC: viewDidLoad: site was not set.")
            return
        }
        guard let username = self.username else {
            print("ERROR: MainTVC: viewDidLoad: username was not set.")
            return
        }
        guard let email = self.email else {
            print("ERROR: MainTVC: viewDidLoad: email was not set.")
            return
        }
        let loginInfo = "Site: \(site) User: \(username) Email: \(email)"
        self.loginInfoLabel.text = loginInfo
        print("MainTVC: viewDidLoad: loginInfo: \(loginInfo)")
        
        secondBarcodeTableViewCell.isUserInteractionEnabled = false
        secondBarcodeButtonLabel.textColor = UIColor.gray
        
        setpGUID(newValue: nil)
        setSelectedVisit(newValue: nil)
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ((self.hideTasks) && (section == 4)) {
            return 0
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if ((self.hideTasks) && (section == 4)) {
            return nil
        }
        return super.tableView(tableView, titleForHeaderInSection: section)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        segueIdentifier = segue.identifier
        print("MainTVC: prepare: for segue: segueIdentifier: \(segueIdentifier ?? "nil")")
        
        if ((segueIdentifier == "FirstBarcode") ||
            (segueIdentifier == "SecondBarcode")) {
            let vc = segue.destination as! ScannerVC
            vc.delegate = self
        } else if (segueIdentifier == "MillisecondVC") {
            let vc = segue.destination as! MillisecondVC
            vc.delegate = self
            vc.site = self.site
            vc.pGUID = self.pGUID
            vc.visit = self.selectedVisit
        } else if (segueIdentifier == "ParentKsadsVC") {
            let vc = segue.destination as! KsadsVC
            vc.delegate = self
            vc.site = self.site
            vc.pGUID = self.pGUID
            vc.visit = self.selectedVisit
            vc.email = self.email
            vc.selectedParentTeen = "Parent"
        } else if (segueIdentifier == "TeenKsadsVC") {
            let vc = segue.destination as! KsadsVC
            vc.delegate = self
            vc.site = self.site
            vc.pGUID = self.pGUID
            vc.visit = self.selectedVisit
            vc.email = self.email
            vc.selectedParentTeen = "Teen"
            vc.selectedLanguage = "English"
        } else {
            print("ERROR: Unknown segueIdentifier: \(String(describing: segueIdentifier))")
        }
    }
    
    func childVCDidSave(_ controller: ScannerVC, text: String) {
        print("MainTVC: childVCDidSave: ScannerVC: text: '\(text)'")
        let text = text.trimmingCharacters(in: CharacterSet(charactersIn: " \r\n"))
        print("MainTVC: childVCDidSave: ScannerVC: text: '\(text)'")
        if (segueIdentifier == "FirstBarcode") {
            firstBarcodeLabel.text = text
            secondBarcodeTableViewCell.isUserInteractionEnabled = true
            secondBarcodeButtonLabel.textColor = view.tintColor
        } else if (segueIdentifier == "SecondBarcode") {
            secondBarcodeLabel.text = text
        } else {
            print("ERROR: childVCDidSave: segueIdentifier: \(segueIdentifier ?? "nil")")
        }
        checkIfBarcodesMatch()
        controller.navigationController!.popViewController(animated: true)
    }
    
    private func checkIfBarcodesMatch() {
        enableTaskButtons(enable: false)
        if ((firstBarcodeLabel.text == "--------") ||
            (secondBarcodeLabel.text == "--------")) {
            setpGUID(newValue: nil)
            return
        }
        if let site = self.site,
            let alternateID = firstBarcodeLabel.text,
            let pGUID = secondBarcodeLabel.text {
            checkIfpGUIDAndAlternateIDMatch(site: site, pGUID: pGUID, alternateID: alternateID, completion: { response,isMatch  in
                print("completion: response: \(response) isMatch: \(isMatch)")
                DispatchQueue.main.async {
                    self.updateMatchLabel(response: response, isMatch: isMatch)
                }
            })
        }
    }
    
    // Check the PII database to see if the pGUID and alternate ID match
    private func checkIfpGUIDAndAlternateIDMatch(
        site: String,
        pGUID: String,
        alternateID: String,
        completion: @escaping ( _ response: String, _ isMatch: Bool ) -> Void) {
        
        let url = URL(string: "https://abcdcontact.me/checkMatchClient.php")!
        
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        let parameters: [String: Any] = [
            "action": "checkMatch",
            "site": site,
            "pGUID": pGUID,
            "alternateID": alternateID,
            "array": ["1","2","3"]
        ]
        print("DEBUG: checkIfpGUIDAndAlternateIDMatch: parameters: \(parameters)")
        
        request.httpBody = parameters.percentEscaped().data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {
                    // check for fundamental networking error
                    print("error", error ?? "Unknown error")
                    return
            }
            
            print("checkIfpGUIDAndAlternateIDMatch:----------")
            
            guard (200 ... 299) ~= response.statusCode else {
                // check for http errors
                print("response = \(response)")
                let message = "ERROR: statusCode should be 2xx, but is \(response.statusCode) for URL: \(url)"
                completion(message, false)
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("responseString = \(String(describing: responseString))")
                if (responseString == "") {
                    let message = "ERROR: checkIfpGUIDAndAlternateIDMatch: responseString is empty."
                    completion(message, false)
                    return;
                }
                let responseDict = self.convertJSONToDictionary(text: responseString)
                print("responseDict: \(responseDict as AnyObject)")
                
                if let isMatch = responseDict?["match"] as! Bool? {
                    print("checkIfpGUIDAndAlternateIDMatch: isMatch: \(isMatch)")
                    completion(responseString, isMatch)
                } else {
                    let message = "ERROR: checkIfpGUIDAndAlternateIDMatch: responseDict?['match'] not found."
                    completion(message, false)
                    return;
                }
            }
        }
        
        task.resume()
    }
    
    // Update the label that shows if the pGUID and alternate ID match
    private func updateMatchLabel(response: String, isMatch: Bool) {
        if (!isMatch) {
            barcodeMatchLabel.text = response
            barcodeMatchLabel.textColor = UIColor.black
            barcodeMatchLabel.backgroundColor = UIColor.red
            
            self.presentAlertWithTitle(title: "Alternate ID does not match pGUID", message: response, options: ["OK"]) { (option) in
                print("option: \(option)")
                switch(option) {
                case 0:
                    print("Copied error message")
                    UIPasteboard.general.string = response
                    break
                default:
                    break
                }
            }
            return;
        }
        
        if let pGUID = secondBarcodeLabel.text {
            
            setpGUID(newValue: pGUID)
            
            guard let site = self.site else {
                print("ERROR: updateMatchLabel: self.site was not set.")
                return
            }
            readVisitFromREDCap(site: site, pGUID: pGUID, completion: { visit,success in
                print("completion: expectedVisit: \(visit) success: \(success)")
                DispatchQueue.main.async {
                    if (success) {
                        var expectedVisit = visit
                        if (expectedVisit == "6_month_follow_up_arm_1") {
                            expectedVisit = "1_year_follow_up_y_arm_1"
                        }
                        if ((expectedVisit == "1_year_follow_up_y_arm_1") ||
                            (expectedVisit == "2_year_follow_up_y_arm_1") ||
                            (expectedVisit == "3_year_follow_up_y_arm_1")) {
                            print("DEBUG: updateMatchLabel: Found expectedVisit: \(expectedVisit)")
                            let message = "'\(self.visitDictionary[expectedVisit] ?? "Unknown visit")'\nIs this the correct visit?"
                            self.presentAlertWithTitle(title: "Expected Visit", message: message, options: ["Yes", "No"]) { (option) in
                                print("option: \(option)")
                                switch(option) {
                                case 0:
                                    print("The RA confirmed the expected visit is correct.")
                                    self.setSelectedVisit(newValue: expectedVisit)
                                    self.enableTaskButtons(enable: true)
                                    break
                                case 1:
                                    print("The RA says expected visit is wrong, so ask them to selected a visit.")
                                    self.askRAToSelectVisit(expectedVisit: expectedVisit)
                                    break
                                default:
                                    break
                                }
                            }
                        } else {
                            self.setSelectedVisit(newValue: nil)
                            self.enableTaskButtons(enable: false)
                            
                            print("ERROR: updateMatchLabel: Invalid expectedVisit: \(expectedVisit)")
                            let message = "'\(expectedVisit)' is not a valid visit."
                            self.presentAlertWithTitle(title: "ERROR: Invalid expected visit", message: message, options: ["OK"]) { (option) in
                                print("option: \(option)")
                                switch(option) {
                                case 0:
                                    print("OK pressed")
                                    break
                                default:
                                    break
                                }
                            }
                        }
                    } else { // (!success)
                        self.presentAlertWithTitle(title: "ERROR: pGUID not in REDCap", message: visit, options: ["OK"]) { (option) in
                            print("option: \(option)")
                            switch(option) {
                            case 0:
                                print("OK pressed")
                                break
                            default:
                                break
                            }
                        }
                    }
                }
            })
        }
    }
    
    // Ask the RA to select a visit
    private func askRAToSelectVisit(expectedVisit: String) {
        let message = "What is the correct visit?"
        let options = [visitDictionary["1_year_follow_up_y_arm_1"]!,
                       visitDictionary["2_year_follow_up_y_arm_1"]!,
                       visitDictionary["3_year_follow_up_y_arm_1"]!,
                       "Don't know"]
        
        self.presentAlertWithTitle(title: "Select Visit", message: message, options: options) { (option) in
            print("option: \(option)")
            switch(option) {
            case 0:
                self.setSelectedVisit(newValue: "1_year_follow_up_y_arm_1")
                break
            case 1:
                self.setSelectedVisit(newValue: "2_year_follow_up_y_arm_1")
                break
            case 2:
                self.setSelectedVisit(newValue: "3_year_follow_up_y_arm_1")
                break
            case 3: // The RA doesn't know, so use the expected visit
                self.setSelectedVisit(newValue: expectedVisit)
                break
            default:
                break
            }
        }
    }
    
    // Read the expected visit from REDCap
    private func readVisitFromREDCap(
        site: String,
        pGUID: String,
        completion:@escaping (( _ visit: String, _ success: Bool )-> Void)) {
        
        let url = URL(string: "https://abcd-rc.ucsd.edu/redcap/api/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        guard let token = tokenDictionary[site] else {
            print("ERROR: readVisitFromREDCap: Could not find token for site: \(site)")
            return
        }
        
        let parameters: [String: Any] = [
            "token": token,
            "content": "record",
            "format": "json",
            "type": "flat",
            "records[0]": pGUID,
            "fields[0]": "sched_current_event_done",
            "fields[1]": "sched_last_event",
            "events[0]": "screener_arm_1",
            "rawOrLabel": "raw",
            "rawOrLabelHeaders": "raw",
            "exportCheckboxLabel": "false",
            "exportSurveyFields": "false",
            "exportDataAccessGroups": "false",
            "returnFormat": "json"
        ]
        request.httpBody = parameters.percentEscaped().data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {
                    // check for fundamental networking error
                    print("error", error ?? "Unknown error")
                    return
            }
            
            print("readVisitFromREDCap:----------")
            
            guard (200 ... 299) ~= response.statusCode else {
                // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("responseString = \(responseString)")
                if (responseString == "[]") {
                    let message = "ERROR: pGUID: '\(pGUID)' not found in REDCap."
                    completion(message, false)
                    return
                }
                
                let responseDict = self.convertJSONArrayToDictionary(text: responseString)
                print("responseDict: \(responseDict as AnyObject)")
                
                if let sched_current_event_done = responseDict?[0]["sched_current_event_done"] {
                    print("sched_current_event_done: \(String(describing: sched_current_event_done))")
                    let sched_current_event_done_items = (sched_current_event_done as! String).split(separator: ",")
                    print("sched_current_event_done_items: '\(sched_current_event_done_items)'")
                    if (sched_current_event_done_items.count > 2) {
                        let sched_current_event_done_visit = sched_current_event_done_items[1].trimmingCharacters(in: .whitespaces)
                        print("sched_current_event_done_visit: '\(sched_current_event_done_visit)'")
                    }
                }
                
                if let sched_last_event = responseDict?[0]["sched_last_event"] {
                    print("sched_last_event: \(String(describing: sched_last_event))")
                    let sched_last_event_items = (sched_last_event as! String).split(separator: ",")
                    print("sched_last_event_items: '\(sched_last_event_items)'")
                    if (sched_last_event_items.count == 2) {
                        let sched_last_event_visit = sched_last_event_items[0].trimmingCharacters(in: .whitespaces)
                        print("sched_last_event_visit: '\(sched_last_event_visit)'")
                        completion(sched_last_event_visit, true)
                    }
                }
            }
        }
        
        task.resume()
    }
    
    // Utility to convert a JSON string into a dictionary
    private func convertJSONToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    private func convertJSONArrayToDictionary(text: String) -> [Dictionary<String,Any>]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [Dictionary<String,Any>]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func childVCDidSave(_ controller: MillisecondVC, text: String) {
        print("MainTVC: childVCDidSave: MillisecondVC: text: \(text)")
    }
    
    func childVCDidSave(_ controller: KsadsVC, text: String) {
        print("MainTVC: childVCDidSave: KsadsVC: text: \(text)")
    }
    
    // Handle table cell selections
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        print("indexPath.section = \(indexPath.section)")
        print("indexPath.row = \(indexPath.row)")
        
        if ((indexPath.section == 3) && (indexPath.row == 0)) {
            if let pGUID = secondBarcodeLabel.text {
                copypGUID(pGUID: pGUID)
            }
        }
        if ((indexPath.section == 4) && (indexPath.row == 0)) {
            openREDCapChildAssentForm()
        }
        if ((indexPath.section == 5) && (indexPath.row == 0)) {
            reset()
        }
        if ((indexPath.section == 5) && (indexPath.row == 1)) {
            logout()
        }
    }
    
    // Open the REDCap Child Assent form
    private func openREDCapChildAssentForm() {
        
        if let pGUID = secondBarcodeLabel.text,
            let visit = self.selectedVisit {
            var event_id: Int
            if (visit == "1_year_follow_up_y_arm_1") {
                event_id = 41
            } else if (visit == "2_year_follow_up_y_arm_1") {
                event_id = 50
            } else if (visit == "3_year_follow_up_y_arm_1") {
                event_id = 61
            } else {
                print("ERROR: Unknown visit: \(visit)")
                return
            }
            print("event_id: \(event_id)")
            
            let urlString = "https://abcd-rc.ucsd.edu/redcap/redcap_v8.10.0/DataEntry/index.php?pid=12&id=\(pGUID)&event_id=\(event_id)&page=assent"
            print("Open REDCap URL: \(urlString)")
            UIApplication.shared.open(NSURL(string:urlString)! as URL)
        }
    }
    
    // Reset the page
    private func reset() {
        self.firstBarcodeLabel.text = "--------"
        self.secondBarcodeLabel.text = "--------"
        
        self.secondBarcodeTableViewCell.isUserInteractionEnabled = false
        self.secondBarcodeButtonLabel.textColor = UIColor.gray
        
        setpGUID(newValue: nil)
        setSelectedVisit(newValue: nil)
    }
    
    // Reset the page
    private func logout() {
    }
    
    private func copypGUID(pGUID: String) {
        UIPasteboard.general.string = pGUID
        let message = "\(pGUID)"
        self.presentAlertWithTitle(title: "Copied pGUID", message: message, options: ["OK"]) { (option) in
            print("option: \(option)")
            switch(option) {
            case 0:
                print("OK pressed")
                break
            default:
                break
            }
        }
    }
}
