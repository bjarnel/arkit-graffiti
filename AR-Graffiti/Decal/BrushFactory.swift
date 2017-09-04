//
//  Brush.swift
//  AR-Graffiti
//
//  Created by Bjarne Lundgren on 30/08/2017.
//  Copyright © 2017 Silicon.dk ApS. All rights reserved.
//

import Foundation
import SpriteKit

class BrushFactory {
    static let shared = BrushFactory()
    let textures:[SKTexture]
    static let BASE_SIZE = CGSize(width: 0.1,
                                  height: 0.1)
    static let MIN_DISTANCE_SCALE:CGFloat = 0.2
    static let MAX_DISTANCE_SCALE:CGFloat = 2
    static let MIN_SCALE:CGFloat = 0.1
    static let MAX_SCALE:CGFloat = 2.0
    
    init() {
        textures = (1...5).map({ SKTexture(imageNamed: "art.scnassets/s/brush\($0).png") })
    }
    
    static func brushSizeForDistance(distance: CGFloat) -> CGSize {
        if distance < MIN_DISTANCE_SCALE {
            return CGSize(width: BASE_SIZE.width * MIN_SCALE,
                          height: BASE_SIZE.height * MIN_SCALE)
        }
        
        if distance > MAX_DISTANCE_SCALE {
            return CGSize(width: BASE_SIZE.width * MAX_SCALE,
                          height: BASE_SIZE.height * MAX_SCALE)
        }
        
        let ratio = (distance - MIN_DISTANCE_SCALE) / (MAX_DISTANCE_SCALE - MIN_DISTANCE_SCALE)
        let scale = ratio * (MAX_SCALE - MIN_SCALE) + MIN_SCALE
        
        
        return CGSize(width: BASE_SIZE.width * scale,
                      height: BASE_SIZE.height * scale)
    }
    
    func brushNode(color:UIColor, size:CGSize) -> SKSpriteNode {
        let texture = textures[Int(arc4random_uniform(UInt32(textures.count)))]
        
        let node = SKSpriteNode(texture: texture,
                            size: size)
        
        // for this the black in the brush images needs to be white.. :D
        node.colorBlendFactor = 1
        node.color = color
        return node
    }
}
