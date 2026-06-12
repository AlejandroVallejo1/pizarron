import SwiftUI

struct ClaseView: View {
    @EnvironmentObject var contenido: ContentStore
    @EnvironmentObject var clase: ClassSession
    @State private var eligiendoTema = false

    var body: some View {
        NavigationStack {
            Group {
                switch clase.fase {
                case .inactiva: inicio
                case .buscando: buscando
                case .lobby: clase.rol == .maestro ? AnyView(lobbyMaestro) : AnyView(lobbyAlumno)
                case .pregunta: clase.rol == .maestro ? AnyView(preguntaMaestro) : AnyView(preguntaAlumno)
                case .resultado: resultado
                case .fin: podio
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.papel)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { coreografiaVideo() }
        }
    }

    // Modo video guiado: recorre las pantallas con los tiempos de una persona
    // real para grabar la demo. La sesión multipeer es real.
    private func coreografiaVideo() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-videoMaestroGuiado"), clase.fase == .inactiva {
            clase.autoMaestro = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { eligiendoTema = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) {
                eligiendoTema = false
                if let tema = contenido.materias.first?.temas.first {
                    clase.iniciarComoMaestro(preguntas: Array(tema.preguntas.prefix(2)),
                                             nombre: contenido.nombreUsuario.isEmpty ? "Profa. Diana" : contenido.nombreUsuario)
                }
            }
        }
        if args.contains("-videoAlumnoGuiado"), clase.fase == .inactiva {
            clase.autoAlumno = true
            DispatchQueue.main.asyncAfter(deadline: .now() + .random(in: 4.5...7)) {
                clase.unirseComoAlumno(nombre: contenido.nombreUsuario)
            }
        }
    }

    // MARK: Pantallas

    private var inicio: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Clase en vivo")
                    .tituloSerif(34)
                    .padding(.top, 8)
                Text("Juega en equipo sin internet: los dispositivos se conectan entre sí por la red local o Bluetooth.")
                    .font(.subheadline)
                    .foregroundStyle(Color.tinta.opacity(0.6))

                VStack(alignment: .leading, spacing: 8) {
                    EtiquetaSeccion(texto: "Tu nombre")
                    TextField("Escribe tu nombre", text: $contenido.nombreUsuario)
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .textFieldStyle(.plain)
                }
                .tarjeta()

                Button {
                    eligiendoTema = true
                } label: {
                    tarjetaRol(icono: "person.crop.rectangle.badge.plus", titulo: "Soy quien enseña",
                               detalle: "Elige un tema y abre una clase para que se unan los demás.")
                }
                .buttonStyle(.plain)

                Button {
                    clase.unirseComoAlumno(nombre: contenido.nombreUsuario)
                } label: {
                    tarjetaRol(icono: "hand.raised", titulo: "Soy estudiante",
                               detalle: "Busca una clase cercana y únete a jugar.")
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .sheet(isPresented: $eligiendoTema) {
            SelectorTema { tema in
                eligiendoTema = false
                clase.iniciarComoMaestro(preguntas: Array(tema.preguntas.shuffled().prefix(5)),
                                         nombre: contenido.nombreUsuario)
            }
        }
    }

    private func tarjetaRol(icono: String, titulo: String, detalle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icono)
                .font(.title2)
                .foregroundStyle(Color.pizarra)
                .frame(width: 50, height: 50)
                .background(Color.pizarraSuave, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(titulo)
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .foregroundStyle(Color.tinta)
                Text(detalle)
                    .font(.caption)
                    .foregroundStyle(Color.tinta.opacity(0.6))
            }
            Spacer()
        }
        .tarjeta()
    }

    private var buscando: some View {
        VStack(spacing: 18) {
            ProgressView().controlSize(.large).tint(.pizarra)
            Text("Buscando una clase cercana…")
                .font(.system(.title3, design: .serif, weight: .semibold))
            Text("Pide a quien enseña que abra la clase en su dispositivo.")
                .font(.caption)
                .foregroundStyle(Color.tinta.opacity(0.6))
            Button("Cancelar") { clase.salir() }
                .foregroundStyle(Color.tinta.opacity(0.5))
        }
        .padding(24)
    }

    private var lobbyMaestro: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Clase abierta")
                .tituloSerif(32)
            Text("Los estudiantes cercanos se conectan solos al abrir Pizarrón → Clase → Soy estudiante.")
                .font(.subheadline)
                .foregroundStyle(Color.tinta.opacity(0.6))

            EtiquetaSeccion(texto: "Conectados (\(clase.jugadores.count))")
            if clase.jugadores.isEmpty {
                Text("Esperando estudiantes…")
                    .font(.system(.body, design: .serif).italic())
                    .foregroundStyle(Color.tinta.opacity(0.5))
            }
            FlujoNombres(nombres: clase.jugadores)

            Spacer()

            Button("Agregar equipo de práctica") { clase.agregarEquipoDePractica() }
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.pizarra)
                .frame(maxWidth: .infinity)

            Button("Empezar juego") { clase.empezarJuego() }
                .buttonStyle(BotonPrimario())
                .disabled(clase.jugadores.isEmpty)
                .opacity(clase.jugadores.isEmpty ? 0.4 : 1)

            Button("Cerrar clase") { clase.salir() }
                .frame(maxWidth: .infinity)
                .foregroundStyle(Color.tinta.opacity(0.5))
        }
        .padding(20)
    }

    private var lobbyAlumno: some View {
        VStack(spacing: 16) {
            Text("🙌")
                .font(.system(size: 56))
            Text("¡Ya estás dentro!")
                .tituloSerif(30)
            Text("Espera a que empiece el juego.")
                .foregroundStyle(Color.tinta.opacity(0.6))
            Button("Salir de la clase") { clase.salir() }
                .foregroundStyle(Color.tinta.opacity(0.5))
        }
        .padding(24)
    }

    private var preguntaMaestro: some View {
        VStack(alignment: .leading, spacing: 20) {
            EtiquetaSeccion(texto: "Pregunta \(clase.indice + 1) de \(clase.total)")
            Text(clase.preguntaActual?.texto ?? "")
                .tituloSerif(28)

            if let opciones = clase.preguntaActual?.opciones {
                ForEach(opciones.indices, id: \.self) { i in
                    HStack(spacing: 12) {
                        Text(["A", "B", "C", "D", "E"][min(i, 4)])
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .frame(width: 30, height: 30)
                            .background(Color.pizarraSuave, in: Circle())
                            .foregroundStyle(Color.pizarra)
                        Text(opciones[i]).foregroundStyle(Color.tinta)
                        Spacer()
                    }
                    .tarjeta(relleno: 12)
                }
            }

            Spacer()

            Label("\(clase.respuestasRecibidas.count) de \(clase.jugadores.count) han respondido",
                  systemImage: "hand.raised.fill")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Color.pizarra)
                .frame(maxWidth: .infinity)

            Button("Cerrar pregunta") { clase.cerrarPregunta() }
                .buttonStyle(BotonPrimario())
        }
        .padding(20)
    }

    private var preguntaAlumno: some View {
        VStack(alignment: .leading, spacing: 18) {
            EtiquetaSeccion(texto: "Pregunta \(clase.indice + 1) de \(clase.total)")
            Text(clase.preguntaActual?.texto ?? "")
                .tituloSerif(26)

            if let opciones = clase.preguntaActual?.opciones {
                ForEach(opciones.indices, id: \.self) { i in
                    Button {
                        clase.responder(i)
                    } label: {
                        HStack(spacing: 12) {
                            Text(["A", "B", "C", "D", "E"][min(i, 4)])
                                .font(.system(.headline, design: .rounded))
                                .frame(width: 34, height: 34)
                                .background(clase.miRespuesta == i ? Color.pizarra : Color.pizarraSuave, in: Circle())
                                .foregroundStyle(clase.miRespuesta == i ? .white : Color.pizarra)
                            Text(opciones[i])
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.tinta)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .tarjeta(relleno: 14)
                    }
                    .buttonStyle(.plain)
                    .disabled(clase.miRespuesta != nil)
                }
            }

            if clase.miRespuesta != nil {
                Label("Respuesta enviada. Espera al resto del grupo…", systemImage: "paperplane.fill")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.pizarra)
                    .frame(maxWidth: .infinity)
            }
            Spacer()
        }
        .padding(20)
        .animation(.snappy, value: clase.miRespuesta)
    }

    private var resultado: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let q = clase.preguntaActual, let correcta = clase.ultimaCorrecta {
                EtiquetaSeccion(texto: "Respuesta correcta")
                Text(q.opciones[correcta])
                    .tituloSerif(26)
                if clase.rol == .alumno {
                    Label(clase.miRespuesta == correcta ? "¡Acertaste! +100 puntos" : "Esta vez no fue.",
                          systemImage: clase.miRespuesta == correcta ? "checkmark.seal.fill" : "arrow.counterclockwise")
                        .font(.headline)
                        .foregroundStyle(clase.miRespuesta == correcta ? Color.acierto : Color.tinta.opacity(0.6))
                }
                Text(q.explicacion)
                    .font(.system(.callout, design: .serif))
                    .foregroundStyle(Color.tinta.opacity(0.85))
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.pizarraSuave, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            EtiquetaSeccion(texto: "Marcador")
            MarcadorLista(marcador: clase.marcador)

            Spacer()

            if clase.rol == .maestro {
                Button(clase.indice + 1 < clase.total ? "Siguiente pregunta" : "Ver podio") {
                    clase.siguientePregunta()
                }
                .buttonStyle(BotonPrimario())
            }
        }
        .padding(20)
    }

    private var podio: some View {
        VStack(spacing: 18) {
            Text("🏆")
                .font(.system(size: 64))
            Text("Fin del juego")
                .tituloSerif(32)
            MarcadorLista(marcador: clase.marcador, destacarPodio: true)
            Spacer()
            Button("Terminar") { clase.salir() }
                .buttonStyle(BotonPrimario())
        }
        .padding(20)
    }
}

