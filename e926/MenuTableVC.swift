//
//  MenuTableVC.swift
//  E621
//
//  Created by Austin Chau on 10/8/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import UIKit

class MenuTableVC: UITableViewController {
    
    let profileCellID = "profileCell"
    let defaultCellID = "defaultCell"
    let showSettingsTableVC = "showSettingsTableVC"
    let showWatchSettingsTableVC = "showWatchSettingsTableVC"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        
        tableView.backgroundColor = Theme.colors().background
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0, 1, 2: return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: profileCellID, for: indexPath) as! MenuTableVCProfileCell
            
            cell.profileLabel.textColor = Theme.colors().text
            
            if Identity.main.isLoggedIn == true {
                let user = Identity.main.user!
                cell.profileLabel.text = user.metadata.name
                
                _ = user.getAvatar()
                    .then { data -> Void in
                        cell.profileImageView.image = UIImage(data: data) ?? nil
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }
            } else {
                cell.profileLabel.text = "Not logged in"
            }
            
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: defaultCellID, for: indexPath) as! MenuTableVCDefaultCell
            
            cell.mainLabel.textColor = Theme.colors().text
            
            cell.mainLabel.text = "Settings"
            
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: defaultCellID, for: indexPath) as! MenuTableVCDefaultCell
            
            cell.mainLabel.textColor = Theme.colors().text
            
            cell.mainLabel.text = "Apple Watch"
            
            return cell
        default:
            return UITableViewCell()
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return 80
        case 1, 2: return 50
        default: return 44
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            LoginManager().signInThroughForm(username: "", password: "")
            tableView.deselectRow(at: indexPath, animated: true)
        case 1:
            switch indexPath.row {
            case 0: performSegue(withIdentifier: showSettingsTableVC, sender: self)
            default: tableView.deselectRow(at: indexPath, animated: true)
            }
        case 2:
            switch indexPath.row {
            case 0: performSegue(withIdentifier: showWatchSettingsTableVC, sender: self)
            default: tableView.deselectRow(at: indexPath, animated: true)
            }
        default: tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

extension MenuTableVC: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController == self {
            navigationController.setNavigationBarHidden(true, animated: animated)
        } else {
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
    }
}

class MenuTableVCProfileCell: UITableViewCell {
    
    @IBOutlet weak var viewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileLabel: UILabel!
    
}

class MenuTableVCDefaultCell: UITableViewCell {
    
    @IBOutlet weak var viewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var mainLabel: UILabel!
    
}






