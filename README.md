# dotfiles

Mis dotfiles de Hyprland, gestionados con [GNU Stow](https://www.gnu.org/software/stow/).

Basado en los dotfiles de [maxhu08/dotfiles](https://github.com/maxhu08/dotfiles), con la
barra/panel de notificaciones adaptada del rice de [ViegPhunt](https://github.com/ViegPhunt/Dotfiles),
y ajustado para:

- Convivir con una sesión de KDE Plasma en la misma máquina (mismo backend de KWallet,
  variables `XDG_CURRENT_DESKTOP`/`XDG_SESSION_DESKTOP` fingidas a `KDE` para que
  Chrome, VS Code y demás apps Electron no pierdan sesiones/logins al cambiar de sesión)
- Mi propio hardware: monitores, sensor de temperatura, terminal (Konsole), file manager
  (Dolphin), wallpapers y mouse

## Instalación

Paquetes de repos oficiales:

```bash
sudo pacman -S --needed stow hyprlock awww wlogout grim slurp ttf-jetbrains-mono-nerd \
    blueman waybar swaync cava adw-gtk-theme
```

Paquetes de AUR:

```bash
paru -S --needed candy-icons-git overskride-bin
```

`candy-icons` normalmente ya viene bajado por KDE en `~/.local/share/icons/candy-icons`
(vía "Obtener iconos nuevos" de System Settings) — el paquete AUR es solo para que una
máquina nueva sin KDE también lo tenga.

Clonar y symlinkear:

```bash
git clone https://github.com/AmiyaMihari/dotfiles ~/dotfiles
cd ~/dotfiles
stow hypr waybar swaync colors cava wofi wlogout
```

Aplicar el tema GTK (una sola vez, queda guardado por gsettings):

```bash
gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"
gsettings set org.gnome.desktop.interface icon-theme "candy-icons"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
```

## Estructura

- `hypr/` — config de Hyprland (Lua, `hyprland.lua` + `conf/*.lua`), hyprlock
- `waybar/` — barra superior
- `swaync/` — panel de notificaciones/control (wifi, bluetooth, volumen, brillo, DND),
  se abre con click en el reloj o en red de la waybar (`swaync-client -t -sw`)
- `colors/` — paleta de colores compartida (Catppuccin Mocha) que importan `waybar/` y `swaync/`
- `cava/` — visualizador de audio de terminal, misma paleta
- `wofi/` — launcher de apps
- `wlogout/` — menú de apagado/logout, con los íconos circulares de ViegPhunt

## Guardar y Actualizar Cambios

Como todo en `~/.config/{hypr,waybar,swaync,colors,cava,wofi,wlogout}` son symlinks hacia
esta carpeta, editar cualquiera de los dos lados es lo mismo. El flujo normal para guardar
cambios:

```bash
cd ~/dotfiles
git add -A
git commit -m "describe qué cambiaste"
git push
```

Si agregas un paquete nuevo (otra carpeta con su propio `.config/algo`), solo falta
symlinkearlo una vez con stow:

```bash
cd ~/dotfiles
stow nombre-del-paquete
```

Para traer cambios hechos desde otra máquina (o si editaste algo directo en GitHub):

```bash
cd ~/dotfiles
git pull
stow -R hypr waybar swaync colors cava wofi wlogout   # re-verifica symlinks, no hace nada si ya estaban bien
```

## Notas

- El fix de KWallet vive en `hypr/.config/hypr/conf/env.lua` y `conf/startup.lua`
- Los monitores están hardcodeados a mis dos pantallas (`DP-4` principal, `HDMI-A-2`
  secundaria) en `hypr/.config/hypr/conf/monitors.lua` — si cambias de hardware, edita ese
  archivo (puedes ver los nombres reales con `kscreen-doctor -o` desde KDE o
  `hyprctl monitors` desde Hyprland). Ahí mismo están las reglas `workspace_rule` que
  asignan el workspace 1 al monitor derecho y el 2 al izquierdo (a propósito, invertido
  del orden de declaración).
- Los wallpapers no están en este repo, viven en `~/Pictures/wallpapers/` y se referencian
  por ruta absoluta desde `hypr/.config/hypr/conf/startup.lua` y `hyprlock.conf`
- `swaync/config.json` tiene los `update-command` de los toggles de wifi/bluetooth escritos
  sin el wrapper redundante `sh -c '...'` del repo original — swaync ya envuelve el comando
  en su propio `sh -c "..."` (con comillas dobles), así que cualquier `"` sin escapar rompía
  el estado mostrado (mostraba bluetooth/wifi apagados aunque estuvieran encendidos)