// MARK: - Piezas compartidas

struct MarcadorLista: View {
    let marcador: [Puntaje]
    var destacarPodio = false

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(marcador.enumerated()), id: \.element.id) { lugar, p in
                HStack {
                    Text(destacarPodio && lugar < 3 ? ["🥇", "🥈", "🥉"][lugar] : "\(lugar + 1).")
                        .frame(width: 34)
                    Text(p.nombre)
                        .font(.system(.body, design: .serif, weight: lugar == 0 ? .bold : .regular))
                        .foregroundStyle(Color.tinta)
                    Spacer()
                    Text("\(p.puntos) pts")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.pizarra)
                }
                .tarjeta(relleno: 12)
            }
        }
    }
}

struct FlujoNombres: View {
    let nombres: [String]
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(nombres, id: \.self) { nombre in
                Text(nombre)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.pizarraSuave, in: Capsule())
                    .foregroundStyle(Color.pizarra)
            }
        }
    }
}

struct SelectorTema: View {
    @EnvironmentObject var contenido: ContentStore
    let alElegir: (Tema) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(contenido.materias) { materia in
                    Section(materia.nombre) {
                        ForEach(materia.temas) { tema in
                            Button {
                                alElegir(tema)
                            } label: {
                                HStack {
                                    Text(tema.titulo).foregroundStyle(Color.tinta)
                                    Spacer()
                                    Text("\(tema.preguntas.count) preguntas")
                                        .font(.caption)
                                        .foregroundStyle(Color.tinta.opacity(0.5))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Elige el tema")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
