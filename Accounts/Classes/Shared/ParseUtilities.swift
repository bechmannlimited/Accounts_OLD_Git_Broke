//
//  ParseUtilities.swift
//  Accounts
//
//  Created by Alex Bechmann on 13/07/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit

public class ParseUtilities: NSObject {
   
    public class func showAlertWithErrorIfExists(error: NSError?) {
        
        if let err = error?.localizedDescription {
        
            UIAlertView(title: "Error!", message: err, delegate: nil, cancelButtonTitle: "OK").show()
        }
    }
    
}
