import Foundation

struct Materia: Codable, Identifiable, Hashable {
    let id: String
    let nombre: String
    let icono: String
    let temas: [Tema]
}

struct Tema: Codable, Identifiable, Hashable {
    let id: String
    let titulo: String
    let resumen: String
    let preguntas: [Pregunta]
}

struct Pregunta: Codable, Identifiable, Hashable {
    let id: String
    let texto: String
    let opciones: [String]
    let correcta: Int
    let explicacion: String
}

enum Contenido {
    static func cargar() -> [Materia] {
        guard let url = Bundle.main.url(forResource: "contenido", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let materias = try? JSONDecoder().decode([Materia].self, from: data)
        else { return [] }
        return materias
    }
}
