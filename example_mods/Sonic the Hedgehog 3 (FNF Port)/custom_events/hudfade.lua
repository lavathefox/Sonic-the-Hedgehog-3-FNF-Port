function onEvent(name, value1, value2)
    if name == 'hudfade' then
        if value1 == 'fade' then
            doTweenAlpha('TweenHUDhide', 'camHUD', 0, value2)
        end
        if value1 == "defade" then
            doTweenAlpha('TweenHUD', 'camHUD', 1, value2)
        end
    end
end