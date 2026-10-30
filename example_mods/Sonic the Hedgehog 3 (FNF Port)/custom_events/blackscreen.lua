function onEvent(n, v1, v2)
    if n == 'blackscreen' then
        if v1 == 'add with hud' then
            setProperty('camGame.alpha', 0)
        elseif v1 == 'add without hud' then
            setProperty('camGame.alpha', 0)
            setProperty('camHUD.alpha', 0)
        elseif v1 == 'remove' then
            setProperty('camGame.alpha', 1)
            setProperty('camHUD.alpha', 1)
        end
    end
end
