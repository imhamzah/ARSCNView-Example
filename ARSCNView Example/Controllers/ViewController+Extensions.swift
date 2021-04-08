//
//  ViewController+Extensions.swift
//  ARSCNView Example
//
//  Created by Ameer Hamza on 08/04/2021.
//

import UIKit
import SceneKit
import ARKit
import AudioToolbox
import AVFoundation



//MARK: - SceneViewer functions
extension ViewController{
    public typealias SCompletionHandler = (_ success:Bool)->()
    
    func load3DModelInViewer(modelName:String){
        sceneViewer.scene?.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
            
        }
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        self.getNearestStores(with: modelName) { (success) in
            dispatchGroup.leave()
        }
    }
    
    func getNearestStores(with modelName:String, completion: @escaping SCompletionHandler){
        DispatchQueue.global(qos: .background).async {
            
            let urlString = "art.scnassets/\(modelName).scn"
            let node = SCNScene(named: urlString)!
            var nodesChair = SCNNode()
            
            nodesChair = node.rootNode.childNode(withName: "\(modelName)", recursively: false)!
            nodesChair.scale = SCNVector3Make(0.5, 0.5, 0.5)
            self.sceneViewer.scene?.rootNode.addChildNode(nodesChair)
            sleep(3)
            completion(true)
        }
    }
}


//MARK: - Coaching Overlay View Delegate
extension ViewController: ARCoachingOverlayViewDelegate{
    // Called When The ARCoachingOverlayView Is Active And Displayed
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
    }
    
    // Called When The ARCoachingOverlayView Is No Active And No Longer Displayer
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        btnAdd.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            if !self.isNodePlaced {
                self.AddSCNNode()
            }
        }
    }
    // Called When Tracking Conditions Are Poor Or The Seesion Needs Restarting
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
    }
}


//MARK: - Class Helper
extension ViewController{
    /// Coaching overlay view setup
    func SetupCoachingOverlayView(){
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.delegate = self
        coachingOverlay.session = sceneView.session
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.goal = .horizontalPlane
        sceneView.addSubview(coachingOverlay)
        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: view.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }
    
