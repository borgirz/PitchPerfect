//
//  CustomViewAnimationsFunctions.swift
//  PitchPerfect
//
//  Created by Nicolas Jasmes on 18/08/15.
//  Copyright (c) 2015 Nicolas Jasmes. All rights reserved.
//

//import Foundation
import UIKit

// Inspired by objective C code at URL : http://stackoverflow.com/questions/15368397/uibutton-flashing-animation
// + add fading with UIViewAnimationOptions.CurveEaseIn (learned from https://www.andrewcbancroft.com/2014/07/27/fade-in-out-animations-as-class-extensions-with-swift/)
// + make it reccursive & use ternary operator

// Function to flash an UIView (including object which inherit from UIView like UIButton, UIImage, UILabel, ...) with fading between 0.2 & 1.O alpha
// Still allow user interaction and is executed with no delay. Full loop = 1.6 sec (0.8 sec fade in, 0.8 sec fade out)
func flashViewWithFadingTransition(view: UIView){
    UIView.animateWithDuration(0.8, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn | UIViewAnimationOptions.AllowUserInteraction, animations: { () -> Void in
        view.alpha = (view.alpha == 1) ? 0.2: 1.0
        }, completion: {(finished:Bool) -> Void in
            if(!finished){
                return
            }
            else{
                flashViewWithFadingTransition(view)
            }
    })
}

// Stop All Animations for a UIView
// Source : http://stackoverflow.com/questions/25117697/after-using-self-view-layer-removeallanimations-the-next-animation-not-workin
func stopAllAnimations(view: UIView){
    view.layer.removeAllAnimations()
}

// EOF

