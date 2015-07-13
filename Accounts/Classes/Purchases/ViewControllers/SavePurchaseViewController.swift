//
//  SavePurchaseViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 07/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//


import UIKit
import ABToolKit

class SavePurchaseViewController: ACFormViewController {

    var purchase = Purchase()
    var allowEditing = false
    
    var billSplitCells = Dictionary<User, FormViewTextFieldCell>()
    var formViewCells = Dictionary<String, FormViewTextFieldCell>()
    
    var delegate: SaveItemDelegate?
    
    var itemDidChange = false
    var isSaving = false
    
    override func viewDidLoad() {
        
        allowEditing = true //purchase.user.UserID == kActiveUser.UserID || purchase.PurchaseID == 0

        if allowEditing && purchase.PurchaseID == 0 {

            title = "New purchase"
            purchase.user = kActiveUser
        }
        else if allowEditing && purchase.PurchaseID > 0 {

            title = "Edit purchase"
        }
        else {
            
            title = "Purchase"
        }
        
        showOrHideSaveButton()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "pop")
        
        super.viewDidLoad()
        
        tableView.setEditing(true, animated: false)
    }
    
    func save() {

        isSaving = true
        showOrHideSaveButton()
        
        purchase.save()?.onDownloadSuccessWithRequestInfo({ (json, request, httpUrlRequest, httpUrlResponse) -> () in
            
            if httpUrlResponse?.statusCode == 200 || httpUrlResponse?.statusCode == 201 || httpUrlResponse?.statusCode == 204 {
                
                self.purchase.PurchaseID = json["PurchaseID"].intValue
                self.delegate?.purchaseDidChange(self.purchase)
                
                self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                self.navigationController?.popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(self.navigationController!.popoverPresentationController!)
                
                self.delegate?.itemDidChange()
            }
            else {
                
                UIAlertView(title: "Error", message: "Purchase not saved!", delegate: nil, cancelButtonTitle: "OK").show()
            }
            
        }).onDownloadFinished({ () -> () in
            
            self.isSaving = false
            self.showOrHideSaveButton()
        })
    }
    
    func showOrHideSaveButton() {
        
        if allowEditing {
            
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "save")
            navigationItem.rightBarButtonItem?.tintColor = kNavigationBarPositiveActionColor
        }
        
        navigationItem.rightBarButtonItem?.enabled = allowEditing && purchase.modelIsValid() && !isSaving
    }
    
    func pop() {
        
        if itemDidChange {
            
            UIAlertController.showAlertControllerWithButtonTitle("Cancel?", confirmBtnStyle: UIAlertActionStyle.Destructive, message: "Going back delete changes to this purchase! Are you sure?") { (response) -> () in
                
                if response == AlertResponse.Confirm {
                    
                    self.dismissViewControllerFromCurrentContextAnimated(true)
                    self.navigationController?.popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(self.navigationController!.popoverPresentationController!)
                }
            }
        }
        else {
            
            dismissViewControllerFromCurrentContextAnimated(true)
            navigationController?.popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(navigationController!.popoverPresentationController!)
        }
        
        
    }
    
    func popAll() {
        
        if itemDidChange {
            
            UIAlertController.showAlertControllerWithButtonTitle("Go back", confirmBtnStyle: UIAlertActionStyle.Destructive, message: "Going back will delete changes to this transaction! Are you sure?") { (response) -> () in
                
                if response == AlertResponse.Confirm {
                    
                    self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                    self.navigationController?.popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(self.navigationController!.popoverPresentationController!)
                    
                    //self.delegate?.itemDidGetDeleted()
                }
            }
        }
        else {
            
            self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
            navigationController?.popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(navigationController!.popoverPresentationController!)
        }
    }
}

extension SavePurchaseViewController: FormViewDelegate {
    
