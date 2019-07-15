//
//  KsadsVC.swift
//  OpenAssessments
//
//  Created by Alex DeCastro on 6/22/19.
//  Copyright © 2019 UCSD. All rights reserved.
//

import UIKit

protocol KsadsVCDelegate:class {
    func childVCDidSave(_ controller: KsadsVC, text: String)
}

class KsadsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    weak var delegate: KsadsVCDelegate?
    
    // Inputs
    var site: String?
    var pGUID: String?
    var visit: String?
    var email: String?
    var selectedParentTeen: String?

    var selectedLanguage: String?
    var selectedSession: String?
    var startTaskEnabled = false
    
    @IBOutlet weak var participantTableView: UITableView!
    @IBOutlet weak var detailTableView: UITableView!
    
    var startTaskCell: UITableViewCell!
    
    let infoSectionTitles = ["pGUID", "Visit", "Select a session"]
    let infoCellTitles =
        [[""],
         [""],
         ["1", "2", "3"]]
    
    let visitDictionary =
        ["1_year_follow_up_y_arm_1": "1 Year Follow up (Year 2)",
         "2_year_follow_up_y_arm_1": "2 Year Follow up (Year 3)",
         "3_year_follow_up_y_arm_1": "3 Year Follow up (Year 4)"]

    // processing@abcd-report:/var/www/html/applications/ksads/mapping.json
    private let ksadsGroupDictionary =
        ["TEST": "9",
         "TESTFITBIT": "9",
         "CHLA": "15",
         "FIU":  "16",
         "MSSM": "24",
         "LIBR": "14",
         "MUSC": "41",
         "OHSU": "10",
         "SRI":  "26",
         "UCSD": "9",
         "UCLA": "19",
         "CUB":  "12",
         "UFL":  "27",
         "OAHU": "22",
         "UMB":  "22",
         "UMICH":"23",
         "UMN":  "28",
         "UPMC": "25",
         "UTAH": "20",
         "UVM":  "21",
         "UWM":  "40",
         "VCU":  "18",
         "WUSTL":"13",
         "YALE": "17",
         "ROC":  "42"]
    
    let taskListSectionTitles =
        ["Session Language", "Start the task"]
    
    let taskListCellTitles =
        [["English", "Spanish"],
         ["Start K-SADS"]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        detailTableView.allowsMultipleSelection = true
        
        if (self.site == nil) {
            print("ERROR: KsadsVC: viewDidLoad: site was not set.")
            return
        }
        if (self.pGUID == nil) {
            print("ERROR: KsadsVC: viewDidLoad: pGUID was not set.")
            return
        }
        if (self.visit == nil) {
            print("ERROR: KsadsVC: viewDidLoad: visit was not set.")
            return
        }
        if (self.selectedParentTeen == nil) {
            print("ERROR: KsadsVC: viewDidLoad: selectedParentTeen was not set.")
            return
        }
        if (self.selectedParentTeen == "Parent") {
            self.title = "Parent K-SADS"
        } else if (self.selectedParentTeen == "Teen"){
            self.title = "Teen K-SADS"
        } else {
            print("ERROR: KsadsVC: viewDidLoad: Invalid value for selectedParentTeen: \(String(describing: self.selectedParentTeen))")
            return
        }
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == self.participantTableView {
            return infoCellTitles.count
        } else {
            return taskListCellTitles.count
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.participantTableView {
            return infoCellTitles[section].count
        } else {
            if ((section == 0) && (self.selectedParentTeen == "Teen")) {
                return 0
            } else {
                return taskListCellTitles[section].count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == self.participantTableView {
            return infoSectionTitles[section]
        } else {
            if ((section == 0) && (self.selectedParentTeen == "Teen")) {
                return nil
            } else {
                return taskListSectionTitles[section]
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.participantTableView {
            let identifier = "InfoCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
            cell.textLabel!.text = infoCellTitles[indexPath.section][indexPath.row]
            
            if (indexPath.section == 0) {
                // Display the pGUID
                cell.textLabel!.text = pGUID
            }
            if (indexPath.section == 1) {
                // Display the visit
                if let visit = self.visit {
                    cell.textLabel!.text = visitDictionary[visit]
                }
            }
            
            if (indexPath.section == 2) {
                // Enable user interaction for selecting the session
                cell.selectionStyle = .default
                cell.isUserInteractionEnabled = true
            } else {
                cell.selectionStyle = .none
                cell.isUserInteractionEnabled = false
            }
            return cell
        } else {
            let identifier = "TaskListCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
            cell.textLabel!.text = taskListCellTitles[indexPath.section][indexPath.row]
            
            if (indexPath.section == 0) { // Language
                //let selectedIndexPaths = tableView.indexPathsForSelectedRows
                //let rowIsSelected = selectedIndexPaths != nil && selectedIndexPaths!.contains(indexPath)
                //cell.accessoryType = rowIsSelected ? .checkmark : .none
            } else if (indexPath.section == 1) {
                // Initialize and disable the Start Task button
                startTaskCell = cell
                startTaskCell.textLabel!.textAlignment = .center
                enableStartButton(enable: false)
            }
            return cell
        }
    }
    
    private func enableStartButton(enable: Bool) {
        startTaskEnabled = enable
        startTaskCell.textLabel!.textColor = enable ? view.tintColor : UIColor.gray
        startTaskCell.isUserInteractionEnabled = enable
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.participantTableView {
            print("KsadsVC: didSelectRowAt: Info Table: Section: \(indexPath.section) Row: \(indexPath.row)")
            if (indexPath.section == 2) {
                // The user selected a session
                if let cell = tableView.cellForRow(at: indexPath) {
                    cell.accessoryType = .checkmark
                    selectedSession = "0\(indexPath.row+1)"
                    if ((selectedSession != nil) && (selectedLanguage != nil)) {
                        enableStartButton(enable: true)
                    }
                }
            }
        } else {
            if (indexPath.section == 1) {
                // The user pressed the start task button
                if (startTaskEnabled) {
                    startTask()
                }
            } else {
                print("KsadsVC: didSelectRowAt: TaskList Table: Section: \(indexPath.section) Row: \(indexPath.row)")
                // The user selected a task
                if let cell = tableView.cellForRow(at: indexPath) {
                    cell.accessoryType = .checkmark
                    cell.isUserInteractionEnabled = false // Try to prevent the user from selecting this cell again
                    // Deselect the other rows in this section
                    if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
                        for ip in selectedIndexPaths {
                            if ((ip.section == indexPath.section) && (ip.row != indexPath.row)) {
                                forceDeselect(tableView, indexPath: ip)
                            }
                        }
                    }
                    if (indexPath.section == 0) {
                        selectedLanguage = cell.textLabel!.text
                        print("selectedLanguage: \(String(describing: selectedLanguage))")
                        if ((selectedSession != nil) && (selectedLanguage != nil)) {
                            enableStartButton(enable: true)
                        }
                    }
                }
            }
        }
    }
    
    // Forcefully deselect this table cell
    private func forceDeselect(_ tableView: UITableView, indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if let cell = tableView.cellForRow(at: indexPath as IndexPath) {
            cell.accessoryType = .none
            cell.isUserInteractionEnabled = true // Make sure this cell can be selected
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView == self.participantTableView {
            if (indexPath.section == 2) {
                // Deselect a session
                if let cell = tableView.cellForRow(at: indexPath) {
                    cell.accessoryType = .none
                }
            }
        } else {
            if (indexPath.section < 1) {
                // Deselect a task
                if let cell = tableView.cellForRow(at: indexPath as IndexPath) {
                    cell.accessoryType = .none
                }
            }
        }
    }
    
    private func startTask() {
        enableStartButton(enable: false)
        
        guard let site = self.site else {
            print("ERROR: site was not set.")
            return
        }
        guard let pGUID = self.pGUID else {
            print("ERROR: pGUID was not set.")
            return
        }
        guard let email = self.email else {
            print("ERROR: email was not set.")
            return
        }
        guard let visit = self.visit else {
            print("ERROR: visit was not set.")
            return
        }
        guard let selectedParentTeen = self.selectedParentTeen else {
            print("ERROR: You did not select parent or teen.")
            return
        }
        guard let selectedLanguage = self.selectedLanguage else {
            print("ERROR: You did not select a selectedLanguage.")
            return
        }
        guard let session = self.selectedSession else {
            print("ERROR: You did not select a session.")
            return
        }
        
        
        let token = "<Token Not Shown>"
        let accountName = email.replacingOccurrences(of: "@", with: "%40")
        let group = ksadsGroupDictionary[site]!
        let ksadsVisit = visit.replacingOccurrences(of: "_", with: "")
        let subjectID = "\(pGUID)_\(ksadsVisit)_\(session)"
        let patientType = (selectedParentTeen == "Parent") ? "P" : "T"
        let language = (selectedLanguage == "English") ? "en" : "esp"
        
        let urlString = "https://www.ksads.net/Login.aspx?Token=\(token)&AccountName=\(accountName)&Group=\(group)&SubjectID=\(subjectID)&PatientType=\(patientType)&Visit=\(ksadsVisit)&Language=\(language)&Run=\(session)"
        
        let message = "Type: '\(selectedParentTeen)'\nLanguage: \(selectedLanguage)\nSession: \(session)"
        self.presentAlertWithTitle(title: "Is this correct?", message: message, options: ["Yes", "No"]) { (option) in
            print("option: \(option)")
            switch(option) {
            case 0:
                print("Open K-SADS: \(urlString)")
                UIApplication.shared.open(NSURL(string:urlString)! as URL)
                break
            case 1:
                print("The RA did not confirm.")
                break
            default:
                break
            }
        }
    }
}
