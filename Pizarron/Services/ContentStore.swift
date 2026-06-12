import Foundation
import SwiftUI

final class ContentStore: ObservableObject {
    @Published var materias: [Materia] = Contenido.cargar()
    @Published var nombreUsuario: String {
        didSet { UserDefaults.standard.set(nombreUsuario, forKey: "nombreUsuario") }
    }
    // Mejor puntaje por tema (id del tema → aciertos)
    @Published var mejores: [String: Int] {
        didSet { UserDefaults.standard.set(mejores, forKey: "mejores") }
    }

    init() {
        nombreUsuario = UserDefaults.standard.string(forKey: "nombreUsuario") ?? ""
        mejores = (UserDefaults.standard.dictionary(forKey: "mejores") as? [String: Int]) ?? [:]
    }

    func registrar(tema: Tema, aciertos: Int) {
        if aciertos > (mejores[tema.id] ?? 0) { mejores[tema.id] = aciertos }
    }

    var totalTemas: Int { materias.flatMap(\.temas).count }
    var temasDominados: Int {
        materias.flatMap(\.temas).filter { (mejores[$0.id] ?? 0) >= $0.preguntas.count }.count
    }
}
