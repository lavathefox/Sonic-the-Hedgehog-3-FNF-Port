package backend;

#if (DISCORD_ALLOWED && cpp)
import sys.thread.Thread;
import lime.app.Application;
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;
import flixel.util.FlxStringUtil;
import api.discord.DiscordUser as UserProfile;

class DiscordClient
{
    public static var isInitialized(default, null):Bool = false;
    public static var isConnecting(default, null):Bool = false;
    public static var currentUser(default, null):Null<UserProfile> = null;
    public static var lastError(default, null):String = "";
    public static var callbackInterval:Float = 0.1;
    public static var onConnected:UserProfile->Void;
    public static var onDisconnected:Int->String->Void;
    public static var onError:Int->String->Void;

    private static inline var DEFAULT_ID:String = "1542326737474687058";
    public static var clientID(default, set):String = DEFAULT_ID;

    private static var presence:DiscordPresence = new DiscordPresence();
    private static var worker:Thread;
    private static var workerRunning:Bool = false;
    private static var registeredClose:Bool = false;
    private static var handlers:DiscordEventHandlers;

    public static function check():Void
    {
        if (ClientPrefs.data.discordRPC)
            initialize();
        else
            shutdown();
    }

    public static function prepare():Void
    {
        if (!registeredClose && Application.current != null && Application.current.window != null)
        {
            Application.current.window.onClose.add(handleClose);
            registeredClose = true;
        }
        check();
    }

    private static function handleClose():Void
    {
        shutdown();
    }

    public static function initialize():Void
    {
        if (isInitialized || isConnecting || !ClientPrefs.data.discordRPC)
            return;

        isConnecting = true;
        lastError = "";
        try
        {
            handlers = DiscordEventHandlers.create();
            handlers.ready = cpp.Function.fromStaticFunction(onReady);
            handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnectedNative);
            handlers.errored = cpp.Function.fromStaticFunction(onErrorNative);

            Discord.Initialize(clientID, cpp.RawPointer.addressOf(handlers), 1, null);
            isInitialized = true;
            isConnecting = false;
            startWorker();
            updatePresence();
        }
        catch (e:Dynamic)
        {
            isConnecting = false;
            isInitialized = false;
            lastError = Std.string(e);
        }
    }

    private static function startWorker():Void
    {
        if (workerRunning) return;
        workerRunning = true;
        worker = Thread.create(function()
        {
            while (workerRunning)
            {
                if (isInitialized)
                {
                    try
                    {
                        #if DISCORD_DISABLE_IO_THREAD
                        Discord.UpdateConnection();
                        #end
                        Discord.RunCallbacks();
                    }
                    catch (e:Dynamic)
                    {
                        lastError = Std.string(e);
                    }
                }
                var interval:Float = callbackInterval;
                if (interval < 0.05) interval = 0.05;
                if (interval > 1) interval = 1;
                Sys.sleep(interval);
            }
        });
    }

    public static function shutdown():Void
    {
        if (!isInitialized && !isConnecting) return;

        isInitialized = false;
        isConnecting = false;
        currentUser = null;

        try
        {
            Discord.ClearPresence();
            Discord.Shutdown();
        }
        catch (e:Dynamic)
        {
            lastError = Std.string(e);
        }
    }

    private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void
    {
        if (!isInitialized) return;

        var nativeUser = request[0];
        var name:String = cast(nativeUser.username, String);
        var discriminator:String = cast(nativeUser.discriminator, String);
        var id:String = cast(nativeUser.userId, String);
        var avatar:String = cast(nativeUser.avatar, String);

        currentUser = new UserProfile(id, name, null, discriminator, avatar);
        if (onConnected != null) onConnected(currentUser);
        updatePresence();
    }

    private static function onErrorNative(code:Int, message:cpp.ConstCharStar):Void
    {
        lastError = cast(message, String);
        if (onError != null) onError(code, lastError);
    }

    private static function onDisconnectedNative(code:Int, message:cpp.ConstCharStar):Void
    {
        currentUser = null;
        var reason:String = cast(message, String);
        lastError = reason;
        if (onDisconnected != null) onDisconnected(code, reason);
    }

    public static function changePresence(
        details:String = "In the Menus",
        ?state:String,
        ?smallImageKey:String,
        ?hasStartTimestamp:Bool,
        ?endTimestamp:Float,
        largeImageKey:String = "icon"
    ):Void
    {
        presence.details = safeText(details, 128);
        presence.state = safeText(state, 128);
        presence.smallImageKey = safeText(smallImageKey, 32);
        presence.largeImageKey = safeText(largeImageKey, 32);
        presence.largeImageText = "Engine Version: " + states.MainMenuState.psychEngineVersion;

        var start:Int = hasStartTimestamp == true ? Std.int(Date.now().getTime() / 1000) : 0;
        var finish:Int = 0;
        if (endTimestamp != null && endTimestamp > 0)
            finish = (start > 0 ? start : Std.int(Date.now().getTime() / 1000)) + Std.int(endTimestamp / 1000);

        presence.startTimestamp = start;
        presence.endTimestamp = finish;
        updatePresence();
    }

    public static function updatePresence():Void
    {
        if (!isInitialized) return;
        try
        {
            Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence.__presence));
        }
        catch (e:Dynamic)
        {
            lastError = Std.string(e);
        }
    }

    public static function clearPresence():Void
    {
        if (isInitialized) Discord.ClearPresence();
    }

    public static function resetClientID():Void
    {
        clientID = DEFAULT_ID;
    }

    private static function set_clientID(value:String):String
    {
        if (value == null || value.length == 0) value = DEFAULT_ID;
        if (value == clientID) return clientID;
        var restart:Bool = isInitialized;
        if (restart) shutdown();
        clientID = value;
        if (restart) initialize();
        return clientID;
    }

    private static function safeText(value:String, limit:Int):String
    {
        if (value == null) return "";
        value = StringTools.trim(value);
        return value.length > limit ? value.substr(0, limit) : value;
    }

    #if MODS_ALLOWED
    public static function loadModRPC():Void
    {
        var pack:Dynamic = Mods.getPack();
        if (pack != null && pack.discordRPC != null)
            clientID = Std.string(pack.discordRPC);
    }
    #end

    #if LUA_ALLOWED
    public static function addLuaCallbacks(lua:State):Void
    {
        Lua_helper.add_callback(lua, "changeDiscordPresence", changePresence);
        Lua_helper.add_callback(lua, "changeDiscordClientID", function(?id:String)
        {
            clientID = id == null ? DEFAULT_ID : id;
        });
    }
    #end
}

