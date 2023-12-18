//
//  ViewController.swift
//  RestoControl
//
//  Created by Ruben Freddy Quea Jacho on 11/12/23.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var btnAccess: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func signInButtonTapped(_ sender: Any) {
        guard let email = txtEmail.text, let password = txtPassword.text else {
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) {
            (user, error) in
            if error != nil {
                print("not Access")
                self.txtEmail.text = ""
                self.txtPassword.text = ""
            }else {
                print("success access")
                self.performSegue(withIdentifier: "listDishes", sender: nil)
            }
        }
    }
}

