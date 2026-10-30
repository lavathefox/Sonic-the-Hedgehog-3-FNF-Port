-- Event by Deady Fr

function onEvent(n, v1, v2)
    if n == 'note twist' then
        if v1 == 'twist' then
            if not downscroll then
                noteTweenY('A', 0, 100, 0.37, 'quartInOut')
            else
                noteTweenY('A', 0, 500, 0.37, 'quartInOut')
            end
                
        elseif v1 == '' then

            cancelTween('A')
            cancelTween('A2')
            cancelTween('B')
            cancelTween('B2')
            cancelTween('C')
            cancelTween('C2')
            cancelTween('D')
            cancelTween('D2')
            cancelTween('E')
            cancelTween('E2')
            cancelTween('F')
            cancelTween('F2')
            cancelTween('G')
            cancelTween('H')
            cancelTween('G2')
            cancelTween('H2')

            if not downscroll then
                noteTweenY('EE8', 0, 50, 0.37, 'quartInOut')
                noteTweenY('EE7', 7, 50, 0.37, 'quartInOut')
                noteTweenY('EE6', 1, 50, 0.37, 'quartInOut')
                noteTweenY('EE', 3, 50, 0.37, 'quartInOut')
                noteTweenY('EE2', 2, 50, 0.37, 'quartInOut')
                noteTweenY('EE3', 4, 50, 0.37, 'quartInOut')
                noteTweenY('EE4', 5, 50, 0.37, 'quartInOut')
                noteTweenY('EE5', 6, 50, 0.37, 'quartInOut')
            else
                noteTweenY('EE8', 0, 570, 0.37, 'quartInOut')
                noteTweenY('EE7', 7, 570, 0.37, 'quartInOut')
                noteTweenY('EE6', 1, 570, 0.37, 'quartInOut')
                noteTweenY('EE', 3, 570, 0.37, 'quartInOut')
                noteTweenY('EE2', 2, 570, 0.37, 'quartInOut')
                noteTweenY('EE3', 4, 570, 0.37, 'quartInOut')
                noteTweenY('EE4', 5, 570, 0.37, 'quartInOut')
                noteTweenY('EE5', 6, 570, 0.37, 'quartInOut')
            end
        end
    end
end

function onTweenCompleted(t)
    if not downscroll then
        if t == 'A' then
            noteTweenY('B', 1, 100, 0.37,'quartInOut')
            noteTweenY('A2', 0, 50, 0.3, 'quartInOut')
        elseif t == 'A2' then
            noteTweenY('B2', 1, 50, 0.37, 'quartInOut')
            noteTweenY('C', 2, 100, 0.3, 'quartInOut')
        elseif t == 'B2' then
            noteTweenY('C2', 2, 50, 0.37, 'quartInOut')
            noteTweenY('D', 3, 100, 0.37, 'quartInOut')
        elseif t == 'C2' then
            noteTweenY('D2', 3, 50, 0.37, 'quartInOut')
            noteTweenY('E', 4, 100, 0.37, 'quartInOut')
        elseif t == 'D2' then
            noteTweenY('E2', 4, 50, 0.37, 'quartInOut')
            noteTweenY('F', 5, 100, 0.37, 'quartInOut')
        elseif t == 'E2' then
            noteTweenY('F2', 5, 50, 0.37, 'quartInOut')
            noteTweenY('G', 6, 100, 0.37, 'quartInOut')
        elseif t == 'F2' then
            noteTweenY('G2', 6, 50, 0.37, 'quartInOut')
            noteTweenY('H', 7, 100, 0.37, 'quartInOut')
        elseif t == 'H' then
            noteTweenY('H2', 7, 50, 0.37, 'quartInOut')
            noteTweenY('A', 0, 100, 0.37, 'quartInOut')
        end
    else
        if t == 'A' then
            noteTweenY('B', 1, 500, 0.37,'quartInOut')
            noteTweenY('A2', 0, 570, 0.3, 'quartInOut')
        elseif t == 'A2' then
            noteTweenY('B2', 1, 570, 0.37, 'quartInOut')
            noteTweenY('C', 2, 500, 0.3, 'quartInOut')
        elseif t == 'B2' then
            noteTweenY('C2', 2, 570, 0.37, 'quartInOut')
            noteTweenY('D', 3, 500, 0.37, 'quartInOut')
        elseif t == 'C2' then
            noteTweenY('D2', 3, 570, 0.37, 'quartInOut')
            noteTweenY('E', 4, 500, 0.37, 'quartInOut')
        elseif t == 'D2' then
            noteTweenY('E2', 4, 570, 0.37, 'quartInOut')
            noteTweenY('F', 5, 500, 0.37, 'quartInOut')
        elseif t == 'E2' then
            noteTweenY('F2', 5, 570, 0.37, 'quartInOut')
            noteTweenY('G', 6, 500, 0.37, 'quartInOut')
        elseif t == 'F2' then
            noteTweenY('G2', 6, 570, 0.37, 'quartInOut')
            noteTweenY('H', 7, 500, 0.37, 'quartInOut')
        elseif t == 'H' then
            noteTweenY('H2', 7, 570, 0.37, 'quartInOut')
            noteTweenY('A', 0, 500, 0.37, 'quartInOut')
        end
    end
end