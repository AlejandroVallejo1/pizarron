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
        if args.contains("-demoClase") || args.contains("-demoPodio") { return 1 }
        if args.contains("-demoTutor") { return 2 }
        return 0
    }

    private func prepararDemo() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-demoClase"), let tema = contenido.materias.first?.temas.first {
            clase.iniciarComoMaestro(preguntas: Array(tema.preguntas.prefix(5)), nombre: "Profa. Diana")
            clase.agregarEquipoDePractica()
            clase.empezarJuego()
        }
        if args.contains("-demoPodio") { clase.cargarDemoPodio() }
        if args.contains("-demoTutor") { tutor.cargarDemoChat() }
    }
}
