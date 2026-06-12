import SwiftUI

struct QuizView: View {
    let preguntas: [Pregunta]
    var alTerminar: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var indice = 0
    @State private var seleccion: Int?
    @State private var aciertos = 0
    @State private var terminado = false

    var body: some View {
        VStack(spacing: 0) {
            if terminado {
                resultadoFinal
            } else {
                encabezado
                ScrollView { preguntaVista.padding(20) }
            }
        }
        .background(Color.papel)
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            guard args.contains("-videoQuizIA") || args.contains("-videoEstudiar") else { return }
            if args.contains("-videoEstudiar") {
                guard !VideoFlags.autoplayProgramado else { return }
                VideoFlags.autoplayProgramado = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                if seleccion == nil {
                    seleccion = preguntas[indice].correcta
                    aciertos += 1
                }
            }
            if args.contains("-videoEstudiar") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 7.5) {
                    if indice + 1 < preguntas.count {
                        indice += 1
                        seleccion = nil
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 11) {
                    if seleccion == nil {
                        seleccion = preguntas[indice].correcta
                        aciertos += 1
                    }
                }
            }
        }
    }

    private var encabezado: some View {
        VStack(spacing: 12) {
            HStack {
                Button("Salir") { dismiss() }
                    .foregroundStyle(Color.tinta.opacity(0.5))
                Spacer()
                Text("Pregunta \(indice + 1) de \(preguntas.count)")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.tinta.opacity(0.7))
            }
            GeometryReader { geo in
                Capsule().fill(Color.pizarraSuave)
                    .overlay(alignment: .leading) {
                        Capsule().fill(Color.pizarra)
                            .frame(width: geo.size.width * CGFloat(indice + 1) / CGFloat(preguntas.count))
                    }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var preguntaVista: some View {
        let pregunta = preguntas[indice]
        return VStack(alignment: .leading, spacing: 18) {
            Text(pregunta.texto)
                .tituloSerif(26)
                .padding(.top, 10)

            ForEach(pregunta.opciones.indices, id: \.self) { i in
                Button {
                    guard seleccion == nil else { return }
                    seleccion = i
                    if i == pregunta.correcta { aciertos += 1 }
                } label: {
                    HStack(spacing: 14) {
                        Text(letra(i))
                            .font(.system(.headline, design: .rounded))
                            .frame(width: 34, height: 34)
                            .background(colorLetra(i, pregunta: pregunta), in: Circle())
                            .foregroundStyle(seleccion == nil ? Color.pizarra : .white)
                        Text(pregunta.opciones[i])
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.tinta)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if seleccion != nil, i == pregunta.correcta {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.acierto)
                        } else if seleccion == i {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(Color.error)
                        }
                    }
                    .tarjeta(relleno: 14)
                }
                .buttonStyle(.plain)
            }

            if let seleccion {
                VStack(alignment: .leading, spacing: 8) {
                    EtiquetaSeccion(texto: seleccion == pregunta.correcta ? "¡Correcto!" : "La respuesta era \(letra(pregunta.correcta))")
                    Text(pregunta.explicacion)
                        .font(.system(.callout, design: .serif))
                        .foregroundStyle(Color.tinta.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.pizarraSuave, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button(indice + 1 < preguntas.count ? "Siguiente" : "Ver mi resultado") {
                    if indice + 1 < preguntas.count {
                        indice += 1
                        self.seleccion = nil
                    } else {
                        terminado = true
                        alTerminar(aciertos)
                    }
                }
                .buttonStyle(BotonPrimario())
            }
        }
        .animation(.snappy, value: seleccion)
    }

    private var resultadoFinal: some View {
        VStack(spacing: 16) {
            Spacer()
            Text(aciertos == preguntas.count ? "🏆" : aciertos > preguntas.count / 2 ? "⭐️" : "📖")
                .font(.system(size: 64))
            Text("\(aciertos) de \(preguntas.count)")
                .tituloSerif(40)
            Text(mensajeFinal)
                .font(.system(.body, design: .serif))
                .foregroundStyle(Color.tinta.opacity(0.7))
                .multilineTextAlignment(.center)
            Spacer()
            Button("Listo") { dismiss() }
                .buttonStyle(BotonPrimario())
        }
        .padding(24)
    }

    private var mensajeFinal: String {
        if aciertos == preguntas.count { return "¡Perfecto! Dominaste el tema." }
        if aciertos > preguntas.count / 2 { return "Muy bien. Repasa las que fallaste y vuelve a intentar." }
        return "Buen comienzo. Lee el resumen del tema y vuelve a practicar."
    }

    private func letra(_ i: Int) -> String { ["A", "B", "C", "D", "E"][min(i, 4)] }

    private func colorLetra(_ i: Int, pregunta: Pregunta) -> Color {
        guard let seleccion else { return .pizarraSuave }
        if i == pregunta.correcta { return .acierto }
        if i == seleccion { return .error }
        return .pizarraSuave
    }
}
