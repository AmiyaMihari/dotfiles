# El diálogo "Abrir con" de Dolphin sale vacío bajo Hyprland

## Síntoma

En **KDE Plasma** todo abre con su app correspondiente. En **Hyprland** en la misma
máquina, al hacer "Abrir con…" (o al abrir un archivo sin default) Dolphin muestra el
diálogo *"Choose an application to open …"* pero el **desplegable sale completamente
vacío** — no aparece ninguna app. Pasa con **todos** los tipos de archivo (PDF,
imágenes, documentos), no solo uno.

No es un problema de la asociación de cada tipo. La asociación XDG estaba bien:

```bash
$ gio mime application/pdf
Default application for "application/pdf": google-chrome.desktop
```

El problema es que **KDE no veía ninguna app en absoluto** para ofrecer.

## Contexto

KDE no lee los `.desktop` de `/usr/share/applications` directamente. `kbuildsycoca6`
(el que construye la caché `ksycoca` que consultan Dolphin y todo KDE) indexa las
apps recorriendo el **menú XDG** `<prefijo>applications.menu`, donde `<prefijo>` sale
de la variable de entorno **`XDG_MENU_PREFIX`**.

En este sistema **solo existe** `/etc/xdg/menus/plasma-applications.menu`; el genérico
`applications.menu` **no está** (lo provee el paquete de Plasma con el prefijo puesto).

## Causa raíz

En Plasma real, la sesión exporta `XDG_MENU_PREFIX=plasma-` automáticamente. En
Hyprland **no estaba puesta** (junto con `XDG_CONFIG_DIRS`, ambas `UNSET` — verificado
leyendo `/proc/$(pgrep -x Hyprland)/environ`).

Sin `XDG_MENU_PREFIX`, `kbuildsycoca6` buscaba `applications.menu` (genérico,
inexistente), no lo encontraba e **indexaba 0 apps** → caché vacía de aplicaciones →
diálogo "Abrir con" vacío para todo.

Comprobado con `kbuildsycoca6 --menutest` (imprime las apps que encuentra en el menú):

| Entorno                              | Apps encontradas |
| ------------------------------------ | ---------------- |
| Como estaba la sesión (sin la var)   | **0**            |
| Solo `XDG_MENU_PREFIX=plasma-`       | **116** ✅       |
| Solo `XDG_CONFIG_DIRS=/etc/xdg`      | 0                |
| Ambas                                | 116              |

La variable **decisiva es `XDG_MENU_PREFIX=plasma-`** por sí sola; `XDG_CONFIG_DIRS`
no hace falta (el default `/etc/xdg` ya se aplica). El tamaño de la caché también lo
refleja: `~/.cache/ksycoca6_*` pasa de ~236 KB (sin apps) a ~600 KB (con las 116).

## Solución

### `hypr/.config/hypr/conf/env.lua`

```lua
hl.env("XDG_MENU_PREFIX", "plasma-")
```

Con esto `kbuildsycoca6` encuentra `plasma-applications.menu` e indexa todas las apps.

> **Requiere relogin.** La variable se aplica al arrancar la sesión. `hyprctl keyword
> env …` **no** funciona con el parser Lua de esta config (`"keyword can't work with
> non-legacy parsers"`), así que no se puede inyectar en caliente al Hyprland ya
> corriendo — hay que cerrar sesión y volver a entrar (o reiniciar Hyprland).

Tras el relogin, si el default de un tipo ya está puesto (p. ej. PDF →
`google-chrome.desktop` en `~/.config/mimeapps.list`), el archivo abre directo sin
preguntar; y el diálogo "Abrir con" lista todas las apps para cualquier tipo.

## Cómo verificar

```bash
# La var debe estar puesta en la sesión:
echo "$XDG_MENU_PREFIX"                       # -> plasma-

# kbuildsycoca debe encontrar las apps (no 0):
kbuildsycoca6 --menutest | wc -l              # -> ~116
kbuildsycoca6 --menutest | grep -i chrome     # -> Internet/  google-chrome.desktop

# La caché debe ser la "llena", no la vacía:
stat -c%s ~/.cache/ksycoca6_*                 # -> ~600000, no ~236000
```

Luego, en Dolphin, "Abrir con…" debe mostrar la lista poblada para cualquier archivo.

## Si vuelve a salir vacío (diagnóstico)

```bash
# ¿La var llegó a la sesión y a los procesos GUI?
tr '\0' '\n' < /proc/$(pgrep -x Hyprland)/environ | grep XDG_MENU_PREFIX

# ¿Qué archivos de menú existen? (aquí solo el plasma-)
ls /etc/xdg/menus/

# Forzar reconstrucción de la caché a mano (con la var):
XDG_MENU_PREFIX=plasma- kbuildsycoca6 --noincremental
```

## Referencias

- Especificación del menú XDG (`XDG_MENU_PREFIX`, `<prefix>applications.menu`):
  freedesktop.org *Desktop Menu Specification*.
- `plasma-applications.menu` lo provee el paquete `plasma-workspace`.
- `kbuildsycoca6` / `ksycoca`: paquete `kservice` de KDE Frameworks 6.
