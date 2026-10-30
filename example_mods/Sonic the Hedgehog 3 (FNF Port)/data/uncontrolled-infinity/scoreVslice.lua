
local visualScore = 0
local scoreLerpSpeed = 8
local scoreInitialized = false

function onCreatePost()
    visualScore = getProperty('songScore') or 0
    scoreInitialized = true
    setTextBorder('scoreTxt', 1.25, 'black')
    setTextSize('scoreTxt', 16)
end

function onUpdatePost(elapsed)
    if botPlay then
        setTextString('scoreTxt', 'Bot Play Enabled')
        return
    end

    local realScore = getProperty('songScore') or 0

    if not scoreInitialized then
        visualScore = realScore
        scoreInitialized = true
    end

    visualScore = visualScore + (realScore - visualScore) * math.min(elapsed * scoreLerpSpeed, 1)

    local shownScore = math.floor(visualScore + 0.5)

    setTextString('scoreTxt', 'Score: ' .. formatScore(shownScore))
    setTextString('botplayTxt', '')
end

function formatScore(num)
    local formatted = tostring(math.floor(num))
    local k

    while true do
        formatted, k = formatted:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then
            break
        end
    end

    return formatted
end