    override func formViewElements() -> Array<Array<FormViewConfiguration>> {
        
        let locale: NSLocale? = Settings.getCurrencyLocaleWithIdentifier().locale
        
        var sections = Array<Array<FormViewConfiguration>>()
        sections.append([
            FormViewConfiguration.textField("Description", value: purchase.Description, identifier: "Description"),
            FormViewConfiguration.textFieldCurrency("Amount", value: Formatter.formatCurrencyAsString(purchase.localeAmount), identifier: "Amount", locale: locale),
            FormViewConfiguration.normalCell("User"),
            
        ])
        
        var userAmount:Double = 0
        if let amount = purchase.billSplitDictionary[purchase.user]  {
            
            userAmount = amount
        }
        
        var friendConfigs: Array<FormViewConfiguration> = [
            FormViewConfiguration.normalCell("Friends"),
            FormViewConfiguration.textFieldCurrency(purchase.user.username!, value: Formatter.formatCurrencyAsString(userAmount), identifier: "userAmount", locale: locale)
        ]
        
        for friend in purchase.friends {

            let value = purchase.billSplitDictionary[friend]!
            
            friendConfigs.append(FormViewConfiguration.textFieldCurrency(friend.username!, value: Formatter.formatCurrencyAsString(value), identifier: "friendAmount\(friend.objectId)", locale: locale))
        }
        
        sections.append(friendConfigs)
        
        sections.append([
            FormViewConfiguration.datePicker("Date Purchased", date: purchase.DatePurchased, identifier: "DatePurchased", format: nil),
            FormViewConfiguration.normalCell("Location")
        ])
        
        if purchase.PurchaseID > 0 {
         
            sections.append([
                FormViewConfiguration.button("Delete", buttonTextColor: kFormDeleteButtonTextColor, identifier: "Delete")
            ])
        }
        
        return sections
    }
    
    func formViewTextFieldEditingChanged(identifier: String, text: String) {
        
        if identifier == "Description" {
            
            purchase.Description = text
        }
    }
    
    func setFriendAmountTextFields() {
    
        for friend in self.purchase.friends {
        
        let v = self.purchase.billSplitDictionary[friend]!
        self.setTextFieldValueAndUpdateConfig("friendAmount\(friend.objectId)", value: Formatter.formatCurrencyAsString(v), cell: self.billSplitCells[friend])
        //c++
        }
        
        if let v = self.purchase.billSplitDictionary[self.purchase.user] {
        
        self.setTextFieldValueAndUpdateConfig("userAmount", value: Formatter.formatCurrencyAsString(v), cell: self.formViewCells["userAmount"])
        }
        
        self.setTextFieldValueAndUpdateConfig("Amount", value: Formatter.formatCurrencyAsString(self.purchase.Amount), cell: self.formViewCells["Amount"])
    }
    
    func formViewTextFieldCurrencyEditingChanged(identifier: String, value: Double) {
        
        if identifier == "Amount" {
            
            purchase.localeAmount = value
            purchase.splitTheBill()
        }
        
        if identifier == "userAmount" {
            
            purchase.billSplitDictionary[purchase.user] = value
            purchase.calculateTotalFromBillSplitDictionary()
        }
        
        for friend in purchase.friends {
            
            if identifier == "friendAmount\(friend.objectId)" {
                
                purchase.billSplitDictionary[friend] = value
                
                purchase.calculateTotalFromBillSplitDictionary()
                setTextFieldValueAndUpdateConfig(identifier, value: Formatter.formatCurrencyAsString(value), cell: billSplitCells[friend])
            }
        }
        
        setFriendAmountTextFields()
    }
    
    func setTextFieldValueAndUpdateConfig(identifier: String, value: String, cell: FormViewTextFieldCell?) {
        
        if let cell = cell {
            
            let indexPath = indexPathForFormViewCellIdentifier(identifier)!
            
            let config = data[indexPath.section][indexPath.row]
            config.value = value
            
            if config.formCellType == FormCellType.TextField {
                
                cell.textField.text = value
            }
            else if config.formCellType == FormCellType.TextFieldCurrency {
                
                cell.textField.text = value
            }
        }
    }
    
    func formViewButtonTapped(identifier: String) {
        
        if identifier == "Delete" {
            
            UIAlertController.showAlertControllerWithButtonTitle("Delete?", confirmBtnStyle: UIAlertActionStyle.Destructive, message: "Delete purchase: \(purchase.Description) for \(Formatter.formatCurrencyAsString(purchase.localeAmount))?", completion: { (response) -> () in
                
                if response == AlertResponse.Confirm {
                    
                    self.purchase.webApiDelete()?.onDownloadFinished({ () -> () in
                        
                        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                        self.navigationController?.popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(self.navigationController!.popoverPresentationController!)
                        
                        self.delegate?.itemDidGetDeleted()
                    })
                }
            })
        }
    }
    
