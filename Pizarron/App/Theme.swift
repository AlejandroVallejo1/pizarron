import SwiftUI

// Paleta "libro de texto gratuito": papel cálido, tinta, un solo acento verde pizarra.
extension Color {
    static let papel = Color(red: 0.980, green: 0.969, blue: 0.937)
    static let tinta = Color(red: 0.118, green: 0.137, blue: 0.125)
    static let pizarra = Color(red: 0.075, green: 0.412, blue: 0.318)
    static let pizarraSuave = Color(red: 0.886, green: 0.937, blue: 0.910)
    static let acierto = Color(red: 0.075, green: 0.412, blue: 0.318)
    static let error = Color(red: 0.753, green: 0.224, blue: 0.169)
}

struct Tarjeta: ViewModifier {
    var relleno: CGFloat = 18
    func body(content: Content) -> some View {
        content
            .padding(relleno)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.tinta.opacity(0.08))
            )
    }
}

extension View {
    func tarjeta(relleno: CGFloat = 18) -> some View { modifier(Tarjeta(relleno: relleno)) }

    func tituloSerif(_ tamano: CGFloat = 28) -> some View {
        font(.system(size: tamano, weight: .bold, design: .serif))
            .foregroundStyle(Color.tinta)
    }
}

struct BotonPrimario: ButtonStyle {
    var color: Color = .pizarra
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct EtiquetaSeccion: View {
    let texto: String
    var body: some View {
        Text(texto.uppercased())
            .font(.system(.caption, design: .rounded, weight: .bold))
            .kerning(1.2)
            .foregroundStyle(Color.pizarra)
    }
}
