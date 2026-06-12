import SwiftUI

@main
struct PizarronApp: App {
    @StateObject private var contenido = ContentStore()
    @StateObject private var tutor = TutorService()
    @StateObject private var clase = ClassSession()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(contenido)
                .environmentObject(tutor)
                .environmentObject(clase)
                .tint(.pizarra)
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var contenido: ContentStore
    @EnvironmentObject var tutor: TutorService
    @EnvironmentObject var clase: ClassSession
    @State private var tab = HomeView.tabInicial

    var body: some View {
        TabView(selection: $tab) {
            EstudiarView()
                .tabItem { Label("Estudiar", systemImage: "book") }
                .tag(0)
            ClaseView()
                .tabItem { Label("Clase", systemImage: "person.3") }
                .tag(1)
            TutorView()
                .tabItem { Label("Tutor", systemImage: "bubble.left.and.text.bubble.right") }
                .tag(2)
            PerfilView()
                .tabItem { Label("Yo", systemImage: "person.crop.circle") }
                .tag(3)
        }
        .onAppear { prepararDemo() }
    }

    // Estados precargados para capturas de pantalla y ensayos (se activan
    // solo con argumentos de lanzamiento, p. ej. desde simctl).
    private static var tabInicial: Int {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-demoClase") || args.contains("-demoPodio") || args.contains("-demoLobby")
            || args.contains("-videoMaestro") || args.contains("-videoAlumno")
            || args.contains("-videoMaestroGuiado") || args.contains("-videoAlumnoGuiado") { return 1 }
        if args.contains("-demoTutor") || args.contains("-videoTutor") { return 2 }
        return 0
    }

    private func prepararDemo() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-demoClase"), let tema = contenido.materias.first?.temas.first {
            clase.iniciarComoMaestro(preguntas: Array(tema.preguntas.prefix(5)), nombre: "Profa. Diana")
            clase.agregarEquipoDePractica()
            clase.empezarJuego()
        }
        if args.contains("-demoLobby"), let tema = contenido.materias.first?.temas.first {
            clase.iniciarComoMaestro(preguntas: Array(tema.preguntas.prefix(5)), nombre: "Profa. Diana")
            clase.agregarEquipoDePractica()
        }
        if args.contains("-demoPodio") { clase.cargarDemoPodio() }
        if args.contains("-demoTutor") { tutor.cargarDemoChat() }

        // Modo video: sesión real por MultipeerConnectivity, automatizada para grabar.
        if args.contains("-videoMaestro"), let tema = contenido.materias.first?.temas.first {
            clase.autoMaestro = true
            clase.iniciarComoMaestro(preguntas: Array(tema.preguntas.prefix(2)),
                                     nombre: contenido.nombreUsuario.isEmpty ? "Profa. Diana" : contenido.nombreUsuario)
        }
        if args.contains("-videoAlumno") {
            clase.autoAlumno = true
            clase.unirseComoAlumno(nombre: contenido.nombreUsuario)
        }
    }
}
