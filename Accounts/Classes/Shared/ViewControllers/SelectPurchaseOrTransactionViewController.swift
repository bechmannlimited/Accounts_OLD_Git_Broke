//
//  PurchaseOrTransactionViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 19/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//


import UIKit
import ABToolKit

class SelectPurchaseOrTransactionViewController: ACBaseViewController {

    var tableView = UITableView(frame: CGRectZero, style: .Grouped)
    var data = [(identifier: "Purchase", textLabelText: "Add purchase"), (identifier: "Transaction", textLabelText: "Add transfer")]
    var contextualFriend: User?
    var saveItemDelegate: SaveItemDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView(tableView, delegate: self, dataSource: self)
        tableView.setEditing(true, animated: false)
        tableView.allowsSelectionDuringEditing = true
        
        addCloseButton()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if isInsidePopover() {

            navigationController?.view.backgroundColor = UIColor.clearColor()
            view.backgroundColor = UIColor.clearColor()
            tableView.backgroundColor = UIColor.clearColor()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        saveItemDelegate?.newItemViewControllerWasPresented(nil)
    }
    
    override func close() {
        super.close()
        
        navigationController?.popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(navigationController!.popoverPresentationController!)
    }
    
    override func setupTableView(tableView: UITableView, delegate: UITableViewDelegate, dataSource: UITableViewDataSource) {
        super.setupTableView(tableView, delegate: delegate, dataSource: dataSource)
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
}

extension SelectPurchaseOrTransactionViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! UITableViewCell
        
        cell.textLabel?.text = data[indexPath.row].textLabelText

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let identifier = data[indexPath.row].identifier
        
        if identifier == "Purchase" {
            
            let v = SavePurchaseViewController()
            
            if let friend = contextualFriend {
                
                v.purchase.friends.append(friend)
                v.purchase.billSplitDictionary[friend] = 0
            }
            
            v.delegate = saveItemDelegate
            saveItemDelegate?.newItemViewControllerWasPresented(v)
            
            navigationController?.pushViewController(v, animated: true)
        }
        else if identifier == "Transaction" {
            
            let v = SaveTransactionViewController()
            
            if let friend = contextualFriend {
                
                v.transaction.friend = friend
            }
            
            v.delegate = saveItemDelegate
            saveItemDelegate?.newItemViewControllerWasPresented(v)
            
            navigationController?.pushViewController(v, animated: true)
        }
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        return UITableViewCellEditingStyle.Insert
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.delegate?.tableView?(tableView, didSelectRowAtIndexPath: indexPath)
    }
}