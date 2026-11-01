#ifndef CLIENT_GAMEMODE_H
#define CLIENT_GAMEMODE_H

#if !defined(__linux__)
#error "GameMode client requires Linux"
#endif

#include <dlfcn.h>
#include <pthread.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>

typedef int (*gm_call)(void);
typedef int (*gm_pid_call)(pid_t);
typedef const char *(*gm_error_call)(void);

typedef struct
{
    void *handle;
    gm_call start;
    gm_call end;
    gm_call status;
    gm_pid_call start_for;
    gm_pid_call end_for;
    gm_pid_call status_for;
    gm_error_call error;
    int loaded;
    char message[512];
} gm_client;

static gm_client gm_state = {0};
static pthread_once_t gm_once = PTHREAD_ONCE_INIT;

static inline void gm_set_error(const char *message)
{
    snprintf(
        gm_state.message,
        sizeof(gm_state.message),
        "%s",
        message != NULL ? message : "Unknown GameMode error"
    );
}

static inline bool gm_bind(
    void *handle,
    const char *name,
    void *destination,
    size_t size,
    bool required
)
{
    dlerror();

    void *symbol = dlsym(handle, name);
    const char *error = dlerror();

    if (error != NULL || symbol == NULL)
    {
        if (required)
        {
            gm_set_error(error != NULL ? error : name);
            return false;
        }

        return true;
    }

    if (size != sizeof(symbol))
    {
        gm_set_error("Incompatible function pointer size");
        return false;
    }

    memcpy(destination, &symbol, size);
    return true;
}

#define GM_BIND(field, symbol, required) \
    gm_bind( \
        gm_state.handle, \
        symbol, \
        &gm_state.field, \
        sizeof(gm_state.field), \
        required \
    )

static void gm_initialize(void)
{
    gm_state.handle = dlopen(
        "libgamemode.so.0",
        RTLD_NOW | RTLD_LOCAL
    );

    if (gm_state.handle == NULL)
    {
        gm_state.handle = dlopen(
            "libgamemode.so",
            RTLD_NOW | RTLD_LOCAL
        );
    }

    if (gm_state.handle == NULL)
    {
        gm_set_error(dlerror());
        return;
    }

    bool success =
        GM_BIND(start, "real_gamemode_request_start", true) &&
        GM_BIND(end, "real_gamemode_request_end", true) &&
        GM_BIND(error, "real_gamemode_error_string", true) &&
        GM_BIND(status, "real_gamemode_query_status", false) &&
        GM_BIND(start_for, "real_gamemode_request_start_for", false) &&
        GM_BIND(end_for, "real_gamemode_request_end_for", false) &&
        GM_BIND(status_for, "real_gamemode_query_status_for", false);

    if (!success)
    {
        dlclose(gm_state.handle);
        gm_state.handle = NULL;
        return;
    }

    gm_state.loaded = 1;
}

#undef GM_BIND

static inline int gm_ready(void)
{
    if (pthread_once(&gm_once, gm_initialize) != 0)
    {
        return 0;
    }

    return gm_state.loaded;
}

static inline const char *gamemode_error_string(void)
{
    if (!gm_ready())
    {
        return gm_state.message[0] != '\0'
            ? gm_state.message
            : "GameMode initialization failed";
    }

    if (gm_state.error != NULL)
    {
        return gm_state.error();
    }

    return "Unknown GameMode error";
}

#ifdef GAMEMODE_AUTO
__attribute__((constructor))
#else
static inline
#endif
int gamemode_request_start(void)
{
    int result = gm_ready() ? gm_state.start() : -1;

#ifdef GAMEMODE_AUTO
    if (result < 0)
    {
        fprintf(
            stderr,
            "gamemodeauto: %s\n",
            gamemode_error_string()
        );
    }
#endif

    return result;
}

#ifdef GAMEMODE_AUTO
__attribute__((destructor))
#else
static inline
#endif
int gamemode_request_end(void)
{
    int result = gm_ready() ? gm_state.end() : -1;

#ifdef GAMEMODE_AUTO
    if (result < 0)
    {
        fprintf(
            stderr,
            "gamemodeauto: %s\n",
            gamemode_error_string()
        );
    }
#endif

    return result;
}

static inline int gamemode_query_status(void)
{
    if (!gm_ready() || gm_state.status == NULL)
    {
        return -1;
    }

    return gm_state.status();
}

static inline int gamemode_request_start_for(pid_t pid)
{
    if (!gm_ready() || gm_state.start_for == NULL)
    {
        return -1;
    }

    return gm_state.start_for(pid);
}

static inline int gamemode_request_end_for(pid_t pid)
{
    if (!gm_ready() || gm_state.end_for == NULL)
    {
        return -1;
    }

    return gm_state.end_for(pid);
}

static inline int gamemode_query_status_for(pid_t pid)
{
    if (!gm_ready() || gm_state.status_for == NULL)
    {
        return -1;
    }

    return gm_state.status_for(pid);
}

#endif
