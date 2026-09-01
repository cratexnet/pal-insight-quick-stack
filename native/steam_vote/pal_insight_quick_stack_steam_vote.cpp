#define WIN32_LEAN_AND_MEAN
#include <Windows.h>

#include <cstdint>

struct lua_State;

namespace {

constexpr std::uint32_t kPalworldAppId = 1623730;
constexpr std::uint64_t kQuickStackWorkshopItemId = 3792968111ULL;
constexpr int kResultOk = 1;
constexpr int kSetUserItemVoteCallback = 3408;
constexpr int kGetUserItemVoteCallback = 3409;
constexpr ULONGLONG kCallTimeoutMs = 10000;

enum class VoteStatus : int {
    unavailable = 0,
    querying = 1,
    no_vote = 2,
    voted_down = 3,
    voted_up = 4,
    setting_up = 5,
};

enum class ErrorKind : int {
    none = 0,
    query_start = 1,
    query_result = 2,
    set_start = 3,
    set_result = 4,
    timeout = 5,
};

#pragma pack(push, 8)
struct SetUserItemVoteResult {
    std::uint64_t published_file_id{};
    std::int32_t result{};
    bool vote_up{};
};

struct GetUserItemVoteResult {
    std::uint64_t published_file_id{};
    std::int32_t result{};
    bool voted_up{};
    bool voted_down{};
    bool vote_skipped{};
};
#pragma pack(pop)

static_assert(sizeof(SetUserItemVoteResult) == 16);
static_assert(sizeof(GetUserItemVoteResult) == 16);

using SteamApiCall = std::uint64_t;
using SteamUgcFunction = void* (__cdecl*)();
using SteamUtilsFunction = void* (__cdecl*)();
using SteamUserFunction = void* (__cdecl*)();
using GetAppIdFunction = std::uint32_t (__cdecl*)(void*);
using IsLoggedOnFunction = bool (__cdecl*)(void*);
using GetUserItemVoteFunction = SteamApiCall (__cdecl*)(void*, std::uint64_t);
using SetUserItemVoteFunction = SteamApiCall (__cdecl*)(void*, std::uint64_t, bool);
using IsApiCallCompletedFunction = bool (__cdecl*)(void*, SteamApiCall, bool*);
using GetApiCallResultFunction = bool (__cdecl*)(
    void*, SteamApiCall, void*, int, int, bool*);

struct SteamFunctions {
    SteamUgcFunction steam_ugc{};
    SteamUtilsFunction steam_utils{};
    SteamUserFunction steam_user{};
    GetAppIdFunction get_app_id{};
    IsLoggedOnFunction is_logged_on{};
    GetUserItemVoteFunction get_user_item_vote{};
    SetUserItemVoteFunction set_user_item_vote{};
    IsApiCallCompletedFunction is_api_call_completed{};
    GetApiCallResultFunction get_api_call_result{};
};

SteamFunctions g_functions{};
void* g_ugc{};
void* g_utils{};
VoteStatus g_status{VoteStatus::unavailable};
VoteStatus g_status_before_set{VoteStatus::no_vote};
SteamApiCall g_pending_call{};
ULONGLONG g_pending_started_at{};
ErrorKind g_error_kind{ErrorKind::none};
int g_error_result{};
bool g_initialized{};
bool g_available{};

template <typename Function>
Function resolve(HMODULE module, const char* name) {
    return reinterpret_cast<Function>(GetProcAddress(module, name));
}

int return_boolean(bool value) {
    return value ? 1 : 0;
}

int return_nibble(int value) {
    return value >= 0 && value <= 15 ? value : 0;
}

void set_error(ErrorKind kind, int result = 0) {
    g_error_kind = kind;
    g_error_result = result;
}

bool resolve_steam() {
    HMODULE module = GetModuleHandleW(L"steam_api64.dll");
    if (module == nullptr) return false;
    g_functions = {
        resolve<SteamUgcFunction>(module, "SteamAPI_SteamUGC_v016"),
        resolve<SteamUtilsFunction>(module, "SteamAPI_SteamUtils_v010"),
        resolve<SteamUserFunction>(module, "SteamAPI_SteamUser_v021"),
        resolve<GetAppIdFunction>(module, "SteamAPI_ISteamUtils_GetAppID"),
        resolve<IsLoggedOnFunction>(module, "SteamAPI_ISteamUser_BLoggedOn"),
        resolve<GetUserItemVoteFunction>(module,
            "SteamAPI_ISteamUGC_GetUserItemVote"),
        resolve<SetUserItemVoteFunction>(module,
            "SteamAPI_ISteamUGC_SetUserItemVote"),
        resolve<IsApiCallCompletedFunction>(module,
            "SteamAPI_ISteamUtils_IsAPICallCompleted"),
        resolve<GetApiCallResultFunction>(module,
            "SteamAPI_ISteamUtils_GetAPICallResult"),
    };
    if (g_functions.steam_ugc == nullptr
        || g_functions.steam_utils == nullptr
        || g_functions.steam_user == nullptr
        || g_functions.get_app_id == nullptr
        || g_functions.is_logged_on == nullptr
        || g_functions.get_user_item_vote == nullptr
        || g_functions.set_user_item_vote == nullptr
        || g_functions.is_api_call_completed == nullptr
        || g_functions.get_api_call_result == nullptr) return false;
    g_ugc = g_functions.steam_ugc();
    g_utils = g_functions.steam_utils();
    void* user = g_functions.steam_user();
    return g_ugc != nullptr && g_utils != nullptr && user != nullptr
        && g_functions.get_app_id(g_utils) == kPalworldAppId
        && g_functions.is_logged_on(user);
}

bool begin_query() {
    g_pending_call = g_functions.get_user_item_vote(
        g_ugc, kQuickStackWorkshopItemId);
    if (g_pending_call == 0) {
        g_status = VoteStatus::no_vote;
        set_error(ErrorKind::query_start);
        return false;
    }
    g_status = VoteStatus::querying;
    g_pending_started_at = GetTickCount64();
    return true;
}

void finish_failure(bool setting, ErrorKind kind, int result = 0) {
    g_status = setting ? g_status_before_set : VoteStatus::no_vote;
    g_pending_call = 0;
    g_pending_started_at = 0;
    set_error(kind, result);
}

void poll_pending() {
    const bool setting = g_status == VoteStatus::setting_up;
    if (!setting && g_status != VoteStatus::querying) return;
    if (g_pending_call == 0) {
        finish_failure(setting,
            setting ? ErrorKind::set_start : ErrorKind::query_start);
        return;
    }
    if (GetTickCount64() - g_pending_started_at >= kCallTimeoutMs) {
        finish_failure(setting, ErrorKind::timeout);
        return;
    }
    bool call_failed = false;
    if (!g_functions.is_api_call_completed(
            g_utils, g_pending_call, &call_failed)) return;
    if (call_failed) {
        finish_failure(setting,
            setting ? ErrorKind::set_result : ErrorKind::query_result);
        return;
    }
    if (setting) {
        SetUserItemVoteResult result{};
        if (!g_functions.get_api_call_result(g_utils, g_pending_call, &result,
                sizeof(result), kSetUserItemVoteCallback, &call_failed)
            || call_failed || result.result != kResultOk
            || result.published_file_id != kQuickStackWorkshopItemId
            || !result.vote_up) {
            finish_failure(true, ErrorKind::set_result, result.result);
            return;
        }
        g_status = VoteStatus::voted_up;
    } else {
        GetUserItemVoteResult result{};
        if (!g_functions.get_api_call_result(g_utils, g_pending_call, &result,
                sizeof(result), kGetUserItemVoteCallback, &call_failed)
            || call_failed || result.result != kResultOk
            || result.published_file_id != kQuickStackWorkshopItemId) {
            finish_failure(false, ErrorKind::query_result, result.result);
            return;
        }
        g_status = result.voted_up ? VoteStatus::voted_up
            : result.voted_down ? VoteStatus::voted_down
            : VoteStatus::no_vote;
    }
    g_pending_call = 0;
    g_pending_started_at = 0;
}

} // namespace

