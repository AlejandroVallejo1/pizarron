import SwiftUI

struct EstudiarView: View {
    @EnvironmentObject var contenido: ContentStore
    @State private var rutaDemo = NavigationPath()

    var body: some View {
        NavigationStack(path: $rutaDemo) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(saludo)
                            .tituloSerif(34)
                        Text("La escuela que funciona sin internet.")
                            .font(.subheadline)
                            .foregroundStyle(Color.tinta.opacity(0.6))
                    }
                    .padding(.top, 8)

                    EtiquetaSeccion(texto: "Materias")
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible())], spacing: 14) {
                        ForEach(contenido.materias) { materia in
                            NavigationLink(value: materia) {
                                MateriaCard(materia: materia)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.papel)
            .navigationDestination(for: Materia.self) { MateriaView(materia: $0) }
            .navigationDestination(for: Tema.self) { TemaView(tema: $0) }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if ProcessInfo.processInfo.arguments.contains("-demoTema"),
                   rutaDemo.isEmpty,
                   let tema = contenido.materias.first?.temas.first {
                    rutaDemo.append(tema)
                }
                // Modo video: navega por las lecciones con tiempos de persona real.
                if ProcessInfo.processInfo.arguments.contains("-videoEstudiar"),
                   rutaDemo.isEmpty,
                   let materia = contenido.materias.first,
                   let tema = materia.temas.first {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { rutaDemo.append(materia) }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) { rutaDemo.append(tema) }
                }
            }
        }
    }

    private var saludo: String {
        let nombre = contenido.nombreUsuario
        return nombre.isEmpty ? "Hola." : "Hola, \(nombre)."
    }
}

struct MateriaCard: View {
    @EnvironmentObject var contenido: ContentStore
    let materia: Materia

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: materia.icono)
                .font(.title2)
                .foregroundStyle(Color.pizarra)
                .frame(width: 46, height: 46)
                .background(Color.pizarraSuave, in: Circle())
            Text(materia.nombre)
                .font(.system(.title3, design: .serif, weight: .bold))
                .foregroundStyle(Color.tinta)
            Text("\(dominados) de \(materia.temas.count) temas dominados")
                .font(.caption)
                .foregroundStyle(Color.tinta.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tarjeta()
    }

    private var dominados: Int {
        materia.temas.filter { (contenido.mejores[$0.id] ?? 0) >= $0.preguntas.count }.count
    }
}

struct MateriaView: View {
    let materia: Materia

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(materia.nombre)
                    .tituloSerif(30)
                ForEach(materia.temas) { tema in
                    NavigationLink(value: tema) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tema.titulo)
                                    .font(.system(.headline, design: .serif))
                                    .foregroundStyle(Color.tinta)
                                Text("\(tema.preguntas.count) preguntas")
                                    .font(.caption)
                                    .foregroundStyle(Color.tinta.opacity(0.55))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(Color.pizarra)
                        }
                        .tarjeta()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(Color.papel)
    }
}

struct TemaView: View {
    @EnvironmentObject var contenido: ContentStore
    @EnvironmentObject var tutor: TutorService
    let tema: Tema
    @State private var quizActivo: QuizSesion?
    @State private var generando = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(tema.titulo)
                    .tituloSerif(30)

                VStack(alignment: .leading, spacing: 10) {
                    EtiquetaSeccion(texto: "Del libro")
                    Text(tema.resumen)
                        .font(.system(.body, design: .serif))
                        .lineSpacing(5)
                        .foregroundStyle(Color.tinta)
                }
                .tarjeta()

                if let mejor = contenido.mejores[tema.id] {
                    Label("Tu mejor ronda: \(mejor) de \(tema.preguntas.count)", systemImage: "star.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.pizarra)
                }

                Button("Practicar este tema") { quizActivo = QuizSesion(preguntas: tema.preguntas.shuffled()) }
                    .buttonStyle(BotonPrimario())

                if tutor.iaDisponible {
                    Button {
                        generarConIA()
                    } label: {
                        HStack {
                            if generando { ProgressView().tint(.pizarra) }
                            Text(generando ? "Creando preguntas nuevas…" : "Quiz nuevo con IA")
                        }
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color.pizarra)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.pizarraSuave, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(generando)
                    Text("Las preguntas se crean en tu dispositivo, sin internet.")
                        .font(.caption)
                        .foregroundStyle(Color.tinta.opacity(0.5))
                }
            }
            .padding(20)
        }
        .background(Color.papel)
        .fullScreenCover(item: $quizActivo) { sesion in
            QuizView(preguntas: sesion.preguntas) { aciertos in
                contenido.registrar(tema: tema, aciertos: aciertos)
            }
        }
        .onAppear { coreografiaVideo() }
    }

    private func generarConIA() {
        Task {
            generando = true
            if let nuevas = await tutor.generarQuiz(tema: tema), !nuevas.isEmpty {
                quizActivo = QuizSesion(preguntas: nuevas)
            }
            generando = false
        }
    }

    // Modo video: genera dos quizzes seguidos para mostrar que las preguntas
    // siempre son distintas.
    private func coreografiaVideo() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-videoQuizIA") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { generarConIA() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 13) { quizActivo = nil }
            DispatchQueue.main.asyncAfter(deadline: .now() + 14.5) { generarConIA() }
        }
        if args.contains("-videoEstudiar"), !VideoFlags.quizLanzado {
            VideoFlags.quizLanzado = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                quizActivo = QuizSesion(preguntas: tema.preguntas.shuffled())
            }
        }
    }
}

// Candados para que las coreografías de video corran una sola vez por lanzamiento,
// aunque onAppear se dispare varias veces.
enum VideoFlags {
    static var quizLanzado = false
    static var autoplayProgramado = false
}

struct QuizSesion: Identifiable {
    let id = UUID()
    let preguntas: [Pregunta]
}
