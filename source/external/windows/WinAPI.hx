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
#include <algorithm>
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "psapi.lib")

namespace SonicWinAPI
{
    static std::wstring wide(const char* text)
    {
        if (!text) return L"";
        int n = MultiByteToWideChar(CP_UTF8, 0, text, -1, nullptr, 0);
        if (n <= 0) return L"";
        std::wstring result(static_cast<size_t>(n), L\'\\0\');
        if (!MultiByteToWideChar(CP_UTF8, 0, text, -1, &result[0], n)) return L"";
        result.resize(static_cast<size_t>(n - 1));
        return result;
    }

    struct Search { DWORD pid; HWND hwnd; };
    static BOOL CALLBACK enumerate(HWND hwnd, LPARAM param)
    {
        Search* s = reinterpret_cast<Search*>(param);
        DWORD pid = 0;
        GetWindowThreadProcessId(hwnd, &pid);
        if (pid != s->pid || GetWindow(hwnd, GW_OWNER) != nullptr || !IsWindowVisible(hwnd)) return TRUE;
        s->hwnd = hwnd;
        return FALSE;
    }
    static HWND window()
    {
        Search s = { GetCurrentProcessId(), nullptr };
        EnumWindows(enumerate, reinterpret_cast<LPARAM>(&s));
        return s.hwnd;
    }
    static bool title(const char* value)
    {
        HWND h = window();
        if (!h) return false;
        std::wstring w = wide(value);
        return SetWindowTextW(h, w.c_str()) != 0;
    }
    static bool focused()
    {
        HWND h = window();
        return h && (GetForegroundWindow() == h || GetAncestor(GetForegroundWindow(), GA_ROOT) == h);
    }
    static double memory()
    {
        PROCESS_MEMORY_COUNTERS_EX m = {};
        m.cb = sizeof(m);
        if (!GetProcessMemoryInfo(GetCurrentProcess(), reinterpret_cast<PROCESS_MEMORY_COUNTERS*>(&m), sizeof(m))) return 0;
        return static_cast<double>(m.WorkingSetSize);
    }
    static double peakMemory()
    {
        PROCESS_MEMORY_COUNTERS_EX m = {};
        m.cb = sizeof(m);
        if (!GetProcessMemoryInfo(GetCurrentProcess(), reinterpret_cast<PROCESS_MEMORY_COUNTERS*>(&m), sizeof(m))) return 0;
        return static_cast<double>(m.PeakWorkingSetSize);
    }
    static std::string version()
    {
        typedef LONG (WINAPI *GetVersionFn)(OSVERSIONINFOW*);
        HMODULE mod = GetModuleHandleW(L"ntdll.dll");
        if (!mod) return "Windows";
        GetVersionFn fn = reinterpret_cast<GetVersionFn>(GetProcAddress(mod, "RtlGetVersion"));
        if (!fn) return "Windows";
        OSVERSIONINFOEXW v = {};
        v.dwOSVersionInfoSize = sizeof(v);
        if (fn(reinterpret_cast<OSVERSIONINFOW*>(&v)) != 0) return "Windows";
        std::string name = "Windows ";
        if (v.dwMajorVersion == 10) name += v.dwBuildNumber >= 22000 ? "11" : "10";
        else name += std::to_string(v.dwMajorVersion) + "." + std::to_string(v.dwMinorVersion);
        return name + " (Build " + std::to_string(v.dwBuildNumber) + ")";
    }
    static bool message(const char* title, const char* text, bool error)
    {
        std::wstring t = wide(title), m = wide(text);
        return MessageBoxW(window(), m.c_str(), t.c_str(), MB_OK | (error ? MB_ICONERROR : MB_ICONINFORMATION)) != 0;
    }
    static bool preventSleep(bool enabled)
    {
        EXECUTION_STATE flags = enabled ? ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED : ES_CONTINUOUS;
        return SetThreadExecutionState(flags) != 0;
    }
    static bool size(int w, int h)
    {
        HWND hwnd = window();
        if (!hwnd || w < 1 || h < 1) return false;
        RECT rect = {0, 0, w, h};
        DWORD style = static_cast<DWORD>(GetWindowLongPtrW(hwnd, GWL_STYLE));
        DWORD exstyle = static_cast<DWORD>(GetWindowLongPtrW(hwnd, GWL_EXSTYLE));
        if (!AdjustWindowRectEx(&rect, style, GetMenu(hwnd) != nullptr, exstyle)) return false;
        return SetWindowPos(hwnd, nullptr, 0, 0, rect.right - rect.left, rect.bottom - rect.top, SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE) != 0;
    }
    static bool position(int x, int y)
    {
        HWND hwnd = window();
        return hwnd && SetWindowPos(hwnd, nullptr, x, y, 0, 0, SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE) != 0;
    }
    static bool center()
    {
        HWND hwnd = window();
        if (!hwnd) return false;
        RECT rect = {};
        if (!GetWindowRect(hwnd, &rect)) return false;
        HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
        MONITORINFO info = {};
        info.cbSize = sizeof(info);
        if (!GetMonitorInfoW(monitor, &info)) return false;
        int w = rect.right - rect.left, h = rect.bottom - rect.top;
        int x = info.rcWork.left + ((info.rcWork.right - info.rcWork.left) - w) / 2;
        int y = info.rcWork.top + ((info.rcWork.bottom - info.rcWork.top) - h) / 2;
        return position(x, y);
    }
    static bool resizable(bool enabled)
    {
        HWND hwnd = window();
        if (!hwnd) return false;
        LONG_PTR style = GetWindowLongPtrW(hwnd, GWL_STYLE);
        if (enabled) style |= WS_THICKFRAME | WS_MAXIMIZEBOX;
        else style &= ~(WS_THICKFRAME | WS_MAXIMIZEBOX);
        SetLastError(0);
        LONG_PTR old = SetWindowLongPtrW(hwnd, GWL_STYLE, style);
        if (old == 0 && GetLastError() != 0) return false;
        return SetWindowPos(hwnd, nullptr, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED) != 0;
    }
    static bool topmost(bool enabled)
    {
        HWND hwnd = window();
        return hwnd && SetWindowPos(hwnd, enabled ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE) != 0;
    }
    static bool minimize()
    {
        HWND hwnd = window();
        if (!hwnd) return false;
        ShowWindow(hwnd, SW_MINIMIZE);
        return true;
    }
    static bool restore()
    {
        HWND hwnd = window();
        if (!hwnd) return false;
        ShowWindow(hwnd, SW_RESTORE);
        return true;
    }
    static bool maximize()
    {
        HWND hwnd = window();
        if (!hwnd) return false;
        ShowWindow(hwnd, SW_MAXIMIZE);
        return true;
    }
    static bool foreground()
    {
        HWND hwnd = window();
        if (!hwnd) return false;
        if (IsIconic(hwnd)) ShowWindow(hwnd, SW_RESTORE);
        return SetForegroundWindow(hwnd) != 0;
    }
    static bool clientSize(int* w, int* h)
    {
        HWND hwnd = window();
        RECT r = {};
        if (!hwnd || !GetClientRect(hwnd, &r)) return false;
        *w = r.right - r.left;
        *h = r.bottom - r.top;
        return true;
    }
    static bool windowRect(int* x, int* y, int* w, int* h)
    {
        HWND hwnd = window();
        RECT r = {};
        if (!hwnd || !GetWindowRect(hwnd, &r)) return false;
        *x = r.left; *y = r.top; *w = r.right - r.left; *h = r.bottom - r.top;
        return true;
    }
    static bool fullscreen = false;
    static WINDOWPLACEMENT placement = { sizeof(WINDOWPLACEMENT) };
    static LONG_PTR savedStyle = 0;
    static LONG_PTR savedExStyle = 0;
    static bool borderless(bool enabled)
    {
        HWND hwnd = window();
        if (!hwnd) return false;
        if (enabled == fullscreen) return true;
        if (enabled)
        {
            placement.length = sizeof(WINDOWPLACEMENT);
            if (!GetWindowPlacement(hwnd, &placement)) return false;
            savedStyle = GetWindowLongPtrW(hwnd, GWL_STYLE);
            savedExStyle = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
            HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
            MONITORINFO info = {};
            info.cbSize = sizeof(info);
            if (!GetMonitorInfoW(monitor, &info)) return false;
            SetWindowLongPtrW(hwnd, GWL_STYLE, savedStyle & ~static_cast<LONG_PTR>(WS_OVERLAPPEDWINDOW));
            if (!SetWindowPos(hwnd, HWND_TOP, info.rcMonitor.left, info.rcMonitor.top, info.rcMonitor.right - info.rcMonitor.left, info.rcMonitor.bottom - info.rcMonitor.top, SWP_FRAMECHANGED | SWP_NOOWNERZORDER))
            {
                SetWindowLongPtrW(hwnd, GWL_STYLE, savedStyle);
                return false;
            }
            fullscreen = true;
            return true;
        }
        SetWindowLongPtrW(hwnd, GWL_STYLE, savedStyle);
        SetWindowLongPtrW(hwnd, GWL_EXSTYLE, savedExStyle);
        SetWindowPlacement(hwnd, &placement);
        if (!SetWindowPos(hwnd, nullptr, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_FRAMECHANGED)) return false;
        fullscreen = false;
        return true;
    }
}
')
#end
class WinAPI
{
    public static var performanceMode(default, null):Bool = false;
    public static var sleepPrevention(default, null):Bool = false;
    public static var lastError(default, null):String = "";
    private static var previousPriority:Int = 0;