extern "C" __declspec(dllexport) int __cdecl
pal_quick_stack_steam_vote_initialize(lua_State*) {
    if (g_initialized) return return_boolean(g_available);
    g_initialized = true;
    g_available = resolve_steam();
    if (!g_available) return 0;
    begin_query();
    return 1;
}

extern "C" __declspec(dllexport) int __cdecl
pal_quick_stack_steam_vote_refresh(lua_State*) {
    if (!g_available) return 0;
    poll_pending();
    if (g_status == VoteStatus::querying
        || g_status == VoteStatus::setting_up) return 1;
    return return_boolean(begin_query());
}

extern "C" __declspec(dllexport) int __cdecl
pal_quick_stack_steam_vote_status(lua_State*) {
    if (g_available) poll_pending();
    return return_nibble(static_cast<int>(g_status));
}

extern "C" __declspec(dllexport) int __cdecl
pal_quick_stack_steam_vote_set_up(lua_State*) {
    if (!g_available) return 0;
    poll_pending();
    if (g_status == VoteStatus::voted_up) return 1;
    if (g_status == VoteStatus::querying
        || g_status == VoteStatus::setting_up) return 0;
    g_status_before_set = g_status;
    g_pending_call = g_functions.set_user_item_vote(
        g_ugc, kQuickStackWorkshopItemId, true);
    if (g_pending_call == 0) {
        set_error(ErrorKind::set_start);
        return 0;
    }
    g_status = VoteStatus::setting_up;
    g_pending_started_at = GetTickCount64();
    return 1;
}

extern "C" __declspec(dllexport) int __cdecl
pal_quick_stack_steam_vote_error_kind(lua_State*) {
    return return_nibble(static_cast<int>(g_error_kind));
}

extern "C" __declspec(dllexport) int __cdecl
pal_quick_stack_steam_vote_error_result_low(lua_State*) {
    return return_nibble(g_error_result & 0xF);
}

extern "C" __declspec(dllexport) int __cdecl
pal_quick_stack_steam_vote_error_result_high(lua_State*) {
    return return_nibble((g_error_result >> 4) & 0xF);
}

extern "C" __declspec(dllexport) int __cdecl
pal_quick_stack_steam_vote_clear_error(lua_State*) {
    const bool had_error = g_error_kind != ErrorKind::none;
    g_error_kind = ErrorKind::none;
    g_error_result = 0;
    return return_boolean(had_error);
}
