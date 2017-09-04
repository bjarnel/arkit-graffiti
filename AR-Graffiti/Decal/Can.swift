//
//  Can.swift
//  AR-Graffiti
//
//  Created by Bjarne Lundgren on 31/08/2017.
//  Copyright © 2017 Silicon.dk ApS. All rights reserved.
//

import Foundation
import SpriteKit

class Can {
    static let HEIGHT:CGFloat = 80
    static let WIDTH:CGFloat = 44
    static let CANS_CONTAINER_NAME = "kasnlkdasldak"
    static let CANS_ACTIVE_COLOR_NAME = "dasdasdsadsa"
    
    //TODO: more useful range of colors..
    static let COLORS:[UIColor] = [.black, .white, .red, .green, .blue, .yellow, .gray, .darkGray, .orange, .purple]
    
    static func renderCansIn(scene:SKScene,
                             currentColor:UIColor) {
        let container = SKNode()
        container.name = CANS_CONTAINER_NAME
        // start invisible...
        container.position = CGPoint(x: 0,
                                     y: HEIGHT * -0.5)
        
        
        
        for i in 0..<COLORS.count {
            let canNode = SKSpriteNode(color: COLORS[i],
                                       size: CGSize(width: WIDTH,
                                                    height: HEIGHT))
            canNode.position = CGPoint(x: CGFloat(i) * WIDTH + WIDTH * 0.5,
                                       y: 0)
            container.addChild(canNode)
        }
        scene.addChild(container)
        
        insertActiveColorNode(color: currentColor, in: scene)
    }
    
    private static func insertActiveColorNode(color:UIColor, in scene:SKScene) {
        let activeNode = SKSpriteNode(color: color,
                                      size: CGSize(width: WIDTH,
                                                   height: HEIGHT))
        activeNode.position = CGPoint(x: WIDTH * 0.5,
                                      y: HEIGHT * 0.5)
        activeNode.name = CANS_ACTIVE_COLOR_NAME
        scene.addChild(activeNode)
    }
    
    private static func removeCurrentActiveColorNode(in scene:SKScene) {
        guard let activeNode = scene.childNode(withName: CANS_ACTIVE_COLOR_NAME) else { return }
        
        activeNode.name = nil
        activeNode.run(SKAction.moveBy(x: 0, y: -HEIGHT, duration: 0.3)) {
            activeNode.removeFromParent()
        }
    }
    
    static func panCansBy(amount:CGFloat, in scene:SKScene) {
        guard let container = scene.childNode(withName: CANS_CONTAINER_NAME) else { return }
        
        let totalWidth = WIDTH * CGFloat(COLORS.count)
        let minX:CGFloat = totalWidth > scene.size.width ? scene.size.width - totalWidth : 0
        let maxX:CGFloat = 0
        
        let newX = container.position.x + amount
        container.position.x = newX < minX ? minX : (newX > maxX ? maxX : newX)
    }
    
    static func didTapActiveColorNode(at position:CGPoint, in scene:SKScene) -> Bool {
        if let node = scene.nodes(at: position).first as? SKSpriteNode,
           let nodeName = node.name,
            nodeName == CANS_ACTIVE_COLOR_NAME { return true}
        return false
    }
    
    static func colorPick(at position:CGPoint, in scene:SKScene) -> UIColor? {
        if let node = scene.nodes(at: position).first as? SKSpriteNode,
            let parentNode = node.parent,
            let parentNodeName = parentNode.name,
            parentNodeName == Can.CANS_CONTAINER_NAME {
            
            // remove active color node if any
            removeCurrentActiveColorNode(in: scene)
            // hide color panel
            hideColors(in: scene)
            // show active color
            insertActiveColorNode(color: node.color, in: scene)
            
            return node.color
        }
        return nil
    }
    
    static func showColors(in scene:SKScene) {
        guard let container = scene.childNode(withName: CANS_CONTAINER_NAME) else { return }
        
        // remove active color node..
        removeCurrentActiveColorNode(in: scene)
        
        let position = CGPoint(x: 0, y: HEIGHT * 0.5)
        container.run(SKAction.move(to: position, duration: 0.3))
    }
    
    static func hideColors(in scene:SKScene) {
        guard let container = scene.childNode(withName: CANS_CONTAINER_NAME) else { return }
        
        let position = CGPoint(x: 0, y: HEIGHT * -0.5)
        container.run(SKAction.move(to: position, duration: 0.3))
    }
}
