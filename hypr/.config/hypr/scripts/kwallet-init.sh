#!/bin/sh
# kwallet-init.sh -- arranca kwalletd6 temprano y DESBLOQUEADO bajo Hyprland.
#
# Problema que resuelve:
#   En KDE puro, kwalletd6 arranca al login y se desbloquea con la contrasena
#   que pam_kwallet capturo en SDDM. Bajo Hyprland eso NO pasa solo:
#
#   1) kwalletd6 se activa "lazy" por dbus recien cuando algo lo pide. El primer
#      intento suele crashear ("There are no outputs") por arrancar antes de que
#      el compositor tenga monitores; systemd lo marca fallido y aplica backoff,
#      asi que el arranque bueno llega ~90s tarde. Si VS Code/Chrome consultan el
#      keyring en esa ventana, ven "OS keyring not available" y pierden la sesion.
#
#   2) pam_kwallet_init NO sirve en este sistema: pam_kwallet5 intenta lanzar
#      kwalletd5, que no esta instalado (solo hay kwalletd6).
#
# Estrategia: propagar el entorno (incluido el socket de PAM para auto-unlock),
# esperar a que el compositor tenga outputs, arrancar kwalletd6 nosotros mismos
# (evitando el crash+backoff) y ESPERAR a que el wallet quede abierto.

set -u

log() { printf '%s kwallet-init: %s\n' "$(date '+%H:%M:%S')" "$*" >> "${XDG_RUNTIME_DIR:-/tmp}/kwallet-init.log"; }

WALLET="kdewallet"

# 1) Propaga el entorno de la sesion a dbus y systemd. Incluimos
#    PAM_KWALLET5_LOGIN para que el kwalletd6 activado por dbus herede el socket
#    de un solo uso que dejo pam_kwallet y se auto-desbloquee sin dialogo.
# Incluye KDE_SESSION_VERSION/KDE_FULL_SESSION: son CLAVE para que Chromium/Electron
# elija el backend kwallet6 (/modules/kwalletd6). Sin ellas en el entorno de
# activacion, un VS Code/Chrome lanzado por dbus/systemd (portal, "abrir con" de
# Dolphin) asume KDE4 y falla el keyring aunque el wallet este abierto. XDG_MENU_PREFIX
# va tambien para que apps KDE activadas por esa via encuentren el menu (ver
# docs/dolphin-open-with-empty.md).
VARS="DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP DBUS_SESSION_BUS_ADDRESS XDG_RUNTIME_DIR KDE_SESSION_VERSION KDE_FULL_SESSION XDG_MENU_PREFIX"
[ -n "${PAM_KWALLET5_LOGIN:-}" ] && VARS="$VARS PAM_KWALLET5_LOGIN"
dbus-update-activation-environment --systemd $VARS 2>/dev/null
systemctl --user import-environment $VARS 2>/dev/null
log "env propagado ($VARS)"

# 2) Espera a que Hyprland tenga al menos un output (evita el crash "no outputs").
i=0
while [ "$i" -lt 50 ]; do
  if hyprctl monitors -j 2>/dev/null | grep -q '"id"'; then break; fi
  i=$((i + 1)); sleep 0.2
done
log "outputs listos tras ${i} intentos"

# 3) Camino PAM: si el socket de un solo uso sigue vivo, dispara que pam_kwallet
#    lance kwalletd con --pam-login (ya desbloqueado). Inofensivo si falla.
if [ -n "${PAM_KWALLET5_LOGIN:-}" ] && [ -S "$PAM_KWALLET5_LOGIN" ]; then
  /usr/lib/pam_kwallet_init >/dev/null 2>&1 && log "pam_kwallet_init disparado"
fi

# 4) Arranque eager por dbus (idempotente: si ya corre, no hace nada). El
#    kwalletd6 resultante se auto-desbloquea leyendo el socket de PAM del entorno.
busctl --user call org.freedesktop.DBus /org/freedesktop/DBus \
  org.freedesktop.DBus StartServiceByName su org.kde.kwalletd6 0 >/dev/null 2>&1
log "kwalletd6 solicitado via dbus"

# 5) Espera a que el wallet quede ABIERTO antes de devolver el control, para que
#    cuando el usuario abra VS Code/Chrome el keyring ya este disponible.
i=0
while [ "$i" -lt 50 ]; do
  if [ "$(qdbus6 org.kde.kwalletd6 /modules/kwalletd6 org.kde.KWallet.isOpen "$WALLET" 2>/dev/null)" = "true" ]; then
    log "wallet '$WALLET' ABIERTO (ok)"
    exit 0
  fi
  i=$((i + 1)); sleep 0.2
done
log "AVISO: wallet '$WALLET' NO abrio tras la espera (revisa contrasena de login vs wallet)"
exit 0
