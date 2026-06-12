# Pizarrón 🇲🇽

**La escuela que funciona sin internet.**

En México, 7 de cada 10 escuelas públicas no tienen internet ni computadora. Pizarrón es una app de iOS para primaria y secundaria que funciona sin WiFi, sin señal y sin internet. Para nada.

## Features

- **Lecciones sin internet.** Materias y temas de primaria y secundaria viven dentro de la app. Con On-Device AI se generan quizzes completamente nuevos y originales, basados en lo que el alumno aprendió.
- **Juegos multijugador en el salón.** Convivencia y aprendizaje estilo Kahoot. Quien enseña abre la clase y los demás aparecen solos. Todo con MultipeerConnectivity, sin internet y sin WiFi.
- **Tutor offline.** El alumno pregunta en español y recibe una respuesta apropiada y segura, completamente offline. Ninguna pregunta sale del teléfono.
- **Widget de pregunta del día.** Una pregunta nueva cada día en la pantalla de inicio.

## Tecnologías

- Swift y SwiftUI en Xcode 26
- Foundation Models para la IA en el dispositivo, iOS 26
- MultipeerConnectivity para la clase en vivo sin red
- WidgetKit para la pregunta del día
- Cero APIs externas, cero servidores, cero nube

## Cómo correrla

1. Abrir `Pizarron.xcodeproj` en Xcode 26.
2. Elegir un simulador de iPhone con iOS 26 o un dispositivo físico.
3. Correr con ⌘R.

Para el tutor con IA se necesita un dispositivo con Apple Intelligence activado, iPhone 15 Pro o más nuevo. Sin Apple Intelligence la app degrada a modo libro y sigue funcionando completa.

La clase multijugador se prueba con dos dispositivos físicos cercanos. En un solo dispositivo se puede usar el equipo de práctica desde el lobby de la clase.

## Equipo

Hecho para el Swift Challenge Fest 2026.

- Alejandro Vallejo
- Icker Villalón
