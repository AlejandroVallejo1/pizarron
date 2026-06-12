import WidgetKit
import SwiftUI

struct EntradaPregunta: TimelineEntry {
    let date: Date
    let pregunta: Pregunta?
}

struct ProveedorPregunta: TimelineProvider {
    private func preguntaDelDia(_ fecha: Date) -> Pregunta? {
        let todas = Contenido.cargar().flatMap(\.temas).flatMap(\.preguntas)
        guard !todas.isEmpty else { return nil }
        let dia = Calendar.current.ordinality(of: .day, in: .year, for: fecha) ?? 0
        return todas[dia % todas.count]
    }

    func placeholder(in context: Context) -> EntradaPregunta {
        EntradaPregunta(date: .now, pregunta: preguntaDelDia(.now))
    }

    func getSnapshot(in context: Context, completion: @escaping (EntradaPregunta) -> Void) {
        completion(EntradaPregunta(date: .now, pregunta: preguntaDelDia(.now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EntradaPregunta>) -> Void) {
        let hoy = Calendar.current.startOfDay(for: .now)
        let entradas = (0..<7).compactMap { dia -> EntradaPregunta? in
            guard let fecha = Calendar.current.date(byAdding: .day, value: dia, to: hoy) else { return nil }
            return EntradaPregunta(date: fecha, pregunta: preguntaDelDia(fecha))
        }
        completion(Timeline(entries: entradas, policy: .atEnd))
    }
}

struct VistaPreguntaDelDia: View {
    var entry: EntradaPregunta

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PREGUNTA DEL DÍA")
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .kerning(1)
                .foregroundStyle(Color(red: 0.075, green: 0.412, blue: 0.318))
            Text(entry.pregunta?.texto ?? "Abre Pizarrón para empezar a estudiar.")
                .font(.system(.subheadline, design: .serif, weight: .semibold))
                .foregroundStyle(Color(red: 0.118, green: 0.137, blue: 0.125))
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            Text("Resuélvela en Pizarrón →")
                .font(.caption2)
                .foregroundStyle(Color(red: 0.118, green: 0.137, blue: 0.125).opacity(0.5))
        }
        .containerBackground(Color(red: 0.980, green: 0.969, blue: 0.937), for: .widget)
    }
}

@main
struct PizarronWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PreguntaDelDia", provider: ProveedorPregunta()) { entrada in
            VistaPreguntaDelDia(entry: entrada)
        }
        .configurationDisplayName("Pregunta del día")
        .description("Una pregunta nueva cada día para practicar, sin internet.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
