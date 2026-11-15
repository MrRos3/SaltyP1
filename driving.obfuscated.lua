-- SALTY driving module (disabled)
-- The driving/autopilot tab was removed: its per-frame autopilot, car-noclip and
-- obstacle-phasing loops were the source of the in-game lag.
-- main.obfuscated.lua still fetches this file and calls the returned installer, so the
-- loader's integrity markers stay valid. The installer below intentionally does nothing:
-- no Drive tab is added and no loops are started.
return function(_window, _state)
    return
end
