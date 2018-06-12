//
//  CreateGroupTVC.swift
//  smallsteps
//
//  Created by Jin Sun Park on 05/06/2018.
//  Copyright © 2018 group29. All rights reserved.
//

import UIKit
import Eureka
import Alamofire
import CoreLocation

class CreateGroupVC: FormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    
        let nextButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(CreateGroupVC.createGroup))
        nextButton.isEnabled = false
        self.navigationItem.rightBarButtonItem = nextButton
        
        form +++ Section("Group Details")
            <<< TextRow(){ row in
                row.tag = "groupName"
                row.title = "Name"
                row.placeholder = "Enter group name here"
                row.add(rule: RuleRequired(msg: "This field is required"))
                row.validationOptions = .validatesOnDemand
                }.cellUpdate { cell, row in
                    self.form.validate()
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                        nextButton.isEnabled = false
                    } else {
                        nextButton.isEnabled = true
                    }
                }
            +++ Section("Meeting Date and Time")
            <<< DateTimeRow(){
                $0.tag = "datetime"
                $0.title = "Date and Time"
                $0.value = Date()
            }
            <<< ActionSheetRow<String>() {
                $0.tag = "repeat"
                $0.title = "Repeat"
                $0.selectorTitle = "Pick a Day"
                $0.options = ["Daily"]
                $0.value = "Daily"    // initially selected
            }
            <<< CountDownRow() {
                $0.tag = "duration"
                $0.title = "Estimated Duration"
                $0.value = Calendar.current.date(bySettingHour: 0, minute: 30, second: 0, of: Date())

            }
            +++ Section("Details")
            <<< SwitchRow() { row in
                row.tag = "hasDogs"
                row.title = "Dog Friendly"
            }
//            <<< SwitchRow() { row in
//                row.tag = "hasKids"
//                row.title = "With Kids"
//            }
            <<< LocationRow("location") {
                $0.title = "Location"
                $0.tag = "location"
                let locManager = CLLocationManager()
                $0.value = CLLocation(latitude: (locManager.location?.coordinate.latitude)!, longitude: (locManager.location?.coordinate.longitude)!)
                }.onChange { [weak self] row in
                    self!.tableView!.reloadData()
            }
        
    }
    
    @objc func setLocation() {
        performSegue(withIdentifier: "setLocation", sender: self)
    }
    
    @objc func createGroup() {
      
        let valuesDict = form.values()
        print(type(of: valuesDict))
        
        let newGroup: Group = Group(groupName: valuesDict["groupName"] as! String,
                                    datetime: valuesDict["datetime"] as! Date,
                                    repeats: valuesDict["repeat"] as! String ,
                                    duration: valuesDict["duration"] as! Date,
                                    latitude: "\(((form.rowBy(tag: "location") as? LocationRow)?.value?.coordinate.latitude)!)",
                                    longitude: "\(((form.rowBy(tag: "location") as? LocationRow)?.value?.coordinate.longitude)!)",
                                    hasDog: ((form.rowBy(tag: "hasDogs") as? SwitchRow)?.cell.switchControl.isOn)!,
//                                    hasKid: ((form.rowBy(tag: "hasKids") as? SwitchRow)?.cell.switchControl.isOn)!,
                                    adminID: UIDevice.current.identifierForVendor!.uuidString)
        print("Group created \(newGroup.groupName)")
        
      
        //Create the walker parameters
        let groupParams: Parameters = [
            "name": newGroup.groupName,
            "time": removeTimezone(datetime: newGroup.datetime),
            "admin_id": newGroup.adminID,
            "location_latitude": newGroup.latitude,
            "location_longitude": newGroup.longitude,
            "duration": getHoursMinutesSeconds(time: newGroup.duration),
            "has_dogs": false,
            "has_kids": false
        ]
//        GroupMenuTVC.loadYourGroups()

        //POST the JSON to the server
        Alamofire.request("http://146.169.45.120:8080/smallsteps/groups", method: .post, parameters: groupParams, encoding: JSONEncoding.default)
            .response {response in
                print(groupParams)
                print("POStedddddddddd")
                print(response.response?.statusCode ?? "no response!")

        }
        self.performSegue(withIdentifier: "returnHome", sender: nil)

        //self.tabBarController?.selectedIndex = 0
        
    }
    
    func removeTimezone(datetime: Date) -> String {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        let newDate: String = dateFormatter.string(for: datetime)!
        //print("THE NEW DATE IS: \(newDate)")
        return newDate
    }
    
    
    func getHoursMinutesSeconds(time: Date) -> String {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm:ss"
        let newTime: String = dateFormatter.string(for: time)!
        print("THE NEW TIME IS: \(newTime)")

        return newTime
    }
}
