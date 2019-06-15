//
//  EntrarViewController.swift
//  Uber
//
//  Created by Luis Fernando Pasquinelli Amaral de Abreu on 03/04/2018.
//  Copyright © 2018 Luis. All rights reserved.
//

import UIKit
import FirebaseAuth

class EntrarViewController: UIViewController {
    
    @IBOutlet weak var campoEmail: UITextField!
    @IBOutlet weak var campoSenha: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func botaoEntrar(_ sender: Any) {
        let retorno = validarCampos()
        if retorno == "" {
            if let email = campoEmail.text {
                if let senha = campoSenha.text {
                    //Login do usuario
                    let autenticao = Auth.auth()
                    autenticao.signIn(withEmail: email, password: senha) { (usuario, erro) in
                        if erro == nil {
                            if usuario != nil{
                                //Valida se o usuario esta logado. sera redirecionado pelo listener da ViewController inicial
                            }
                        }else{
                            print("erro ao logar")
                        }
                            
                    }
                }
            }
        }else{
            print("O campo \(retorno) não foi preenchido")
        }
    }
    
    func validarCampos() -> String {
        if (self.campoEmail.text?.isEmpty)!{
            return "Email"
        } else if (self.campoSenha.text?.isEmpty)!{
            return "Senha"
        } else {
            return ""
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
