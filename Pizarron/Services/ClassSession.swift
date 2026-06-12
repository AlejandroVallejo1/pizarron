import Foundation
import MultipeerConnectivity

struct Puntaje: Codable, Identifiable, Equatable {
    var id: String { nombre }
    let nombre: String
    let puntos: Int
}

enum MsgRed: Codable {
    case pregunta(Pregunta, indice: Int, total: Int)
    case resultado(correcta: Int, marcador: [Puntaje])
    case fin(marcador: [Puntaje])
    case respuesta(nombre: String, opcion: Int)
}

/// Sesión de clase tipo Kahoot 100% local (WiFi/Bluetooth entre dispositivos, sin internet).
final class ClassSession: NSObject, ObservableObject {
    enum Rol { case ninguno, maestro, alumno }
    enum Fase { case inactiva, buscando, lobby, pregunta, resultado, fin }

    @Published var rol: Rol = .ninguno
    @Published var fase: Fase = .inactiva
    @Published var jugadores: [String] = []
    @Published var preguntaActual: Pregunta?
    @Published var indice = 0
    @Published var total = 0
    @Published var marcador: [Puntaje] = []
    @Published var respuestasRecibidas: [String: Int] = [:]
    @Published var miRespuesta: Int?
    @Published var ultimaCorrecta: Int?

    static let servicio = "pizarron-cls"

    private var peerID: MCPeerID!
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var preguntas: [Pregunta] = []
    private var puntos: [String: Int] = [:]
    private var bots: [String] = []

    // Modo video: automatiza la sesión para grabar la demo sin tocar la pantalla.
    var autoMaestro = false
    var autoAlumno = false
    private var autoEmpezo = false

    // MARK: Maestro