    public static inline function isSupported():Bool
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
        return nativeSetWindowTitle(title == null ? "" : title);
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

    public static function getPeakMemoryUsage():Float
    {
        #if (windows && cpp)
        return nativeGetPeakMemory();
        #else
        return 0;
        #end
    }

    public static inline function getMemoryUsageMB():Float return getMemoryUsage() / 1048576.0;
    public static inline function getPeakMemoryUsageMB():Float return getPeakMemoryUsage() / 1048576.0;

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
        if (priority != 0x40 && priority != 0x4000 && priority != 0x20 && priority != 0x8000 && priority != 0x80) return false;
        return nativeSetPriority(priority);
        #else
        return false;
        #end
    }

    public static function enablePerformanceMode():Bool
    {
        if (performanceMode) return true;
        #if (windows && cpp)
        var priority = getPriority();
        if (priority == 0 || !nativeEnablePerformance()) return false;
        previousPriority = priority;
        performanceMode = true;
        return true;
        #else
        return false;
        #end
    }

    public static function disablePerformanceMode():Bool
    {
        if (!performanceMode) return true;
        if (!setPriority(previousPriority)) return false;
        previousPriority = 0;
        performanceMode = false;
        return true;
    }

    public static function setSleepPrevention(enabled:Bool):Bool
    {
        #if (windows && cpp)
        if (!nativePreventSleep(enabled)) return false;
        sleepPrevention = enabled;
        return true;
        #else
        return false;
        #end
    }

