#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <Xinput.h>

#include <array>
#include <cstdint>
#include <cstring>

struct lua_State;

namespace {

constexpr DWORD kControllerCount = 4;
constexpr std::uint64_t kModalLeaseMs = 2500;
constexpr int kTriggerThreshold = 30;
constexpr int kStickEnterThreshold = 16000;
constexpr int kStickReleaseThreshold = 7000;
using XInputGetStateFunction = DWORD(WINAPI*)(DWORD, XINPUT_STATE*);

struct PadState {
    std::uint16_t buttons{};
    std::uint8_t left_trigger{};
    std::uint8_t right_trigger{};
    std::int16_t left_x{};
    std::int16_t left_y{};
    std::int16_t right_x{};
    std::int16_t right_y{};

    friend bool operator==(const PadState&, const PadState&) = default;
};

struct ReleaseDrain {
    std::uint16_t buttons{};
    bool left_trigger{};
    bool right_trigger{};
    int left_x_sign{};
    int left_y_sign{};
    int right_x_sign{};
    int right_y_sign{};
};

struct ControllerSlot {
    PadState raw{};
    PadState last_output{};
    ReleaseDrain drain{};
    DWORD synthetic_packet{};
    bool connected{};
    bool output_initialized{};
};

SRWLOCK g_lock = SRWLOCK_INIT;
std::array<ControllerSlot, kControllerCount> g_slots{};
XInputGetStateFunction g_original_xinput_get_state{};
void** g_xinput_iat_entry{};
bool g_hooked{};
bool g_modal{};
bool g_watchdog_armed{};
bool g_watchdog_expired{};
std::uint64_t g_watchdog_deadline{};

PadState from_xinput(const XINPUT_GAMEPAD& source) {
    return {
        source.wButtons,
        source.bLeftTrigger,
        source.bRightTrigger,
        source.sThumbLX,
        source.sThumbLY,
        source.sThumbRX,
        source.sThumbRY,
    };
}

void to_xinput(const PadState& source, XINPUT_GAMEPAD& destination) {
    destination.wButtons = source.buttons;
    destination.bLeftTrigger = source.left_trigger;
    destination.bRightTrigger = source.right_trigger;
    destination.sThumbLX = source.left_x;
    destination.sThumbLY = source.left_y;
    destination.sThumbRX = source.right_x;
    destination.sThumbRY = source.right_y;
}

int active_sign(std::int16_t value, int threshold) {
    return value >= threshold ? 1 : value <= -threshold ? -1 : 0;
}

void arm_release_drain(ControllerSlot& slot) {
    const auto& raw = slot.raw;
    slot.drain.buttons = raw.buttons;
    slot.drain.left_trigger = raw.left_trigger >= kTriggerThreshold;
    slot.drain.right_trigger = raw.right_trigger >= kTriggerThreshold;
    slot.drain.left_x_sign = active_sign(raw.left_x, kStickEnterThreshold);
    slot.drain.left_y_sign = active_sign(raw.left_y, kStickEnterThreshold);
    slot.drain.right_x_sign = active_sign(raw.right_x, kStickEnterThreshold);
    slot.drain.right_y_sign = active_sign(raw.right_y, kStickEnterThreshold);
}

void drain_axis(std::int16_t raw, int& held_sign, std::int16_t& output) {
    if (held_sign == 0) return;
    const int current_sign = active_sign(raw, kStickReleaseThreshold);
    if (current_sign == held_sign) output = 0;
    else held_sign = 0;
}

PadState apply_release_drain(ControllerSlot& slot, const PadState& raw) {
    PadState output = raw;
    slot.drain.buttons = static_cast<std::uint16_t>(
        slot.drain.buttons & raw.buttons);
    output.buttons = static_cast<std::uint16_t>(
        output.buttons & ~slot.drain.buttons);
    if (slot.drain.left_trigger) {
        if (raw.left_trigger >= kTriggerThreshold) output.left_trigger = 0;
        else slot.drain.left_trigger = false;
    }
    if (slot.drain.right_trigger) {
        if (raw.right_trigger >= kTriggerThreshold) output.right_trigger = 0;
        else slot.drain.right_trigger = false;
    }
    drain_axis(raw.left_x, slot.drain.left_x_sign, output.left_x);
    drain_axis(raw.left_y, slot.drain.left_y_sign, output.left_y);
    drain_axis(raw.right_x, slot.drain.right_x_sign, output.right_x);
    drain_axis(raw.right_y, slot.drain.right_y_sign, output.right_y);
    return output;
}

DWORD packetize(ControllerSlot& slot, DWORD raw_packet, const PadState& output) {
    if (!slot.output_initialized) {
        slot.synthetic_packet = raw_packet;
        slot.last_output = output;
        slot.output_initialized = true;
    } else if (!(slot.last_output == output)) {
        ++slot.synthetic_packet;
        slot.last_output = output;
    }
    return slot.synthetic_packet;
}

void set_modal_locked(bool active, std::uint64_t now) {
    if (g_modal == active) {
        if (active) {
            g_watchdog_armed = true;
            g_watchdog_expired = false;
            g_watchdog_deadline = now + kModalLeaseMs;
        }
        return;
    }
    g_modal = active;
    if (active) {
        g_watchdog_armed = true;
        g_watchdog_expired = false;
        g_watchdog_deadline = now + kModalLeaseMs;
        return;
    }
    for (auto& slot : g_slots) arm_release_drain(slot);
    g_watchdog_armed = false;
    g_watchdog_deadline = 0;
}

DWORD WINAPI hooked_xinput_get_state(DWORD user_index, XINPUT_STATE* state) {
    const auto original = g_original_xinput_get_state;
    if (original == nullptr) return ERROR_DEVICE_NOT_CONNECTED;
    const DWORD status = original(user_index, state);
    if (user_index >= kControllerCount || state == nullptr) return status;

    AcquireSRWLockExclusive(&g_lock);
    const auto now = GetTickCount64();
    if (g_watchdog_armed && now >= g_watchdog_deadline) {
        set_modal_locked(false, now);
        g_watchdog_expired = true;
    }
    auto& slot = g_slots[user_index];
    if (status != ERROR_SUCCESS) {
        slot.connected = false;
        slot.raw = {};
        slot.drain = {};
        ReleaseSRWLockExclusive(&g_lock);
        return status;
    }

    const PadState raw = from_xinput(state->Gamepad);
    slot.connected = true;
    slot.raw = raw;
    const PadState output = g_modal ? PadState{}
        : apply_release_drain(slot, raw);
    to_xinput(output, state->Gamepad);
    state->dwPacketNumber = packetize(slot, state->dwPacketNumber, output);
    ReleaseSRWLockExclusive(&g_lock);
    return status;
}

bool is_xinput_import(const char* name) {
    return name != nullptr && (_stricmp(name, "xinput1_3.dll") == 0
        || _stricmp(name, "xinput1_4.dll") == 0
        || _stricmp(name, "xinput9_1_0.dll") == 0);
}

bool patch_xinput_import() {
    if (g_hooked) return true;
    auto* base = reinterpret_cast<std::uint8_t*>(GetModuleHandleW(nullptr));
    if (base == nullptr) return false;
    auto* dos = reinterpret_cast<IMAGE_DOS_HEADER*>(base);
    if (dos->e_magic != IMAGE_DOS_SIGNATURE) return false;
    auto* nt = reinterpret_cast<IMAGE_NT_HEADERS64*>(base + dos->e_lfanew);
    if (nt->Signature != IMAGE_NT_SIGNATURE
        || nt->OptionalHeader.Magic != IMAGE_NT_OPTIONAL_HDR64_MAGIC) return false;
    const auto directory =
        nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];
    if (directory.VirtualAddress == 0 || directory.Size == 0) return false;

