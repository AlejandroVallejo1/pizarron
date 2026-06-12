import SwiftUI

struct PerfilView: View {
    @EnvironmentObject var contenido: ContentStore
    @EnvironmentObject var tutor: TutorService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Mi avance")
                        .tituloSerif(34)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        EtiquetaSeccion(texto: "Mi nombre")
                        TextField("Escribe tu nombre", text: $contenido.nombreUsuario)
                            .font(.system(.title3, design: .serif, weight: .semibold))
                            .textFieldStyle(.plain)
                    }
                    .tarjeta()

                    HStack(spacing: 14) {
                        cifra(valor: "\(contenido.temasDominados)", titulo: "temas\ndominados")
                        cifra(valor: "\(contenido.totalTemas)", titulo: "temas\nen el libro")
                        cifra(valor: tutor.iaDisponible ? "Sí" : "No", titulo: "IA en este\ndispositivo")
                    }

                    EtiquetaSeccion(texto: "Por materia")
                    ForEach(contenido.materias) { materia in
                        let total = materia.temas.count
                        let hechos = materia.temas.filter { (contenido.mejores[$0.id] ?? 0) >= $0.preguntas.count }.count
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label(materia.nombre, systemImage: materia.icono)
                                    .font(.system(.headline, design: .serif))
                                    .foregroundStyle(Color.tinta)
                                Spacer()
                                Text("\(hechos)/\(total)")
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .foregroundStyle(Color.pizarra)
                            }
                            GeometryReader { geo in
                                Capsule().fill(Color.pizarraSuave)
                                    .overlay(alignment: .leading) {
                                        Capsule().fill(Color.pizarra)
                                            .frame(width: total > 0 ? geo.size.width * CGFloat(hechos) / CGFloat(total) : 0)
                                    }
                            }
                            .frame(height: 6)
                        }
                        .tarjeta()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        EtiquetaSeccion(texto: "Pregunta del día")
                        Text("Agrega el widget de Pizarrón a tu pantalla de inicio para practicar una pregunta nueva cada día, también sin internet.")
                            .font(.system(.callout, design: .serif))
                            .foregroundStyle(Color.tinta.opacity(0.8))
                    }
                    .tarjeta()

                    Text("Hecho para las escuelas donde el internet no llega. 🇲🇽")
                        .font(.caption)
                        .foregroundStyle(Color.tinta.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color.papel)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func cifra(valor: String, titulo: String) -> some View {
        VStack(spacing: 6) {
            Text(valor)
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(Color.pizarra)
            Text(titulo)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.tinta.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .tarjeta(relleno: 14)
    }
}
