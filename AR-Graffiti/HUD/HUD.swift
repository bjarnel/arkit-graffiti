//
//  HUD.swift
//  BouncyAR
//
//  Created by Bjarne Lundgren on 19/08/2017.
//  Copyright © 2017 Silicon.dk ApS. All rights reserved.
//

import Foundation
import SpriteKit
import ARKit

private let OPTION_YOFFSET:CGFloat = 60
private let ARKIT_STATE_LABEL_NAME = "_Status_Message_"

class HUD {
    static var currentStateDisplayed:String? = nil
    
    class func present(state:ARCamera.TrackingState, in scene:SKScene) {
        var message:String
        
        switch state {
        case .notAvailable:
            message = "ARKit not available"
        case .normal:
            message = "ARKit is tracking.."
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                message = "You are moving the device too much"
            case .initializing:
                message = "Tracking is initializing"
            case .insufficientFeatures:
                message = "Not enough features detected"
            }
        }
        
        if currentStateDisplayed != nil && currentStateDisplayed! == message { return }
        currentStateDisplayed = message
        
        removeTrackingState(in: scene)
        
        let labelNode = SKLabelNode()
        labelNode.text = message
        labelNode.name = ARKIT_STATE_LABEL_NAME
        labelNode.position = CGPoint(x: 20, y: scene.size.height - 80)
        labelNode.horizontalAlignmentMode = .left
        labelNode.verticalAlignmentMode = .center
        scene.addChild(labelNode)
    }
    
    class func removeTrackingState(in scene:SKScene) {
        scene.childNode(withName: ARKIT_STATE_LABEL_NAME)?.removeFromParent()
    }
    
    class func present(options:[HUDOption], in scene:SKScene) {
        for i in 0..<options.count {
            let labelNode = SKLabelNode()
            labelNode.text = options[i].title
            labelNode.name = options[i].id
            labelNode.position = CGPoint(x: 20, y: CGFloat(i + 1) * OPTION_YOFFSET)
            labelNode.horizontalAlignmentMode = .left
            labelNode.verticalAlignmentMode = .center
            scene.addChild(labelNode)
        }
    }
    
    class func remove(options:[HUDOption], in scene:SKScene) {
        for option in options {
            scene.childNode(withName: option.id)?.removeFromParent()
        }
    }
}
