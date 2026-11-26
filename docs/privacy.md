# Política de privacidad de Inklus

*Última actualización: 27 de septiembre de 2026*

Inklus es una app de escritura a mano **libre y gratuita** (licencia GPL-3.0). No tiene cuentas propias, anuncios, analítica ni funciones de pago. Esta política explica qué datos maneja la app y adónde van.

## Resumen

- **Tus notas se guardan en tu dispositivo.** Inklus no tiene servidores y nadie más que tú puede leerlas.
- **Google Drive es opcional.** Si conectas tu cuenta, Inklus sube una copia de tus notas a **tu** Drive. Nosotros no tenemos acceso a ella.
- **Sin analítica, sin anuncios, sin rastreo.** No vendemos ni compartimos datos con nadie.

## Datos que se guardan en el dispositivo

Cuadernos, notas, páginas, trazos, imágenes que insertes, plantillas, etiquetas, recordatorios, estadísticas de escritura y el historial de versiones se guardan en la carpeta privada de la app (`inklus/`). Se borran al desinstalar la app. Puedes exportarlos cuando quieras (Configuración → "Exportar respaldo completo").

## Google Drive (opcional)

Solo si pulsas "Conectar" en Configuración:

- **Inicio de sesión con Google**: la app recibe el correo de tu cuenta solo para mostrarte con cuál estás conectado. No se guarda en ningún servidor.
- **Permiso `drive.file`**: Inklus **solo puede ver y modificar los archivos que ella misma crea** (una carpeta "Inklus" con un archivo `.inklus` por nota). No puede leer el resto de tu Drive.
- Las copias pueden **cifrarse con una contraseña** (AES-256-GCM) antes de subirse. La contraseña nunca sale del dispositivo.
- Google trata esos archivos según la [política de privacidad de Google](https://policies.google.com/privacy). Puedes desconectar la cuenta en Configuración y borrar la carpeta "Inklus" de tu Drive cuando quieras.

El uso y la transferencia a cualquier otra app de la información recibida de las API de Google se ajustan a la [Política de datos de usuario de los servicios de API de Google](https://developers.google.com/terms/api-services-user-data-policy), incluidos los requisitos de uso limitado.

## Reconocimiento de escritura (ML Kit)

Las funciones "Convertir a texto" e "Indexar escritura" usan **Google ML Kit**, que reconoce el texto **en el dispositivo**: tus trazos y páginas no se envían a ningún servidor. La primera vez, ML Kit descarga desde los servidores de Google el modelo del idioma. Según sus [condiciones](https://developers.google.com/ml-kit/terms), ML Kit puede enviar a Google métricas técnicas anónimas de uso y rendimiento, que no incluyen el contenido de tus notas.

## Marketplace

Al abrir el Marketplace, la app descarga el catálogo y los paquetes gratuitos (plantillas, paletas, stickers) desde la CDN pública de jsDelivr (`cdn.jsdelivr.net`), que sirve el repositorio público `inklus-marketplace` de GitHub. Como cualquier descarga web, esa CDN ve tu dirección IP. No se envía ningún otro dato.

## Avisos de nuevas versiones

Una vez al día, la app consulta la API pública de GitHub (`api.github.com`) para saber cuál es la última versión publicada de Inklus. No se envía ningún dato tuyo; como cualquier petición web, GitHub ve tu dirección IP. Si hay una versión nueva, la app te avisa y el instalador solo se descarga si tú lo pides. Puedes desactivarlo en Configuración → "Avisar de nuevas versiones".

## Grabaciones de audio

Si grabas audio en una nota, el micrófono solo se usa mientras grabas (lo pides tú con el botón) y el audio se guarda **solo en tu dispositivo**, dentro de la nota. Viaja con ella a tus copias `.inklus` y, si lo activas, a tu Google Drive.

## Registro de errores

Si la app falla, el error se guarda **solo en tu dispositivo** (Configuración → "Registro de errores"). No se envía automáticamente a nadie. Puedes compartirlo tú, si quieres ayudar a corregir el fallo.

## Permisos de Android

- **Internet**: solo para Google Drive (si lo activas), el Marketplace, los modelos de ML Kit y el aviso de nuevas versiones.
- **Micrófono**: solo mientras grabas audio en una nota (lo pide la primera vez que pulsas el botón).
- **Archivos**: solo los que eliges tú en el selector del sistema (importar PDF, imágenes o `.inklus`; exportar).

## Menores

Inklus no recoge datos personales, así que es apta para cualquier edad. El inicio de sesión con Google está sujeto a los requisitos de edad de Google.

## Cambios y contacto

Si esta política cambia, se actualizará este documento (su historial está en el repositorio). Para cualquier duda, abre un *issue* en <https://github.com/Pedroj-64/inklus/issues>.

---

### English summary

Inklus stores your notes **only on your device**. There are no Inklus servers, accounts, ads, analytics or tracking. **Google Drive backup is optional**: it uses the `drive.file` scope, so the app can only see the files it creates in your own Drive (optionally encrypted with your password). Handwriting recognition runs **on-device** with Google ML Kit, which downloads language models from Google and may send anonymous technical metrics under its own terms. The Marketplace downloads free packs from the jsDelivr CDN. Once a day the app asks GitHub's public API for the latest published version (no personal data is sent; you can turn it off in Settings). Audio recordings, if you make any, stay on your device inside the note (and in your own backups). Crash logs stay on your device unless you share them. Inklus' use of information received from Google APIs adheres to the Google API Services User Data Policy, including the Limited Use requirements. Questions: <https://github.com/Pedroj-64/inklus/issues>.
