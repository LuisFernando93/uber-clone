//
//  PassageiroViewController.swift
//  Uber
//
//  Created by Luis Fernando Pasquinelli Amaral de Abreu on 04/04/2018.
//  Copyright © 2018 Luis. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import MapKit

class PassageiroViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapa: MKMapView!
    @IBOutlet weak var botaoUber: UIButton!
    var gerenciadorLocal = CLLocationManager()
    var localUsuario = CLLocationCoordinate2D()
    var localMotorista = CLLocationCoordinate2D()
    var uberChamado = false
    var uberACaminho = false
    @IBOutlet weak var areaEndereco: UIView!
    @IBOutlet weak var marcadorLocalPassageiro: UIView!
    @IBOutlet weak var marcadorLocalDestino: UIView!
    @IBOutlet weak var campoEnderecoDestino: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        gerenciadorLocal.delegate = self
        gerenciadorLocal.desiredAccuracy = kCLLocationAccuracyBest
        gerenciadorLocal.requestWhenInUseAuthorization()
        gerenciadorLocal.startUpdatingLocation()
        
        //configurar arredondamento dos marcadores
        self.marcadorLocalPassageiro.layer.cornerRadius = 7.5
        self.marcadorLocalPassageiro.clipsToBounds = true
        
        self.marcadorLocalDestino.layer.cornerRadius = 7.5
        self.marcadorLocalDestino.clipsToBounds = true
        
        self.areaEndereco.layer.cornerRadius = 10
        self.areaEndereco.clipsToBounds = true
        
        //Verificar se Uber ja foi requisitado
        let database = Database.database().reference()
        let autenticacao = Auth.auth()
        
        if let emailUsuario = autenticacao.currentUser?.email {
            
            let requisicoes = database.child("requisicoes")
            let consultaRequisicoes = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: emailUsuario)
            
            consultaRequisicoes.observe(.childAdded) { (snapshot) in
                if snapshot.value != nil {
                    self.alternaBotaoCancelar()
                }
            }
            consultaRequisicoes.observe(.childChanged) { (snapshot) in
                
                if let dados = snapshot.value as? [String: Any] {
                    if let status = dados["status"] as? String {
                        if status == StatusCorrida.PegarPassageiro.rawValue{
                            if let latitudeMotorista = dados["motoristaLatitude"] {
                                if let longitudeMotorista = dados["motoristaLongitude"] {
                                    self.localMotorista = CLLocationCoordinate2D(latitude: latitudeMotorista as! CLLocationDegrees, longitude: longitudeMotorista as! CLLocationDegrees)
                                    self.exibirMotoristaPassageiro()
                                }
                            }
                        } else if status == StatusCorrida.EmViagem.rawValue {
                            self.alternarBotaoEmViagem()
                        } else if status == StatusCorrida.ViagemFinalizada.rawValue{
                            if let preco = dados["precoViagem"] as? Double {
                                self.alternarViagemFinalizada(preco: preco)
                            }
                        }
                    }
                    
                    
                    
                    
                }
            }
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
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let coordenadas = manager.location?.coordinate {
            
            //configura local atual do usuario
            self.localUsuario = coordenadas
            
            if self.uberACaminho{
                exibirMotoristaPassageiro()
            } else {
                let regiao = MKCoordinateRegionMakeWithDistance(coordenadas, 200, 200)
                mapa.setRegion(regiao, animated: true)
                
                //remove todas anotacoes
                mapa.removeAnnotations(mapa.annotations)
                
                //criar uma anotacao pra localizacao do usuario
                let anotacaoUsuario = MKPointAnnotation()
                anotacaoUsuario.coordinate = coordenadas
                anotacaoUsuario.title = "Seu local"
                mapa.addAnnotation(anotacaoUsuario)
            }
        }
    }
    
    @IBAction func chamarUber(_ sender: Any) {
        
        let database = Database.database().reference()
        let autenticacao = Auth.auth()
        let requisicao = database.child("requisicoes")
        if let usuarioEmail = autenticacao.currentUser?.email {
            if self.uberChamado {//Uber Chamado
                self.alternaBotaoChamar()
                
                //remover requisicao
                requisicao.queryOrdered(byChild: "email").queryEqual(toValue: usuarioEmail).observeSingleEvent(of: DataEventType.childAdded) { (snapshot) in
                    snapshot.ref.removeValue()
                }
                
            }else{// Uber nao foi chamado
                self.salvarRequisicao()
            } //fim else
        }
    }
    
    func salvarRequisicao() {
        
        let database = Database.database().reference()
        let autenticacao = Auth.auth()
        
        //recuperar nome do usuario
        if let idUsuario = autenticacao.currentUser?.uid {
            if let emailUsuario = autenticacao.currentUser?.email {
                if let enderecoDestino = self.campoEnderecoDestino.text {
                    if enderecoDestino != "" {
                        CLGeocoder().geocodeAddressString(enderecoDestino) { (local, erro) in
                            if erro == nil{
                                if let dadosLocal = local?.first {
                                    print(dadosLocal)
                                    var rua = ""
                                    if dadosLocal.thoroughfare != nil {
                                        rua = dadosLocal.thoroughfare!
                                    }
                                    var numero = ""
                                    if dadosLocal.subThoroughfare != nil {
                                        numero = dadosLocal.subThoroughfare!
                                    }
                                    var bairro = ""
                                    if dadosLocal.subLocality != nil {
                                        bairro = dadosLocal.subLocality!
                                    }
                                    var cidade = ""
                                    if dadosLocal.locality != nil {
                                        cidade = dadosLocal.locality!
                                    }
                                    var cep = ""
                                    if dadosLocal.postalCode != nil {
                                        cep = dadosLocal.postalCode!
                                    }
                                    let enderecoCompleto = "\(rua) , \(numero) , \(bairro) - \(cidade) - \(cep)"
                                    
                                    if let latitudeDestido = dadosLocal.location?.coordinate.latitude {
                                        if let longitudeDestido = dadosLocal.location?.coordinate.longitude {
                                            
                                            let alerta = UIAlertController(title: "Confirme o endereço", message: enderecoCompleto, preferredStyle: .alert)
                                            let acaoCancelar = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
                                            let acaoConfirmar = UIAlertAction(title: "Confirmar", style: .default, handler: { (alertAction) in
                                                
                                                let requisicao = database.child("requisicoes")
                                                let usuarios = database.child("usuarios").child(idUsuario)
                                                usuarios.observeSingleEvent(of: .value) { (snapshot) in
                                                    
                                                    let dados = snapshot.value as? NSDictionary
                                                    let nomeUsuario = dados!["nome"] as? String
                                                    
                                                    //adicionar requisicao
                                                    let dadosUsuario = [
                                                        "latitudeDestino": latitudeDestido,
                                                        "longitudeDestino": longitudeDestido,
                                                        "email": emailUsuario,
                                                        "nome": nomeUsuario,
                                                        "latitude": self.localUsuario.latitude,
                                                        "longitude": self.localUsuario.longitude
                                                        ] as [String: Any]
                                                    requisicao.childByAutoId().setValue(dadosUsuario)
                                                    self.alternaBotaoCancelar()
                                                    
                                                }
                                                
                                            })
                                            
                                            alerta.addAction(acaoCancelar)
                                            alerta.addAction(acaoConfirmar)
                                            self.present(alerta, animated: true, completion: nil)
                                        }
                                    }
                                }
                            }
                        }
                        
                    }else{
                        print("insiro um endereço")
                    }
                }
                
                
                
            }
        }
    }
    
    func exibirMotoristaPassageiro() {
        
        self.uberACaminho = true
        
        //Calcular a distancia entre os dois
        let motoristaLocation = CLLocation(latitude: self.localMotorista.latitude, longitude: self.localMotorista.longitude)
        let passageiroLocation = CLLocation(latitude: self.localUsuario.latitude, longitude: self.localUsuario.longitude)
        var mensagem = ""
        let distancia = motoristaLocation.distance(from: passageiroLocation)
        let distanciaKm = round(distancia/1000)
        mensagem = "Morista \(distanciaKm) Km distante"
        
        if distanciaKm < 1 {
            let distanciaM = distanciaKm * 1000
            mensagem = "Morista \(distanciaM) m distante"
        }
        
        self.botaoUber.backgroundColor = UIColor(displayP3Red: 0.067, green: 0.576, blue: 0.604, alpha: 1)
        self.botaoUber.setTitle(mensagem, for: .normal)
        
        //exibir motorista e passageiro no mapa
        mapa.removeAnnotations(mapa.annotations)
        
        let latitudeDiferenca = abs(self.localUsuario.latitude - self.localMotorista.latitude) * 300000
        let longitudeDiferenca = abs(self.localUsuario.longitude - self.localMotorista.longitude) * 300000
        
        let regiao = MKCoordinateRegionMakeWithDistance(self.localUsuario, latitudeDiferenca, longitudeDiferenca)
        mapa.setRegion(regiao, animated: true)
        
        let anotacaoMotorista = MKPointAnnotation()
        anotacaoMotorista.coordinate = self.localMotorista
        anotacaoMotorista.title = "Motorista"
        
        mapa.addAnnotation(anotacaoMotorista)
        
        let anotacaoPassageiro = MKPointAnnotation()
        anotacaoPassageiro.coordinate = self.localUsuario
        anotacaoPassageiro.title = "Motorista"
        
        mapa.addAnnotation(anotacaoMotorista)
        
    }
    
    func alternaBotaoCancelar() {
        self.botaoUber.setTitle("Cancelar Uber", for: .normal)
        self.botaoUber.backgroundColor = UIColor(displayP3Red: 0.831, green: 0.237, blue: 0.146, alpha: 1)
        self.uberChamado = true
    }
    
    func alternarBotaoEmViagem() {
        self.botaoUber.setTitle("Em viagem", for: .normal)
        self.botaoUber.backgroundColor = UIColor(displayP3Red: 0.502, green: 0.502, blue: 0.502, alpha: 1)
        self.botaoUber.isEnabled = false
    }
    
    func alternaBotaoChamar() {
        self.botaoUber.setTitle("Chamar Uber", for: .normal)
        self.botaoUber.backgroundColor = UIColor(displayP3Red: 0.067, green: 0.576, blue: 0.604, alpha: 1)
        self.uberChamado = false
    }
    
    func alternarViagemFinalizada(preco: Double ) {
        self.botaoUber.backgroundColor = UIColor(displayP3Red: 0.502, green: 0.502, blue: 0.502, alpha: 1)
        self.botaoUber.isEnabled = false
        
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        nf.locale = Locale(identifier: "pt_BR")
        let precoFinal = nf.string(from: NSNumber(value: preco))
        self.botaoUber.setTitle("Viagem finalizada - R$ " + precoFinal!, for: .normal)
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