    public static function showMessage(title:String, message:String, ?error:Bool = false):Void
    {
        #if (windows && cpp)
        nativeShowMessage(title == null ? "" : title, message == null ? "" : message, error);
        #end
    }

    public static function setWindowSize(width:Int, height:Int):Bool
    {
        #if (windows && cpp)
        return nativeSetSize(width, height);
        #else
        return false;
        #end
    }

    public static function setWindowPosition(x:Int, y:Int):Bool
    {
        #if (windows && cpp)
        return nativeSetPosition(x, y);
        #else
        return false;
        #end
    }

    public static function centerWindow():Bool
    {
        #if (windows && cpp)
        return nativeCenter();
        #else
        return false;
        #end
    }

    public static function setResizable(value:Bool):Bool
    {
        #if (windows && cpp)
        return nativeResizable(value);
        #else
        return false;
        #end
    }

    public static function setAlwaysOnTop(value:Bool):Bool
    {
        #if (windows && cpp)
        return nativeTopmost(value);
        #else
        return false;
        #end
    }

    public static function minimizeWindow():Bool
    {
        #if (windows && cpp)
        return nativeMinimize();
        #else
        return false;
        #end
    }

    public static function maximizeWindow():Bool
    {
        #if (windows && cpp)
        return nativeMaximize();
        #else
        return false;
        #end
    }

    public static function restoreWindow():Bool
    {
        #if (windows && cpp)
        return nativeRestore();
        #else
        return false;
        #end
    }

    public static function focusWindow():Bool
    {
        #if (windows && cpp)
        return nativeForeground();
        #else
        return false;
        #end
    }

