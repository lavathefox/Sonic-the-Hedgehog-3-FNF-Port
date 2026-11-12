# Nintendo Switch Port

This is a **homebrew** port, so you'll need a Switch running custom firmware (Atmosphère) and you launch it from the Homebrew Menu. Publishing it officially would mean going through Nintendo's developer program, which is a separate process and isn't covered here.

It's built on [Lime-NX](https://github.com/Slushi-Github/lime-nx) (an experimental fork of Lime), hxcpp-nx and devkitPro. [Switch Funkin'](https://github.com/Slushi-Github/Switch-Funkin) (Psych 1.0.4) shows this setup works with a Psych Engine on the same versions this project uses.

> I wrote all of this without access to a Switch, so **please test on real hardware**, just like Switch Funkin' asks you to.

## Defines

| Define | Comes from | When to use it |
|---|---|---|
| `switch` | Lime-NX | simple conditions (`#if switch`) |
| `SWITCH_BUILD` | `project.xml` | **use this one in compound conditions** (`#if (mobile \|\| SWITCH_BUILD)`) |

`switch` is a Haxe keyword, so keeping it out of `#if (a || b)` avoids a possible compile error.

## Suggested order of work

Each step should leave you with a build that still compiles.

1. **Get it compiling.** Apply `project.xml` and `switch.yml`, run the workflow, and fix whatever compile errors show up.
2. **Paths.** Copy `source/backend/FS.hx` and `PlatformUtil.hx`, run `bash setup/switch_codemod.sh`, and go through the `git diff` to check the changes.
   On Switch, `assets/` becomes `romfs:/assets/` (inside the .nro) and `mods/` becomes `sdmc:/switch/Sonic3-FNF-Port/mods/`.
3. **Saves.** Flixel's `FlxSave` writes to a folder that doesn't exist on Switch. Switch Funkin' fixes this with a modified copy of `flixel/util/FlxSave.hx`: a `_SWITCH_SAVE_PATH` field pointing to `sdmc:/.../saves`, and no `:` in the list of invalid characters.
   Copy `source/flixel/util/FlxSave.hx` from their repo (same Apache-2.0 license, so keep the credit) and add this at the top of `Main.hx`:
   ```haxe
   #if SWITCH_BUILD
   flixel.util.FlxSave._SWITCH_SAVE_PATH = PlatformUtil.DATA_DIR + '/saves';
   FS.createDirectory(PlatformUtil.DATA_DIR + '/saves');
   #end
   ```
4. **Controls.** In `ClientPrefs`, Switch Funkin' swaps the gamepad's `accept` and `back` (`accept = B`, `back = A`) because of Nintendo's mirrored button layout. Do the same here and double-check it on the console.
   For handheld mode, you can reuse `HitBox`/`MobileControls` by changing `#if mobile` to `#if (mobile || SWITCH_BUILD)` where it makes sense (read the code before swapping anything).
5. **Crash handler and logs.** Replace the `./crash/`, `asset_problems.txt` and `shaderCrashes/` paths with `FS.createDirectory` / `FS.saveContent` (which write to the SD card). Only after that, remove the `<section unless="switch">` around `CRASH_HANDLER` in `project.xml`.
6. **Performance.** The console dates from 2016 and has 4 GB of RAM, so:
   - loading threads: the Switch has 4 cores and the main thread takes one, so use 3 at most;
   - turn antialiasing off on heavy sprites;
   - expensive shaders (rain, audio visualizers) were the biggest bottleneck in Switch Funkin';
   - the NRO loads the entire romfs, so big songs make the file larger and slow down startup.
7. **Video** (optional, do it last). `hxvlc` doesn't exist on Switch. The way forward is [HxSwitchVideo](https://github.com/Slushi-Github/HxSwitchVideo), which is still in development. Keep `VIDEOS_ALLOWED` off on Switch until steps 1 to 6 are stable.

## Building locally (Linux/macOS)

```bash
sudo dkp-pacman -S --needed switch-bzip2 switch-cmake switch-curl switch-flac switch-freetype switch-glad \
  switch-glm switch-harfbuzz switch-libdrm_nouveau switch-libjpeg-turbo switch-libmodplug switch-libogg \
  switch-libopus switch-libpng switch-libvorbis switch-libvorbisidec switch-libwebp switch-mesa switch-mpg123 \
  switch-openal-soft switch-opusfile switch-pkg-config switch-sdl2 switch-sdl2_gfx switch-sdl2_image \
  switch-sdl2_mixer switch-sdl2_net switch-sdl2_ttf switch-tools switch-zlib switch-liblua51

haxelib git hxcpp https://github.com/Slushi-Github/hxcpp-nx.git
(cd "$(haxelib path hxcpp | head -n1)/tools/hxcpp" && haxe compile.hxml)
haxelib git lime https://github.com/Slushi-Github/lime-nx.git lime-9778682
haxelib git hx_libnx https://github.com/Slushi-Github/hx_libnx.git
haxelib install format && haxelib install hxp

haxelib run lime rebuild switch
haxelib run lime build project.xml switch     # output: export/release/switch/bin/*.nro
```

Heads up: installing Lime-NX **replaces** the official `lime` on your machine. To go back to the other targets, run `haxelib set lime 8.1.2`
(and `haxelib set hxcpp 4.3.2`). If you'll be building for both a lot, it's easier to keep a separate `haxelib setup` just for Switch.

## On the console

Copy the `.nro` to `sd:/switch/`. On first launch the game creates `sd:/switch/Sonic3-FNF-Port/` with `mods/`, `saves/` and logs inside.
