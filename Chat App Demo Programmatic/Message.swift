//
//  Message.swift
//  Chat App Demo Programmatic
//
//  Created by Rey Cerio on 2017-01-04.
//  Copyright © 2017 CeriOS. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    
    var fromId: String?
    var text: String?
    var timeStamp: NSNumber?
    var toId: String?
    
    func chatPartnerId() -> String? {
        
        //we dont want the table to always display the toId name and image so this IF statement is the fix.
        //this will make it so it its never the current users image and name thats printed on the table.
        if fromId == FIRAuth.auth()?.currentUser?.uid {
            return toId!
        } else {
            return fromId!
        }
        
        //return (fromId == FIRAuth.auth()?.currentUser?.uid ? toId : fromId)! //one liner version of the if statement

    }
    
}
