//
//  MotoristaTableViewController.swift
//  Uber
//
//  Created by Luis Fernando Pasquinelli Amaral de Abreu on 04/04/2018.
//  Copyright © 2018 Luis. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import MapKit


class MotoristaTableViewController: UITableViewController, CLLocationManagerDelegate {

    var listaRequisicoes : [DataSnapshot] = []
    var gerenciadorLocal = CLLocationManager()
    var localUsuario = CLLocationCoordinate2D()
    var timerControle = Timer()
    
    override func viewDidAppear(_ animated: Bool) {
        self.recuperarRequisicoes()
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { (timer) in
            self.recuperarRequisicoes()
            self.timerControle = timer
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.timerControle.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gerenciadorLocal.delegate = self
        gerenciadorLocal.desiredAccuracy = kCLLocationAccuracyBest
        gerenciadorLocal.requestWhenInUseAuthorization()
        gerenciadorLocal.startUpdatingLocation()
        let database = Database.database().reference()
        let requisicoes = database.child("requisicoes")
        
        requisicoes.observe(.childAdded) { (snapshot) in
            self.listaRequisicoes.append(snapshot)
            self.tableView.reloadData()
        }
        
        //limpar requisicao caso cancelada
        requisicoes.observe(.childRemoved) { (snapshot) in
            
            var indice = 0
            for requisicao in self.listaRequisicoes{
                if requisicao.key == snapshot.key {
                    self.listaRequisicoes.remove(at: indice)
                }
                indice += 1
            }
            self.tableView.reloadData()
        }
        
    }
    
    func recuperarRequisicoes() {
        let database = Database.database().reference()
        let requisicoes = database.child("requisicoes")
        
        // Limpar Requisicoes
        self.listaRequisicoes = []
        
        requisicoes.observeSingleEvent(of: .childAdded) { (snapshot) in
            self.listaRequisicoes.append(snapshot)
            self.tableView.reloadData()
        }
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let coordenadas = manager.location?.coordinate {
            self.localUsuario = coordenadas
        }
    }
    
    @IBAction func deslogarUsuario(_ sender: Any) {
        let autenticacao = Auth.auth()
        do {
            try autenticacao.signOut()
            dismiss(animated: true, completion: nil)
        } catch  {
            print("Nao foi possivel deslogar")
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.listaRequisicoes.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let snapshot = self.listaRequisicoes [indexPath.row]
        self.performSegue(withIdentifier: "segueAceitarCorrida", sender: snapshot)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueAceitarCorrida" {
            if let confirmarViewController = segue.destination as? ConfirmarRequisicaoViewController {
                if let snapshot = sender as? DataSnapshot {
                    if let dados = snapshot.value as? [String:Any] {
                        if let latPassageiro = dados["latitude"] as? Double {
                            if let lonPassageiro = dados["longitude"] as? Double {
                                if let nomePassageiro = dados["nome"] as? String {
                                    if let emailPassageiro = dados["email"] as? String {
                                        // Recupera os dados do Passageiro
                                        let localPassageiro = CLLocationCoordinate2D(latitude: latPassageiro, longitude: lonPassageiro)
                                        // Envia os dados para a próxima ViewController
                                        confirmarViewController.nomePassageiro = nomePassageiro
                                        confirmarViewController.emailPassageiro = emailPassageiro
                                        confirmarViewController.localPassageiro = localPassageiro
                                        // Envia os dados do motorista
                                        confirmarViewController.localMotorista = self.localUsuario
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celula = tableView.dequeueReusableCell(withIdentifier: "celula", for: indexPath)

        let snapshot = self.listaRequisicoes [indexPath.row]
        print(snapshot)
        if let dados = snapshot.value as? [String: Any] {
            if let latitudePassageiro = dados["latitude"] as? Double {
                if let longitudePassageiro = dados["longitude"] as? Double {
                    
                    
                    let motoristaLocation = CLLocation(latitude: self.localUsuario.latitude, longitude: self.localUsuario.longitude)
                    let passageiroLocation = CLLocation(latitude: latitudePassageiro, longitude: longitudePassageiro)
                    
                    let distanciaMetros = motoristaLocation.distance(from: passageiroLocation)
                    let distanciaKm = distanciaMetros / 1000
                    let distanciaFinal = round(distanciaKm)
                    
                    var requisicaoMotorista =  ""
                    if let emailMotorista = dados["motoristaEmail"] as? String {
                        let autenticacao = Auth.auth()
                        if let emailMotoristaLogado = autenticacao.currentUser?.email {
                            if emailMotorista == emailMotoristaLogado {
                                requisicaoMotorista =  " {ANDAMENTO} "
                                if let status = dados["status"] as? String {
                                    if status == StatusCorrida.ViagemFinalizada.rawValue {
                                        requisicaoMotorista =  " {FINALIZADA} "
                                    }
                                }
                            }
                        }
                    }
                    if let nomePassageiro = dados["nome"] as? String {
                        celula.textLabel?.text = "\(nomePassageiro) \(requisicaoMotorista)"
                        celula.detailTextLabel?.text = "\(distanciaFinal) Km de distãncia"
                    }
                }
            }
        }

        return celula
    }
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
