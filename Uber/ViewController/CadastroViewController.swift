//
//  CadastroViewController.swift
//  Uber
//  Created by Luis Fernando Pasquinelli Amaral de Abreu on 03/04/2018.
//  Copyright © 2018 Luis. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class CadastroViewController: UIViewController {

    @IBOutlet weak var campoEmail: UITextField!
    @IBOutlet weak var campoNome: UITextField!
    @IBOutlet weak var campoSenha: UITextField!
    @IBOutlet weak var campoConfirmaSenha: UITextField!
    @IBOutlet weak var tipoUsuario: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func botaoCadastro(_ sender: Any) {
        
        let retorno = validarCampos()
        if retorno == ""{
            
            if let email = self.campoEmail.text {
                if let nome = self.campoNome.text {
                    if let senha = self.campoSenha.text{
                        if let senha2 = self.campoConfirmaSenha.text{
                            if senha == senha2 {
                                //Cadastro do usuario
                                let autenticao = Auth.auth()
                                autenticao.createUser(withEmail: email, password: senha) { (usuario, erro) in
                                    if erro == nil {
                                        
                                        //validar se usuario esta logado
                                        if usuario != nil{
                                            
                                            //verificar tipo de usuario
                                            var tipo = ""
                                            if self.tipoUsuario.isOn{
                                                tipo = "passageiro"
                                            } else{ tipo = "motorista"}
                                            
                                            //salva no database os dados do usuario
                                            let database = Database.database().reference()
                                            let dadosUsuario = [
                                                "email": usuario?.email,
                                                "nome": nome,
                                                "tipo": tipo
                                            ]
                                            let usuarios = database.child("usuarios")
                                            usuarios.child((usuario?.uid)!).setValue(dadosUsuario)
                                            
                                            //Valida se o usuario esta logado. sera redirecionado pelo listener da ViewController inicial
                                        } else{
                                            print("erro ao autenticar usuario")
                                        }
                                        
                                    } else{
                                        print("erro ao criar conta")
                                    }
                                }
                            }else{
                                print("As senhas não estão iguais")
                            }
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
        }else if (self.campoNome.text?.isEmpty)!{
            return "Nome Completo"
        } else if (self.campoSenha.text?.isEmpty)!{
            return "Senha"
        } else if (self.campoConfirmaSenha.text?.isEmpty)!{
            return "Confirmar Senha"
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
