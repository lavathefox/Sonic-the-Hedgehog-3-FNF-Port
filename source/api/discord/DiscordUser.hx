package api.discord;

import haxe.Json;
import StringTools;

typedef DiscordUserData =
{
    var id:String;
    var username:String;
    @:optional var globalName:String;
    @:optional var discriminator:String;
    @:optional var avatar:String;
    @:optional var bot:Bool;
}

class DiscordUser
{
    public var id(default, null):String;
    public var username(default, null):String;
    public var globalName(default, null):String;
    public var discriminator(default, null):String;
    public var avatar(default, null):String;
    public var bot(default, null):Bool;

    public var displayName(get, never):String;
    public var tag(get, never):String;
    public var avatarURL(get, never):String;
    public var hasAvatar(get, never):Bool;

    public function new(id:String, username:String, ?globalName:String, ?discriminator:String, ?avatar:String, bot:Bool = false)
    {
        this.id = normalizeId(id);
        this.username = clean(username, 32);
        this.globalName = clean(globalName, 32);
        this.discriminator = clean(discriminator, 4);
        this.avatar = clean(avatar, 256);
        this.bot = bot;
    }

    public static function fromDynamic(data:Dynamic):Null<DiscordUser>
    {
        if (data == null) return null;

        var userId:String = readString(data, "id");
        var userName:String = readString(data, "username");
        if (normalizeId(userId).length == 0 || clean(userName, 32).length == 0)
            return null;

        return new DiscordUser(
            userId,
            userName,
            readString(data, "global_name"),
            readString(data, "discriminator"),
            readString(data, "avatar"),
            Reflect.field(data, "bot") == true
        );
    }

    public static function fromJson(json:String):Null<DiscordUser>
    {
        if (json == null || json.length == 0) return null;
        try
        {
            return fromDynamic(Json.parse(json));
        }
        catch (_:Dynamic)
        {
            return null;
        }
    }

    public function toData():DiscordUserData
    {
        return {
            id: id,
            username: username,
            globalName: globalName,
            discriminator: discriminator,
            avatar: avatar,
            bot: bot
        };
    }

    public function toJson():String
    {
        return Json.stringify(toData());
    }

    public function isValid():Bool
    {
        return id.length > 0 && username.length > 0;
    }

    public function matchesId(otherId:String):Bool
    {
        return id.length > 0 && id == normalizeId(otherId);
    }

    public function getAvatarURL(size:Int = 128):String
    {
        if (!hasAvatar || id.length == 0) return "";

        var validSize:Int = 16;
        while (validSize < size && validSize < 4096)
            validSize *= 2;

        var extension:String = StringTools.startsWith(avatar, "a_") ? "gif" : "png";
        return 'https://cdn.discordapp.com/avatars/$id/$avatar.$extension?size=$validSize';
    }

    public function getDefaultAvatarURL():String
    {
        var index:Int = 0;
        if (discriminator != null && discriminator.length > 0 && discriminator != "0")
        {
            var parsed = Std.parseInt(discriminator);
            if (parsed != null) index = parsed % 5;
        }
        else
        {
            index = 0;
        }
        return 'https://cdn.discordapp.com/embed/avatars/$index.png';
    }

    public function getMention():String
    {
        return id.length > 0 ? '<@$id>' : "";
    }

    function get_displayName():String
    {
        return globalName.length > 0 ? globalName : username;
    }

    function get_tag():String
    {
        return discriminator.length > 0 && discriminator != "0"
            ? username + "#" + discriminator
            : username;
    }

    function get_avatarURL():String
    {
        return hasAvatar ? getAvatarURL() : getDefaultAvatarURL();
    }

    function get_hasAvatar():Bool
    {
        return avatar.length > 0;
    }

    private static function readString(data:Dynamic, field:String):String
    {
        var value:Dynamic = Reflect.field(data, field);
        return value == null ? "" : Std.string(value);
    }

    private static function clean(value:String, maxLength:Int):String
    {
        if (value == null) return "";
        var result = StringTools.trim(value);
        return result.length > maxLength ? result.substr(0, maxLength) : result;
    }

    private static function normalizeId(value:String):String
    {
        var result = clean(value, 32);
        if (result.length == 0) return "";
        for (i in 0...result.length)
        {
            var code:Int = result.charCodeAt(i);
            if (code < 48 || code > 57) return "";
        }
        return result;
    }
}
