//
//  Purchase.swift
//  Accounts
//
//  Created by Alex Bechmann on 21/04/2015.
//  Copyright (c) 2015 Ustwo. All rights reserved.
//

import UIKit
import ABToolKit
import Alamofire
import SwiftyJSON
import Parse

class Purchase: PFObject {

    @NSManaged var amount: Double
    //@NSManaged var purchaseDescription: String?
    @NSManaged var title: String
    @NSManaged var user: User
    @NSManaged var purchasedDate:NSDate?
    
    var transactions: Array<Transaction> = []
    //var friends: [User] = []
    //var billSplitDictionary = Dictionary<User, Double>()
    
    var originalTransactions = Array<Transaction>()
    
    var localeAmount: Double {
        
        get {
            
            let currencyIdentifier = Settings.getCurrencyLocaleWithIdentifier().identifier
            
            if currencyIdentifier == "DKK" {
                
                return self.amount * 10
            }
            else {
                
                return self.amount
            }
        }
        
        set(newValue) {
            
            let currencyIdentifier = Settings.getCurrencyLocaleWithIdentifier().identifier
            
            if currencyIdentifier == "DKK" {
                
                self.amount = newValue / 10
            }
            else {
                
                self.amount = newValue
            }
        }
    }
    
    func savePurchase(completion: (success:Bool) -> ()) {
        
        var isNewPurchase = objectId == nil
        
        if !modelIsValid() {
            
            completion(success: false)
        }
        
        var sendPushNotifications: () -> () = {
            
            let query = PFInstallation.query()
            
            for transaction in self.transactions {
                
                query?.whereKey("User", equalTo: transaction.toUser!)
            }
            
            let pushNotification = PFPush()
            pushNotification.setQuery(query)
            
            let noun: String = isNewPurchase ? "added" : "updated"
            pushNotification.setMessage("Purchase: \(self.title) \(noun)!")
            
            pushNotification.sendPushInBackground()
        }
        
        var savePurchase: () -> () = {
            
            for transaction in self.transactions {
                
                // again - not 100% sure this is needed
                transaction.purchase = self
                transaction.transactionDate = self.purchasedDate!
                
                self.relationForKey(kParse_Purchase_TransactionsRelation_Key).addObject(transaction)
            }
            
            self.saveInBackgroundWithBlock({ (success, error) -> Void in
                
                if success {
                    
                    //need to set again for new purchases
                    for transaction in self.transactions {
                        
                        transaction.purchase = self
                        transaction.saveInBackground()
                    }
                    
                    sendPushNotifications()
                }
                else {
                    
                    ParseUtilities.showAlertWithErrorIfExists(error)
                }
                
                completion(success: success)
            })
        }
        
        var newTransactions = [Transaction]()
        
        for transaction in self.transactions {
            
            // required to ensure objectid is null (restulting to null resulted in an error from localdatastore)
            let newTransaction = Transaction()
            newTransaction.title = self.title
            newTransaction.fromUser = transaction.fromUser
            newTransaction.toUser = transaction.toUser
            newTransaction.amount = transaction.amount
            newTransaction.purchase = transaction.purchase
            newTransaction.transactionDate = transaction.transactionDate
            
            newTransactions.append(transaction)
        }
        
        // delete all previous transactions neccessary
        for transaction in originalTransactions {
            
            if !contains(transactions, transaction){
                
                transaction.deleteEventually()
            }
        }
        
        transactions = newTransactions
        
        PFObject.saveAllInBackground(transactions, block: { (success, error) -> Void in
            
            if success {
                
                savePurchase()
            }
            else {
                
                ParseUtilities.showAlertWithErrorIfExists(error)
                completion(success: success)
            }
        })
    }
    
    func splitTheBill() {
        
        let splitAmount = self.amount / Double(self.transactions.count)
        
        for transaction in transactions {
            
            transaction.amount = splitAmount
        }
    }
    

    
    func modelIsValid() -> Bool {

        var errors:Array<String> = []
        
        if amount == 0 {
         
            errors.append("Amount is 0")
        }
        
        if transactions.count < 2 {
            
            errors.append("You havnt split this with anyone!")
        }
        
        if String.emptyIfNull(title) == "" {
            
            errors.append("title is empty")
        }
        
        var friendTotals:Double = 0
        
        var c = 1
        var errorMessageString = ""
        
        for error in errors {
            
            let suffix = c == errors.count ? "" : ", "
            errorMessageString += "\(error)\(suffix)"
            c++
        }
        
        if errors.count > 0 {
            
            //UIAlertView(title: "Purchase not saved!", message: errorMessageString, delegate: nil, cancelButtonTitle: "OK").show()
        }
        
        return errors.count > 0 ? false : true
    }

    
    func calculateTotalFromTransactions() {
        
        amount = 0
        
        for transaction in transactions {
            
            amount += transaction.amount
        }
    }
    
    func transactionForToUser(toUser: User) -> Transaction? {
        
        for transaction in transactions {
            
            if transaction.toUser == toUser {
                
                return transaction
            }
        }
        
        return nil
    }
    
    func usersInTransactions() -> Array<User> {
        
        var users = Array<User>()
        
        for transaction in transactions {
            
            users.append(transaction.toUser!)
        }
        
        return users
    }
    
    func removeTransactionForToUser(toUser: User) {
        
        for transaction in transactions {
            
            if transaction.toUser == toUser {
                
                let index = find(transactions, transaction)!
                transactions.removeAtIndex(index)
            }
        }
    }
}

extension Purchase: PFSubclassing {
    
    static func parseClassName() -> String {
        return Purchase.getClassName()
    }
}