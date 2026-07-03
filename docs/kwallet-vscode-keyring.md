# VS Code / Chrome pierden la sesión bajo Hyprland ("OS keyring is not available")

## Síntoma

En **KDE Plasma** VS Code (y Chrome/Brave/apps Electron) mantienen sus logins y
tokens. Al iniciar sesión en **Hyprland** en la misma máquina, VS Code muestra:

> ⓧ You're running in a KDE environment but the OS keyring is not available for
> encryption. Ensure you have kwallet running.

…y aparece **deslogueado**: cuentas, tokens y "sign in" se pierden. El secreto sí
existía (VS Code lo había guardado antes en `kdewallet`, carpeta `Code Keys`),
pero la app no puede leerlo, cae al almacenamiento `basic` vacío y parece cerrada.

## Contexto

Estos dotfiles hacen que Hyprland finja ser "KDE" (`XDG_CURRENT_DESKTOP=KDE`,
etc.) para reutilizar **KWallet** como backend de secretos y **no perder logins
al alternar entre la sesión de KDE y la de Hyprland**. El daemon en el sistema es
`kwalletd6` (Plasma 6); `kwalletd5` **no** está instalado.

## Causa raíz (había DOS problemas)

### 1. Faltaba `KDE_SESSION_VERSION` — *la causa principal*

Chromium/Electron eligen el backend de secretos así:

1. Miran `XDG_CURRENT_DESKTOP`. Contiene `KDE` → backend KWallet.
2. Miran `KDE_SESSION_VERSION` para decidir **qué versión** de KWallet y, con
   ello, **qué object path de D-Bus** usar:
   - `6` → `org.kde.kwalletd6` en `/modules/kwalletd6`
   - `5` → `.../kwalletd5` en `/modules/kwalletd5`
   - **sin la variable → asume KDE4** → `org.kde.kwalletd` en `/modules/kwalletd`

En Plasma real `KDE_SESSION_VERSION=6` viene puesta. En Hyprland **no**, así que
Chromium asumía KDE4 y le hablaba a `/modules/kwalletd`, que `kwalletd6` **no
implementa**:

```
$ qdbus6 org.kde.kwalletd6 /modules/kwalletd org.kde.KWallet.isEnabled
Error: org.freedesktop.DBus.Error.UnknownObject
No such object path '/modules/kwalletd'

$ qdbus6 org.kde.kwalletd6 /modules/kwalletd6 org.kde.KWallet.isEnabled
true
```

Resultado: la init del keyring fallaba **aunque el wallet estuviera abierto y
desbloqueado**. Este era el motivo por el que el error persistía pasara lo que
pasara con el daemon.

### 2. `kwalletd6` arrancaba ~90 s tarde (secundario)

Bajo Hyprland `kwalletd6` no se lanzaba al login; se activaba "lazy" por D-Bus
recién cuando algo lo pedía. Peor: el primer intento **crasheaba** por arrancar
antes de que el compositor tuviera monitores:

```
kwalletd6: There are no outputs - creating placeholder screen
dbus-...kwalletd6@2.service: Main process exited, code=exited, status=1/FAILURE
```

systemd lo marcaba fallido y aplicaba backoff, así que el arranque bueno llegaba
~90 s después del login. Si VS Code se abría en esa ventana, no había keyring.

> Nota: `pam_kwallet_init` **no** ayuda en este sistema, porque `pam_kwallet5.so`
> intenta lanzar `kwalletd5`, que no está instalado (solo hay `kwalletd6`).

## Solución

### `hypr/.config/hypr/conf/env.lua`

```lua
hl.env("KDE_SESSION_VERSION", "6")
hl.env("KDE_FULL_SESSION", "true")
```

Con esto Chromium elige el backend **kwallet6** y habla a `/modules/kwalletd6`.
Arregla el problema principal.

> **Gotcha (la causa más común de "no queda"):** las variables `hl.env` de `env.lua`
> solo se aplican al **arrancar** la sesión de Hyprland. Si editas `env.lua` y sigues
> en la misma sesión, los apps ya abiertos (y los que lances) **conservan el entorno
> viejo** — VS Code seguirá sin `KDE_SESSION_VERSION` y fallando. `hyprctl reload`
> re-exporta las vars a los apps que lances **después** del reload, pero VS Code
> **ya abierto no las recibe**: hay que **cerrarlo por completo y reabrirlo** (o
> reloguear). Verifica el entorno real de un proceso con
> `tr '\0' '\n' < /proc/$(pgrep -x waybar|head -1)/environ | grep KDE_SESSION_VERSION`.

### `hypr/.config/hypr/scripts/kwallet-init.sh` (llamado desde `conf/startup.lua`)

Al iniciar Hyprland:

1. Propaga el entorno a dbus/systemd, **incluido `PAM_KWALLET5_LOGIN`** (para que
   `kwalletd6` se auto-desbloquee leyendo el socket de un solo uso que dejó
   `pam_kwallet` en el login, sin diálogo) y **`KDE_SESSION_VERSION`/`KDE_FULL_SESSION`**
   (para que un VS Code/Chrome lanzado por activación dbus/systemd —portal, "abrir con"
   de Dolphin— también elija el backend kwallet6, no solo los que lanza Hyprland).
2. **Espera a que Hyprland tenga outputs** antes de arrancar `kwalletd6` → evita
   el crash + backoff que causaba el retraso de 90 s.
3. Fuerza el arranque de `kwalletd6` y **espera a que `kdewallet` quede abierto**
   antes de devolver el control.

Deja un log en `$XDG_RUNTIME_DIR/kwallet-init.log` para depurar.

## Cómo verificar

Tras un login limpio en Hyprland:

```bash
# El wallet debe estar ABIERTO poco después del login:
cat "$XDG_RUNTIME_DIR/kwallet-init.log"        # -> "wallet 'kdewallet' ABIERTO (ok)"
qdbus6 org.kde.kwalletd6 /modules/kwalletd6 org.kde.KWallet.isOpen kdewallet   # -> true

# Chromium/Electron deben ver KDE6:
env | grep -E '^KDE_(SESSION_VERSION|FULL_SESSION)='   # KDE_SESSION_VERSION=6 ...

# El object path correcto responde:
qdbus6 org.kde.kwalletd6 /modules/kwalletd6 org.kde.KWallet.isEnabled          # -> true
```

Luego abre VS Code: no debe aparecer el aviso del keyring y la sesión persiste.

## Comandos de diagnóstico útiles (si vuelve a fallar)

```bash
# ¿Quién provee cada servicio de secretos?
busctl --user list | grep -iE 'kwallet|secret'

# ¿kwalletd6 arrancó con --pam-login o lazy por dbus?
cat /proc/$(pgrep -x kwalletd6)/cmdline | tr '\0' ' '

# Historial de arranques/crashes de kwalletd6:
journalctl --user -b | grep -iE 'kwallet|pam_kwallet'

# ¿Hay dos sesiones gráficas a la vez? (no debería)
loginctl list-sessions
```

## Referencias

- Chromium, selección de backend de secretos: `base/nix/xdg_util.cc`
  (`GetDesktopEnvironment` lee `KDE_SESSION_VERSION`) y
  `components/os_crypt/sync/key_storage_util_linux.cc`.
- `kwallet-pam` (provee `pam_kwallet5.so` y `/usr/lib/pam_kwallet_init`).
- Paquete `kwallet` 6.x (provee `kwalletd6` y `ksecretd`).
