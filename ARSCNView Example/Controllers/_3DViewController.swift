//
//  _3DViewController.swift
//  ARSCNView Example
//
//  Created by Ameer Hamza on 12/04/2021.
//

import UIKit
import SceneKit

class _3DViewController: UIViewController {

    @IBOutlet weak var sceneView: SCNView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "3D Viewer"
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        let scene = SCNScene()
        sceneView.scene = scene
        showModel()
    }
}


//MARK: - Class Helper
extension _3DViewController{
    func showModel(){
        let scene = SCNScene(named: "art.scnassets/lamp.scn")
        guard let node = scene?.rootNode.childNode(withName: "lamp", recursively: true)
            else {return}
        sceneView.scene?.rootNode.addChildNode(node)
    }
}
