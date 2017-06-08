//
//  WatchSettingTableVC.swift
//  e926
//
//  Created by Austin Chau on 6/6/17.
//  Copyright © 2017 Austin Chau. All rights reserved.
//

import UIKit

class WatchSettingTableVC: UITableViewController {
    
    private let inputCellID = "inputCell"
    
    var vm: FavoritesSearchTagsVM!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        vm = FavoritesSearchTagsVM()
        
        navigationItem.rightBarButtonItem = editButtonItem
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    func showEditing(sender: UIBarButtonItem) {
        if tableView.isEditing == true {
            tableView.isEditing = false
            navigationItem.rightBarButtonItem?.title = "Done"
        } else {
            tableView.isEditing = true
            navigationItem.rightBarButtonItem?.title = "Edit"
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vm.entryCount + 1
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: inputCellID, for: indexPath) as! WatchSettingTableVCInputCell
        
        cell.currIndex = indexPath
        cell.setupCellContent(vm: vm)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Set the search terms here to be used on the Watch"
        default: return nil
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            vm.remove(entryAt: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    

}

class WatchSettingTableVCInputCell: UITableViewCell, UITextFieldDelegate {
    var currIndex: IndexPath!
    var vm: FavoritesSearchTagsVM!
    
    @IBOutlet weak var inputField: UITextField!
    
    func setupCellContent(vm: FavoritesSearchTagsVM) {
        self.vm = vm
        print(vm)
        inputField.delegate = self
        inputField.backgroundColor = .clear
        inputField.textColor = .white
        if let string = vm.entry(for: currIndex.row) {
            inputField.text = string
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text else { return true }
        vm.set(text, at: currIndex.row)
        textField.resignFirstResponder()
        return false
    }
}