@:allow(backend.DiscordClient)
private final class DiscordPresence
{
    public var state(get, set):String;
    public var details(get, set):String;
    public var smallImageKey(get, set):String;
    public var largeImageKey(get, set):String;
    public var largeImageText(get, set):String;
    public var startTimestamp(get, set):Int;
    public var endTimestamp(get, set):Int;

    @:noCompletion private var __presence:DiscordRichPresence;

    public function new()
    {
        __presence = DiscordRichPresence.create();
    }

    public function toString():String
    {
        return FlxStringUtil.getDebugString([
            LabelValuePair.weak("state", state),
            LabelValuePair.weak("details", details),
            LabelValuePair.weak("smallImageKey", smallImageKey),
            LabelValuePair.weak("largeImageKey", largeImageKey),
            LabelValuePair.weak("largeImageText", largeImageText),
            LabelValuePair.weak("startTimestamp", startTimestamp),
            LabelValuePair.weak("endTimestamp", endTimestamp)
        ]);
    }

    inline function get_state():String return __presence.state;
    inline function set_state(value:String):String return __presence.state = value;
    inline function get_details():String return __presence.details;
    inline function set_details(value:String):String return __presence.details = value;
    inline function get_smallImageKey():String return __presence.smallImageKey;
    inline function set_smallImageKey(value:String):String return __presence.smallImageKey = value;
    inline function get_largeImageKey():String return __presence.largeImageKey;
    inline function set_largeImageKey(value:String):String return __presence.largeImageKey = value;
    inline function get_largeImageText():String return __presence.largeImageText;
    inline function set_largeImageText(value:String):String return __presence.largeImageText = value;
    inline function get_startTimestamp():Int return __presence.startTimestamp;
    inline function set_startTimestamp(value:Int):Int return __presence.startTimestamp = value;
    inline function get_endTimestamp():Int return __presence.endTimestamp;
    inline function set_endTimestamp(value:Int):Int return __presence.endTimestamp = value;
}
#end