    public static function setBorderlessFullscreen(enabled:Bool):Bool
    {
        #if (windows && cpp)
        return nativeBorderless(enabled);
        #else
        return false;
        #end
    }

    public static function toggleBorderlessFullscreen():Bool
    {
        return setBorderlessFullscreen(!isBorderlessFullscreen());
    }

    public static function isBorderlessFullscreen():Bool
    {
        #if (windows && cpp)
        return nativeIsBorderless();
        #else
        return false;
        #end
    }

    public static function getWindowWidth():Int
    {
        #if (windows && cpp)
        return nativeClientWidth();
        #else
        return 0;
        #end
    }

    public static function getWindowHeight():Int
    {
        #if (windows && cpp)
        return nativeClientHeight();
        #else
        return 0;
        #end
    }

    public static function shutdown():Void
    {
        if (performanceMode) disablePerformanceMode();
        if (sleepPrevention) setSleepPrevention(false);
        if (isBorderlessFullscreen()) setBorderlessFullscreen(false);
    }

    #if (windows && cpp)
    @:functionCode('return static_cast<int>(GetCurrentProcessId());')
    private static function nativeProcessID():Int return 0;

    @:functionCode('return SonicWinAPI::title(title.utf8_str());')
    private static function nativeSetWindowTitle(title:String):Bool return false;

    @:functionCode('return SonicWinAPI::focused();')
    private static function nativeIsFocused():Bool return false;

    @:functionCode('return SonicWinAPI::memory();')
    private static function nativeGetMemory():Float return 0;

    @:functionCode('return SonicWinAPI::peakMemory();')
    private static function nativeGetPeakMemory():Float return 0;

    @:functionCode('std::string v = SonicWinAPI::version(); return ::String(v.c_str());')
    private static function nativeGetVersion():String return "";

    @:functionCode('return static_cast<int>(GetPriorityClass(GetCurrentProcess()));')
    private static function nativeGetPriority():Int return 0;

    @:functionCode('return SetPriorityClass(GetCurrentProcess(), static_cast<DWORD>(priority)) != 0;')
    private static function nativeSetPriority(priority:Int):Bool return false;

    @:functionCode('return SetPriorityClass(GetCurrentProcess(), ABOVE_NORMAL_PRIORITY_CLASS) != 0;')
    private static function nativeEnablePerformance():Bool return false;

    @:functionCode('return SonicWinAPI::preventSleep(enabled);')
    private static function nativePreventSleep(enabled:Bool):Bool return false;

    @:functionCode('SonicWinAPI::message(title.utf8_str(), message.utf8_str(), error);')
    private static function nativeShowMessage(title:String, message:String, error:Bool):Void {}

    @:functionCode('return SonicWinAPI::size(width, height);')
    private static function nativeSetSize(width:Int, height:Int):Bool return false;

    @:functionCode('return SonicWinAPI::position(x, y);')
    private static function nativeSetPosition(x:Int, y:Int):Bool return false;

    @:functionCode('return SonicWinAPI::center();')
    private static function nativeCenter():Bool return false;

    @:functionCode('return SonicWinAPI::resizable(value);')
    private static function nativeResizable(value:Bool):Bool return false;

    @:functionCode('return SonicWinAPI::topmost(value);')
    private static function nativeTopmost(value:Bool):Bool return false;

    @:functionCode('return SonicWinAPI::minimize();')
    private static function nativeMinimize():Bool return false;

    @:functionCode('return SonicWinAPI::maximize();')
    private static function nativeMaximize():Bool return false;

    @:functionCode('return SonicWinAPI::restore();')
    private static function nativeRestore():Bool return false;

    @:functionCode('return SonicWinAPI::foreground();')
    private static function nativeForeground():Bool return false;

    @:functionCode('return SonicWinAPI::borderless(enabled);')
    private static function nativeBorderless(enabled:Bool):Bool return false;

    @:functionCode('return SonicWinAPI::fullscreen;')
    private static function nativeIsBorderless():Bool return false;

    @:functionCode('int w = 0, h = 0; SonicWinAPI::clientSize(&w, &h); return w;')
    private static function nativeClientWidth():Int return 0;

    @:functionCode('int w = 0, h = 0; SonicWinAPI::clientSize(&w, &h); return h;')
    private static function nativeClientHeight():Int return 0;
    #end
}
