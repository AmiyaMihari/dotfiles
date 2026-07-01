-- Simplificado: 10 workspaces normales (1-10), sin asumir nombres de monitor
-- especificos (el repo original asumia 3 monitores fijos DP-1/DP-2/DP-3).

for i = 1, 9 do
  local key = tostring(i)

  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = key }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = key }))
end

hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = "10" }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = "10" }))
