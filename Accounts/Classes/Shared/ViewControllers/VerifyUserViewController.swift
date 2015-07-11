//
//  VerifyUserViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 10/07/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//

import UIKit
import ABToolKit
import Parse
import Bolts
import Alamofire

class VerifyUserViewController: ACBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.showLoader()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        proceed()
        
//        var query: PFQuery = PFInstallation.query()!
//        query.whereKey(kParseInstallationUserIDKey, equalTo: 1)
//        query.includeKey(kParseInstallationUserIDKey)
//        
//        var push = PFPush()
//        push.setQuery(query)
//        push.setMessage("HI !")
//        push.setData(["test": "foo"])
//        push.sendPushInBackground()
    }
    
    func proceed() {
        
        let v = UINavigationController(rootViewController: FriendsViewController())
        v.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        presentViewController(v, animated: true, completion: nil)
    }

}
