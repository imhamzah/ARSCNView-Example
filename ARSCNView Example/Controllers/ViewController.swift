//
//  ViewController.swift
//  ARSCNView Example
//
//  Created by Ameer Hamza on 08/04/2021.
//

import UIKit
import SceneKit
import ARKit
import AudioToolbox
import AVFoundation

class ViewController: UIViewController{

    //MARK: - Declarations
    
    var panGesture = UIPanGestureRecognizer()
    var rotationGesture = UIRotationGestureRecognizer()
    var ringOnFloorNode = SCNNode()
    var shadowOnFloorNode = SCNNode()
    
    var isNodePlaced = Bool()
    var isTappedOnScreen = Bool()
    var alreadyHovering = Bool()
    var modelName = "lamp"
    var modelNode = SCNNode()
    var originalRotationFactor: SCNVector3?
    var currentPositionOfNode = SCNVector3()
    var planPosition : SCNVector3?
    
    //MARK: - IBOutlets
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var sceneViewer: SCNView!{
        didSet{
            sceneViewer.allowsCameraControl = true
            let scene = SCNScene()
            sceneViewer.scene = scene
            self.sceneViewer.autoenablesDefaultLighting = true
            self.load3DModelInViewer(modelName: modelName)
        }
    }

    @IBOutlet weak var btnAdd: UIButton!{
        didSet{
            btnAdd.isHidden = true
        }
    }
    
    //MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "AR View"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SetupConfiguration()
        SetupCoachingOverlayView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    //MARK: - IBActions
    @IBAction func ActAddNode(_ sender: Any) {
        modelNode.removeAllActions()
        btnAdd.isHidden = true
        alreadyHovering = false
        panGesture.isEnabled = false
        rotationGesture.isEnabled = false
//        SCNTransaction.animationDuration = 1
        ringOnFloorNode.opacity = 0
        
        DropWithGravity(node: self.modelNode)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
}

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
