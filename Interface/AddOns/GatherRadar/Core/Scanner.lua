local ADDON_NAME, ns = ...

-- ==========================================
-- LECTURA DEL MINIMAPA AL PASAR EL RATON
-- ==========================================
-- Blizzard ya no deja leer el minimapa sin el raton: un raton falso
-- (Minimap:UpdateMouseoverAtPoint) recibe el nombre secreto y no es fiable.
-- Con el raton de verdad el juego si da el nombre. Al pasar el raton por el
-- punto de Buscar hierbas, minerales, tesoros o peces, su nodo queda como
-- "esta ahora" y se guarda (o se corrige) en el sitio del punto.
--
-- En el minimapa lo identificado asi sale con su icono unos minutos; lo
-- recordado, como un aro hueco (UI/MinimapPins.lua).
-- ponytail: solo lo que el jugador toca con el raton; lo que nadie mira se
-- queda como recordado.
--
-- PENDIENTE (cuando la API lo permita): si Blizzard vuelve a dar el nombre del
-- minimapa a un raton falso (C_TooltipInfo.GetMinimapMouseover deja de ser
-- secreto tras Minimap:UpdateMouseoverAtPoint), volver a la deteccion
-- automatica: el escaner de rejilla de 75631cb (Core/Scanner.lua) y el
-- minimapa con solo lo detectado ahora (3827ebd, UI/MinimapPins.lua).
-- Probado en Forever (noviembre de 2026): el nombre llega secreto y el raton
-- falso no es fiable (con SetUsingSoftCursor el tooltip se queda pegado).

local EVERY = 0.1 -- segundos entre lecturas mientras el raton esta en el minimapa
local LIVE = 180 -- segundos que un nodo visto cuenta como "esta ahi ahora"

local elapsedSum = 0
local lastSeen -- ids del ultimo tooltip leido: el mismo punto no se procesa dos veces
ns.live = {}

local function LiveKey(kind, map, coord) return kind .. map .. ":" .. coord end

function ns.IsLive(kind, map, coord)
    local t = ns.live[LiveKey(kind, map, coord)]
    return t and GetTime() - t < LIVE
end

function ns.MarkLive(kind, map, coord) ns.live[LiveKey(kind, map, coord)] = GetTime() end
function ns.ClearLive(kind, map, coord) ns.live[LiveKey(kind, map, coord)] = nil end

-- Quita colores y texturas de una linea del tooltip
local function Clean(text)
    text = text:gsub("|A.-|a", ""):gsub("|T.-|t", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return text:match("^%s*(.-)%s*$")
end

-- Modo debug: que se ha leido, sin repetir el mismo mensaje
local lastDebug
local function Debug(msg)
    if ns.db.debug and msg ~= lastDebug then
        lastDebug = msg
        print(ns.PREFIX .. "hover: " .. msg)
    end
end

-- IDs de los nodos que nombra el tooltip del minimapa (puede haber varios)
local function ReadTooltip()
    local data = C_TooltipInfo.GetMinimapMouseover()
    if not data then return nil end
    if issecretvalue(data) then return nil, Debug("secret data") end
    local lines = data.lines
    if not lines or issecretvalue(lines) then return nil, Debug("no lines / secret lines") end
    local ids = {}
    for _, line in ipairs(lines) do
        local text = line.leftText
        if text and issecretvalue(text) then Debug("secret text") end
        if text and not issecretvalue(text) then
            for name in text:gmatch("[^\n]+") do
                local id = ns.IdByName(Clean(name))
                local kind = id and ns.KindOf(id)
                Debug(("[%s] -> %s %s"):format(Clean(name), tostring(id), tostring(kind)))
                if kind and ns.db.kinds[kind] then ids[#ids + 1] = id end
            end
        end
    end
    return ids
end

-- Coordenadas del mapa del jugador bajo el raton, o nil
local function CursorOnMap()
    local map, px, py = ns.PlayerPosition()
    local radius = ns.ViewRadius()
    if not (map and radius) then return nil end
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local mx, my = Minimap:GetCenter()
    local yards = radius / (Minimap:GetWidth() / 2)
    local east, north = (cx / scale - mx) * yards, (cy / scale - my) * yards
    if GetCVar("rotateMinimap") == "1" then
        local f = ns.Facing()
        if not f then return nil end
        east, north = east * math.cos(f) - north * math.sin(f), east * math.sin(f) + north * math.cos(f)
    end
    local w, h = ns.MapSize(map)
    local x, y = px + east / w, py - north / h
    if x < 0 or x >= 1 or y < 0 or y >= 1 then return nil end
    return map, x, y
end

local function Read()
    local ids = ReadTooltip()
    local key = ids and #ids > 0 and table.concat(ids, ",") or nil
    if key == lastSeen then return end
    lastSeen = key
    if not key then return end
    local map, x, y = CursorOnMap()
    if not map then return Debug("no map position") end
    Debug(("%s at %.4f, %.4f"):format(key, x, y))
    for _, id in ipairs(ids) do
        local kind = ns.KindOf(id)
        local coord, isNew, temp = ns.AddNode(kind, map, x, y, id, "seen")
        if coord then
            ns.MarkLive(kind, map, coord)
            if isNew then
                if ns.OnNewNode then ns.OnNewNode(kind, map, coord, id) end
                if not temp and ns.ShareNode then ns.ShareNode(kind, map, coord, id) end
            end
        end
    end
    if ns.RefreshPins then ns.RefreshPins() end
end

-- Cada frame desde Core/GatherRadar.lua
function ns.ScannerUpdate(elapsed)
    elapsedSum = elapsedSum + elapsed
    if elapsedSum < EVERY then return end
    elapsedSum = 0
    if not (ns.db.scan and C_TooltipInfo and C_TooltipInfo.GetMinimapMouseover
        and Minimap:IsVisible() and Minimap:IsMouseOver()) then
        lastSeen = nil
        return
    end
    Read()
end

-- Tras una pantalla de carga o un cambio de opciones: volver a leer
function ns.RescanNow() lastSeen = nil end
