//
//  ViewController.swift
//  AR-Graffiti
//
//  Created by Bjarne Lundgren on 30/08/2017.
//  Copyright © 2017 Silicon.dk ApS. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    var trackState = WallTrackState.findFirstPoint
    var colorPick = ColorPickMode.picked(color: Can.COLORS[0])
    var mode = AppState.menu {
        willSet {
            if mode == .menu {
                HUD.remove(options: [BouncyOption.newWall, BouncyOption.start],
                           in: sceneView.overlaySKScene!)
            }
            if mode == .addingWall {
                HUD.remove(options: [BouncyOption.cancelWall],
                           in: sceneView.overlaySKScene!)
            }
        }
        didSet {
            switch mode {
            case .menu:
                HUD.present(options: [BouncyOption.newWall, BouncyOption.start],
                            in: sceneView.overlaySKScene!)
            case .addingWall:
                trackState = .findFirstPoint
                HUD.present(options: [BouncyOption.cancelWall],
                            in: sceneView.overlaySKScene!)
                
            case .playing:
                guard case .picked(let color) = colorPick else { fatalError() }
                Can.renderCansIn(scene: sceneView.overlaySKScene!,
                                 currentColor: color)
                
                for wall in walls {
                    Wall.makeDecalable(wallNode: wall.wallNode,
                                       width: CGFloat(wall.wallStartPosition.distance(vector: wall.wallEndPosition)),
                                       height: Wall.HEIGHT)
                
                }
            }
        }
    }
    var walls = [(wallNode:SCNNode, wallStartPosition:SCNVector3, wallEndPosition:SCNVector3, wallId:String)]()
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        // sceneView.showsStatistics = true
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        sceneView.overlaySKScene = SKScene(size: view.frame.size)
        
        // with this we will stil get touches began..
        sceneView.overlaySKScene!.isUserInteractionEnabled = false
        
        let tapGest = UITapGestureRecognizer(target: self,
                                             action: #selector(didTap))
        sceneView.addGestureRecognizer(tapGest)
        let panGest = UIPanGestureRecognizer(target: self,
                                             action: #selector(didPan))
        panGest.cancelsTouchesInView = false
        sceneView.addGestureRecognizer(panGest)
        mode = .menu
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = false
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneView.overlaySKScene?.size = view.frame.size
        //center = view.center
    }
    
    private func anyPlaneFrom(location:CGPoint, usingExtent:Bool = true) -> (SCNNode, SCNVector3, ARPlaneAnchor)? {
        let results = sceneView.hitTest(location,
                                        types: usingExtent ? ARHitTestResult.ResultType.existingPlaneUsingExtent : ARHitTestResult.ResultType.existingPlane)
        
        guard results.count > 0,
            let anchor = results[0].anchor as? ARPlaneAnchor,
            let node = sceneView.node(for: anchor) else { return nil }
        
        return (node,
                SCNVector3Make(results[0].worldTransform.columns.3.x, results[0].worldTransform.columns.3.y, results[0].worldTransform.columns.3.z),
                anchor)
    }
    
    @objc func didTap(_ sender:UITapGestureRecognizer) {
        let location = sender.location(in: sceneView)
        
        switch mode {
        case .menu: menuTapped(location: location)
        case .addingWall: addingWallTapped(location: location)
        case .playing: playingTapped(location: location)
        }
    }
    
    private func menuTapped(location:CGPoint) {
        guard let hudPosition = sceneView.overlaySKScene?.convertPoint(fromView: location),
            let node = sceneView.overlaySKScene?.nodes(at: hudPosition).first,
            let nodeName = node.name else { return }
        
        switch nodeName {
        case BouncyOption.newWall.id:
            mode = .addingWall
            
        case BouncyOption.start.id:
            guard !walls.isEmpty else { return }
            mode = .playing
            
        default: break
        }
    }
    
    private func addingWallTapped(location:CGPoint) {
        if let hudPosition = sceneView.overlaySKScene?.convertPoint(fromView: location),
            let node = sceneView.overlaySKScene?.nodes(at: hudPosition).first,
            let nodeName = node.name {
            
            switch nodeName {
            case BouncyOption.cancelWall.id:
                if case .findScondPoint(let trackingNode, _, _) = trackState {
                    // cleanup!
                    trackingNode.removeFromParentNode()
                }
                trackState = .findFirstPoint
                mode = .menu
                
            default: break
            }
            
            return
        }
        
        
        switch trackState {
        case .findFirstPoint:
            // begin wall placement
            
            guard let planeData = anyPlaneFrom(location: location) else { return }
            
            let trackingNode = TrackingNode.node(from: planeData.1,
                                                 to: nil)
            sceneView.scene.rootNode.addChildNode(trackingNode)
            trackState = .findScondPoint(trackingNode: trackingNode,
                                         wallStartPosition: planeData.1,
                                         originAnchor: planeData.2)
        case .findScondPoint(let trackingNode, let wallStartPosition, let originAnchor):
            // finalize wall placement
            
            guard let planeData = anyPlaneFrom(location: self.view.center),
                planeData.2 == originAnchor else { return }
            
            trackingNode.removeFromParentNode()
            let wallNode = Wall.node(from: wallStartPosition,
                                     to: planeData.1)
            sceneView.scene.rootNode.addChildNode(wallNode)
            
            let newTrackingNode = TrackingNode.node(from: planeData.1,
                                                    to: nil)
            trackState = .findScondPoint(trackingNode: newTrackingNode, wallStartPosition: planeData.1, originAnchor: originAnchor)
            
            walls.append((wallNode: wallNode,
                          wallStartPosition: wallStartPosition,
                          wallEndPosition: planeData.1,
                          wallId: UUID().uuidString))
            
        default:fatalError()
        }
    }
    
    private func playingTapped(location:CGPoint) {
        guard !isInPaintRect(location: location),
            let position = sceneView.overlaySKScene?.convertPoint(fromView: location) else { return }
        if case .picking = colorPick,
                // calling colorPick(.. has the side-effect is hiding colors if successful..
            let newColor = Can.colorPick(at: position, in: sceneView.overlaySKScene!) {
            
            colorPick = .picked(color: newColor)
        } else if case .picked(_) = colorPick,
            Can.didTapActiveColorNode(at: position, in: sceneView.overlaySKScene!) {
            colorPick = .picking
            Can.showColors(in: sceneView.overlaySKScene!)
        }
    }
    
    var lastPaint = Date()
    private func paint() {
        let now = Date()
        guard lastPaint + 1.0/30.0 < now,
              let trackingTouch = trackingTouch,
              let povPosition = sceneView.pointOfView?.position,
              case .picked(let color) = colorPick else { return }
        lastPaint = now
        
        let location = trackingTouch.location(in: view)
        let results = sceneView.hitTest(location, options: [
            SCNHitTestOption.categoryBitMask: NodeCategory.wallNode.rawValue,
            SCNHitTestOption.firstFoundOnly: true
            ])
        
        // find "target" position..
        guard let wallNode = results.first?.node,
              let localCoordinates = results.first?.localCoordinates,
              let worldCoordinates = results.first?.worldCoordinates,
              let scene = wallNode.geometry?.firstMaterial?.diffuse.contents as? SKScene else {
                return
        }
        
        let distance = povPosition.distance(vector: worldCoordinates)
        
        // this calculation works, however it is entirely specific to this particular geometry (scnplane) and the
        // coordinate system of the skscene.. also who knows, may not work in all cases :D
        let skPosition = CGPoint(x: CGFloat(localCoordinates.x) * WALL_TEXT_SIZE_MULP + scene.size.width * 0.5,
                                 y: CGFloat(localCoordinates.y) * -WALL_TEXT_SIZE_MULP + scene.size.height * 0.5)
        
        let scnSize = BrushFactory.brushSizeForDistance(distance: CGFloat(distance))
        
        let skSize = CGSize(width: scnSize.width * WALL_TEXT_SIZE_MULP,
                            height: scnSize.height * WALL_TEXT_SIZE_MULP)
        
        let decalNode = BrushFactory.shared.brushNode(color: color,
                                                      size: skSize)
        decalNode.position = skPosition
        scene.addChild(decalNode)
    }
    
    private func updateWallTracking() {
        guard case .findScondPoint(let trackingNode, let wallStartPosition, let originAnchor) = trackState,
            let planeData = anyPlaneFrom(location: self.view.center),
            planeData.2 == originAnchor else { return }
        
        trackingNode.removeFromParentNode()
        let newTrackingNode = TrackingNode.node(from: wallStartPosition,
                                                to: planeData.1)
        sceneView.scene.rootNode.addChildNode(newTrackingNode)
        trackState = .findScondPoint(trackingNode: newTrackingNode,
                                     wallStartPosition: wallStartPosition,
                                     originAnchor: originAnchor)
    }
    
    private var trackingTouch:UITouch?
    private func isInPaintRect(location:CGPoint) -> Bool {
        if view.bounds.height - Can.HEIGHT > location.y {
            return true
        }
        if case .picked(_) = colorPick, Can.WIDTH < location.x {
            return true
        }
        return false
    }
    private func isInPaintRect(touch:UITouch) -> Bool {
        let location = touch.location(in: view)
        return isInPaintRect(location: location)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard mode == .playing,
              case .picked(_) = colorPick,
              let touch = touches.first,
              isInPaintRect(touch: touch) else { return }
        trackingTouch = touch
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let trackingTouch = trackingTouch,
            touches.contains(trackingTouch) else { return }
        self.trackingTouch = nil
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard let trackingTouch = trackingTouch,
            touches.contains(trackingTouch) else { return }
        self.trackingTouch = nil
    }
    
    var cansPanState = CansPanState.none
    @objc func didPan(_ sender:UIPanGestureRecognizer) {
        let location = sender.location(in: view)
        
        switch sender.state {
        case .began:
            guard case .picking = colorPick,
                  !isInPaintRect(location: location) else { break }
            cansPanState = .from(startPosition: location)
        case .cancelled:  cansPanState = .none
        case .changed:
            guard case .from(let startPosition) = cansPanState else { break }
            Can.panCansBy(amount: location.x - startPosition.x,
                          in: sceneView.overlaySKScene!)
            
        case .ended: cansPanState = .none
        case .failed: cansPanState = .none
        case .possible:break
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if mode == .playing && trackingTouch != nil { paint() }
        
        DispatchQueue.main.async(execute: updateWallTracking)
    }
    
    // MARK: - ARSessionObserver
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        HUD.present(state: camera.trackingState,
                    in: sceneView.overlaySKScene!)
    }
    
}


