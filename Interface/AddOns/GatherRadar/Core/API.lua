local ADDON_NAME, ns = ...

-- ==========================================
-- API PUBLICA (solo lectura)
-- ==========================================
-- Para otros addons (p. ej. Azeroth AI: "donde farmeo cobre?"): los nodos que
-- GatherRadar conoce (recogidos, vistos, compartidos o importados), por tipo y
-- mapa. Devuelve siempre copias.
--
--   kind:    "herb" | "ore" | "treasure" | "fish"
--   mapID:   uiMapID
--   x, y:    0-100, como TomTom y Dungeon Quest Atlas (por dentro van en 0-1)
--   nodeID:  el ID de nodo de GatherMate2 (401 Peacebloom, 201 Copper Vein...);
--            los de Forever que GatherMate2 no tiene, 90000+
--
-- version solo sube si cambia el significado de algo ya existente; anadir
-- funciones o campos no la sube.
--
--   local api = GatherRadarAPI
--   if api and api.version == 1 then
--       local id = api.FindNode("Copper Vein")
--       for _, zone in ipairs(api.GetMapsForNode(id) or {}) do print(zone.mapID, zone.count) end
--   end

local function Info(id)
    local node = ns.NODES[id]
    local kind = ns.KindOf(id)
    if not kind then return nil end
    return { nodeID = id, kind = kind, name = ns.NodeName(id), englishName = node and node.name,
        item = node and node.item, skill = node and node.skill }
end

local function Valid(kind)
    return kind and ns.KINDS[kind] ~= nil
end

GatherRadarAPI = {
    version = 1,

    KINDS = { "herb", "ore", "treasure", "fish" },

    -- { nodeID, kind, name (idioma del cliente), englishName, item, skill } o nil
    GetNodeInfo = Info,

    -- nodeID y kind por el nombre del nodo o de su hierba, en ingles o en el
    -- idioma del cliente; nil si no lo conoce
    FindNode = function(name)
        local id = ns.IdByName(name)
        if not id then return nil end
        return id, ns.KindOf(id)
    end,

    -- Nodos de un tipo en un mapa: { { x, y, nodeID }, ... }. nodeID limita a ese nodo.
    GetNodes = function(mapID, kind, nodeID)
        if not (mapID and Valid(kind)) then return nil end
        local out = {}
        ns.EachNode(kind, mapID, function(coord, id)
            if not nodeID or id == nodeID then
                local x, y = ns.Decode(coord)
                out[#out + 1] = { x = x * 100, y = y * 100, nodeID = id }
            end
        end)
        return out
    end,

    -- Mapas donde hay ese nodo, del que mas tiene al que menos: { { mapID, count }, ... }
    GetMapsForNode = function(nodeID)
        local kind = nodeID and ns.KindOf(nodeID)
        if not kind then return nil end
        local counts = {}
        for _, store in ipairs({ ns.db.nodes, ns.temp }) do
            for mapID, zone in pairs(store[kind] or {}) do
                for _, id in pairs(zone) do
                    if id == nodeID then counts[mapID] = (counts[mapID] or 0) + 1 end
                end
            end
        end
        local out = {}
        for mapID, count in pairs(counts) do out[#out + 1] = { mapID = mapID, count = count } end
        table.sort(out, function(a, b) return a.count > b.count end)
        return out
    end,

    -- El nodo mas cercano al jugador en su mapa: { mapID, x, y, nodeID, yards } o nil
    -- (sin posicion: instancias o valores secretos). nodeID limita a ese nodo.
    GetNearest = function(kind, nodeID)
        if not Valid(kind) then return nil end
        local mapID, px, py = ns.PlayerPosition()
        if not mapID then return nil end
        local w, h = ns.MapSize(mapID)
        local best
        ns.EachNode(kind, mapID, function(coord, id)
            if not nodeID or id == nodeID then
                local x, y = ns.Decode(coord)
                local dx, dy = (x - px) * w, (y - py) * h
                local gap = dx * dx + dy * dy
                if not best or gap < best.gap then best = { gap = gap, x = x, y = y, id = id } end
            end
        end)
        if not best then return nil end
        return { mapID = mapID, x = best.x * 100, y = best.y * 100, nodeID = best.id, yards = math.sqrt(best.gap) }
    end,

    -- Si el jugador tiene la profesion de ese tipo (los tesoros no piden ninguna)
    HasProfession = function(kind)
        return Valid(kind) and ns.HasProfession(kind) or false
    end,
}