    func iniciarComoMaestro(preguntas: [Pregunta], nombre: String) {
        reiniciar(nombre: nombre.isEmpty ? "Maestro" : nombre)
        rol = .maestro
        self.preguntas = preguntas
        total = preguntas.count
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: Self.servicio)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        fase = .lobby
    }

    /// Alumnos simulados para probar la dinámica con un solo dispositivo.
    func agregarEquipoDePractica() {
        guard bots.isEmpty else { return }
        bots = ["Lupita ✏️", "Mateo 📐", "Sofía 🔬"]
        actualizarJugadores()
    }

    func empezarJuego() {
        indice = -1
        puntos = jugadores.reduce(into: [:]) { $0[$1] = 0 }
        siguientePregunta()
    }

    func siguientePregunta() {
        indice += 1
        guard indice < preguntas.count else { return terminarJuego() }
        respuestasRecibidas = [:]
        ultimaCorrecta = nil
        let q = preguntas[indice]
        preguntaActual = q
        enviar(.pregunta(q, indice: indice, total: total))
        fase = .pregunta
        lanzarBots(paraIndice: indice, pregunta: q)
    }

    func cerrarPregunta() {
        guard let q = preguntaActual else { return }
        for (nombre, opcion) in respuestasRecibidas where opcion == q.correcta {
            puntos[nombre, default: 0] += 100
        }
        marcador = marcadorOrdenado()
        ultimaCorrecta = q.correcta
        enviar(.resultado(correcta: q.correcta, marcador: marcador))
        fase = .resultado
    }

    private func terminarJuego() {
        marcador = marcadorOrdenado()
        enviar(.fin(marcador: marcador))
        fase = .fin
    }

    // MARK: Alumno

    func unirseComoAlumno(nombre: String) {
        reiniciar(nombre: nombre.isEmpty ? "Estudiante" : nombre)
        rol = .alumno
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.servicio)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        fase = .buscando
    }

    func responder(_ opcion: Int) {
        guard fase == .pregunta, miRespuesta == nil else { return }
        miRespuesta = opcion
        enviar(.respuesta(nombre: peerID.displayName, opcion: opcion))
    }

    /// Estado de podio precargado para capturas de pantalla.
    func cargarDemoPodio() {
        rol = .maestro
        marcador = [Puntaje(nombre: "Lupita ✏️", puntos: 500),
                    Puntaje(nombre: "Mateo 📐", puntos: 400),
                    Puntaje(nombre: "Sofía 🔬", puntos: 300),
                    Puntaje(nombre: "Diego", puntos: 200)]
        fase = .fin
    }

    // MARK: Común

    func salir() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        advertiser = nil; browser = nil; session = nil
        rol = .ninguno; fase = .inactiva
        jugadores = []; marcador = []; respuestasRecibidas = [:]
        preguntaActual = nil; miRespuesta = nil; ultimaCorrecta = nil
        puntos = [:]; bots = []; indice = 0; total = 0
    }

    private func reiniciar(nombre: String) {
        salir()
        peerID = MCPeerID(displayName: nombre)
        let s = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        s.delegate = self
        session = s
    }

    private func enviar(_ msg: MsgRed) {
        guard let session, !session.connectedPeers.isEmpty,
              let data = try? JSONEncoder().encode(msg) else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }

    private func marcadorOrdenado() -> [Puntaje] {
        puntos.map { Puntaje(nombre: $0.key, puntos: $0.value) }
            .sorted { $0.puntos > $1.puntos }
    }

    private func actualizarJugadores() {
        jugadores = (session?.connectedPeers.map(\.displayName) ?? []) + bots
        if autoMaestro, !autoEmpezo, fase == .lobby, jugadores.count >= 2 {
            autoEmpezo = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self, self.fase == .lobby else { return }
                self.empezarJuego()
            }
        }
    }

    private func autoCierraSiCompleto() {
        guard autoMaestro, fase == .pregunta, !jugadores.isEmpty,
              respuestasRecibidas.count >= jugadores.count else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self, self.fase == .pregunta else { return }
            self.cerrarPregunta()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                guard let self, self.fase == .resultado else { return }
                self.siguientePregunta()
            }
        }
    }

    private func lanzarBots(paraIndice i: Int, pregunta q: Pregunta) {
        for bot in bots {
            DispatchQueue.main.asyncAfter(deadline: .now() + .random(in: 1.5...5)) { [weak self] in
                guard let self, self.fase == .pregunta, self.indice == i else { return }
                let acierta = Double.random(in: 0...1) < 0.6
                self.respuestasRecibidas[bot] = acierta ? q.correcta : Int.random(in: 0..<q.opciones.count)
            }
        }
    }

    private func recibir(_ msg: MsgRed) {
        switch msg {
        case .pregunta(let q, let i, let t):
            preguntaActual = q; indice = i; total = t
            miRespuesta = nil; ultimaCorrecta = nil
            fase = .pregunta
            if autoAlumno {
                DispatchQueue.main.asyncAfter(deadline: .now() + .random(in: 2...4.5)) { [weak self] in
                    guard let self, self.fase == .pregunta, self.miRespuesta == nil,
                          let q = self.preguntaActual else { return }
                    let acierta = Double.random(in: 0...1) < 0.7
                    self.responder(acierta ? q.correcta : Int.random(in: 0..<q.opciones.count))
                }
            }
        case .resultado(let correcta, let tabla):
            ultimaCorrecta = correcta; marcador = tabla
            fase = .resultado
        case .fin(let tabla):
            marcador = tabla
            fase = .fin
        case .respuesta(let nombre, let opcion):
            if rol == .maestro {
                respuestasRecibidas[nombre] = opcion
                autoCierraSiCompleto()
            }
        }
    }
}

extension ClassSession: MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.actualizarJugadores()
            if self.rol == .alumno {
                if state == .connected { self.fase = .lobby }
                if state == .notConnected, self.fase != .inactiva, self.fase != .fin { self.fase = .buscando }
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let msg = try? JSONDecoder().decode(MsgRed.self, from: data) else { return }
        DispatchQueue.main.async { self.recibir(msg) }
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        guard let session else { return }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
