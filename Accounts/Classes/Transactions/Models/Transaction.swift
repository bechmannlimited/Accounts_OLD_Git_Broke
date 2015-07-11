//
//  Transaction.swift
//  Accounts
//
//  Created by Alex Bechmann on 20/04/2015.
//  Copyright (c) 2015 Ustwo. All rights reserved.
//

import UIKit
import ABToolKit
import SwiftyJSON
import Alamofire

class Transaction: JSONObject {
   
    var TransactionID: Int = 0
    var user = User()
    var friend = User()
    var Amount: Double = 0
    
    // for preventing notification in backend
    var activeUserID = kActiveUser.UserID
    
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
    var purchase = Purchase()
    var TransactionDate:NSDate = NSDate()
    var DateEntered: NSDate = NSDate()
    
    override func registerClassesForJsonMapping() {
        
        //registerClass(User.self, propertyKey: "user", jsonKey: "User")
        //registerClass(User.self, propertyKey: "friend", jsonKey: "User1")
        //registerClass(Purchase.self, propertyKey: "purchase", jsonKey: "Purchase")
        registerDate("TransactionDate")
        registerDate("DateEntered")
    }
    
    override func setExtraPropertiesFromJSON(json: JSON) {
       
        user = User.createObjectFromJson(json["User"])
        friend = User.createObjectFromJson(json["User1"])
        purchase = Purchase.createObjectFromJson(json["Purchase"])
    }
    
    override func webApiRestObjectID() -> Int? {
        
        return TransactionID
    }
    
    override func modelIsValid() -> Bool {
        
        var errors:Array<String> = []
        
        if user.UserID == 0 {
            
            errors.append("User not set")
        }
        
        if friend.UserID == 0 {
            
            errors.append("This transaction isnt going to anyone!")
        }
        
        if Amount == 0 {
            
            errors.append("The amount is 0")
        }
        
        if Description == "" {
            
            errors.append("Description is empty")
        }
        
        var c = 1
        var errorMessageString = ""
        
        for error in errors {
            
            let suffix = c == errors.count ? "" : ", "
            errorMessageString += "\(error)\(suffix)"
            c++
        }
        
        if errors.count > 0 {
            
            //UIAlertView(title: "Transaction not saved!", message: errorMessageString, delegate: nil, cancelButtonTitle: "OK").show()
        }
        
        return errors.count == 0
    }
    
    func save() -> JsonRequest? {
        
        if !modelIsValid() {
            
            return nil
        }
        
        let url = TransactionID == 0 ? Transaction.webApiUrls().insertUrl()! : Transaction.webApiUrls().updateUrl(TransactionID)!
        let httpMethod: Alamofire.Method = TransactionID == 0 ? .POST : .PUT
        
        
        var params: Dictionary<String, AnyObject> = convertToDictionary(nil, includeNestedProperties: false)
        params["UserID"] = user.UserID
        params["RelationUserID"] = friend.UserID
        
        return JsonRequest.create(url, parameters: params, method: httpMethod).onDownloadSuccessWithRequestInfo({ (json, request, httpUrlRequest, httpUrlResponse) -> () in
            
            if httpUrlResponse?.statusCode == 200 || httpUrlResponse?.statusCode == 201 || httpUrlResponse?.statusCode == 204 {
                
                request.succeedContext()
            }
            else {
                
                request.failContext()
            }
            
        }).onDownloadFailure( { (error, alert) in
            
            alert.show()
            
        })
    }
}
