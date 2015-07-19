//
//  SaveTransactionViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 08/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//


import UIKit
import ABToolKit
import SwiftyUserDefaults

class SaveTransactionViewController: ACFormViewController {

    var transaction = Transaction()
    var allowEditing = false
    var delegate: SaveItemDelegate?
    
    var itemDidChange = false
    var isSaving = false
    
    override func viewDidLoad() {

        if transaction.objectId == nil {

            transaction.fromUser = User.currentUser()
            transaction.transactionDate = NSDate()
            transaction.title = ""
        }

        allowEditing = true // transaction.TransactionID == 0 || transaction.user.UserID == kActiveUser.UserID
        
        if allowEditing && transaction.objectId == nil {
            
            title = "New transfer"
            //transaction.user = kActiveUser
        }
        else if allowEditing && transaction.objectId != nil {
            
            title = "Edit transfer"
        }
        else {
            
            title = "Transfer"
        }
        
        showOrHideSaveButton()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "pop")
        
        super.viewDidLoad()
    }
    
    func save() {

        isSaving = true
        showOrHideSaveButton()
        
        transaction.saveEventually { (success, error) -> Void in

            if success {

                self.delegate?.transactionDidChange(self.transaction)

                self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                self.navigationController?.popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(self.navigationController!.popoverPresentationController!)
                
                self.delegate?.itemDidChange()
            }
            else {
                
                ParseUtilities.showAlertWithErrorIfExists(error)
            }

            self.isSaving = false
            self.showOrHideSaveButton()
        }
    }
    
    func pop() {
        
        if itemDidChange {
            
            UIAlertController.showAlertControllerWithButtonTitle("Go back", confirmBtnStyle: UIAlertActionStyle.Destructive, message: "Going back will delete changes to this transaction! Are you sure?") { (response) -> () in
                
                if response == AlertResponse.Confirm {
                    
                    self.dismissViewControllerFromCurrentContextAnimated(true)
                    self.navigationController?.popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(self.navigationController!.popoverPresentationController!)
                    //self.delegate?.itemDidGetDeleted()
                }
            }
        }
        else {
            
            self.dismissViewControllerFromCurrentContextAnimated(true)
            navigationController?.popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(navigationController!.popoverPresentationController!)
        }
    }
    
    func popAll() {
        
        if itemDidChange {
            
            UIAlertController.showAlertControllerWithButtonTitle("Go back", confirmBtnStyle: UIAlertActionStyle.Destructive, message: "Going back will delete changes to this transaction! Are you sure?") { (response) -> () in
                
                if response == AlertResponse.Confirm {
                    
                    self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                    self.navigationController?.popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(self.navigationController!.popoverPresentationController!)
                    self.delegate?.itemDidGetDeleted()
                }
            }
        }
        else {
            
            navigationController?.dismissViewControllerAnimated(true, completion: nil)
            navigationController?.popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(navigationController!.popoverPresentationController!)
        } 
    }
    
    func showOrHideSaveButton() {
        
        if allowEditing {
            
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "save")
            navigationItem.rightBarButtonItem?.tintColor = kNavigationBarPositiveActionColor
        }
        
        navigationItem.rightBarButtonItem?.enabled = allowEditing && transaction.modelIsValid() && !isSaving
    }
}

extension SaveTransactionViewController: FormViewDelegate {
    
    override func formViewElements() -> Array<Array<FormViewConfiguration>> {
        
        let locale = Settings.getCurrencyLocaleWithIdentifier().locale
        
        var sections = Array<Array<FormViewConfiguration>>()
        sections.append([
            FormViewConfiguration.textField("Title", value: String.emptyIfNull(transaction.title), identifier: "Title"),
            FormViewConfiguration.textFieldCurrency("Amount", value: Formatter.formatCurrencyAsString(transaction.localeAmount), identifier: "Amount", locale: locale)
        ])
        
        sections.append([
            FormViewConfiguration.normalCell("User"),
            FormViewConfiguration.normalCell("Friend"),
            FormViewConfiguration.datePicker("Transaction date", date: transaction.transactionDate, identifier: "TransactionDate", format: nil)
        ])
        
        if transaction.objectId != nil {
            
            sections.append([
                FormViewConfiguration.button("Delete", buttonTextColor: kFormDeleteButtonTextColor, identifier: "Delete")
            ])
        }
        
        return sections
    }
    
