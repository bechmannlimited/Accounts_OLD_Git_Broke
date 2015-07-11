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

class Purchase: JSONObject {
   
    var PurchaseID: Int = 0
    var friends: [User] = []
    var Amount: Double = 0
    
    var localeAmount: Double {
        
        get {
            
            let currencyIdentifier = Settings.getCurrencyLocaleWithIdentifier().identifier
            
            if currencyIdentifier == "DKK" {
                
                return self.Amount * 10
            }
            else {
                
                return self.Amount
            }
        }
        
        set(newValue) {
            
            let currencyIdentifier = Settings.getCurrencyLocaleWithIdentifier().identifier
            
            if currencyIdentifier == "DKK" {
                
                self.Amount = newValue / 10
            }
            else {
                
                self.Amount = newValue
            }
        }
    }
    
    var Description = ""
    var user = User()
    var billSplitDictionary = Dictionary<User, Double>()
    var DatePurchased:NSDate = NSDate()
    var DateEntered: NSDate = NSDate()
    //var transactions = Array<Transaction>()
    
    override func registerClassesForJsonMapping() {
        
        registerDate("DatePurchased")
        registerDate("DateEntered")
        registerClass(Transaction.self, propertyKey: "transactions", jsonKey: "Transactions")
        //registerClass(User.self, propertyKey: "user", jsonKey: "User")
        //registerClass(User.self, propertyKey: "friends", jsonKey: "RelationUsers")
    }
    
    override func setExtraPropertiesFromJSON(json: JSON) {
        
        user.UserID = json["UserID"].intValue
        
        //friends = User.convertJsonToMultipleObjects(User.self, json: json["RelationUsers"])
        
        user = User.createObjectFromJson(json["User"])
        
        for (key: String, subJson: JSON) in json["RelationUserAmounts"] {
            
            let amount = subJson["Amount"].doubleValue
            let friend:User = User.createObjectFromJson(subJson["User"])
            
            if friend.UserID == user.UserID {
                
                billSplitDictionary[user] = amount
            }
            else {
                
                friends.append(friend)
                billSplitDictionary[friend] = amount
            }
        }
    }
    
    func save() -> JsonRequest? {
        
        if !modelIsValid() {
            
            return nil
        }

        var urlString = ""
        let httpMethod: Alamofire.Method = PurchaseID == 0 ? .POST : .PUT
        
        if PurchaseID > 0 {
            
            urlString = Purchase.webApiUrls().updateUrl(PurchaseID)!
        }
        else {
            
            urlString = Purchase.webApiUrls().insertUrl()!
        }
        
        var c = 0
        
        var friendsToInclude = friends
        friendsToInclude.append(user)
        
        for user in friendsToInclude {
            
            let amount = billSplitDictionary[user]!
            
            let prefix = c == 0 ? "?" : "&"
            urlString = urlString + "\(prefix)RelationUserIDs=\(user.UserID)&RelationUserAmounts=\(amount)"
            c++
        }
        
        //let prefix = urlString.contains("?") ? "&" : "?"
        //urlString += "\(prefix)activeUserID=\(kActiveUser.UserID)"
    
        var params = convertToDictionary(["Description", "Amount", "PurchaseID"], includeNestedProperties: false)
        params["UserID"] = user.UserID
        params["DateEntered"] = DateEntered.toString(JSONMappingDefaults.sharedInstance().webApiSendDateFormat)
        params["DatePurchased"] = DatePurchased.toString(JSONMappingDefaults.sharedInstance().webApiSendDateFormat)

        println(urlString)
        println(params)
        println(Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders)
        
        return JsonRequest.create(urlString, parameters: params, method: httpMethod).onDownloadSuccessWithRequestInfo({ (json, request, httpUrlRequest, httpUrlResponse) -> () in

            println(httpUrlResponse?.statusCode)
            println(json)
            
            if httpUrlResponse?.statusCode == 200 || httpUrlResponse?.statusCode == 201 || httpUrlResponse?.statusCode == 204 {
                
                request.succeedContext()
            }
            else {
                
                request.failContext()
            }
            
        })
    }
    
    func splitTheBill() {
        
        self.billSplitDictionary = Dictionary<User, Double>()
        var amount:Double = self.Amount / Double(self.friends.count + 1)
        
        for friend in self.friends {
            
            billSplitDictionary[friend] = amount
        }
        
        billSplitDictionary[user] = amount
    }
    
    override func webApiRestObjectID() -> Int? {
        
        return PurchaseID
    }
    
    override func modelIsValid() -> Bool {

        var errors:Array<String> = []
        
        if Amount == 0 {
         
            errors.append("Amount is 0")
        }
        
        if friends.count == 0 {
            
            errors.append("You havnt split this with anyone!")
        }
        
        if Description == "" {
            
            errors.append("Description is empty")
        }
        
        for friend in friends {
            
            if billSplitDictionary[friend] == nil || billSplitDictionary[friend] == 0 {
                
                errors.append("\(friend.Username) hasn't got an amount associated")
            }
        }
        
        var friendTotals:Double = 0
        
        for friend in friends {
            
            if let amount = billSplitDictionary[friend] {
                
                friendTotals += amount
            }
        }
        
        if friendTotals > Amount {
            
            errors.append("The amounts for the users don't add up to the total")
        }
        
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
    
    func calculateTotalFromBillSplitDictionary() {
        
        var total:Double = 0
        
        for friend in friends {
            
            if let amount = billSplitDictionary[friend] {
                
                total += amount
            }
        }
        
        if let userTotal = billSplitDictionary[user] {
            
            total += userTotal
        }

        Amount = total
    }
    
//    func amountPaidByUser() -> Double {
//        
//        return purchase.Amount - calculateTotalFromBillSplitDictionary()
//    }
    
}
