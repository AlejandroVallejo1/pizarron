import Foundation
import FoundationModels

struct MensajeChat: Identifiable, Equatable {
    let id = UUID()
    let esUsuario: Bool
    let texto: String
}

@Generable
struct QuizGenerado {
    @Guide(description: "Exactamente 4 preguntas de opción múltiple sobre el tema")
    var preguntas: [PreguntaGenerada]
}

@Generable
struct PreguntaGenerada {
    @Guide(description: "La pregunta, breve y clara, para nivel primaria o secundaria")
    var texto: String
    @Guide(description: "Exactamente 4 opciones de respuesta cortas")
    var opciones: [String]
    @Guide(description: "Índice de la opción correcta, entre 0 y 3")
    var indiceCorrecta: Int
    @Guide(description: "Explicación breve y amable de por qué es la correcta")
    var explicacion: String
}

@MainActor
final class TutorService: ObservableObject {
    @Published var mensajes: [MensajeChat] = []
    @Published var ocupado = false
    @Published private(set) var iaDisponible = false
    @Published private(set) var motivoSinIA = ""

    private var session: LanguageModelSession?
    private var materias: [Materia] = []

    init() {
        materias = Contenido.cargar()
        switch SystemLanguageModel.default.availability {
        case .available:
            iaDisponible = true
            session = LanguageModelSession(instructions: """
            Eres un tutor amable para estudiantes de primaria y secundaria pública en México. \
            Responde siempre en español, con explicaciones breves, claras y con ejemplos de la vida \
            diaria de un niño mexicano. Si la pregunta no es escolar, redirige con amabilidad al estudio.
            """)
        case .unavailable(let razon):
            iaDisponible = false
            switch razon {
            case .deviceNotEligible:
                motivoSinIA = "Este dispositivo no es compatible con Apple Intelligence."
            case .appleIntelligenceNotEnabled:
                motivoSinIA = "Activa Apple Intelligence en Ajustes para usar el tutor con IA."
            case .modelNotReady:
                motivoSinIA = "El modelo se está descargando; intenta en unos minutos."
            @unknown default:
                motivoSinIA = "La IA no está disponible en este momento."
            }
        }

        // Solo para capturas y videos del pitch: el simulador no trae Apple
        // Intelligence, así que forzamos la apariencia de IA disponible.
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-demoIA") || args.contains("-videoQuizIA") || args.contains("-videoTutor") {
            iaDisponible = true
            motivoSinIA = ""
        }
        // En el video del tutor el simulador no puede generar de verdad:
        // responde siempre con el contenido del libro.
        if args.contains("-videoTutor") { session = nil }
    }

    func preguntar(_ texto: String) async {
        let limpio = texto.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !limpio.isEmpty, !ocupado else { return }
        mensajes.append(MensajeChat(esUsuario: true, texto: limpio))
        ocupado = true
        defer { ocupado = false }

        // Pausa de "pensando" para los videos del pitch.
        if ProcessInfo.processInfo.arguments.contains("-videoTutor") {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
        }

        if let session {
            do {
                let respuesta = try await session.respond(to: limpio)
                mensajes.append(MensajeChat(esUsuario: false, texto: respuesta.content))
            } catch let error as LanguageModelSession.GenerationError {
                switch error {
                case .assetsUnavailable:
                    // El modelo no está realmente descargado: cambia a modo libro permanente.
                    cambiarAModoLibro(motivo: "El modelo de IA no está descargado en este dispositivo; te respondo en modo libro.")
                    mensajes.append(MensajeChat(esUsuario: false, texto: respuestaDeLibro(para: limpio)))
                case .guardrailViolation:
                    mensajes.append(MensajeChat(esUsuario: false, texto: "Esa pregunta no la puedo responder. Pregúntame algo de tus temas de la escuela."))
                default:
                    mensajes.append(MensajeChat(esUsuario: false, texto: "No pude responder esa pregunta. Intenta con otras palabras."))
                }
            } catch {
                mensajes.append(MensajeChat(esUsuario: false, texto: "No pude responder esa pregunta. Intenta con otras palabras."))
            }
        } else {
            mensajes.append(MensajeChat(esUsuario: false, texto: respuestaDeLibro(para: limpio)))
        }
    }

    /// Genera un quiz nuevo con el modelo on-device; nil si no hay IA o falla.
    func generarQuiz(tema: Tema) async -> [Pregunta]? {
        // Video del pitch: el simulador no tiene el modelo, así que se muestran
        // dos rondas precargadas con preguntas distintas (en dispositivo real
        // este camino no se usa y la generación es genuina).
        if ProcessInfo.processInfo.arguments.contains("-videoQuizIA") {
            ocupado = true
            defer { ocupado = false }
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            demoQuizRonda += 1
            return Self.quizDemo(ronda: demoQuizRonda)
        }
        guard let session else { return nil }
        ocupado = true
        defer { ocupado = false }
        do {
            let prompt = """
            Crea un quiz sobre "\(tema.titulo)". Apóyate en este resumen del libro: \(tema.resumen)
            """
            let respuesta = try await session.respond(to: prompt, generating: QuizGenerado.self)
            return respuesta.content.preguntas.enumerated().compactMap { i, p in
                guard p.opciones.count >= 2, (0..<p.opciones.count).contains(p.indiceCorrecta) else { return nil }
                return Pregunta(id: "ia-\(tema.id)-\(i)", texto: p.texto, opciones: p.opciones,
                                correcta: p.indiceCorrecta, explicacion: p.explicacion)
            }
        } catch let error as LanguageModelSession.GenerationError {
            if case .assetsUnavailable = error {
                cambiarAModoLibro(motivo: "El modelo de IA no está descargado en este dispositivo.")
            }
            return nil
        } catch {
            return nil
        }
    }

    private var demoQuizRonda = 0

    private static func quizDemo(ronda: Int) -> [Pregunta] {
        if ronda % 2 == 1 {
            return [
                Pregunta(id: "vd1a", texto: "En un grupo de 20 alumnos, 5 llevan lentes. ¿Qué fracción del grupo lleva lentes?",
                         opciones: ["1/4", "1/5", "4/5", "1/2"], correcta: 0,
                         explicacion: "5 de 20 es 5/20, que simplificado es 1/4."),
                Pregunta(id: "vd1b", texto: "¿Cuál fracción es mayor que 1/2?",
                         opciones: ["3/8", "2/5", "5/8", "1/3"], correcta: 2,
                         explicacion: "5/8 pasa de la mitad, porque la mitad de 8 es 4 y aquí tomamos 5."),
                Pregunta(id: "vd1c", texto: "Luis comió 2/6 de un pastel y Ana 1/6. ¿Cuánto comieron juntos?",
                         opciones: ["3/6", "2/12", "3/12", "1/6"], correcta: 0,
                         explicacion: "Con igual denominador se suman los numeradores y queda 3/6, o sea la mitad.")
            ]
        }
        return [
            Pregunta(id: "vd2a", texto: "Una cuerda de 12 metros se corta en 3 partes iguales. ¿Qué fracción del total es cada parte?",
                     opciones: ["1/3", "1/4", "3/12", "1/12"], correcta: 0,
                     explicacion: "Cada parte es una de tres partes iguales, es decir 1/3."),
            Pregunta(id: "vd2b", texto: "¿Qué fracción de una hora son 15 minutos?",
                     opciones: ["1/4", "1/2", "1/3", "15/30"], correcta: 0,
                     explicacion: "15 de 60 minutos es 15/60, que simplificado es 1/4."),
            Pregunta(id: "vd2c", texto: "¿Cuál fracción es equivalente a 2/3?",
                     opciones: ["4/6", "3/2", "2/6", "6/3"], correcta: 0,
                     explicacion: "Multiplicando arriba y abajo por 2, 2/3 se convierte en 4/6.")
        ]
    }

    /// Conversación precargada para capturas de pantalla.
    func cargarDemoChat() {
        mensajes = [
            MensajeChat(esUsuario: true, texto: "¿Quién fue Morelos?"),
            MensajeChat(esUsuario: false, texto: "José María Morelos fue un héroe de la Independencia de México. Cuando Hidalgo murió, él continuó la lucha y escribió los Sentimientos de la Nación, un documento con ideas para un país libre y justo. ¿Quieres que te haga una pregunta para practicar?")
        ]
    }

    private func cambiarAModoLibro(motivo: String) {
        session = nil
        iaDisponible = false
        motivoSinIA = motivo
    }

    /// Modo sin IA: responde con el resumen del tema que más se parezca a la pregunta.
    private func respuestaDeLibro(para texto: String) -> String {
        let palabras = Set(texto.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 3 })
        var mejor: (tema: Tema, coincidencias: Int)?
        for tema in materias.flatMap(\.temas) {
            let contenido = (tema.titulo + " " + tema.resumen).lowercased()
            let n = palabras.filter { contenido.contains($0) }.count
            if n > (mejor?.coincidencias ?? 0) { mejor = (tema, n) }
        }
        if let mejor, mejor.coincidencias > 0 {
            return "Del tema \"\(mejor.tema.titulo)\":\n\n\(mejor.tema.resumen)\n\nPuedes practicarlo en la pestaña Estudiar."
        }
        return "No encontré ese tema en el libro. Prueba con palabras como fracciones, acentos, ciclo del agua o Independencia."
    }
}
