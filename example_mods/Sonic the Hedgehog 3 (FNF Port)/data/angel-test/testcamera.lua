function onUpdatePost()
	if camerafollowplayer then
		local cameraX = getMidpointX(player)
		local cameraY = getMidpointY(player) - 54

		if SpeedX > 0 then
			cameraX = cameraX + 100
		elseif SpeedX < 0 then
			cameraX = cameraX - 100
		end

		setOnScripts('camFollow.y', cameraY)
	end
end
