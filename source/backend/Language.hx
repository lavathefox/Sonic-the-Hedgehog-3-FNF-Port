package backend;

class Language
{
	public static var defaultLangName:String = 'English (US)';

	#if TRANSLATIONS_ALLOWED
	private static var phrases:Map<String, String> = [];
	#end

	public static function reloadPhrases()
	{
		#if TRANSLATIONS_ALLOWED
		var langFile:String = ClientPrefs.data.language;

		phrases.clear();

		if (langFile == 'ESPANOL')
		{
			loadSpanishPhrases();
		}
		else
		{
			var loadedText:Array<String> = Mods.mergeAllTextsNamed('data/$langFile.lang');
			var hasPhrases:Bool = false;

			for (num => phrase in loadedText)
			{
				phrase = phrase.trim();

				if (num < 1 && !phrase.contains(':'))
				{
					phrases.set('language_name', phrase.trim());
					continue;
				}

				if (phrase.length < 4 || phrase.startsWith('//'))
					continue;

				var n:Int = phrase.indexOf(':');

				if (n < 0)
					continue;

				var key:String = phrase.substr(0, n).trim().toLowerCase();

				var value:String = phrase.substr(n);

				n = value.indexOf('"');

				if (n < 0)
					continue;

				phrases.set(key, value.substring(n + 1, value.lastIndexOf('"')).replace('\\n', '\n'));
				hasPhrases = true;
			}

			if (!hasPhrases)
			{
				ClientPrefs.data.language = ClientPrefs.defaultData.language;
				reloadPhrases();
				return;
			}
		}

		var alphaPath:String = getFileTranslation('images/alphabet');

		if (alphaPath.startsWith('images/'))
			alphaPath = alphaPath.substr('images/'.length);

		var pngPos:Int = alphaPath.indexOf('.png');

		if (pngPos > -1)
			alphaPath = alphaPath.substring(0, pngPos);

		AlphaCharacter.loadAlphabetData(alphaPath);
		#else
		AlphaCharacter.loadAlphabetData();
		#end
	}

	#if TRANSLATIONS_ALLOWED
	private static function loadSpanishPhrases():Void
	{
		phrases.set('language_name', 'Español');

		// General
		phrases.set('yes', 'Sí');
		phrases.set('no', 'No');
		phrases.set('ok', 'Aceptar');
		phrases.set('cancel', 'Cancelar');
		phrases.set('confirm', 'Confirmar');
		phrases.set('back', 'Atrás');
		phrases.set('accept', 'Aceptar');
		phrases.set('reset', 'Restablecer');
		phrases.set('default', 'Predeterminado');
		phrases.set('on', 'Activado');
		phrases.set('off', 'Desactivado');

		// Main menu / common menus
		phrases.set('story_mode', 'Modo Historia');
		phrases.set('freeplay', 'Partida Libre');
		phrases.set('options', 'Opciones');
		phrases.set('credits', 'Créditos');
		phrases.set('donate', 'Donar');
		phrases.set('mods', 'Mods');
		phrases.set('achievements', 'Logros');
		phrases.set('gallery', 'Galería');

		// Options
		phrases.set('preferences', 'Preferencias');
		phrases.set('gameplay', 'Jugabilidad');
		phrases.set('controls', 'Controles');
		phrases.set('graphics', 'Gráficos');
		phrases.set('visuals', 'Visuales');
		phrases.set('language', 'Idioma');
		phrases.set('languages', 'Idiomas');

		// Controls
		phrases.set('notes', 'Notas');
		phrases.set('left', 'Izquierda');
		phrases.set('down', 'Abajo');
		phrases.set('up', 'Arriba');
		phrases.set('right', 'Derecha');
		phrases.set('ui', 'Interfaz');
		phrases.set('volume', 'Volumen');
		phrases.set('debug', 'Depuración');
		phrases.set('key_1', 'Tecla 1');
		phrases.set('key_2', 'Tecla 2');
		phrases.set('reset_to_default_keys', 'Restablecer teclas');

		// Graphics
		phrases.set('fullscreen', 'Pantalla completa');
		phrases.set('framerate', 'Velocidad de fotogramas');
		phrases.set('antialiasing', 'Antialiasing');
		phrases.set('low_quality', 'Baja calidad');
		phrases.set('shaders', 'Shaders');
		phrases.set('cache_on_gpu', 'Caché en GPU');

		// Visuals
		phrases.set('distractions', 'Distracciones');
		phrases.set('flashing_lights', 'Luces parpadeantes');
		phrases.set('camera_zooms', 'Zoom de cámara');
		phrases.set('combo_position', 'Posición del combo');
		phrases.set('time_bar', 'Barra de tiempo');

		// Gameplay
		phrases.set('downscroll', 'Notas hacia abajo');
		phrases.set('middlescroll', 'Notas centradas');
		phrases.set('ghost_tapping', 'Ghost Tapping');
		phrases.set('miss_sound', 'Sonido al fallar');
		phrases.set('botplay', 'Botplay');
		phrases.set('practice', 'Práctica');

		// Pause
		phrases.set('resume', 'Continuar');
		phrases.set('restart_song', 'Reiniciar canción');
		phrases.set('exit_to_menu', 'Salir al menú');
		phrases.set('exit', 'Salir');

		// Notes / gameplay
		phrases.set('note_colors', 'Colores de notas');
		phrases.set('adjust_delay_and_combo', 'Ajustar retraso y combo');

		// Language menu
		phrases.set('english', 'Inglés');
		phrases.set('portuguese', 'Portugués');
		phrases.set('spanish', 'Español');
	}
	#end

	inline public static function getPhrase(key:String, ?defaultPhrase:String, values:Array<Dynamic> = null):String
	{
		#if TRANSLATIONS_ALLOWED
		var str:String = phrases.get(formatKey(key));

		if (str == null)
			str = defaultPhrase;
		#else
		var str:String = defaultPhrase;
		#end

		if (str == null)
			str = key;

		if (values != null)
		{
			for (num => value in values)
				str = str.replace('{${num + 1}}', value);
		}

		return str;
	}

	inline public static function getFileTranslation(key:String)
	{
		#if TRANSLATIONS_ALLOWED
		var str:String = phrases.get(key.trim().toLowerCase());

		if (str != null)
			key = str;
		#end

		return key;
	}

	#if TRANSLATIONS_ALLOWED
	inline static private function formatKey(key:String)
	{
		final hideChars = ~/[~&\\\/;:<>#.,'"%?!]/g;
		return hideChars.replace(key.replace(' ', '_'), '').toLowerCase().trim();
	}
	#end

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State)
	{
		Lua_helper.add_callback(lua, "getTranslationPhrase", function(key:String, ?defaultPhrase:String, ?values:Array<Dynamic> = null)
		{
			return getPhrase(key, defaultPhrase, values);
		});

		Lua_helper.add_callback(lua, "getFileTranslation", function(key:String)
		{
			return getFileTranslation(key);
		});
	}
	#end
}
