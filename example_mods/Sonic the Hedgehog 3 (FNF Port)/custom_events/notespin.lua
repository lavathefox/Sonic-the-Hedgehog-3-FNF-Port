-- Code by Deady Fr

function onEvent(n, v1, v2)
    if n == 'notespin' then
        noteTweenAngle('nT', 0, 360, 0.13)
        noteTweenAngle('nT2', 1, 360, 0.13)
        noteTweenAngle('nT3', 2, 360, 0.13)
        noteTweenAngle('nT4', 3, 360, 0.13)
        
        noteTweenAngle('nT5', 4, 360, 0.13)
        noteTweenAngle('nT6', 5, 360, 0.13)
        noteTweenAngle('nT7', 6, 360, 0.13)
        noteTweenAngle('nT8', 7, 360, 0.13)

        doTweenAngle('IcoTween', "iconP1", -360, 0.13)
        doTweenAngle('IcoTween2', "iconP2", 360, 0.13)

        local currentHealth = getHealth()
        if currentHealth > 0.15 then
            addHealth(-0.15)
        else
            setHealth(0.05)
        end
        
    end
end

function onTweenCompleted(t)
    if t == 'nT' then
        noteTweenAngle('nTp', 0, 0, 0.0001)
        noteTweenAngle('nTp2', 1, 0, 0.0001)
        noteTweenAngle('nTp3', 2, 0, 0.0001)
        noteTweenAngle('nTp4', 3, 0, 0.0001)

        noteTweenAngle('nTp5', 4, 0, 0.0001)
        noteTweenAngle('nTp6', 5, 0, 0.0001)
        noteTweenAngle('nTp7', 6, 0, 0.0001)
        noteTweenAngle('nTp8', 7, 0, 0.0001)

        doTweenAngle('IcoTweenA', "iconP1", 0, 0.0001)
        doTweenAngle('IcoTweenA2', "iconP2", 0, 0.0001)

    end
end