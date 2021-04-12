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


//MARK: - ARKIT Delegates
extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let x = CGFloat(planeAnchor.transform.columns.3.x)
        let y = CGFloat(planeAnchor.transform.columns.3.y)
        let z = CGFloat(planeAnchor.transform.columns.3.z)
        let position = SCNVector3(x,y,z)
        self.planPosition = position
    }
}

//MARK: - Coaching Overlay View Delegate
extension ViewController: ARCoachingOverlayViewDelegate{
    // Called When The ARCoachingOverlayView Is Active And Displayed
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
    }
    
    // Called When The ARCoachingOverlayView Is No Active And No Longer Displayer
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
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
        self.sceneView.autoenablesDefaultLighting = true
        
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
        
        DispatchQueue.main.async {
            self.sceneView.scene.rootNode.addChildNode(self.modelNode)
            self.isNodePlaced = true
            
            self.RegisterGestures()
        }
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
            modelNode.eulerAngles.y = originalRotation.y
        default:
            originalRotationFactor = nil
        }}
    }
    
    /// Registering gestures in sceneView
    func RegisterGestures(){
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(viewPanned))
        sceneView.addGestureRecognizer(panGesture)
        rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(viewRotated))
        sceneView.addGestureRecognizer(rotationGesture)
    }
}
