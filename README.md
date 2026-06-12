# Pizarrón

La escuela que funciona sin internet.

En México, 7 de cada 10 escuelas públicas no tienen internet ni computadora. Pizarrón es una app de iOS para primaria y secundaria que funciona sin WiFi, sin señal y sin internet.

## Presentación

Pitch en Keynote, con la demostración en video:

**https://drive.google.com/file/d/18LCybCYcXl0zFmIBEHzr7UVnqOnYuouu/view?usp=sharing**

Descárgalo y ábrelo en Keynote para ver los videos de la demo.

## Funcionalidades

- **Lecciones y práctica sin conexión.** Las materias y temas de primaria y secundaria viven dentro de la app. El modelo de lenguaje en el dispositivo genera quizzes nuevos a partir de lo que el alumno acaba de estudiar.
- **Clase multijugador en el salón.** Dinámica de preguntas estilo Kahoot. Quien enseña abre la clase y los demás se unen solos. Los dispositivos se comunican directamente entre sí, sin internet y sin router.
- **Tutor offline.** El alumno pregunta en español y recibe una respuesta clara y segura, generada por completo en el dispositivo. Ninguna pregunta sale del teléfono.
- **Widget de pregunta del día.** Una pregunta nueva cada día en la pantalla de inicio.

## Tecnologías

- Swift y SwiftUI, Xcode 26
- Foundation Models para el modelo de lenguaje en el dispositivo, iOS 26
- MultipeerConnectivity para la clase en vivo sin red
- WidgetKit para el widget de pregunta del día

Sin APIs externas, sin servidores y sin nube.

## Cómo correrla

1. Abrir `Pizarron.xcodeproj` en Xcode 26.
2. Elegir un simulador de iPhone con iOS 26 o un dispositivo físico.
3. Correr con Cmd R.

El tutor con IA requiere un dispositivo con Apple Intelligence, iPhone 15 Pro o más reciente. Sin Apple Intelligence la app cambia a modo libro y sigue funcionando completa. La clase multijugador se prueba con dos dispositivos cercanos, o con el equipo de práctica del lobby en un solo dispositivo.

## Equipo

Swift Challenge Fest 2026.

- Alejandro Vallejo
- Icker Villalón
