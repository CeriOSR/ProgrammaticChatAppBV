//
//  Extensions.swift
//  Chat App Demo Programmatic
//
//  Created by Rey Cerio on 2017-01-03.
//  Copyright © 2017 CeriOS. All rights reserved.
//

import UIKit

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    
    func loadImageUsingCacheWithUrlString(urlString: String) {
        
        //This will empty all the images getting rid of the blinking or reused images when scrolling...This was the solution to our messenger app problem for the messages!!!!!!!!!
        self.image = nil
        
        
        //check cache for image first
        if let cacheImage = imageCache.object(forKey: urlString as AnyObject) {
            
            self.image = cacheImage as? UIImage
            return
            
        }
        //otherwise fire off a new downlaod
        let url = NSURL(string: urlString)
        //need to downcast url as URL else ambigous
        URLSession.shared.dataTask(with: url! as URL, completionHandler: { (data, response, error) in
            
            
            if error != nil {
                print(error ?? "")
                return
            }
            
            //need to bring it back to main thread so cells will dequeue and reload
            DispatchQueue.main.async {
                
                if let downloadedImage = UIImage(data: data!) {
                    //assigning the image to a cache for later use
                    imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                    
                    self.image = downloadedImage
   
                }
                
                
            }
            //need .resume here to fire off the NSURL request
            
        }).resume()
        

        
    }
    
    
}