    auto* descriptors = reinterpret_cast<IMAGE_IMPORT_DESCRIPTOR*>(
        base + directory.VirtualAddress);
    for (auto* descriptor = descriptors; descriptor->Name != 0; ++descriptor) {
        const char* module_name = reinterpret_cast<const char*>(
            base + descriptor->Name);
        if (!is_xinput_import(module_name)) continue;
        auto* imported_module = GetModuleHandleA(module_name);
        auto* ordinal_address = imported_module == nullptr ? nullptr
            : GetProcAddress(imported_module, MAKEINTRESOURCEA(2));
        auto* lookup = descriptor->OriginalFirstThunk == 0 ? nullptr
            : reinterpret_cast<IMAGE_THUNK_DATA64*>(
                base + descriptor->OriginalFirstThunk);
        auto* address = reinterpret_cast<IMAGE_THUNK_DATA64*>(
            base + descriptor->FirstThunk);
        for (std::size_t index = 0; address[index].u1.Function != 0; ++index) {
            bool matches = false;
            if (lookup != nullptr) {
                const auto value = lookup[index].u1.Ordinal;
                if (IMAGE_SNAP_BY_ORDINAL64(value)) {
                    matches = IMAGE_ORDINAL64(value) == 2;
                } else {
                    const auto* by_name = reinterpret_cast<IMAGE_IMPORT_BY_NAME*>(
                        base + lookup[index].u1.AddressOfData);
                    matches = std::strcmp(
                        reinterpret_cast<const char*>(by_name->Name),
                        "XInputGetState") == 0;
                }
            } else if (ordinal_address != nullptr) {
                matches = reinterpret_cast<void*>(address[index].u1.Function)
                    == reinterpret_cast<void*>(ordinal_address);
            }
            if (!matches) continue;
            auto** entry = reinterpret_cast<void**>(&address[index].u1.Function);
            DWORD old_protection{};
            if (!VirtualProtect(entry, sizeof(void*), PAGE_READWRITE,
                    &old_protection)) return false;
            g_original_xinput_get_state =
                reinterpret_cast<XInputGetStateFunction>(*entry);
            InterlockedExchangePointer(entry,
                reinterpret_cast<void*>(&hooked_xinput_get_state));
            DWORD ignored{};
            VirtualProtect(entry, sizeof(void*), old_protection, &ignored);
            g_xinput_iat_entry = entry;
            g_hooked = true;
            return true;
        }
    }
    return false;
}

