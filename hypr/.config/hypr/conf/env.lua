-- Some default env vars.

hl.env("QT_QPA_PLATFORMTHEME", "kde6") -- ya tienes plasma-integration instalado, reusa el theming de KDE
hl.env("WLR_DRM_NO_ATOMIC", "1") -- some nvidia fix
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("GBM_BACKEND", "nvidia-drm")
-- Tema de cursor EXPLICITO (mismo que KDE: mint-fantome). Antes no estaba
-- declarado y el cursor solo cargaba "de chiripa" via ~/.icons/default ->
-- Inherits=mint-fantome; cualquier contexto que no cayera en ese fallback
-- (p.ej. el greeter SDDM) mostraba el cursor negro X11 crudo que se quedaba
-- pasmado en pantalla. Con el tema fijo eso ya no pasa.
hl.env("XCURSOR_THEME", "mint-fantome")
hl.env("XCURSOR_SIZE", "48")   -- igual que KDE (cursorSize=48)
hl.env("HYPRCURSOR_SIZE", "48")

-- Chrome como navegador. El default de xdg ya es google-chrome.desktop (clicks en
-- links, apps GUI); esto cubre ademas las herramientas de terminal que leen $BROWSER.
hl.env("BROWSER", "google-chrome-stable")

-- Compatibilidad KDE <-> Hyprland: fuerza a que apps (Chrome, VS Code, etc.)
-- sigan viendo un "escritorio KDE" y usando KWallet para no perder logins/cookies
-- al cambiar de sesion.
hl.env("XDG_CURRENT_DESKTOP", "KDE")
hl.env("XDG_SESSION_DESKTOP", "KDE")
hl.env("XDG_SESSION_TYPE", "wayland")

-- CLAVE para "Abrir con" en Dolphin (y cualquier menu de apps de KDE): kbuildsycoca
-- indexa las apps leyendo el menu XDG "<prefijo>applications.menu". En este sistema
-- solo existe /etc/xdg/menus/plasma-applications.menu (no el generico
-- applications.menu). Sin XDG_MENU_PREFIX, KDE busca el generico, no lo encuentra e
-- indexa 0 apps => el dialogo "Choose an application" sale VACIO para todo tipo de
-- archivo. En Plasma real esta var ya viene puesta a "plasma-"; aqui hay que ponerla.
hl.env("XDG_MENU_PREFIX", "plasma-")

-- CLAVE para VS Code/Chrome: sin KDE_SESSION_VERSION, Chromium asume "KDE4" y le
-- habla al object path viejo /modules/kwalletd (que kwalletd6 NO implementa) =>
-- "No such object path" => "OS keyring not available", aunque el wallet este
-- abierto. Con =6 elige el backend kwallet6 correcto (/modules/kwalletd6). En
-- Plasma real estas dos ya vienen puestas; aqui hay que ponerlas a mano.
hl.env("KDE_SESSION_VERSION", "6")
hl.env("KDE_FULL_SESSION", "true")
