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
    
//    func generateTransactionsFromBillSplitDictionary(completion:() -> ()) {
//        
//        transactions = []
//        
//        var c = 0
//        var friendsToInclude = friends
//        friendsToInclude.append(user)
//        
////        relationForKey("transactions").query()?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
////            
////            ParseUtilities.showAlertWithErrorIfExists(error)
////            
////            if let transactions = objects as? [Transaction] {
////                
////                for transaction: Transaction in transactions {
////                    
////                    //see if a transaction
////                    
////                    
////                    
////                    
////                    self.relationForKey("transactions").removeObject(transaction)
////                }
////            }
//        
//            //self.saveInBackground()
//            
////            for user in friendsToInclude {
////                
////                let transaction = Transaction()
////                transaction.fromUser = self.user
////                transaction.toUser = user
////                transaction.amount = self.billSplitDictionary[user]!
////                transaction.transactionDate = self.purchasedDate!
////                self.transactions.append(transaction)
////            }
//            
//           // completion()
//        //})
//        
//        
//    }
    
    func savePurchase(completion: (success:Bool) -> ()) {
        
        if !modelIsValid() {
            
            completion(success: false)
        }
        
        var savePurchase: () -> () = {
            
            for transaction in self.transactions {
                
                //again
                transaction.purchase = self
                transaction.transactionDate = self.purchasedDate!
                
                self.relationForKey(kParse_Purchase_TransactionsRelation_Key).addObject(transaction)
            }
            
            self.saveInBackgroundWithBlock({ (success, error) -> Void in
                
                ParseUtilities.showAlertWithErrorIfExists(error)
                completion(success: success)
            })
        }
        
        var newTransactions = [Transaction]()
        
        for transaction in self.transactions {
            
            let newTransaction = Transaction()
            newTransaction.title = self.title
            newTransaction.fromUser = transaction.fromUser
            newTransaction.toUser = transaction.toUser
            newTransaction.amount = transaction.amount
            newTransaction.purchase = transaction.purchase
            newTransaction.transactionDate = transaction.transactionDate
            
            newTransactions.append(transaction)
        }
        
        // delete all previous ones
        
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
        
//        self.billSplitDictionary = Dictionary<User, Double>()
//        var amount:Double = self.amount / Double(self.friends.count + 1)
//        
//        for friend in self.friends {
//            
//            billSplitDictionary[friend] = amount
//        }
//        
//        billSplitDictionary[user] = amount
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
        
//        for friend in friends {
//            
//            if billSplitDictionary[friend] == nil || billSplitDictionary[friend] == 0 {
//                
//                errors.append("\(friend.username) hasn't got an amount associated")
//            }
//        }
        
        var friendTotals:Double = 0
        
//        for friend in friends {
//            
//            if let amount = billSplitDictionary[friend] {
//                
//                friendTotals += amount
//            }
//        }
//        
//        if friendTotals > amount {
//            
//            errors.append("The amounts for the users don't add up to the total")
//        }
        
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
//    
//    func calculateTotalFromBillSplitDictionary() {
//        
//        var total:Double = 0
//        
//        for friend in friends {
//            
//            if let amount = billSplitDictionary[friend] {
//                
//                total += amount
//            }
//        }
//        
//        if let userTotal = billSplitDictionary[user] {
//            
//            total += userTotal
//        }
//
//        amount = total
//    }
    
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