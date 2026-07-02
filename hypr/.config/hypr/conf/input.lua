-- For all categories, see https://wiki.hyprland.org/Configuring/Variables/

hl.config({
  input = {
    kb_layout = "latam",
    kb_variant = "",
    kb_model = "",
    kb_options = "",
    kb_rules = "",

    follow_mouse = 1,

    touchpad = {
      natural_scroll = false,
    },

    -- Ajustado a mano probando en vivo con hyprctl eval hasta que se sintio bien
    sensitivity = 0.1,
    accel_profile = "flat",
  },
})
