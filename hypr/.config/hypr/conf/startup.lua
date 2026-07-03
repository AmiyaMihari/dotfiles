hl.on("hyprland.start", function()
  -- Compatibilidad KDE <-> Hyprland: arranca kwalletd6 temprano y desbloqueado
  -- para que Chrome/VS Code/etc. no pierdan sesiones al cambiar de DE.
  --
  -- Toda la logica vive en scripts/kwallet-init.sh (evita comillas anidadas y
  -- espera a que el wallet abra). Resumen del bug que arregla:
  --   * kwalletd6 se activaba "lazy" ~90s tarde: su 1er arranque por dbus
  --     crasheaba ("no outputs") y systemd aplicaba backoff. VS Code, abierto en
  --     esa ventana, veia "no keyring" y cerraba sesion.
  --   * pam_kwallet_init NO sirve aqui: pam_kwallet5 lanza kwalletd5, que no esta
  --     instalado (solo kwalletd6).
  -- El script espera outputs, propaga PAM_KWALLET5_LOGIN, fuerza el arranque y
  -- espera a que kdewallet quede abierto.
  hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/kwallet-init.sh")

  hl.exec_cmd("sh -c 'waybar &'")
  hl.exec_cmd("sh -c 'swaync &'")
  hl.exec_cmd("awww-daemon")

  -- Mismo wallpaper por monitor que ya tienes en KDE
  hl.exec_cmd("awww img -o DP-4 \"$HOME/Pictures/wallpapers/539e3213c1e110f5bca5f07e0a67f8a5.jpg\" --transition-type none")
  hl.exec_cmd("awww img -o HDMI-A-2 \"$HOME/Pictures/wallpapers/943d76a9c991937d67a95d405d7bc835.jpg\" --transition-type none")
end)
