-- Marks the song that just ended as completed in the Data Select save slot

local requireFairRun = true -- ignore botplay, practice mode and charting mode
local debugMode = false

local marked = false

function onEndSong()
	if marked then return Function_Continue end

	if requireFairRun and (botPlay or practiceMode or chartingMode) then
		return Function_Continue
	end

	local ok = runHaxeCode([[
		var c = Type.resolveClass('states.DataSelectState');
		if (c == null) return false;

		return Reflect.callMethod(c, Reflect.field(c, 'markSongCompleted'), [PlayState.SONG.song]);
	]])

	marked = (ok == true)

	if debugMode then debugPrint('completion marked: ' .. tostring(ok)) end

	return Function_Continue
end