    func formViewDidSelectRow(identifier: String) {
        
        if identifier == "Friends" {
            
//            let usersToChooseFrom = User.userListExcludingID(purchase.user.UserID)
//            
//            let v = SelectUsersViewController(identifier: identifier, users: purchase.friends, selectUsersDelegate: self, allowEditing: allowEditing, usersToChooseFrom: usersToChooseFrom)
//            navigationController?.pushViewController(v, animated: true)
        }
        
        if identifier == "User" {
            
//            let usersToChooseFrom = User.userListExcludingID(nil)
//            
//            let v = SelectUsersViewController(identifier: identifier, user: purchase.user, selectUserDelegate: self, allowEditing: allowEditing, usersToChooseFrom: usersToChooseFrom)
//            navigationController?.pushViewController(v, animated: true)
        }
    }
    
    func formViewDateChanged(identifier: String, date: NSDate) {
        
        if identifier == "DatePurchased" {
            
            purchase.DatePurchased = date
        }
    }
    
    func formViewManuallySetCell(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath, identifier: String) -> UITableViewCell {
        
        let cell = tableView.dequeueOrCreateReusableCellWithIdentifier("Cell", requireNewCell: { (identifier) -> (UITableViewCell) in
            
            return UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: identifier)
        })
        
        if identifier == "Friends" {
            
            cell.textLabel?.text = "Split with"
            
            var friendCount = purchase.friends.count
            
            for friend in purchase.friends {
                
                if friend.objectId == purchase.user.objectId {
                    
                    friendCount--
                }
            }
            
            cell.detailTextLabel?.text = "\(friendCount)"
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            
            return cell
        }
        else if identifier == "User" {
            
            cell.textLabel?.text = "Purchased by "
            cell.detailTextLabel?.text = "\(purchase.user.username!)"
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            
            return cell
        }
        else if identifier == "Location" {
            
            cell.imageView?.image = AppTools.iconAssetNamed("07-map-marker.png")
            cell.textLabel?.text = "Location"
            cell.detailTextLabel?.text = "None"
        }
        
        return UITableViewCell()
    }
    
    override func formViewElementIsEditable(identifier: String) -> Bool {
        
        return allowEditing
    }
    
    func formViewElementDidChange(identifier: String, value: AnyObject?) {
        
        showOrHideSaveButton()
        itemDidChange = true
    }
}

extension SavePurchaseViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        
        if let cell = cell as? FormViewTextFieldCell {
            
            cell.label.textColor = UIColor.blackColor()
            cell.textField.textColor = UIColor.lightGrayColor()
            formViewCells[cell.config.identifier] = cell
            
            //hacky way to set friend cells
            if indexPath.section == 1 {
                
                let i = indexPath.row - 2
                
                if i >= 0 {
                    
                    let friend = purchase.friends[i]
                    billSplitCells[friend] = cell
                }
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        //hacky way to set friend cells
        if indexPath.section == 1 {
            
            let i = indexPath.row - 2
            
            if i >= 0 {
                
                return .Delete
            }
        }
        
        return .None
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        //hacky way to set friend cells
        if indexPath.section == 1 {
            
            let i = indexPath.row - 2
            
            if i >= 0 {
                
                return true
            }
        }
        
        return false
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            
            //hacky way to set friend cells
            if indexPath.section == 1 {
                
                let i = indexPath.row - 2
                
                if i >= 0 {
                    
                    let friend = purchase.friends[i]
                    
                    tableView.beginUpdates()
                    
                    billSplitCells.removeValueForKey(friend)
                    purchase.billSplitDictionary.removeValueForKey(friend)
                    
                    let index = find(purchase.friends, friend)!
                    purchase.friends.removeAtIndex(index)
                    
                    purchase.splitTheBill()
                    //purchase.calculateTotalFromBillSplitDictionary()
                    setFriendAmountTextFields()
                    
                    data[indexPath.section].removeAtIndex(indexPath.row)

                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
                    tableView.endUpdates()
                    
                    itemDidChange = true
                }
            }
        }
        
        showOrHideSaveButton()
    }
}

extension SavePurchaseViewController: SelectUsersDelegate {

    func didSelectUsers(users: Array<User>, identifier: String) {

        billSplitCells = Dictionary<User, FormViewTextFieldCell>()
        
        if identifier == "Friends" {
            
            purchase.friends = users
            purchase.splitTheBill()
        }

        itemDidChange = true
        showOrHideSaveButton()
        reloadForm()
    }
}

extension SavePurchaseViewController: SelectUserDelegate {
    
    func didSelectUser(user: User, identifier: String) {
        
        if identifier == "User" {
            
            purchase.user = user
            purchase.friends = []
            purchase.splitTheBill()
        }
        
        itemDidChange = true
        showOrHideSaveButton()
        reloadForm()
    }
}