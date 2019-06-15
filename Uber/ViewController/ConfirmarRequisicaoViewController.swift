//
//  ConfirmarRequisicaoViewController.swift
//  Uber
//
//  Created by Luis Fernando Pasquinelli Amaral de Abreu on 06/04/2018.
//  Copyright © 2018 Luis. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase
import FirebaseAuth

class ConfirmarRequisicaoViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var botaoAceitarCorrida: UIButton!
    @IBOutlet weak var mapa: MKMapView!
    var nomePassageiro = ""
    var emailPassageiro = ""
    var localPassageiro = CLLocationCoordinate2D()
    var localMotorista = CLLocationCoordinate2D()
    var localDestino = CLLocationCoordinate2D()
    var status: StatusCorrida = .EmRequisicao
    var gerenciadorLocal = CLLocationManager()
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let coordenadas = manager.location?.coordinate {
            self.localMotorista = coordenadas
            atualizarLocalMotorista()
        }
        
    }
    
    func atualizarLocalMotorista() {
        
        let database = Database.database().reference()
        if self.emailPassageiro != ""{
            let requisicoes = database.child("requisicoes")
            let consultaRequisicao = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: emailPassageiro)
            consultaRequisicao.observeSingleEvent(of: .childAdded) { (snapshot) in
                if let dados = snapshot.value as? [String: Any] {
                    if let statusAtual = dados["status"] as?  String{
                        if statusAtual == StatusCorrida.PegarPassageiro.rawValue{
                            
                            let motoristaLocation = CLLocation(latitude: self.localMotorista.latitude, longitude: self.localMotorista.longitude)
                            let passageiroLocation = CLLocation(latitude: self.localPassageiro.latitude, longitude: self.localPassageiro.longitude)
                            let distancia = motoristaLocation.distance(from: passageiroLocation)
                            let distanciaKm = round(distancia/1000)
                            if distanciaKm <= 0.3 {
                                self.atualizarStatusRequisicao(status: StatusCorrida.IniciarViagem.rawValue)
                            }
                            
                        }else if (statusAtual == StatusCorrida.IniciarViagem.rawValue) {
                            //self.alternarBotaoIniciarViagem()
                            
                            self.exibiMotoristaPassageiro(localPartida: self.localMotorista, localDestino: self.localPassageiro, tituloPartida: "Motorista", tituloDestino: "Passageiro")
                            
                        }
                        
                        let dadosMotorista = [
                            "motoristaLatitude" : self.localMotorista.latitude,
                            "motoristaLongitude" : self.localMotorista.longitude
                            ] as [String : Any]
                        snapshot.ref.updateChildValues(dadosMotorista)
                        
                        
                    }
                }
            }
        }
    }
    
    func atualizarStatusRequisicao (status: String) {
        if status != "" && self.emailPassageiro != "" {
            let database = Database.database().reference()
            let requisicoes = database.child("requisicoes")
            let consultaRequisicao = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro)
            consultaRequisicao.observeSingleEvent(of: .childAdded) { (snapshot) in
                if let dados = snapshot.value as? [String: Any] {
                    let dadosAtualizar = [
                        "status": status
                    ]
                    
                    snapshot.ref.updateChildValues(dadosAtualizar)
                }
            }
        }
    }
    
    func exibiMotoristaPassageiro(localPartida: CLLocationCoordinate2D, localDestino: CLLocationCoordinate2D, tituloPartida: String, tituloDestino: String) {
        
        mapa.removeAnnotations(mapa.annotations)
        
        let latitudeDiferenca = abs(localDestino.latitude - localPartida.latitude) * 300000
        let longitudeDiferenca = abs(localDestino.longitude - localPartida.longitude) * 300000
        
        let regiao = MKCoordinateRegionMakeWithDistance(localPartida, latitudeDiferenca, longitudeDiferenca)
        mapa.setRegion(regiao, animated: true)
        
        let anotacaoPartida = MKPointAnnotation()
        anotacaoPartida.coordinate = localPartida
        anotacaoPartida.title = tituloPartida
        
        mapa.addAnnotation(anotacaoPartida)
        
        let anotacaoDestino = MKPointAnnotation()
        anotacaoDestino.coordinate = localDestino
        anotacaoDestino.title = tituloDestino
        
        mapa.addAnnotation(anotacaoDestino)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gerenciadorLocal.delegate = self
        gerenciadorLocal.desiredAccuracy = kCLLocationAccuracyBest
        gerenciadorLocal.requestWhenInUseAuthorization()
        gerenciadorLocal.startUpdatingLocation()
        gerenciadorLocal.allowsBackgroundLocationUpdates = true
        

        //Configurar area inicial do mapa
        let regiao = MKCoordinateRegionMakeWithDistance(self.localPassageiro, 200, 200)
        mapa.setRegion(regiao, animated: true)
        
        //adicionar anotacao do passageiro
        let anotacaoPassageiro = MKPointAnnotation()
        anotacaoPassageiro.coordinate = self.localPassageiro
        anotacaoPassageiro.title = nomePassageiro
        mapa.addAnnotation(anotacaoPassageiro)
        
        let database = Database.database().reference()
        let requisicoes = database.child("requisicoes")
        let consultaRequisicoes = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro)
        consultaRequisicoes.observeSingleEvent(of: .childChanged) { (snapshot) in
            if let dados = snapshot.value as?  [String: Any] {
                if let statusRecuperado = dados["status"] as? String {
                    self.recarregarTelaStatus(status: statusRecuperado, dados: dados)
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let database = Database.database().reference()
        let requisicoes = database.child("requisicoes")
        let consultaRequisicoes = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro)
        
        consultaRequisicoes.observeSingleEvent(of: .childAdded) { (snapshot) in
            if let dados = snapshot.value as?  [String: Any] {
                if let statusRecuperado = dados["status"] as? String {
                    self.recarregarTelaStatus(status: statusRecuperado, dados: dados)
                }
            }
        }
    }

    func recarregarTelaStatus(status: String, dados: [String: Any]) {
        if status == StatusCorrida.PegarPassageiro.rawValue {
            self.pegarPassageiro()
            
            self.exibiMotoristaPassageiro(localPartida: self.localMotorista, localDestino: self.localPassageiro, tituloPartida: "Meu local", tituloDestino: "Passageiro")
        }else if status == StatusCorrida.IniciarViagem.rawValue {
            self.status = .IniciarViagem
            self.alternarBotaoIniciarViagem()
            if let latitudeDestino = dados["destinoLatitude"] as? Double {
                if let longitudeDestino = dados["destinoLongitude"] as? Double {
                    self.localDestino = CLLocationCoordinate2D(latitude: latitudeDestino, longitude: longitudeDestino)
                    
                }
            }
        } else if status == StatusCorrida.EmViagem.rawValue {
            self.status = .EmViagem
            self.alternarBotaoPendenteFinalizarViagem()
            
            if let latitudeDestino = dados["destinoLatitude"] as? Double {
                if let longitudeDestino = dados["destinoLongitude"] as? Double {
                    self.localDestino = CLLocationCoordinate2D(latitude: latitudeDestino, longitude: longitudeDestino)
                    self.exibiMotoristaPassageiro(localPartida: self.localPassageiro, localDestino: self.localDestino, tituloPartida: "Motorista", tituloDestino: "Destino")
                }
            }
        } else if status == StatusCorrida.ViagemFinalizada.rawValue {
            self.status = .ViagemFinalizada
            if let precoViagem = dados["precoViagem"] as? Double {
                self.alternarViagemFinalizada(preco: precoViagem)
            }
            
        }
    }
    
    @IBAction func aceitarCorrida(_ sender: Any) {
        
        
        if status == StatusCorrida.EmRequisicao{
            //Atualizar requisicao
            let database = Database.database().reference()
            let autenticacao = Auth.auth()
            let requisicoes = database.child("requisicoes")
            
            if let emailMotorista = autenticacao.currentUser?.email {
                requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro).observeSingleEvent(of: .childAdded) { (snapshot) in
                    
                    let dadosMotorista = [
                        "motoristaEmail"  : emailMotorista,
                        "motoristaLatitude" : self.localMotorista.latitude,
                        "motoristaLongitude" : self.localMotorista.longitude,
                        "status": StatusCorrida.PegarPassageiro.rawValue
                        ] as [String : Any]
                    snapshot.ref.updateChildValues(dadosMotorista)
                    self.pegarPassageiro()
                }
            }
            
            //Exibir caminho para o passageiro no mapa
            let passageiroCLL = CLLocation(latitude: localPassageiro.latitude, longitude: localPassageiro.longitude)
            CLGeocoder().reverseGeocodeLocation(passageiroCLL) { (local, erro) in
                
                if erro == nil{
                    if let dadosLocal = local?.first {
                        let placeMark = MKPlacemark(placemark: dadosLocal)
                        
                        let mapaItem = MKMapItem(placemark: placeMark)
                        mapaItem.name = self.nomePassageiro
                        
                        let opcoes = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        mapaItem.openInMaps(launchOptions: opcoes)
                    }
                }
            }
        } else if status == StatusCorrida.IniciarViagem {
            self.iniciarViagemDestino()
        } else if status == StatusCorrida.EmViagem {
            self.finalizarViagem()
        }
    }
    
    func finalizarViagem() {
        
        self.status = .ViagemFinalizada
        let precoKm: Double = 4
        let database = Database.database().reference()
        let requisicoes = database.child("requisicoes")
        let consultaRequisicao = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: emailPassageiro)
        
        consultaRequisicao.observeSingleEvent(of: .childAdded) { (snapshot) in
            if let dados = snapshot.value as?  [String: Any] {
                if let latitudeInicial = dados["latitude"] as? Double {
                    if let longitudeInicial = dados["longitude"] as? Double {
                        if let latitudeFinal = dados["destinoLatitude"] as? Double {
                            if let longitudeFinal = dados["destinoLongitude"] as? Double {
                                let inicioLocation = CLLocation(latitude: latitudeInicial, longitude: longitudeInicial)
                                let destinoLocation = CLLocation(latitude: latitudeFinal, longitude: longitudeFinal)
                                let distancia = inicioLocation.distance(from: destinoLocation)
                                let distanciaKm = distancia/1000
                                let precoViagem = distanciaKm * precoKm
                                let dadosAtualizar = [
                                    "precoViagem": precoViagem,
                                    "distanciaPercorrida": distanciaKm
                                ]
                                
                                snapshot.ref.updateChildValues(dadosAtualizar)
                                self.atualizarStatusRequisicao(status: self.status.rawValue)
                                self.alternarViagemFinalizada(preco: precoViagem)
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    
    func iniciarViagemDestino() {
        
        self.status = .EmViagem
        self.atualizarStatusRequisicao(status: status.rawValue)
        let destinoCLL = CLLocation(latitude: localDestino.latitude, longitude: localDestino.longitude)
        CLGeocoder().reverseGeocodeLocation(destinoCLL) { (local, erro) in
            
            if erro == nil{
                if let dadosLocal = local?.first {
                    let placeMark = MKPlacemark(placemark: dadosLocal)
                    
                    let mapaItem = MKMapItem(placemark: placeMark)
                    mapaItem.name = "Destino passageiro"
                    
                    let opcoes = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                    mapaItem.openInMaps(launchOptions: opcoes)
                }
            }
        }
    }
    
    func pegarPassageiro() {
        
        //Alterar passageiro
        self.status = .PegarPassageiro
        
        //alternar botao
        self.alternarBotaoPegarPassageiro()
    }
    
    func alternarViagemFinalizada(preco: Double ) {
        self.botaoAceitarCorrida.backgroundColor = UIColor(displayP3Red: 0.502, green: 0.502, blue: 0.502, alpha: 1)
        self.botaoAceitarCorrida.isEnabled = false
        
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        nf.locale = Locale(identifier: "pt_BR")
        let precoFinal = nf.string(from: NSNumber(value: preco))
        self.botaoAceitarCorrida.setTitle("Viagem finalizada - R$ " + precoFinal!, for: .normal)
    }
    
    func alternarBotaoIniciarViagem() {
        self.botaoAceitarCorrida.setTitle("Iniciar viagem", for: .normal)
        self.botaoAceitarCorrida.backgroundColor = UIColor(displayP3Red: 0.067, green: 0.576, blue: 0.604, alpha: 1)
        self.botaoAceitarCorrida.isEnabled = true
    }
    
    func alternarBotaoPendenteFinalizarViagem() {
        self.botaoAceitarCorrida.setTitle("Finalizar viagem", for: .normal)
        self.botaoAceitarCorrida.backgroundColor = UIColor(displayP3Red: 0.067, green: 0.576, blue: 0.604, alpha: 1)
        self.botaoAceitarCorrida.isEnabled = true
    }
    
    func alternarBotaoPegarPassageiro() {
        self.botaoAceitarCorrida.setTitle("A caminho do passageiro", for: .normal)
        self.botaoAceitarCorrida.backgroundColor = UIColor(displayP3Red: 0.502, green: 0.502, blue: 0.502, alpha: 1)
        self.botaoAceitarCorrida.isEnabled = false
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
