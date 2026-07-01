-- Some default env vars.

hl.env("QT_QPA_PLATFORMTHEME", "kde6") -- ya tienes plasma-integration instalado, reusa el theming de KDE
hl.env("WLR_DRM_NO_ATOMIC", "1") -- some nvidia fix
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Compatibilidad KDE <-> Hyprland: fuerza a que apps (Chrome, VS Code, etc.)
-- sigan viendo un "escritorio KDE" y usando KWallet para no perder logins/cookies
-- al cambiar de sesion.
hl.env("XDG_CURRENT_DESKTOP", "KDE")
hl.env("XDG_SESSION_DESKTOP", "KDE")
hl.env("XDG_SESSION_TYPE", "wayland")
