package external.windows;

#if (windows && cpp)
@:cppFileCode('
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#ifndef NOMINMAX
#define NOMINMAX
#endif

#include <windows.h>
#include <psapi.h>
#include <string>

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "psapi.lib")

namespace SonicWinAPI
{
    static std::wstring toWide(const char* text)
    {
        if (text == nullptr)
            return L"";

        int length = MultiByteToWideChar(
            CP_UTF8, 0, text, -1, nullptr, 0
        );

        if (length <= 0)
            return L"";

        std::wstring result(length, L\'\\0\');

        if (!MultiByteToWideChar(
            CP_UTF8, 0, text, -1, &result[0], length
        ))
            return L"";

        result.resize(length - 1);
        return result;
    }

    struct WindowSearch
    {
        DWORD processId;
        HWND window;
    };

    static BOOL CALLBACK findWindow(HWND hwnd, LPARAM param)
    {
        WindowSearch* search =
            reinterpret_cast<WindowSearch*>(param);

        DWORD processId = 0;

        GetWindowThreadProcessId(hwnd, &processId);

        if (processId != search->processId)
            return TRUE;

        if (GetWindow(hwnd, GW_OWNER) != nullptr)
            return TRUE;

        if (!IsWindowVisible(hwnd))
            return TRUE;

        search->window = hwnd;
        return FALSE;
    }

    static HWND getWindow()
    {
        WindowSearch search = {
            GetCurrentProcessId(),
            nullptr
        };

        EnumWindows(
            findWindow,
            reinterpret_cast<LPARAM>(&search)
        );

        return search.window;
    }

    static bool setTitle(const char* title)
    {
        HWND hwnd = getWindow();

        if (hwnd == nullptr)
            return false;

        std::wstring value = toWide(title);

        return SetWindowTextW(
            hwnd, value.c_str()
        ) != 0;
    }

    static bool isFocused()
    {
        HWND hwnd = getWindow();

        return hwnd != nullptr &&
            GetForegroundWindow() == hwnd;
    }

    static double getMemory()
    {
        PROCESS_MEMORY_COUNTERS_EX info = {};

        info.cb = sizeof(info);

        if (!GetProcessMemoryInfo(
            GetCurrentProcess(),
            reinterpret_cast<PROCESS_MEMORY_COUNTERS*>(&info),
            sizeof(info)
        ))
            return 0.0;

        return static_cast<double>(info.WorkingSetSize);
    }

    static std::string getVersion()
    {
        typedef LONG (WINAPI *VersionFunction)(
            OSVERSIONINFOW*
        );

        HMODULE module = GetModuleHandleW(L"ntdll.dll");

        if (module == nullptr)
            return "Windows";

        VersionFunction function =
            reinterpret_cast<VersionFunction>(
                GetProcAddress(module, "RtlGetVersion")
            );

        if (function == nullptr)
            return "Windows";

        OSVERSIONINFOEXW info = {};
        info.dwOSVersionInfoSize = sizeof(info);

        if (function(
            reinterpret_cast<OSVERSIONINFOW*>(&info)
        ) != 0)
            return "Windows";

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

        return name;
    }

    static bool showMessage(
        const char* title,
        const char* message,
        bool error
    )
    {
        std::wstring nativeTitle = toWide(title);
        std::wstring nativeMessage = toWide(message);

        UINT flags = MB_OK |
            (error ? MB_ICONERROR : MB_ICONINFORMATION);

        return MessageBoxW(
            getWindow(),
            nativeMessage.c_str(),
            nativeTitle.c_str(),
            flags
        ) != 0;
    }

    static bool preventSleep(bool enabled)
    {
        EXECUTION_STATE flags = enabled
            ? ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED
            : ES_CONTINUOUS;

        return SetThreadExecutionState(flags) != 0;
    }
}
')
#end
class WinAPI
{
    public static var performanceMode(default, null):Bool = false;
    public static var sleepPrevention(default, null):Bool = false;

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
        return nativeIsFocused();
        #else
        return false;
        #end
    }

    public static function getMemoryUsage():Float
    {
        #if (windows && cpp)
        return nativeGetMemory();
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
        return nativeGetVersion();
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
        var priority:Int = getPriority();

        if (priority == 0)
            return false;

        if (!nativeEnablePerformance())
            return false;

        previousPriority = priority;
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

    public static function setSleepPrevention(enabled:Bool):Bool
    {
        #if (windows && cpp)
        if (!nativePreventSleep(enabled))
            return false;

        sleepPrevention = enabled;
        return true;
        #else
        return false;
        #end
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

    public static function shutdown():Void
    {
        if (performanceMode)
            disablePerformanceMode();

        if (sleepPrevention)
            setSleepPrevention(false);
    }

    #if (windows && cpp)

    @:functionCode('
        return static_cast<int>(GetCurrentProcessId());
    ')
    private static function nativeProcessID():Int
    {
        return 0;
    }

    @:functionCode('
        return SonicWinAPI::setTitle(title.utf8_str());
    ')
    private static function nativeSetWindowTitle(
        title:String
    ):Bool
    {
        return false;
    }

    @:functionCode('
        return SonicWinAPI::isFocused();
    ')
    private static function nativeIsFocused():Bool
    {
        return false;
    }

    @:functionCode('
        return SonicWinAPI::getMemory();
    ')
    private static function nativeGetMemory():Float
    {
        return 0;
    }

    @:functionCode('
        std::string version = SonicWinAPI::getVersion();
        return ::String(version.c_str());
    ')
    private static function nativeGetVersion():String
    {
        return "";
    }

    @:functionCode('
        return static_cast<int>(
            GetPriorityClass(GetCurrentProcess())
        );
    ')
    private static function nativeGetPriority():Int
    {
        return 0;
    }

    @:functionCode('
        return SetPriorityClass(
            GetCurrentProcess(),
            static_cast<DWORD>(priority)
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
        return SonicWinAPI::preventSleep(enabled);
    ')
    private static function nativePreventSleep(
        enabled:Bool
    ):Bool
    {
        return false;
    }

    @:functionCode('
        SonicWinAPI::showMessage(
            title.utf8_str(),
            message.utf8_str(),
            error
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