    func formViewManuallySetCell(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath, identifier: String) -> UITableViewCell {
        
        let cell = tableView.dequeueOrCreateReusableCellWithIdentifier("Cell", requireNewCell: { (identifier) -> (UITableViewCell) in
            
            return UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "Cell")
        })
        
        if identifier == "Friend" {
            
            cell.textLabel?.text = "Transfer to"
            cell.detailTextLabel?.text = "\(transaction.toUser!.username!)"
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            
            return cell
        }
        
        if identifier == "User" {
            
            cell.textLabel?.text = "Transfer from"
            cell.detailTextLabel?.text = "\(transaction.fromUser!.username!)"
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    
    func formViewDateChanged(identifier: String, date: NSDate) {
        
        if identifier == "TransactionDate" {
            
            transaction.transactionDate = date
        }
    }
    
    func formViewTextFieldEditingChanged(identifier: String, text: String) {
        
        if identifier == "Title" {

            transaction.title = text
        }
    }
    
    func formViewTextFieldCurrencyEditingChanged(identifier: String, value: Double) {
        
        if identifier == "Amount" {

            transaction.localeAmount = value
        }
    }
    
    func formViewButtonTapped(identifier: String) {
        
        if identifier == "Delete" {

            UIAlertController.showAlertControllerWithButtonTitle("Delete?", confirmBtnStyle: UIAlertActionStyle.Destructive, message: "Delete transaction for \(Formatter.formatCurrencyAsString(transaction.localeAmount))?", completion: { (response) -> () in
                
                if response == AlertResponse.Confirm {
                    
//                    self.transaction.webApiDelete()?.onDownloadFinished({ () -> () in
//                        
//                        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
//                        self.navigationController?.popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(self.navigationController!.popoverPresentationController!)
//                        
//                        self.delegate?.itemDidGetDeleted()
//                    })
                }
            })
        }
    }
    
    func formViewDidSelectRow(identifier: String) {
        
        if identifier == "Friend" {

//            let usersToChooseFrom = User.userListExcludingID(transaction.user.UserID)
//            
//            let v = SelectUsersViewController(identifier: identifier, user: transaction.friend, selectUserDelegate: self, allowEditing: allowEditing, usersToChooseFrom: usersToChooseFrom)
//            navigationController?.pushViewController(v, animated: true)
        }
        
        if identifier == "User" {
            
//            let usersToChooseFrom = User.userListExcludingID(nil)
//            
//            let v = SelectUsersViewController(identifier: identifier, user: transaction.user, selectUserDelegate: self, allowEditing: allowEditing, usersToChooseFrom: usersToChooseFrom)
//            navigationController?.pushViewController(v, animated: true)
        }
    }
    
    override func formViewElementIsEditable(identifier: String) -> Bool {
        
        return allowEditing
    }
    
    func formViewElementDidChange(identifier: String, value: AnyObject?) {
        
        showOrHideSaveButton()
        itemDidChange = true
    }
}

extension SaveTransactionViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        
        if let c = cell as? FormViewTextFieldCell {
            
            c.label.textColor = UIColor.blackColor()
            c.textField.textColor = UIColor.lightGrayColor()
        }
        
        return cell
    }
}

extension SaveTransactionViewController: SelectUserDelegate {
    
    func didSelectUser(user: User, identifier: String) {
        
        if identifier == "Friend" {
            
            transaction.toUser = user
        }
        if identifier == "User" {
        
            transaction.fromUser = user
            transaction.toUser = nil
        }
        
        itemDidChange = true
        showOrHideSaveButton()
        reloadForm()
    }
}