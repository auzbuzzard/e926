//
//  SettingsTableVC.swift
//  E621
//
//  Created by Austin Chau on 10/8/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import UIKit

class SettingsTableVC: UITableViewController {
    
    @IBOutlet weak var useE621ModeSwitch: UISwitch!
    @IBAction func useE621ModeSwitchDidChange(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: Preferences.useE621Mode.rawValue)
        NotificationCenter.default.post(name: Notification.Name.init(rawValue: Preferences.useE621Mode.rawValue), object: nil)
        
    }
    @IBOutlet weak var useStrongFiltersSwitch: UISwitch!
    @IBAction func useStrongFiltersSwitchDidChange(_ sender: UISwitch) {
        if sender.isOn {
            UserDefaults.standard.set(false, forKey: Preferences.useE621Mode.rawValue)
            useE621ModeSwitch.setOn(false, animated: true)
            useE621ModeSwitch.isEnabled = false
        } else {
            useE621ModeSwitch.isEnabled = true
        }
        UserDefaults.standard.set(sender.isOn, forKey: Preferences.useStrongFilters.rawValue)
        NotificationCenter.default.post(name: Notification.Name.init(rawValue: Preferences.useStrongFilters.rawValue), object: nil)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        useE621ModeSwitch.isOn = UserDefaults.standard.bool(forKey: Preferences.useE621Mode.rawValue)
        useStrongFiltersSwitch.isOn = UserDefaults.standard.bool(forKey: Preferences.useStrongFilters.rawValue)
    }

}
