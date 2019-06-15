//
//  ViewController.swift
//  Uber
//
//  Created by Luis Fernando Pasquinelli Amaral de Abreu on 03/04/2018.
//  Copyright © 2018 Luis. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let autenticacao = Auth.auth()
        autenticacao.addStateDidChangeListener { (autenticao, usuario) in
            if let usuarioLogado = usuario {
                let database = Database.database().reference()
                let usuarios = database.child("usuarios").child(usuarioLogado.uid)
                
                usuarios.observeSingleEvent(of: .value, with: { (snapshot) in
                    let dados = snapshot.value as? NSDictionary
                    if dados != nil {
                        let tipoUsuario = dados!["tipo"] as! String
                        
                        if tipoUsuario == "passageiro" {
                            self.performSegue(withIdentifier: "segueLoginPassageiro", sender: nil)
                        } else{
                            self.performSegue(withIdentifier: "segueLoginMotorista", sender: nil)
                        }
                    }
                })
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

