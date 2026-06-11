# 📱 Pokédex Flutter (Infinite Scroll & Expandable Cards)

¡Una aplicación móvil de Pokédex moderna y eficiente construida con **Flutter** y **Material 3**! La aplicación consume datos en tiempo real desde la API pública [PokeAPI](https://pokeapi.co/).

A diferencia de las Pokédex tradicionales, esta versión ofrece una experiencia de usuario fluida al mostrar los detalles de cada Pokémon directamente en la lista principal mediante tarjetas desplegables, optimizando el consumo de red.

---

## ✨ Características Principales

* **⚡ Carga Bajo Demanda (Lazy Loading):** Los detalles avanzados de la API de un Pokémon solo se descargan cuando el usuario expande su tarjeta.
* **🔄 Scroll Infinito Nativo:** Carga dinámica de Pokémon en lotes de 5 en 5 utilizando `NotificationListener` (sin necesidad de controladores pesados).
* **🔍 Buscador Inteligente:** Permite buscar cualquier Pokémon por su nombre o ID exacto, mostrando el resultado al instante en una ventana flotante.
* **🎨 Interfaz Adaptativa:** Colores de tarjetas que cambian dinámicamente según el tipo elemental del Pokémon (Fuego, Agua, Planta, etc.).
* **🧠 Retención de Estado:** Uso de `PageStorageKey` para evitar que las tarjetas expandidas se cierren accidentalmente al hacer scroll.

---

## 📸 Capturas de Pantalla (Estructura Visual)

| Lista General e Infinite Scroll | Tarjeta Expandida (Detalles) | Buscador en Acción |
| <img width="738" height="1600" alt="image" src="https://github.com/user-attachments/assets/e4fd663f-6c83-4d73-bc3e-0457c7cca703" /> |
| <img width="738" height="1600" alt="image" src="https://github.com/user-attachments/assets/4256785b-18e0-423b-9d9f-0405d44f351c" /> | 
| Tarjetas compactas con ID, Nombre y Sprite oficial. | Despliegue fluido con Stats Base, Tipos, Altura y Peso. | Diálogo emergente con la información del Pokémon buscado. |

---

## 🛠️ Tecnologías y Paquetes Utilizados

* [Flutter SDK](https://flutter.dev/) - Framework de desarrollo UI.
* [Http](https://pub.dev/packages/http) - Para realizar las peticiones de red a la PokeAPI.
* [Material 3](https://m3.material.io/) - Sistema de diseño moderno con soporte de semillas de color (`Colors.red`).

---

## 🚀 Instalación y Configuración

Sigue estos pasos para clonar y ejecutar el proyecto localmente:

### Prerequisites
* Tener instalado [Flutter](https://docs.flutter.dev/get-started/install) (versión compatible con Dart 3).
* Un emulador (Android/iOS) o un dispositivo físico conectado.

### Pasos

1. **Clonar el repositorio:**
   ```bash
   git clone [https://github.com/TU_USUARIO/TU_REPOSITORIO.git](https://github.com/TU_USUARIO/TU_REPOSITORIO.git)
   cd TU_REPOSITORIO
