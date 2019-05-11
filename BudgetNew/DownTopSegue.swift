//
//  DownTopSegue.swift
//  BudgetNew
//
//  Created by linoj ravindran on 02/05/2019.
//  Copyright © 2019 linoj ravindran. All rights reserved.
//

import Foundation
import UIKit
class DownTop: UIStoryboardSegue {
    let duration: TimeInterval = 0.5
    let delay: TimeInterval = 0
    let animationOptions: UIView.AnimationOptions = .curveEaseInOut
    
    override func perform() {
        // get views
        let sourceView = self.source.view as UIView
        let destinationView = self.destination.view as UIView
        let window = UIApplication.shared.delegate?.window!
        
        // 1. beloveSubview
        window?.insertSubview(destinationView, belowSubview: sourceView)
        
        
        //2. y cordinate change
        destinationView.center = CGPoint(x: (sourceView.center.x), y: (sourceView.center.y) + (destinationView.center.y))
        
        
        //3. create UIAnimation- change the views's position when present it
        UIView.animate(withDuration: 0.4,
                       animations: {
                        destinationView.center = CGPoint(x: (sourceView.center.x), y: (sourceView.center.y) + 63)
                        sourceView.center = CGPoint(x: (sourceView.center.x), y: 0 - 2 * (destinationView.center.y))
        }, completion: {
            (value: Bool) in
            //4. dismiss
//            destinationView.removeFromSuperview()
//            if let navController = self.destination.navigationController {
//                navController.popToViewController(self.destination, animated: false)
//            }
            
            
        })
    }
}