    /// Configuration setup
    func SetupConfiguration(){
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        self.sceneView.autoenablesDefaultLighting = false
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth){
            print("people occlusion supported")
            configuration.frameSemantics = .personSegmentationWithDepth
        } else {
            print("people occlusion not supported")
        }
        sceneView.delegate = self
        sceneView.scene = SCNScene()
        sceneView.preferredFramesPerSecond = 30
        sceneView.session.run(configuration)
    }
    
    
    /// place node in front of camera
    /// - Parameters:
    ///   - node: the front view of camera node
    ///   - distance: depth at which we need to place a node
    /// - Returns: returns the position of scene
    func SceneSpacePosition(inFrontOf node: SCNNode, atDistance distance: Float) -> SCNVector3 {
        let localPosition = SCNVector3(x: 0, y: 0, z: Float(-distance))
        let scenePosition = node.convertPosition(localPosition, to: nil)
        return scenePosition
    }
    
    /// Adding node into sceneView whenever coachingOverlay view successfully scanned the environment
    func AddSCNNode(){
        guard let frame = self.sceneView.session.currentFrame
            else {return}
        
        let node = SCNScene(named: "art.scnassets/\(self.modelName).scn")!.rootNode
        modelNode = node.childNode(withName: "\(self.modelName)", recursively: true) ?? SCNNode()
        let cameraNode = self.sceneView.pointOfView!
        let cameraPosition = self.SceneSpacePosition(inFrontOf: cameraNode, atDistance: 1.2)
    
        var position = self.planPosition ?? SCNVector3(0,0,0)
        position.x = cameraPosition.x
        position.z = cameraPosition.z
        modelNode.position = position
        currentPositionOfNode = position
        modelNode.eulerAngles.y = frame.camera.eulerAngles.y
        
        modelNode.castsShadow = true
        DispatchQueue.main.async {
            self.sceneView.scene.rootNode.addChildNode(self.modelNode)
            self.isNodePlaced = true
        }
        
        RegisterGestures()
        AddLights(node: self.modelNode)
        PopUpNodeEffect(node: self.modelNode)
        HoveringEffect(node: self.modelNode)
    }

    
    /// Calling directional lights function and adding floor for shadow reflection and ring node for editing purpose in sceneView
    /// - Parameter node: this is the node on which we need to add effect
    func AddLights(node: SCNNode){
        //getting size of node
        let min = node.boundingBox.min
        let max = node.boundingBox.max
        let w = CGFloat(max.x - min.x) + 20
        let h = CGFloat(max.y - min.y) + 20
        
        //adding shadow plane where shadow will be added
        let shadowPlane = SCNPlane(width: w, height: h)
        shadowOnFloorNode = SCNNode(geometry: shadowPlane)
        shadowOnFloorNode.eulerAngles.x = -.pi / 2
        shadowOnFloorNode.castsShadow = false
        let material = SCNMaterial()
        material.isDoubleSided = false
        material.lightingModel = .shadowOnly
        shadowPlane.materials = [material]
        shadowOnFloorNode.position.y = modelNode.position.y
        self.sceneView.scene.rootNode.addChildNode(shadowOnFloorNode)
        
        //adding lights on node
        let light1 = AddDirectionalLights(angle: SCNVector3(-Float.pi / 1.8, 0, 0))
        let light2 = AddDirectionalLights(angle: SCNVector3(-Float.pi / 2.2, 0, 0))
        self.sceneView.scene.rootNode.addChildNode(light1)
        self.sceneView.scene.rootNode.addChildNode(light2)
        
        //adding ringPlane on bottom of node
        let ringPlane = SCNPlane(width: 0.85, height: 0.85)
        ringOnFloorNode = SCNNode(geometry: ringPlane)
        ringOnFloorNode.eulerAngles.x = -.pi / 2
        ringOnFloorNode.castsShadow = false
        let ringMaterial = SCNMaterial()
        ringMaterial.isDoubleSided = false
        ringMaterial.diffuse.contents = UIImage(named: "Circle1")
        ringMaterial.lightingModel = .constant
        ringPlane.materials = [ringMaterial]
        ringOnFloorNode.position.x = modelNode.position.x
        ringOnFloorNode.position.y = modelNode.position.y + 0.001
        ringOnFloorNode.position.z = modelNode.position.z
        self.sceneView.scene.rootNode.addChildNode(ringOnFloorNode)
        
        //rotating bottom ring node on y-axis
        let action = SCNAction.rotateBy(x: 0, y: CGFloat(2 * Double.pi), z: 0, duration: 22)
        let repAction = SCNAction.repeatForever(action)
        ringOnFloorNode.runAction(repAction)
    }
    
    
    /// Adding directional light in scene for shadow purpose
    /// - Parameter angle: on which angle the light should be directed at
    /// - Returns: returns a light node to add it into sceneView
    func AddDirectionalLights(angle: SCNVector3) -> SCNNode{
        let light = SCNLight()
        let lightNode = SCNNode()
        light.type = .directional
        light.castsShadow = true
//        light.color = UIColor.white
        light.shadowMode = .forward
        light.shadowSampleCount = 512
        light.shadowRadius = 5
        light.shadowColor = UIColor.black.withAlphaComponent(0.7)
        light.shadowMapSize = CGSize(width: 500, height: 500)
        light.orthographicScale = 2
        light.zNear = 1
        light.zFar = 1000
        light.categoryBitMask = -1
        lightNode.eulerAngles = angle
        lightNode.light = light
        return lightNode
    }
    
    
    /// Pan gesture recognizer on screen
    /// - Parameter gesture: sender object
    @objc private func viewPanned(_ gesture: UIPanGestureRecognizer) {
        if modelNode != nil{
            if gesture.state == .changed{
                let currentTouchPoint = gesture.location(in: self.sceneView)
                guard let hitTest = self.sceneView.hitTest(currentTouchPoint, types: .existingPlane).first else { return }
                let worldTransform = hitTest.worldTransform
                let newPosition = SCNVector3(worldTransform.columns.3.x, modelNode.position.y, worldTransform.columns.3.z)
                currentPositionOfNode = newPosition
//                SCNTransaction.animationDuration = 0.8
                ringOnFloorNode.position.x = modelNode.position.x
                ringOnFloorNode.position.y = ringOnFloorNode.position.y
                ringOnFloorNode.position.z = modelNode.position.z
//                shadowOnFloorNode.position = SCNVector3(newPosition.x, newPosition.y, newPosition.z)
                modelNode.position = SCNVector3(newPosition.x, newPosition.y, newPosition.z)
            }
        }
    }
    
    /// Rotation gesture recognizer on screen
    /// - Parameter sender: sender object
    @objc func viewRotated(sender: UIRotationGestureRecognizer) {
        if modelNode != nil{
        switch sender.state {
        case .began:
            originalRotationFactor = modelNode.eulerAngles
        case .changed:
            guard var originalRotation = originalRotationFactor else { return }
            originalRotation.y -= Float(sender.rotation * 1.5)
            ringOnFloorNode.eulerAngles.y = originalRotation.y
            modelNode.eulerAngles.y = originalRotation.y
        default:
            originalRotationFactor = nil
        }}
    }
    
    /// Tap gesture recognizer on screen
    /// - Parameter sender: sender object
    @objc func handleTap(sender: UITapGestureRecognizer){
        if isTappedOnScreen{
//            isTappedOnScreen = false
//            btnAdd.isHidden = true
//            ringOnFloorNode.opacity = 0
        }
        else if !isTappedOnScreen{
            if !alreadyHovering{
                HoveringEffect(node: self.modelNode)
                alreadyHovering = true
            }
            panGesture.isEnabled = true
            rotationGesture.isEnabled = true
            btnAdd.isHidden = false
            ringOnFloorNode.opacity = 1
        }
    }
    
    /// Registering gestures in sceneView
    func RegisterGestures(){
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(viewPanned))
        sceneView.addGestureRecognizer(panGesture)
        rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(viewRotated))
        sceneView.addGestureRecognizer(rotationGesture)
    }
    
    
    /// dropping model with gravity effect
    /// - Parameter node: this is the node on which we need to add effect
    func DropWithGravity(node: SCNNode){
        let heartBeat = SCNAction.sequence([
            SCNAction.move(to: currentPositionOfNode, duration: 0.1),
            SCNAction.move(to: SCNVector3(currentPositionOfNode.x, currentPositionOfNode.y + 0.008, currentPositionOfNode.z), duration: 0.1),
            SCNAction.move(to: SCNVector3(currentPositionOfNode.x, currentPositionOfNode.y - 0.008, currentPositionOfNode.z), duration: 0.1),
        ])
        node.runAction(SCNAction.repeat(heartBeat, count: 1))
    }
    
    
    /// add model with hovering effect (up & down) in sceneView
    /// - Parameter node: this is the node on which we need to add effect
    func HoveringEffect(node: SCNNode){
        let moveDown = SCNAction.move(by: SCNVector3(0, -0.1, 0), duration: 1)
        let moveUp = SCNAction.move(by: SCNVector3(0,0.1,0), duration: 1)
        let hoverSequence = SCNAction.sequence([moveUp,moveDown])
        let loopSequence = SCNAction.repeatForever(hoverSequence)
        node.runAction(loopSequence)
    }
    
    /// add zoom effect to model from 0 to 1
    /// - Parameter node: this is the node on which we need to add effect
    func PopUpNodeEffect(node: SCNNode){
        let popUp = SCNAction.sequence([
            SCNAction.hide(),
            SCNAction.scale(to: 0.0, duration: 0),
            SCNAction.unhide(),
            SCNAction.scale(to: 0.2, duration: 0.75),
            SCNAction.fadeIn(duration: 0.75)
        ])
        node.runAction(SCNAction.repeat(popUp, count: 1))
    }
}

