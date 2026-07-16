# 🍕 Pizzería 3D — proyecto Godot

Prototipo 3D del juego idle de la pizzería hecho en **Godot 4**, pensado como
base para diseñar personajes de verdad y exportar a móvil.

Incluye la misma mecánica que la versión web:
- Cocinero que hace pizzas (toque manual o **Gestor** automático).
- **Clientes con paciencia**: si tardas, se **enojan 😠** y se van; servir a
  tiempo da **propina + combo 🔥**.
- **Reparto** con vehículos que llevan pizzas a la casa y vuelven.
- Mejoras: Cocinero, Horno, Gestor, Reparto.

> ⚠️ Los personajes actuales son **figuras de marcador de posición** (cápsulas +
> esferas). Toda la gracia de este proyecto es que puedas cambiarlas por
> personajes reales — más abajo te explico cómo.
>
> Nota: este proyecto se escribió sin poder ejecutar Godot en el entorno donde
> se creó. Si al abrir alguna línea te da error por diferencias de versión, el
> editor te la señala y se corrige en segundos. Probado conceptualmente contra
> la API de **Godot 4.3**.

---

## 1) Abrir y jugar

1. Descarga **Godot 4.3+** (gratis, sin cuenta, ~100 MB): https://godotengine.org/download
   — usa la versión **estándar** (no la de .NET/C#, aquí usamos GDScript).
2. Abre Godot → **Importar** → selecciona la carpeta `games/pizzeria-3d/`
   (el archivo `project.godot`).
3. Pulsa **F5** (o el ▶ arriba a la derecha) para jugar.

Controles: botón **¡HACER PIZZA!** (o luego el Gestor lo hace solo), y los 4
botones de mejora abajo.

> Los emojis de los botones (🍕, 👨‍🍳…) pueden verse como cuadraditos según la
> fuente por defecto de Godot. Es solo estético; se arregla asignando una fuente
> con emojis, o cambiando los textos por palabras.

---

## 2) Diseñar / meter personajes reales  ⭐

Aquí es donde el juego pasa de "prototipo" a tener personajes de verdad. Tres
caminos, de más fácil a más completo:

### A. Rápido y sin cuenta — packs listos (CC0)
- **Kenney** (https://kenney.nl/assets) → busca *"Mini Characters"* o
  *"Blocky Characters"*. Son gratis, de dominio público, y vienen en `.glb`/
  `.gltf` con animaciones básicas.
- Descomprime y arrastra los `.glb` a la carpeta `characters/` dentro de Godot
  (panel *FileSystem*).

### B. Realista y animado — Mixamo (gratis)
- Entra a **https://www.mixamo.com** (cuenta gratuita de Adobe).
- Elige un **personaje** y añade **animaciones**: `Idle`, `Walking`,
  `Cheering` (cliente feliz) y `Angry`/`Arguing` (cliente enojado).
- Descarga en **glTF (.glb)** si está disponible; si solo hay **FBX**, ábrelo en
  **Blender** (gratis) y expórtalo como `.glb` (`File → Export → glTF 2.0`).
- Arrastra el `.glb` a `characters/` en Godot.

### C. Hazlos tú
- **Blender** (gratis) para modelar y riguear, o **Ready Player Me**
  (https://readyplayer.me) para avatares listos.

### Cómo enchufarlos en el juego
El código crea a los personajes en `_make_person()` (en `Main.gd`). Para usar un
modelo real en vez de la figura de cápsulas, cambia esa función por algo así:

```gdscript
func _make_person(shirt: Color, is_chef: bool = false) -> Node3D:
    var scene := load("res://characters/chef.glb") if is_chef \
        else load("res://characters/customer.glb")
    var fig: Node3D = scene.instantiate()
    # los modelos de Mixamo/Kenney traen un AnimationPlayer:
    var anim := fig.get_node_or_null("AnimationPlayer")
    if anim: anim.play("Idle")   # usa el nombre real de la animación
    return fig
```

Y para animar reacciones (cliente feliz/enojado, cocinero lanzando masa) llama a
`anim.play("Cheering")` / `anim.play("Angry")` en `_leave()`, y `anim.play("Idle")`
o una de "cocina" en el bucle. Deja los nombres de animación que traiga tu modelo.

> Consejo: guarda una referencia al `AnimationPlayer` en la clase `Customer`
> para poder reproducir la animación correcta al servir o al enojarse.

---

## 3) Exportar a móvil / web

Primero: en Godot, **Editor → Gestionar plantillas de exportación → Descargar**.

- **Web (lo más rápido para compartir)**: `Proyecto → Exportar → Añadir → Web`.
  Genera un `index.html` que puedes subir a cualquier hosting. Ideal para probar
  en el móvil sin instalar nada.
- **Android**: necesitas el **Android SDK** y una **keystore** de firma.
  Guía oficial: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
- **iOS**: requiere **Mac + Xcode**.
  Guía: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html

---

## ¿Godot o Unity?

- **Godot** (lo que usamos): gratis y open-source, ligero, sin licencias ni
  cuotas, exporta a Android/iOS/Web. Perfecto para un idle 3D indie.
- **Unity**: tienda de assets más grande y mucho material de personajes, pero
  más pesado y con condiciones de licencia. Si te vas por Unity, el flujo de
  personajes (Mixamo/Blender/Ready Player Me) es el mismo; solo cambia el editor.

---

## Ideas de siguiente paso
- Sustituir figuras por modelos reales (Mixamo) con animaciones idle/andar/feliz/enojado.
- Furgonetas 🚚 además de motos (reparto más grande = más dinero) al subir de nivel.
- Hora punta ⏰: oleada de clientes y todo x2 un rato.
- Niveles de local que cambian el escenario 3D al ampliar.
- Guardado/carga y ganancias mientras no juegas (como en la versión web).
