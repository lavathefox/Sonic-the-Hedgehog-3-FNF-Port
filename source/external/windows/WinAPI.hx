package external.windows;

#if (windows && cpp)
import cpp.Lib;
#end

#if (windows && cpp)
@:headerCode('
#ifndef NOMINMAX
#define NOMINMAX
#endif

#include <windows.h>
#include <psapi.h>
#include <string>

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "psapi.lib")

static std::wstring winapi_utf16(const char* text)
{
    if (text == nullptr)
        return L"";

    int length = MultiByteToWideChar(
        CP_UTF8, 0, text, -1, nullptr, 0
    );

    if (length <= 0)
        return L"";

    std::wstring result(length, L\'\\0\');

    MultiByteToWideChar(
        CP_UTF8, 0, text, -1,
        &result[0], length
    );

    result.resize(length - 1);
    return result;
}

static HWND winapi_window()
{
    DWORD pid = GetCurrentProcessId();
    HWND result = nullptr;

    struct WindowData
    {
        DWORD pid;
        HWND window;
    };

    WindowData data = {pid, nullptr};

    EnumWindows([](HWND hwnd, LPARAM param) -> BOOL
    {
        WindowData* data =
            reinterpret_cast<WindowData*>(param);

        DWORD windowPid = 0;
        GetWindowThreadProcessId(hwnd, &windowPid);

        if (windowPid == data->pid &&
            GetWindow(hwnd, GW_OWNER) == nullptr &&
            IsWindowVisible(hwnd))
        {
            data->window = hwnd;
            return FALSE;
        }

        return TRUE;
    }, reinterpret_cast<LPARAM>(&data));

    result = data.window;
    return result;
}
')
#end
class WinAPI
{
    public static var performanceMode(default, null):Bool = false;

    private static var previousPriority:Int = 0;

    public static function isSupported():Bool
    {
        #if (windows && cpp)
        return true;
        #else
        return false;
        #end
    }

    public static function getProcessID():Int
    {
        #if (windows && cpp)
        return nativeProcessID();
        #else
        return -1;
        #end
    }

    public static function setWindowTitle(title:String):Bool
    {
        #if (windows && cpp)
        return nativeSetWindowTitle(title);
        #else
        return false;
        #end
    }

    public static function isWindowFocused():Bool
    {
        #if (windows && cpp)
        return nativeWindowFocused();
        #else
        return false;
        #end
    }

    public static function getMemoryUsage():Float
    {
        #if (windows && cpp)
        return nativeMemoryUsage();
        #else
        return 0;
        #end
    }

    public static function getMemoryUsageMB():Float
    {
        return getMemoryUsage() / 1048576.0;
    }

    public static function getWindowsVersion():String
    {
        #if (windows && cpp)
        return nativeWindowsVersion();
        #else
        return "Unsupported";
        #end
    }

    public static function getPriority():Int
    {
        #if (windows && cpp)
        return nativeGetPriority();
        #else
        return 0;
        #end
    }

    public static function setPriority(priority:Int):Bool
    {
        #if (windows && cpp)
        return nativeSetPriority(priority);
        #else
        return false;
        #end
    }

    public static function enablePerformanceMode():Bool
    {
        if (performanceMode)
            return true;

        #if (windows && cpp)
        previousPriority = getPriority();

        if (previousPriority == 0)
            return false;

        if (!nativeEnablePerformance())
            return false;

        performanceMode = true;
        return true;
        #else
        return false;
        #end
    }

    public static function disablePerformanceMode():Bool
    {
        if (!performanceMode)
            return true;

        if (!setPriority(previousPriority))
            return false;

        performanceMode = false;
        previousPriority = 0;
        return true;
    }

    public static function showMessage(
        title:String,
        message:String,
        ?error:Bool = false
    ):Void
    {
        #if (windows && cpp)
        nativeShowMessage(title, message, error);
        #end
    }

    #if (windows && cpp)

    @:functionCode('
        return (int)GetCurrentProcessId();
    ')
    private static function nativeProcessID():Int
    {
        return 0;
    }

    @:functionCode('
        HWND hwnd = winapi_window();

        if (!hwnd)
            return false;

        std::wstring text = winapi_utf16(title.utf8_str());

        return SetWindowTextW(
            hwnd, text.c_str()
        ) != 0;
    ')
    private static function nativeSetWindowTitle(
        title:String
    ):Bool
    {
        return false;
    }

    @:functionCode('
        HWND hwnd = winapi_window();

        return hwnd != nullptr &&
            GetForegroundWindow() == hwnd;
    ')
    private static function nativeWindowFocused():Bool
    {
        return false;
    }

    @:functionCode('
        PROCESS_MEMORY_COUNTERS_EX memory = {};

        memory.cb = sizeof(memory);

        if (!GetProcessMemoryInfo(
            GetCurrentProcess(),
            reinterpret_cast<PROCESS_MEMORY_COUNTERS*>(&memory),
            sizeof(memory)
        ))
            return 0;

        return (double)memory.WorkingSetSize;
    ')
    private static function nativeMemoryUsage():Float
    {
        return 0;
    }

    @:functionCode('
        OSVERSIONINFOEXW info = {};
        info.dwOSVersionInfoSize = sizeof(info);

        typedef LONG (WINAPI *RtlGetVersionFn)(
            OSVERSIONINFOW*
        );

        HMODULE module = GetModuleHandleW(L"ntdll.dll");

        if (!module)
            return ::String("Windows");

        RtlGetVersionFn getVersion =
            reinterpret_cast<RtlGetVersionFn>(
                GetProcAddress(module, "RtlGetVersion")
            );

        if (!getVersion ||
            getVersion(
                reinterpret_cast<OSVERSIONINFOW*>(&info)
            ) != 0)
            return ::String("Windows");

        std::string name = "Windows ";

        if (info.dwMajorVersion == 10)
        {
            name += info.dwBuildNumber >= 22000
                ? "11"
                : "10";
        }
        else
        {
            name += std::to_string(info.dwMajorVersion);
            name += ".";
            name += std::to_string(info.dwMinorVersion);
        }

        name += " (Build ";
        name += std::to_string(info.dwBuildNumber);
        name += ")";

        return ::String(name.c_str());
    ')
    private static function nativeWindowsVersion():String
    {
        return "";
    }

    @:functionCode('
        DWORD priority = GetPriorityClass(
            GetCurrentProcess()
        );

        return (int)priority;
    ')
    private static function nativeGetPriority():Int
    {
        return 0;
    }

    @:functionCode('
        return SetPriorityClass(
            GetCurrentProcess(),
            (DWORD)priority
        ) != 0;
    ')
    private static function nativeSetPriority(
        priority:Int
    ):Bool
    {
        return false;
    }

    @:functionCode('
        return SetPriorityClass(
            GetCurrentProcess(),
            ABOVE_NORMAL_PRIORITY_CLASS
        ) != 0;
    ')
    private static function nativeEnablePerformance():Bool
    {
        return false;
    }

    @:functionCode('
        std::wstring nativeTitle =
            winapi_utf16(title.utf8_str());

        std::wstring nativeMessage =
            winapi_utf16(message.utf8_str());

        UINT flags = MB_OK |
            (error ? MB_ICONERROR : MB_ICONINFORMATION);

        MessageBoxW(
            winapi_window(),
            nativeMessage.c_str(),
            nativeTitle.c_str(),
            flags
        );
    ')
    private static function nativeShowMessage(
        title:String,
        message:String,
        error:Bool
    ):Void
    {
    }

    #end
}
