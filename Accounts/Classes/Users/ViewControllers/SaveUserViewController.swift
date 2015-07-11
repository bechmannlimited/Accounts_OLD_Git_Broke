//
//  RegisterViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 20/06/2015.
//  Copyright (c) 2015 Alex Bechmann. All rights reserved.
//


import UIKit
import ABToolKit
import SwiftyJSON

class SaveUserViewController: ACFormViewController {
    
    var user = User()
    var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if user.UserID == 0 {
            
            title = "Register"
        }
        else {
            
            title = "Edit profile"
        }
        
        showOrHideRegisterButton()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if view.frame.width >= kTableViewMaxWidth {
            
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        }
    }
    
    override func setupView() {
        super.setupView()
        
        view.backgroundColor = UIColor.groupTableViewBackgroundColor()
    }
    
    func showOrHideRegisterButton() {
        
        let saveButton = user.UserID == 0 ? UIBarButtonItem(title: "Register", style: .Plain, target: self, action: "save") : UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "save")
        
        navigationItem.rightBarButtonItem = saveButton
        navigationItem.rightBarButtonItem?.tintColor = kNavigationBarPositiveActionColor
        
        navigationItem.rightBarButtonItem?.enabled = user.modelIsValid() && !isLoading
    }
    
    func save() {
        
        if user.UserID != 0 {
            
            isLoading = true
            showOrHideRegisterButton()
            
            user.webApiUpdate()?.onDownloadSuccessWithRequestInfo({ (json, request, httpUrlRequest, httpUrlResponse) -> () in
                
                let success = httpUrlResponse!.statusCode == 200 || httpUrlResponse!.statusCode == 204
                
                if success {
                    
                    self.navigationController?.popViewControllerAnimated(true)
                    kActiveUser = User.createObjectFromJson(json)
                    kActiveUser.saveUserOnDevice()
                }
                else {
                    
                    let errorsJson = json["ModelState"]["Error"]
                    
                    let errors = NSMutableArray()
                    
                    for (index: String, errorJson: JSON) in errorsJson {
                        
                        errors.addObject(errorJson.stringValue)
                        println(errorJson)
                    }
                    
                    let errorMsg = errors.componentsJoinedByString(",\n")
                    
                    UIAlertView(title: "Error", message: errorMsg, delegate: nil, cancelButtonTitle: "OK").show()
                }
                
            }).onDownloadFinished({ () -> () in
                
                self.isLoading = false
                self.showOrHideRegisterButton()
            })
        }
        else {
            
            isLoading = true
            showOrHideRegisterButton()
            
            user.register()?.onContextSuccess({ () -> () in
                
                var v = UIStoryboard.initialViewControllerFromStoryboardNamed("Main")
                self.presentViewController(v, animated: true, completion: nil)
                
            }).onDownloadFinished({ () -> () in
                
                self.isLoading = false
                self.showOrHideRegisterButton()
            })
        }
    }
}

extension SaveUserViewController: FormViewDelegate {
    
    override func formViewElements() -> Array<Array<FormViewConfiguration>> {
        
        var sections = Array<Array<FormViewConfiguration>>()
        sections.append([
            FormViewConfiguration.textField("Username", value: user.Username, identifier: "Username"),
            FormViewConfiguration.textField("Email", value: user.Email, identifier: "Email"),
            FormViewConfiguration.textField("Password", value: user.Password, identifier: "Password")
        ])
        return sections
    }
    
    func formViewElementDidChange(identifier: String, value: AnyObject?) {

        showOrHideRegisterButton()
    }
    
    func formViewTextFieldEditingChanged(identifier: String, text: String) {
        
        switch identifier {
            
        case "Username":
            user.Username = text
            break
            
        case "Password":
            user.Password = text
            break;
            
        case "Email":
            user.Email = text
            break
            
        default: break;
        }
    }
}

extension SaveUserViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath) as! FormViewTextFieldCell
        
        if indexPath.row == 2 {
            
            cell.textField.secureTextEntry = true
        }
        
        cell.textField.autocapitalizationType = UITextAutocapitalizationType.None
        
        return cell
    }
}