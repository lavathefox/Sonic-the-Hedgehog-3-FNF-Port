package hscript;

import haxe.ds.StringMap;

#if HSCRIPT_ALLOWED
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
#end

class HaxeScripted
{
    public var path(default, null):String;
    public var active(default, null):Bool = false;
    public var lastError(default, null):String = '';
    public var onError:String->Void;

    #if HSCRIPT_ALLOWED
    public var interp(default, null):Interp;
    public var parser(default, null):Parser;
    public var program(default, null):Expr;
    #end

    var variables:StringMap<Dynamic> = new StringMap<Dynamic>();
    var running:Bool = false;

    public function new(?scriptPath:String)
    {
        path = scriptPath;
        #if HSCRIPT_ALLOWED
        parser = new Parser();
        parser.allowTypes = true;
        parser.allowJSON = true;
        interp = new Interp();
        for (name in variables.keys()) interp.variables.set(name, variables.get(name));
        #else
        fail('HScript support is disabled. Compile with -D HSCRIPT_ALLOWED and install hscript.');
        #end
        if (scriptPath != null) load(scriptPath);
    }

    public function set(name:String, value:Dynamic):Void
    {
        if (name == null || name.length == 0) return;
        variables.set(name, value);
        #if HSCRIPT_ALLOWED
        interp.variables.set(name, value);
        #end
    }

    public function get(name:String):Dynamic
    {
        #if HSCRIPT_ALLOWED
        if (interp.variables.exists(name)) return interp.variables.get(name);
        #end
        return variables.get(name);
    }

    public function exists(name:String):Bool
    {
        #if HSCRIPT_ALLOWED
        if (interp.variables.exists(name)) return true;
        #end
        return variables.exists(name);
    }

    public function remove(name:String):Bool
    {
        #if HSCRIPT_ALLOWED
        interp.variables.remove(name);
        #end
        return variables.remove(name);
    }

    public function load(scriptPath:String):Bool
    {
        path = scriptPath;
        #if sys
        try
        {
            if (!sys.FileSystem.exists(scriptPath)) return fail('Script not found: ' + scriptPath);
            return executeString(sys.io.File.getContent(scriptPath));
        }
        catch (e:Dynamic) return fail(Std.string(e));
        #else
        return fail('Loading files requires a sys target. Use executeString() for embedded scripts.');
        #end
    }

    public function executeString(source:String):Bool
    {
        active = false;
        if (source == null) return fail('Script source is null.');
        #if HSCRIPT_ALLOWED
        try
        {
            program = parser.parseString(source);
            interp.execute(program);
            active = true;
            lastError = '';
            return true;
        }
        catch (e:Dynamic) return fail(Std.string(e));
        #else
        return fail('HScript support is disabled.');
        #end
    }

    public function call(name:String, ?args:Array<Dynamic>):Dynamic
    {
        if (!active || running) return null;
        var fn:Dynamic = get(name);
        if (fn == null || !Reflect.isFunction(fn)) return null;
        if (args == null) args = [];
        running = true;
        try
        {
            var result:Dynamic = Reflect.callMethod(null, fn, args);
            running = false;
            return result;
        }
        catch (e:Dynamic)
        {
            running = false;
            fail('Error in ' + name + ': ' + Std.string(e));
            return null;
        }
    }

    public function reload():Bool
    {
        if (path == null) return fail('No script path to reload.');
        return load(path);
    }

    public function destroy():Void
    {
        active = false;
        running = false;
        variables = new StringMap<Dynamic>();
        #if HSCRIPT_ALLOWED
        program = null;
        interp = new Interp();
        #end
    }

    function fail(message:String):Bool
    {
        lastError = message;
        active = false;
        if (onError != null) onError(message);
        return false;
    }
}
