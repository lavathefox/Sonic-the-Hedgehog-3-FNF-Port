local requireFairRun = true -- ignore botplay, practice mode and charting mode
local debugMode = false

local marked = false

-- Same format as Paths.formatToSongPath: lowercase, spaces become dashes
local function slug(name)
	name = string.lower(name or '')
	name = string.gsub(name, '%s+', '-')
	name = string.gsub(name, '[^%w%-]', '')
	return name
end

local function markCompleted(songId)
	return runHaxeCode([[
		var data = FlxG.save.data;
		var songId = ']] .. songId .. [[';

		var slot = (data.dataSelectCurrentSlot != null) ? data.dataSelectCurrentSlot : -1;
		var current = data.dataSelectCurrentSong;

		if (slot < 1 || current != songId)
			return false;

		var list = (data.dataSelectCompleted != null) ? data.dataSelectCompleted : [];
		var key = slot + ':' + songId;

		if (list.indexOf(key) < 0)
		{
			list.push(key);
			data.dataSelectCompleted = list;
			FlxG.save.flush();
		}

		return true;
	]])
end

function onEndSong()
	if marked then return Function_Continue end

	if requireFairRun and (botPlay or practiceMode or chartingMode) then
		return Function_Continue
	end

	local ok = markCompleted(slug(songName))
	marked = (ok == true)

	if debugMode then debugPrint('completion marked: ' .. tostring(ok)) end

	return Function_Continue
end
