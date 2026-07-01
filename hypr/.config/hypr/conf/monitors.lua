-- Layout de 2 monitores, tomado de tu config actual de KDE (kscreen-doctor -o):
-- DP-4   = principal (Xiaomi), 1920x1080@100Hz, izquierda (0,0)
-- HDMI-A-2 = secundario (HP), 1920x1080@60Hz, a la derecha (1920,0)

hl.monitor({ output = "DP-4", mode = "1920x1080@100", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-2", mode = "1920x1080@60", position = "1920x0", scale = 1 })
