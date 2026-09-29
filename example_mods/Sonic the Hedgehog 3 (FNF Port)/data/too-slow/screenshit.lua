
wideScreen = 0

local widescreen = false
local widescreentog = false
switchtonextsong = false

function onCreate()
	addHaxeLibrary("Lib", "openfl");
			setPropertyFromClass("openfl.Lib", "application.window.resizable", false)
end

function onSpawnNote(index, direction, noteType, isSustainNote, strumTime)
		setPropertyFromGroup("unspawnNotes", index, "scale.x", 1)
	
		local anim = getPropertyFromGroup("unspawnNotes", index, "animation.name")
		local isEnd = anim:sub(#anim-2,#anim)=='end';
		if (isEnd or not isSustainNote) then
			setPropertyFromGroup("unspawnNotes", index, "scale.y", 1)
		end
		if(isEnd)then
			setPropertyFromGroup("unspawnNotes", index, "offsetY", getPropertyFromGroup("unspawnNotes", index, "offsetY") +0)
		end

	setPropertyFromGroup("unspawnNotes", 4, "antialiasing", false)
	setPropertyFromGroup("unspawnNotes", 5, "antialiasing", false)
	setPropertyFromGroup("unspawnNotes", 6, "antialiasing", false)
	setPropertyFromGroup("unspawnNotes", 7, "antialiasing", false)
end

function onUpdate()
	--
	setPropertyFromGroup("strumLineNotes", 4, "scale.x", 1)
	setPropertyFromGroup("strumLineNotes", 4, "scale.y", 1)
	setPropertyFromGroup("strumLineNotes", 5, "scale.x", 1)
	setPropertyFromGroup("strumLineNotes", 5, "scale.y", 1)
	setPropertyFromGroup("strumLineNotes", 6, "scale.x", 1)
	setPropertyFromGroup("strumLineNotes", 6, "scale.y", 1)
	setPropertyFromGroup("strumLineNotes", 7, "scale.x", 1)
	setPropertyFromGroup("strumLineNotes", 7, "scale.y", 1)

	--]]

	setPropertyFromGroup("strumLineNotes", 4, "antialiasing", false)
	setPropertyFromGroup("strumLineNotes", 5, "antialiasing", false)
	setPropertyFromGroup("strumLineNotes", 6, "antialiasing", false)
	setPropertyFromGroup("strumLineNotes", 7, "antialiasing", false)

	for i = 0,3 do
		setPropertyFromGroup("strumLineNotes", i, "alpha", 0)
	end

	setPropertyFromGroup("strumLineNotes", 4, "x", 105*3)
	setPropertyFromGroup("strumLineNotes", 5, "x", 137*3)
	setPropertyFromGroup("strumLineNotes", 6, "x", 167*3)
	setPropertyFromGroup("strumLineNotes", 7, "x", 198*3)

	if downscroll then
		setPropertyFromGroup("strumLineNotes", 4, "y", 196*3-1)
		setPropertyFromGroup("strumLineNotes", 5, "y", 196*3-1)
		setPropertyFromGroup("strumLineNotes", 6, "y", 196*3-1)
		setPropertyFromGroup("strumLineNotes", 7, "y", 196*3-1)

		setProperty('misseshud.y', 196*3-1)
		setProperty('misses.y', 610)
		setProperty('missesback.y', 613)

		setProperty('accuracyTxt1.y', 510)
		setProperty('accuracyTxt2.y', 529)
		setProperty('accuracyTxt1BACK.y', 513)
		setProperty('accuracyTxt2BACK.y', 532)
	else
		setPropertyFromGroup("strumLineNotes", 4, "y", 27*3-1)
		setPropertyFromGroup("strumLineNotes", 5, "y", 27*3-1)
		setPropertyFromGroup("strumLineNotes", 6, "y", 27*3-1)
		setPropertyFromGroup("strumLineNotes", 7, "y", 27*3-1)
	end

	if curStep >= 0 and curStep <= 1 then
		runHaxeCode([[
			var stage = Lib.current.stage;
			var resolutionX = 0;
			var resolutionY = 0;

			if (stage.window != null)
			{
				var display = stage.window.display;

				if (display != null)
				{
					resolutionX = Math.ceil(display.currentMode.width * stage.window.scale);
					resolutionY = Math.ceil(display.currentMode.height * stage.window.scale);
				}
			}

			if(resolutionX <= 0){
				resolutionX = stage.stageWidth;
				resolutionY = stage.stageHeight;
			}

		Lib.application.window.x = (resolutionX - Lib.application.window.width)/2;
		Lib.application.window.y = (resolutionY - Lib.application.window.height)/2;
		]]);
	end
end

function onUpdatePost()
	for i = 4,7 do
		if getPropertyFromGroup('unspawnNotes', i, 'isSustainNote') then
			setPropertyFromGroup('unspawnNotes', i, 'alpha',  1);
		end
	end
end
function onEndSong()
	switchtonextsong = true
	loadSong('test')
end
function onExitSong()
	saveFile('gameoverX/data/fixscreen', 'false')
end

function onPause()
	saveFile('gameoverX/data/fixscreen', 'false')
end