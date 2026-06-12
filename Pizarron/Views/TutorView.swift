import SwiftUI

struct TutorView: View {
    @EnvironmentObject var tutor: TutorService
    @State private var texto = ""

    private let sugerencias = [
        "¿Cómo sumo fracciones?",
        "¿Por qué llueve?",
        "¿Quién fue Morelos?",
        "¿Cuándo lleva tilde una palabra?"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                encabezado
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            if !tutor.iaDisponible { avisoSinIA }
                            if tutor.mensajes.isEmpty { bienvenida }
                            ForEach(tutor.mensajes) { burbuja($0) }
                            if tutor.ocupado {
                                HStack { ProgressView().tint(.pizarra); Text("Pensando…").font(.caption).foregroundStyle(Color.tinta.opacity(0.5)); Spacer() }
                                    .padding(.horizontal, 4)
                            }
                            Color.clear.frame(height: 1).id("fin")
                        }
                        .padding(20)
                    }
                    .onChange(of: tutor.mensajes) {
                        withAnimation { proxy.scrollTo("fin") }
                    }
                }
                barraEntrada
            }
            .background(Color.papel)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { coreografiaVideo() }
        }
    }

    // Modo video: escribe preguntas letra por letra con tiempos de persona real.
    private func coreografiaVideo() {
        guard ProcessInfo.processInfo.arguments.contains("-videoTutor"), tutor.mensajes.isEmpty else { return }
        escribirYEnviar("¿Por qué se forman las nubes?", en: 2.5)
        escribirYEnviar("¿Quién fue Morelos?", en: 16)
    }

    private func escribirYEnviar(_ pregunta: String, en inicio: Double) {
        let caracteres = Array(pregunta)
        for i in caracteres.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + inicio + Double(i) * 0.09) {
                texto = String(caracteres[0...i])
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + inicio + Double(caracteres.count) * 0.09 + 0.8) {
            enviar()
        }
    }

    private var encabezado: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Tutor")
                    .tituloSerif(34)
                Spacer()
                if ProcessInfo.processInfo.arguments.contains("-videoTutor") {
                    Label("Modo avión", systemImage: "airplane")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.pizarra)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.pizarraSuave, in: Capsule())
                }
            }
            Text(tutor.iaDisponible
                 ? "Pregunta lo que quieras. Todo se responde en tu dispositivo, sin internet."
                 : "Modo libro: te respondo con los resúmenes de tus temas.")
                .font(.subheadline)
                .foregroundStyle(Color.tinta.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var avisoSinIA: some View {
        Label(tutor.motivoSinIA, systemImage: "info.circle")
            .font(.caption)
            .foregroundStyle(Color.tinta.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.pizarraSuave, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var bienvenida: some View {
        VStack(alignment: .leading, spacing: 10) {
            EtiquetaSeccion(texto: "Prueba con")
            ForEach(sugerencias, id: \.self) { s in
                Button {
                    Task { await tutor.preguntar(s) }
                } label: {
                    Text(s)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Color.pizarra)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Color.white, in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.pizarra.opacity(0.3)))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func burbuja(_ mensaje: MensajeChat) -> some View {
        HStack {
            if mensaje.esUsuario { Spacer(minLength: 40) }
            Text(mensaje.texto)
                .font(.system(.body, design: mensaje.esUsuario ? .default : .serif))
                .lineSpacing(4)
                .foregroundStyle(mensaje.esUsuario ? .white : Color.tinta)
                .padding(14)
                .background(
                    mensaje.esUsuario ? Color.pizarra : Color.white,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.tinta.opacity(mensaje.esUsuario ? 0 : 0.08))
                )
            if !mensaje.esUsuario { Spacer(minLength: 40) }
        }
    }

    private var barraEntrada: some View {
        HStack(spacing: 10) {
            TextField("Escribe tu pregunta…", text: $texto)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.tinta.opacity(0.1)))
                .onSubmit(enviar)
            Button(action: enviar) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.pizarra)
            }
            .disabled(texto.trimmingCharacters(in: .whitespaces).isEmpty || tutor.ocupado)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.papel)
    }

    private func enviar() {
        let t = texto
        texto = ""
        Task { await tutor.preguntar(t) }
    }
}
