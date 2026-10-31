-- megaDriversSplashFix.lua
-- Coloque em: mods/<seu mod>/scripts/
-- Centraliza o note splash "megaDriversNotesSplashes" em cima da seta (strum) correta.
-- O atlas dele usa frames de 218x218 com frameX/frameY negativos, entao o sprite
-- precisa ser centralizado pelo centro do frame, nao pelo canto.

local SKIN = 'megaDriversNotesSplashes'

-- Ajuste fino (em pixels) se ainda ficar um pouco torto
local OFFSET_X = 0
local OFFSET_Y = 0

local function getStrumCenters()
    local list = {}
    local groups = {'playerStrums', 'opponentStrums'}
    for _, g in ipairs(groups) do
        local n = getProperty(g .. '.length')
        for i = 0, n - 1 do
            local base = g .. '.members[' .. i .. ']'
            local cx = getProperty(base .. '.x') + getProperty(base .. '.width') / 2
            local cy = getProperty(base .. '.y') + getProperty(base .. '.height') / 2
            table.insert(list, {x = cx, y = cy})
        end
    end
    return list
end

function onUpdatePost(elapsed)
    local total = getProperty('grpNoteSplashes.length')
    if total == nil or total <= 0 then return end

    local strums = nil

    for i = 0, total - 1 do
        local base = 'grpNoteSplashes.members[' .. i .. ']'

        if getProperty(base .. '.alive') and getProperty(base .. '.visible') then
            -- so mexe nos splashes que usam essa skin (se a propriedade existir)
            local tex = getProperty(base .. '.texture')
            if tex == nil or tex == '' or string.find(tex, SKIN, 1, true) then
                strums = strums or getStrumCenters()

                local w = getProperty(base .. '.width')
                local h = getProperty(base .. '.height')
                local sx = getProperty(base .. '.x') + w / 2
                local sy = getProperty(base .. '.y') + h / 2

                -- acha a seta mais proxima do splash
                local best, bestDist = nil, math.huge
                for _, s in ipairs(strums) do
                    local d = (s.x - sx) ^ 2 + (s.y - sy) ^ 2
                    if d < bestDist then
                        bestDist = d
                        best = s
                    end
                end

                if best ~= nil then
                    setProperty(base .. '.x', best.x - w / 2 + OFFSET_X)
                    setProperty(base .. '.y', best.y - h / 2 + OFFSET_Y)
                end
            end
        end
    end
end
