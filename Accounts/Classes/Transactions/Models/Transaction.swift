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
import Parse

class Transaction: PFObject {
   
    @NSManaged var fromUser: User?
    @NSManaged var toUser: User?
    @NSManaged var amount: Double
    //@NSManaged var transactionDescription: String
    @NSManaged var title: String
    @NSManaged var purchase: Purchase
    @NSManaged var transactionDate: NSDate
    
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
    
    func modelIsValid() -> Bool {

        var errors:Array<String> = []

        if fromUser == nil {

            errors.append("User not set")
        }

        if toUser == nil {

            errors.append("This transaction isnt going to anyone!")
        }

        if amount == 0 {

            errors.append("The amount is 0")
        }

        if String.emptyIfNull(title) == "" {

            errors.append("title is empty")
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
}

extension Transaction: PFSubclassing {
    
    static func parseClassName() -> String {
        return Transaction.getClassName()
    }
}

//
//    func save() -> JsonRequest? {
//        
//        if !modelIsValid() {
//            
//            return nil
//        }
//        
//        let url = TransactionID == 0 ? Transaction.webApiUrls().insertUrl()! : Transaction.webApiUrls().updateUrl(TransactionID)!
//        let httpMethod: Alamofire.Method = TransactionID == 0 ? .POST : .PUT
//        
//        
//        var params: Dictionary<String, AnyObject> = convertToDictionary(nil, includeNestedProperties: false)
//        params["UserID"] = user.UserID
//        params["RelationUserID"] = friend.UserID
//        
//        return JsonRequest.create(url, parameters: params, method: httpMethod).onDownloadSuccessWithRequestInfo({ (json, request, httpUrlRequest, httpUrlResponse) -> () in
//            
//            if httpUrlResponse?.statusCode == 200 || httpUrlResponse?.statusCode == 201 || httpUrlResponse?.statusCode == 204 {
//                
//                request.succeedContext()
//            }
//            else {
//                
//                request.failContext()
//            }
//            
//        }).onDownloadFailure( { (error, alert) in
//            
//            alert.show()
//            
//        })
//    }
//}
