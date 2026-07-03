hl.on("hyprland.start", function()
  -- Compatibilidad KDE <-> Hyprland: propaga el entorno a dbus y desbloquea
  -- KWallet para que Chrome/VS Code/etc. no pierdan sesiones al cambiar de DE.
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  hl.exec_cmd("/usr/lib/pam_kwallet_init")
  -- kwalletd6 normalmente se activa "perezosamente" (recien cuando algo lo
  -- pide via dbus), lo que tarda ~15-20s tras el login. Si Chrome/VS Code
  -- lo piden antes de eso, fallan una vez y se quedan pensando que no hay
  -- keyring (no reintentan). Forzamos el arranque aqui para que ya este
  -- listo desde el inicio de la sesion.
  hl.exec_cmd(
    "busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus StartServiceByName su org.kde.kwalletd6 0"
  )

  hl.exec_cmd("sh -c 'waybar &'")
  hl.exec_cmd("sh -c 'swaync &'")
  hl.exec_cmd("awww-daemon")

  -- Mismo wallpaper por monitor que ya tienes en KDE
  hl.exec_cmd("awww img -o DP-4 \"$HOME/Pictures/wallpapers/539e3213c1e110f5bca5f07e0a67f8a5.jpg\" --transition-type none")
  hl.exec_cmd("awww img -o HDMI-A-2 \"$HOME/Pictures/wallpapers/943d76a9c991937d67a95d405d7bc835.jpg\" --transition-type none")
end)
