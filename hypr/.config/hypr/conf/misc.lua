hl.config({
  misc = {
    -- See https://wiki.hyprland.org/Configuring/Variables/ for more
    force_default_wallpaper = -1,
    -- Silencia el aviso "XDG_CURRENT_DESKTOP managed externally": lo forzamos
    -- a "KDE" a propósito en env.lua (KWallet/Chrome), así que el aviso es esperado.
    disable_xdg_env_checks = true,
  },
  cursor = {
    -- No hay ningún tema hyprcursor instalado (solo el XCursor mint-fantome),
    -- así que desactivamos hyprcursor para que Hyprland use directo el tema
    -- XCURSOR_THEME y no caiga en el fallback (que renderizaba el cursor negro).
    enable_hyprcursor = false,
  },
})

-- Example per-device config
-- See https://wiki.hyprland.org/Configuring/Keywords/#executing for more
-- hl.device({
--   name = "epic-mouse-v1",
--   sensitivity = -0.5,
-- })