bool restore_xinput_import() {
    if (!g_hooked) return true;
    if (g_xinput_iat_entry == nullptr || g_original_xinput_get_state == nullptr)
        return false;
    DWORD old_protection{};
    if (!VirtualProtect(g_xinput_iat_entry, sizeof(void*), PAGE_READWRITE,
            &old_protection)) return false;
    if (*g_xinput_iat_entry == reinterpret_cast<void*>(&hooked_xinput_get_state)) {
        InterlockedExchangePointer(g_xinput_iat_entry,
            reinterpret_cast<void*>(g_original_xinput_get_state));
    }
    DWORD ignored{};
    VirtualProtect(g_xinput_iat_entry, sizeof(void*), old_protection, &ignored);
    g_hooked = false;
    return true;
}

int return_boolean(bool value) {
    return value ? 1 : 0;
}

std::uint16_t aggregate_buttons() {
    std::uint16_t result{};
    for (const auto& slot : g_slots) {
        if (slot.connected) {
            result = static_cast<std::uint16_t>(result | slot.raw.buttons);
        }
    }
    return result;
}

int direction_bits(const PadState& state) {
    return (state.left_y >= kStickEnterThreshold ? 0x1 : 0)
        | (state.left_y <= -kStickEnterThreshold ? 0x2 : 0)
        | (state.left_x <= -kStickEnterThreshold ? 0x4 : 0)
        | (state.left_x >= kStickEnterThreshold ? 0x8 : 0);
}

int aggregate_nibble(int index) {
    int result{};
    AcquireSRWLockShared(&g_lock);
    if (index >= 0 && index < 4) {
        result = (aggregate_buttons() >> (index * 4)) & 0xF;
    } else {
        for (const auto& slot : g_slots) {
            if (!slot.connected) continue;
            if (index == 4) {
                if (slot.raw.left_trigger >= kTriggerThreshold) result |= 0x1;
                if (slot.raw.right_trigger >= kTriggerThreshold) result |= 0x2;
            } else if (index == 5) {
                result |= direction_bits(slot.raw);
            }
        }
    }
    ReleaseSRWLockShared(&g_lock);
    return result & 0xF;
}

bool any_connected() {
    bool result = false;
    AcquireSRWLockShared(&g_lock);
    for (const auto& slot : g_slots) result = result || slot.connected;
    ReleaseSRWLockShared(&g_lock);
    return result;
}

}  // namespace

extern "C" __declspec(dllexport) int pal_quick_stack_input_initialize(lua_State*) {
    return return_boolean(patch_xinput_import());
}

extern "C" __declspec(dllexport) int pal_quick_stack_input_is_hooked(lua_State*) {
    return return_boolean(g_hooked);
}

extern "C" __declspec(dllexport) int pal_quick_stack_input_is_connected(lua_State*) {
    return return_boolean(any_connected());
}

extern "C" __declspec(dllexport) int pal_quick_stack_input_modal_on(lua_State*) {
    AcquireSRWLockExclusive(&g_lock);
    set_modal_locked(true, GetTickCount64());
    ReleaseSRWLockExclusive(&g_lock);
    return 1;
}

extern "C" __declspec(dllexport) int pal_quick_stack_input_modal_off(lua_State*) {
    AcquireSRWLockExclusive(&g_lock);
    set_modal_locked(false, GetTickCount64());
    ReleaseSRWLockExclusive(&g_lock);
    return 1;
}

extern "C" __declspec(dllexport) int pal_quick_stack_input_heartbeat(lua_State*) {
    bool renewed = false;
    AcquireSRWLockExclusive(&g_lock);
    if (g_watchdog_armed && g_modal) {
        g_watchdog_deadline = GetTickCount64() + kModalLeaseMs;
        renewed = true;
    }
    ReleaseSRWLockExclusive(&g_lock);
    return return_boolean(renewed);
}

extern "C" __declspec(dllexport) int pal_quick_stack_input_take_watchdog_release(
        lua_State*) {
    AcquireSRWLockExclusive(&g_lock);
    const bool expired = g_watchdog_expired;
    g_watchdog_expired = false;
    ReleaseSRWLockExclusive(&g_lock);
    return return_boolean(expired);
}

extern "C" __declspec(dllexport) int pal_quick_stack_input_shutdown(lua_State*) {
    AcquireSRWLockExclusive(&g_lock);
    set_modal_locked(false, GetTickCount64());
    ReleaseSRWLockExclusive(&g_lock);
    return return_boolean(restore_xinput_import());
}

#define NIBBLE_EXPORT(index) \
    extern "C" __declspec(dllexport) int pal_quick_stack_input_state_##index( \
            lua_State*) { \
        return aggregate_nibble(index); \
    }

NIBBLE_EXPORT(0)
NIBBLE_EXPORT(1)
NIBBLE_EXPORT(2)
NIBBLE_EXPORT(3)
NIBBLE_EXPORT(4)
NIBBLE_EXPORT(5)
