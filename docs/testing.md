# Pruebas en dispositivo (antes de cada release)

Los tests automáticos (`flutter test`, capturas e `integration_test`) cubren datos, lógica y los flujos principales. Lo que depende del **lápiz real, la pantalla y la red** hay que comprobarlo a mano en una tablet. Este guion tarda unos 15 minutos.

**Dispositivos de referencia:** Galaxy Tab S (S-Pen), una tablet con lápiz USI y un teléfono (sin lápiz).

## 0. Instalación

- [ ] El APK de la release (firmado) se instala **encima** de la versión anterior sin perder notas.
- [ ] Configuración muestra la versión correcta.

## 1. Escritura y lápiz

- [ ] Escribir con el lápiz: trazo sin retraso visible, con variación de presión (lápiz, pincel).
- [ ] Apoyar la palma mientras se escribe: no deja marcas.
- [ ] Al detectar el lápiz, un dedo desplaza la página y dos dedos hacen zoom sin saltos.
- [ ] Botón lateral del S-Pen / goma del lápiz: borra mientras se mantiene.
- [ ] Mantener el lápiz quieto al final de una figura la endereza (línea, rectángulo, círculo).
- [ ] Regla: se arrastra con un dedo, gira con dos, el trazo se pega al borde.

## 2. Vista (rendimiento)

Importa el cuaderno de estrés (`flutter test tool/stress/stress_note_test.dart` → `build/inklus_stress.inklus`) y ábrelo con `flutter run --profile` (tecla `P` para ver la gráfica de frames):

- [ ] Desplazar y hacer zoom en la página con 1.700 trazos: fluido; al soltar se ve nítido.
- [ ] Al desplazar no aparecen líneas ni saltos entre la zona "congelada" y la que se dibuja en vivo.
- [ ] Página con 5 fotos de 12 MP: abre y se mueve sin cierres por memoria.
- [ ] Hoja fija: al arrastrar lejos, la hoja se detiene cerca del borde.

## 3. Selección

- [ ] Lazo alrededor de trazos + imagen + texto: mover, escalar (asa inferior derecha) y rotar (asa superior); deshacer lo revierte en un paso.
- [ ] Copiar y pegar la selección: aparece desplazada y seleccionada.

## 4. Datos

- [ ] Cerrar la app a la fuerza justo después de escribir: al volver, el trazo está.
- [ ] Borrar una nota y restaurarla desde la Papelera: vuelve a su cuaderno.
- [ ] Exportar respaldo completo, importarlo (Configuración → Importar): cuadernos intactos.
- [ ] Exportar página PNG/PDF y cuaderno PDF (calidad alta): se ven las fotos.

## 5. Google Drive (con la cuenta de pruebas)

- [ ] Conectar: sin error `DEVELOPER_ERROR` (la huella SHA-1 del APK está registrada).
- [ ] Escribir, salir del editor: la nota se sube (☁️ verde).
- [ ] Historial de versiones: aparecen copias locales y revisiones de Drive; restaurar una funciona.
- [ ] En otro dispositivo: Configuración → Restaurar desde Drive trae las notas.

## 6. Tema y accesibilidad

- [ ] Modo oscuro: todas las pantallas legibles (biblioteca, notas, configuración, papelera, estadísticas, hojas).
- [ ] Selector de fecha de recordatorios en español.

Anota el dispositivo, la versión de Android y cualquier fallo en un *issue*; si la app se cerró, adjunta Configuración → Registro de errores → Compartir.
