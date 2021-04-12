//
//  ViewController.swift
//  ARSCNView Example
//
//  Created by Ameer Hamza on 08/04/2021.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController{

    //MARK: - Declarations
    
    var panGesture = UIPanGestureRecognizer()
    var rotationGesture = UIRotationGestureRecognizer()
    
    var isNodePlaced = Bool()
    var modelName = "lamp"
    var modelNode = SCNNode()
    var originalRotationFactor: SCNVector3?
    var currentPositionOfNode = SCNVector3()
    var planPosition : SCNVector3?
    
    //MARK: - IBOutlets
    @IBOutlet var sceneView: ARSCNView!
    
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
}
