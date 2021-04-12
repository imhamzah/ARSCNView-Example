//
//  InitialViewController.swift
//  ARSCNView Example
//
//  Created by Ameer Hamza on 08/04/2021.
//

import UIKit

class InitialViewController: UIViewController {

    @IBOutlet weak var btnAR: UIButton!{
        didSet{
            btnAR.layer.cornerRadius = 12
            btnAR.clipsToBounds = true
        }
    }
    @IBOutlet weak var btn3D: UIButton!{
        didSet{
            btn3D.layer.cornerRadius = 12
            btn3D.clipsToBounds = true
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "View in AR"

        // Do any additional setup after loading the view.
    }
    
    @IBAction func ActButtonAR(_ sender: Any) {
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ViewController") as? ViewController{
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func ActButton3D(_ sender: Any) {
        if let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "_3DViewController") as? _3DViewController{
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
