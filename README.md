# dotfiles

Mis dotfiles de Hyprland, gestionados con [GNU Stow](https://www.gnu.org/software/stow/).

Basado en los dotfiles de [maxhu08/dotfiles](https://github.com/maxhu08/dotfiles), adaptados para:

- Convivir con una sesión de KDE Plasma en la misma máquina (mismo backend de KWallet,
  variables `XDG_CURRENT_DESKTOP`/`XDG_SESSION_DESKTOP` fingidas a `KDE` para que
  Chrome, VS Code y demás apps Electron no pierdan sesiones/logins al cambiar de sesión)
- Mi propio hardware: monitores, sensor de temperatura, terminal (Konsole), file manager
  (Dolphin), wallpapers y mouse

## Instalación

```bash
sudo pacman -S --needed stow waybar hyprlock awww wlogout grim slurp ttf-jetbrains-mono-nerd blueman

git clone https://github.com/AmiyaMihari/dotfiles ~/dotfiles
cd ~/dotfiles
stow hypr waybar wofi wlogout
```

## Estructura

- `hypr/` — config de Hyprland (Lua, `hyprland.lua` + `conf/*.lua`), hyprlock
- `waybar/` — barra superior
- `wofi/` — launcher de apps
- `wlogout/` — menú de apagado/logout

## Guardar y Actualizar Cambios

Como todo en `~/.config/{hypr,waybar,wofi,wlogout}` son symlinks hacia esta carpeta,
editar cualquiera de los dos lados es lo mismo. El flujo normal para guardar cambios:

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
stow -R hypr waybar wofi wlogout   # re-verifica los symlinks, no hace nada si ya estaban bien
```

## Notas

- El fix de KWallet vive en `hypr/.config/hypr/conf/env.lua` y `conf/startup.lua`
- Los monitores están hardcodeados a mis dos pantallas (`DP-4` principal, `HDMI-A-2`
  secundaria) — si cambias de hardware, edita `hypr/.config/hypr/conf/monitors.lua`
  (puedes ver los nombres reales con `kscreen-doctor -o` desde KDE o `hyprctl monitors`
  desde Hyprland)
- Los wallpapers no están en este repo, viven en `~/Pictures/wallpapers/` y se referencian
  por ruta absoluta desde `hypr/.config/hypr/conf/startup.lua` y `hyprlock.conf`
