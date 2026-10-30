-- Code by Deady Fr (or Majin Fr as Lava calls me)

function onCreate()
    makeLuaText('inf', 'FUN IS INFINITE', 0, 0, 0)
    setTextSize('inf', 60)
    setTextFont('inf', 'cd-font.ttf')
    setObjectCamera('inf', "hud")
    addLuaText('inf')
    screenCenter('inf', 'xy')

    makeLuaSprite('maj', 'majinepic', 0, 0)
    setObjectCamera('maj', "hud")
    addLuaSprite('maj')

    setProperty('maj.alpha', 0)
    setProperty('inf.alpha', 0)
end

function onEvent(n, v1, v2)
    if n == "majin epic halo" then
        if v1 == "add" then
            setObjectCamera('maj', "camother")
            setProperty('maj.alpha', 1)

            doTweenAlpha('mT', "maj", 0, 0.8)
        
        elseif v1 == "remove" then
            doTweenAlpha('mT4', "maj", 0, 0.3)
            doTweenAlpha('mT3', "inf", 0, 0.3)

            cancelTween('mT')
            cancelTween('mT2')

            cancelTimer('infByeByee')
            cancelTimer('infGetHere')

        elseif v1 == "add with text" then
            setObjectCamera('maj', "camother")
            setProperty('maj.alpha', 1)
            setProperty('inf.alpha', 1)
            
            doTweenAlpha('mT', "maj", 0, 0.8)

            runTimer('infByeByee', 0.37)
            
        end
    end
end

function onTweenCompleted(t)
    if t == 'mT' then
        doTweenAlpha('mT2', "maj", 1, 0.8)
    elseif t == "mT2" then
        doTweenAlpha('mT', "maj", 0, 0.8)
    end
end

function onTimerCompleted(t)
    if t == "infByeByee" then
        setProperty('inf.alpha', 0)
        runTimer('infGetHere', 0.37)
    end
    
    if t == 'infGetHere' then
        setProperty('inf.alpha', 1)
        runTimer('infByeByee', 0.37)
    end
end