package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import backend.Mods;
import backend.Sonic3Storage;

/**
 * First-run screen shown on Android when the storage permission is missing.
 *
 * Flow:
 *  1. Explains why the permission is needed and where the mods folder will be.
 *  2. "GRANT ACCESS" opens the system settings screen.
 *  3. While waiting, the permission is checked twice per second, so the game
 *     continues on its own as soon as the player comes back with access enabled.
 *  4. "CONTINUE WITHOUT ACCESS" skips everything and keeps using the app's
 *     private storage.
 *
 * When access is granted it creates /storage/emulated/0/.Sonic3Funkin/mods,
 * copies any mods bundled in the APK, rescans the mods folder and opens the
 * title screen. No relaunch is needed.
 */
class PermissionState extends FlxState
{
	static inline var BUTTON_WIDTH:Int = 420;
	static inline var BUTTON_HEIGHT:Int = 76;

	var titleText:FlxText;
	var bodyText:FlxText;
	var statusText:FlxText;

	var grantButton:FlxSprite;
	var grantLabel:FlxText;
	var skipButton:FlxSprite;
	var skipLabel:FlxText;

	var requested:Bool = false;
	var finishing:Bool = false;
	var grantedAccess:Bool = false;

	var pollTimer:Float = 0;
	var grantCooldown:Float = 0;
	var finishFrames:Int = 0;

	override public function create():Void
	{
		super.create();

		var background:FlxSprite = new FlxSprite(0, 0);
		background.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(8, 16, 48));
		add(background);

		titleText = new FlxText(0, 50, FlxG.width, 'Storage access needed', 44);
		titleText.setFormat(null, 44, FlxColor.WHITE, CENTER);
		add(titleText);

		bodyText = new FlxText(60, 130, FlxG.width - 120, '', 26);
		bodyText.setFormat(null, 26, FlxColor.fromRGB(210, 220, 255), CENTER);
		bodyText.text = 'The game keeps your mods in:\n'
			+ Sonic3Storage.getModsFolder()
			+ '\n\nTo create this folder it needs access to all files. '
			+ 'Tap GRANT ACCESS, turn on the switch on the next screen, then come back to the game.';
		add(bodyText);

		grantButton = createButton(350, FlxColor.fromRGB(0, 120, 255));
		grantLabel = createLabel(grantButton, 'GRANT ACCESS', 32);

		skipButton = createButton(460, FlxColor.fromRGB(70, 80, 110));
		skipLabel = createLabel(skipButton, 'CONTINUE WITHOUT ACCESS', 22);

		statusText = new FlxText(60, 570, FlxG.width - 120, '', 22);
		statusText.setFormat(null, 22, FlxColor.YELLOW, CENTER);
		add(statusText);
	}

	function createButton(y:Float, color:FlxColor):FlxSprite
	{
		var button:FlxSprite = new FlxSprite((FlxG.width - BUTTON_WIDTH) / 2, y);
		button.makeGraphic(BUTTON_WIDTH, BUTTON_HEIGHT, color);
		add(button);
		return button;
	}

	function createLabel(button:FlxSprite, label:String, size:Int):FlxText
	{
		var text:FlxText = new FlxText(button.x, button.y + (BUTTON_HEIGHT - size) / 2 - 4, BUTTON_WIDTH, label, size);
		text.setFormat(null, size, FlxColor.WHITE, CENTER);
		add(text);
		return text;
	}

	/** True when the target was tapped this frame (mouse or touch). */
	function tapped(target:FlxSprite):Bool
	{
		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(target))
			return true;

		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed && touch.overlaps(target))
				return true;
		}

		return false;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (finishing)
		{
			// Wait a couple of frames so the "Setting up..." text is drawn
			// before the (blocking) folder setup starts.
			finishFrames++;

			if (finishFrames == 3)
				finish();

			return;
		}

		if (grantCooldown > 0)
			grantCooldown -= elapsed;

		// Once the system screen was opened, keep checking until access is granted.
		if (requested)
		{
			pollTimer += elapsed;

			if (pollTimer >= 0.5)
			{
				pollTimer = 0;

				if (Sonic3Storage.hasPermission())
				{
					beginFinish(true);
					return;
				}
			}
		}

		if (tapped(grantButton) || FlxG.keys.justPressed.ENTER)
			onGrantPressed();
		else if (tapped(skipButton))
			beginFinish(false);
	}

	function onGrantPressed():Void
	{
		// Ignore repeated taps (mouse and touch can both fire for the same tap).
		if (grantCooldown > 0)
			return;

		grantCooldown = 1.5;
		requested = true;
		pollTimer = 0;

		statusText.text = 'Waiting for access... enable the switch, then come back to the game.';
		Sonic3Storage.requestPermission();
	}

	function beginFinish(granted:Bool):Void
	{
		if (finishing)
			return;

		finishing = true;
		grantedAccess = granted;
		finishFrames = 0;

		grantButton.visible = false;
		grantLabel.visible = false;
		skipButton.visible = false;
		skipLabel.visible = false;

		statusText.text = granted ? 'Setting up folders...' : 'Continuing with private storage...';
	}

	function finish():Void
	{
		if (grantedAccess)
		{
			if (Sonic3Storage.ensureFolders(true))
			{
				var copied:Int = Sonic3Storage.copyBundledMods();
				trace('PermissionState: copied ' + copied + ' bundled mod file(s)');

				// The working directory changed, so scan the mods folder again.
				#if LUA_ALLOWED
				Mods.pushGlobalMods();
				#end
				Mods.loadTopMod();
			}
			else
			{
				trace('PermissionState: access was granted but the folders could not be created.');
			}
		}

		FlxG.switchState(new Sonic3TitleStateV2());
	}
}
