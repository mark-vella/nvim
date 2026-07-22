-- The override is useful for isolated lifecycle tests; normal sessions share 8000.
local PORT = tonumber(vim.env.CURSORTAB_LLAMA_PORT) or 8000
local URL = "http://127.0.0.1:" .. PORT

local hostname = (vim.uv.os_gethostname and vim.uv.os_gethostname()) or vim.uv.os_uname().nodename
hostname = hostname:gsub("[^%w._-]", "_")

-- This lifecycle originally assumed Linux: it reads process identity from procfs
-- (/proc/<pid>/{stat,exe,cmdline,environ} and boot_id) and uses Linux fcntl(2)
-- flag values. macOS has neither, so the OS-specific primitives below (boot_id,
-- process_start_time, proc_*, the fcntl/errno constants, and the watchdog's
-- proc_start) branch on `is_macos` and use libproc/sysctl/ps. Everything else,
-- including the shared-server lock/lease/daemon lifecycle, is identical on both.
local is_macos = vim.uv.os_uname().sysname == "Darwin"

local state_dir = vim.fn.stdpath("state") .. "/mrk/cursortab/" .. hostname
if PORT ~= 8000 then
        state_dir = state_dir .. "/port-" .. PORT
end
local profile_path = state_dir .. "/profile"
local server_path = state_dir .. "/llama-server.json"
local log_path = state_dir .. "/llama-server.log"
local lease_dir = state_dir .. "/leases"
local daemon_root = state_dir .. "/daemon"
local lock_path = state_dir .. "/state.lock"

local editor_pid = vim.uv.os_getpid()
local boot_id = ""
do
        if is_macos then
                -- No /proc; kern.boottime is a stable identifier for this boot.
                local handle = io.popen("/usr/sbin/sysctl -n kern.boottime 2>/dev/null")
                if handle then
                        local value = handle:read("*a") or ""
                        handle:close()
                        local seconds = value:match("sec%s*=%s*(%d+)")
                        if seconds then
                                boot_id = "boottime-" .. seconds
                        end
                end
        else
                local file = io.open("/proc/sys/kernel/random/boot_id", "rb")
                if file then
                        boot_id = vim.trim(file:read("*a") or "")
                        file:close()
                end
        end
end
if boot_id == "" then
        boot_id = hostname
end

local function process_start_time(pid)
        if is_macos then
                -- No procfs. `ps -o lstart=` is stable per process instance and is
                -- exactly what the shell watchdog computes, so the two always agree.
                local handle = io.popen("ps -o lstart= -p " .. tonumber(pid) .. " 2>/dev/null")
                if not handle then
                        return nil
                end
                local started = (handle:read("*a") or ""):gsub("[\r\n]", "")
                handle:close()
                if started == "" then
                        return nil
                end
                return started
        end

        local file = io.open("/proc/" .. pid .. "/stat", "rb")
        if not file then
                return nil
        end

        local stat = file:read("*a") or ""
        file:close()
        -- Everything after the final ") " starts at proc(5) field 3. starttime is field 22.
        local rest = stat:match("^%d+ %b() (.*)$")
        if not rest then
                return nil
        end

        local field = 0
        for value in rest:gmatch("%S+") do
                field = field + 1
                if field == 20 then
                        return value
                end
        end
        return nil
end

local lifecycle_registry = rawget(_G, "__mrk_cursortab_lifecycles") or {}
_G.__mrk_cursortab_lifecycles = lifecycle_registry
local previous_lifecycle = lifecycle_registry[state_dir]

local editor_start_time = process_start_time(editor_pid) or tostring(vim.uv.hrtime())
local session_token = previous_lifecycle and previous_lifecycle.pid == editor_pid
                and previous_lifecycle.session_token
        or vim.fn.sha256(table.concat({ boot_id, editor_pid, editor_start_time, vim.uv.hrtime() }, ":")):sub(1, 16)
local session_id = previous_lifecycle and previous_lifecycle.pid == editor_pid
                and previous_lifecycle.session_id
        -- session_token already encodes editor_start_time, so it alone keeps this
        -- unique. Keep start_time out of the id: it becomes the daemon dir name,
        -- and on macOS a start_time string would push the daemon's unix socket
        -- path past the ~104-byte sun_path limit, so bind() would fail.
        or table.concat({ editor_pid, session_token }, "-")
local lease_path = lease_dir .. "/" .. session_id .. ".lease"
local daemon_state_dir = daemon_root .. "/" .. session_id
local daemon_owner_path = daemon_state_dir .. "/owner.json"

-- context_size is the input budget. The server context also leaves room for the
-- completion and provider-specific prompt wrappers/history.
local profiles = {
        fast = {
                model = "unsloth/Qwen3.5-0.8B-GGUF:Q8_0",
                server_context = 2048,
                threads = 6,
                start_timeout_ms = 10 * 60 * 1000,
                provider = {
                        type = "inline",
                        url = URL,
                        context_size = 1536,
                        max_tokens = 64,
                        max_diff_history_tokens = 256,
                        completion_timeout = 5000,
                },
        },
        ["zeta-2"] = {
                -- Keep the highest-quality quant for GPU-capable machines.
                -- This profile remains heavy when run on CPU; use `fast` there.
                model = "bartowski/zed-industries_zeta-2-GGUF:Q8_0",
                server_context = 4096,
                threads = 8,
                start_timeout_ms = 45 * 60 * 1000,
                provider = {
                        type = "zeta-2",
                        url = URL,
                        context_size = 3072,
                        -- Zeta can replace roughly 31 lines; observed useful edits
                        -- exceed 100 tokens, so an inline-sized cap is too small.
                        max_tokens = 256,
                        max_diff_history_tokens = 384,
                        completion_timeout = 180000,
                },
        },
}

local SERVER_FLAGS_VERSION = "single-slot-no-cache-auto-gpu-v3"
local available_threads = (vim.uv.available_parallelism and vim.uv.available_parallelism()) or 1
for name, profile in pairs(profiles) do
        profile.effective_threads = math.max(1, math.min(profile.threads, available_threads))
        profile.config_id = table.concat({
                name,
                profile.model,
                profile.server_context,
                profile.provider.context_size,
                profile.provider.max_tokens,
                profile.provider.completion_timeout,
                profile.effective_threads,
                PORT,
                SERVER_FLAGS_VERSION,
        }, ":")
end

local desired_profile = "off"
local effective_profile = "off"
local cursortab_initialized = previous_lifecycle and previous_lifecycle.cursortab_initialized or false
local generation = 0
local cleaned_up = false
local profile_timer
local last_error
local temporary_counter = 0
local activation_in_flight = false
local recovery_attempt = 0
local next_recovery_at = 0
local owner_published = false
local lifecycle_entry = {
        pid = editor_pid,
        session_id = session_id,
        session_token = session_token,
}
local test_start_timeout_ms = tonumber(vim.env.CURSORTAB_TEST_START_TIMEOUT_MS)
local recovery_base_ms = tonumber(vim.env.CURSORTAB_TEST_RECOVERY_MS) or 5000

local function notify(message, level)
        vim.notify("CursorTab: " .. message, level or vim.log.levels.INFO)
end

local function ensure_state_dir()
        vim.fn.mkdir(state_dir, "p")
        vim.fn.mkdir(lease_dir, "p")
        vim.fn.mkdir(daemon_root, "p")
end

local function read_text(path)
        local file = io.open(path, "rb")
        if not file then
                return nil
        end
        local value = file:read("*a")
        file:close()
        return value
end

local function write_file(path, lines)
        ensure_state_dir()
        temporary_counter = temporary_counter + 1
        local temporary_path = table.concat({ path, "tmp", session_token, temporary_counter }, ".")
        local ok, error_message = pcall(vim.fn.writefile, lines, temporary_path)
        if not ok then
                vim.fn.delete(temporary_path)
                error("Could not write CursorTab state: " .. tostring(error_message))
        end

        local renamed, rename_error = vim.uv.fs_rename(temporary_path, path)
        if not renamed then
                vim.fn.delete(temporary_path)
                error("Could not persist CursorTab state: " .. (rename_error or "unknown error"))
        end
end

local function write_json(path, value)
        write_file(path, { vim.json.encode(value) })
end

local function read_json(path)
        local contents = read_text(path)
        if not contents then
                return nil
        end
        local ok, value = pcall(vim.json.decode, contents)
        if not ok or type(value) ~= "table" then
                return nil
        end
        return value
end

local function process_is_running(pid)
        return type(pid) == "number" and process_start_time(pid) ~= nil
end

local function identity_is_live(identity)
        return type(identity) == "table"
                and identity.boot_id == boot_id
                and type(identity.pid) == "number"
                and tostring(identity.start_time) == tostring(process_start_time(identity.pid))
end

local function editor_identity()
        return {
                boot_id = boot_id,
                pid = editor_pid,
                start_time = editor_start_time,
                session = session_id,
        }
end

local ffi = require("ffi")
ffi.cdef([[
        int open(const char *path, int flags, ...);
        int flock(int fd, int operation);
        int close(int fd);
]])
if is_macos then
        -- libproc/sysctl provide the process identity that /proc gives on Linux.
        ffi.cdef([[
                int proc_pidpath(int pid, void *buffer, uint32_t buffersize);
                int sysctl(int *name, unsigned int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
        ]])
end

-- open(2)/flock(2) constants. O_CLOEXEC is essential because model and daemon
-- jobs are spawned while holding this lock and must not inherit it. The open
-- flags and EAGAIN differ on macOS (BSD values); flock/EINTR are the same.
local O_RDWR = 2
local O_CREAT = is_macos and 0x0200 or 0x40
local O_CLOEXEC = is_macos and 0x1000000 or 0x80000
local LOCK_EX = 2
local LOCK_NB = 4
local LOCK_UN = 8
local EAGAIN = is_macos and 35 or 11
local EINTR = 4
local lock_timeout_ms = tonumber(vim.env.CURSORTAB_TEST_LOCK_TIMEOUT_MS) or 10000

local function acquire_host_lock()
        ensure_state_dir()
        -- mode must be a typed int: open(2) is variadic, and a bare Lua number
        -- is passed as a double, which the macOS arm64 varargs ABI reads wrong.
        local fd = ffi.C.open(lock_path, O_RDWR + O_CREAT + O_CLOEXEC, ffi.new("int", 384)) -- 0600
        if fd < 0 then
                local errno = ffi.errno()
                local hint = errno == 21 and " (remove the legacy state.lock directory once no old Neovim is using it)"
                        or ""
                return nil, "could not open the shared CursorTab state lock (errno " .. errno .. ")" .. hint
        end

        local deadline = vim.uv.now() + lock_timeout_ms
        repeat
                if ffi.C.flock(fd, LOCK_EX + LOCK_NB) == 0 then
                        return fd
                end
                local errno = ffi.errno()
                if errno ~= EAGAIN and errno ~= EINTR then
                        ffi.C.close(fd)
                        return nil, "could not acquire the shared CursorTab state lock (errno " .. errno .. ")"
                end
                vim.wait(25)
        until vim.uv.now() >= deadline

        ffi.C.close(fd)
        return nil, "timed out waiting for the shared CursorTab state lock"
end

local function with_host_lock(callback)
        local fd, lock_error = acquire_host_lock()
        if not fd then
                error(lock_error)
        end

        local results = { xpcall(callback, debug.traceback) }
        local unlock_ok = ffi.C.flock(fd, LOCK_UN) == 0
        local unlock_errno = unlock_ok and nil or ffi.errno()
        local close_ok = ffi.C.close(fd) == 0
        local close_errno = close_ok and nil or ffi.errno()

        if not results[1] then
                error(results[2])
        end
        if not unlock_ok then
                error("could not release the shared CursorTab state lock (errno " .. unlock_errno .. ")")
        end
        if not close_ok then
                error("could not close the shared CursorTab state lock (errno " .. close_errno .. ")")
        end
        return unpack(results, 2)
end

local function persist_profile_unlocked(profile)
        write_file(profile_path, { profile })
end

local function read_profile_unlocked()
        if vim.fn.filereadable(profile_path) == 0 then
                return "off"
        end

        local lines = vim.fn.readfile(profile_path, "", 1)
        local profile = vim.trim(lines[1] or "")
        if profile ~= "off" and not profiles[profile] then
                return "off"
        end
        return profile
end

local function read_server_state_unlocked()
        local state = read_json(server_path)
        if not state or type(state.pid) ~= "number" then
                if vim.fn.filereadable(server_path) == 1 then
                        vim.fn.delete(server_path)
                end
                return nil
        end
        return state
end

local function same_server(left, right)
        return left
                and right
                and left.pid == right.pid
                and tostring(left.start_time) == tostring(right.start_time)
                and left.token == right.token
end

local function remove_server_state_unlocked(expected)
        local current = read_server_state_unlocked()
        if not expected or same_server(current, expected) then
                vim.fn.delete(server_path)
        end
end

-- macOS process identity. KERN_PROCARGS2 returns argc, the executable path,
-- argv, then the environment as NUL-separated strings; proc_pidpath returns the
-- executable path. Together they replace /proc/<pid>/{exe,cmdline,environ}.
local CTL_KERN, KERN_ARGMAX, KERN_PROCARGS2 = 1, 8, 49
local mac_argmax
local function mac_kern_argmax()
        if mac_argmax then
                return mac_argmax
        end
        local name = ffi.new("int[2]", { CTL_KERN, KERN_ARGMAX })
        local value = ffi.new("int[1]")
        local length = ffi.new("size_t[1]", ffi.sizeof("int"))
        mac_argmax = (ffi.C.sysctl(name, 2, value, length, nil, 0) == 0) and value[0] or 262144
        return mac_argmax
end

local function mac_proc_argv_environ(pid)
        local size = mac_kern_argmax()
        local buffer = ffi.new("char[?]", size)
        local length = ffi.new("size_t[1]", size)
        local name = ffi.new("int[3]", { CTL_KERN, KERN_PROCARGS2, tonumber(pid) })
        if ffi.C.sysctl(name, 3, buffer, length, nil, 0) ~= 0 then
                return {}, {}
        end
        local raw = ffi.string(buffer, tonumber(length[0]))
        if #raw < 4 then
                return {}, {}
        end
        local argc = raw:byte(1) + raw:byte(2) * 256 + raw:byte(3) * 65536 + raw:byte(4) * 16777216
        local position = 5
        local terminator = raw:find("\0", position, true) -- executable path
        if not terminator then
                return {}, {}
        end
        position = terminator + 1
        while position <= #raw and raw:byte(position) == 0 do -- padding before argv
                position = position + 1
        end
        local arguments = {}
        for _ = 1, argc do
                local stop = raw:find("\0", position, true)
                if not stop then
                        break
                end
                table.insert(arguments, raw:sub(position, stop - 1))
                position = stop + 1
        end
        while position <= #raw and raw:byte(position) == 0 do -- padding before env
                position = position + 1
        end
        local environment = {}
        while position <= #raw do
                local stop = raw:find("\0", position, true)
                if not stop then
                        break
                end
                if stop > position then
                        table.insert(environment, raw:sub(position, stop - 1))
                end
                position = stop + 1
        end
        return arguments, environment
end

local function proc_executable(pid)
        if is_macos then
                local buffer = ffi.new("char[4096]")
                local length = ffi.C.proc_pidpath(pid, buffer, 4096)
                if length <= 0 then
                        return nil
                end
                local path = ffi.string(buffer, length)
                return vim.uv.fs_realpath(path) or path
        end
        return vim.uv.fs_realpath("/proc/" .. pid .. "/exe")
end

local function proc_arguments(pid)
        if is_macos then
                return (mac_proc_argv_environ(pid))
        end
        local command_line = read_text("/proc/" .. pid .. "/cmdline")
        local arguments = {}
        for argument in (command_line or ""):gmatch("([^%z]+)") do
                table.insert(arguments, argument)
        end
        return arguments
end

local function proc_environment(pid, name)
        local prefix = name .. "="
        if is_macos then
                local _, environment = mac_proc_argv_environ(pid)
                for _, item in ipairs(environment) do
                        if vim.startswith(item, prefix) then
                                return item:sub(#prefix + 1)
                        end
                end
                return nil
        end
        local environment = read_text("/proc/" .. pid .. "/environ") or ""
        for item in environment:gmatch("([^%z]+)") do
                if vim.startswith(item, prefix) then
                        return item:sub(#prefix + 1)
                end
        end
        return nil
end

local function has_argument_pair(arguments, option, value)
        for index = 1, #arguments - 1 do
                if arguments[index] == option and arguments[index + 1] == value then
                        return true
                end
        end
        return false
end

local function server_identity_without_executable_matches(state)
        if not process_is_running(state.pid) then
                return false
        end

        if state.start_time and tostring(state.start_time) ~= tostring(process_start_time(state.pid)) then
                return false
        end
        if state.boot_id and state.boot_id ~= boot_id then
                return false
        end

        local arguments = proc_arguments(state.pid)
        local profile = profiles[state.profile]
        if not profile then
                return false
        end
        if not has_argument_pair(arguments, "--host", "127.0.0.1") then
                return false
        end
        if not has_argument_pair(arguments, "--port", tostring(PORT)) then
                return false
        end
        if not has_argument_pair(arguments, "-hf", profile.model) then
                return false
        end

        if state.token then
                -- Token state is only trusted with the PID-reuse guards introduced
                -- alongside it. The environment token ties that process to this state.
                return state.start_time ~= nil
                        and state.boot_id ~= nil
                        and proc_environment(state.pid, "CURSORTAB_SERVER_TOKEN") == state.token
        end
        return true
end

local legacy_executables
local function legacy_expected_executables()
        if legacy_executables then
                return legacy_executables
        end

        legacy_executables = {}
        local command_path = vim.fn.exepath("llama-server")
        local resolved = command_path ~= "" and vim.uv.fs_realpath(command_path) or nil
        if resolved then
                legacy_executables[resolved] = true
        end

        -- mise shims resolve to the mise binary, which then execs the installed
        -- tool. Ask mise for that final path so old tokenless state stays strict.
        if resolved and vim.fs.basename(resolved) == "mise" then
                local result = vim.system({ resolved, "which", "llama-server" }, { text = true }):wait()
                local installed = result.code == 0 and vim.trim(result.stdout or "") or ""
                installed = installed ~= "" and vim.uv.fs_realpath(installed) or nil
                if installed then
                        legacy_executables[installed] = true
                end
        end
        return legacy_executables
end

local function final_server_executable(pid)
        local executable = proc_executable(pid)
        if executable and vim.fs.basename(executable) == "llama-server" then
                return executable
        end
        return nil
end

local function server_process_matches(state)
        if not server_identity_without_executable_matches(state) then
                return false
        end

        local executable = final_server_executable(state.pid)
        if not executable then
                return false
        end
        if state.token then
                -- New state publishes /proc/PID/exe after the complete shim/exec
                -- chain, rather than guessing from exepath().
                return state.executable ~= nil and executable == state.executable
        end

        -- Migration for the original tokenless state. Keep exact executable,
        -- model, host and port checks before permitting one managed restart.
        return state.start_time == nil
                and state.boot_id == nil
                and legacy_expected_executables()[executable] == true
end

local function capture_server_executable_unlocked(state)
        if not state.token or not server_identity_without_executable_matches(state) then
                return false
        end
        local executable = final_server_executable(state.pid)
        if not executable then
                return false
        end

        state.executable = executable
        local current = read_server_state_unlocked()
        if current and same_server(current, state) and current.executable ~= executable then
                current.executable = executable
                state = current
                write_json(server_path, current)
        end
        return server_process_matches(state)
end

local function send_signal(pid, signal)
        local number = vim.uv.constants["SIG" .. signal]
        return number ~= nil and vim.uv.kill(pid, number) == 0
end

local function signal_server(state, signal)
        if not server_process_matches(state) then
                return false
        end
        -- Avoid an external-process spawn between identity verification and signal.
        return send_signal(state.pid, signal)
end

local function stop_model_server_unlocked()
        local state = read_server_state_unlocked()
        if not state then
                return true
        end

        -- Repair state produced by the shim-unaware version. Boot ID, start
        -- time, argv and the secret environment token are verified first.
        capture_server_executable_unlocked(state)
        if not process_is_running(state.pid) then
                remove_server_state_unlocked(state)
                return true
        end

        if not server_process_matches(state) then
                remove_server_state_unlocked(state)
                last_error = "Refused to stop PID " .. state.pid .. ": managed server identity did not match."
                return false
        end

        signal_server(state, "TERM")
        vim.wait(3000, function()
                return not process_is_running(state.pid)
        end, 100, true)

        -- Re-check the full identity before escalating, so a recycled PID is never killed.
        if process_is_running(state.pid) and server_process_matches(state) then
                signal_server(state, "KILL")
        end
        remove_server_state_unlocked(state)
        return not process_is_running(state.pid)
end

local function write_lease_unlocked()
        write_file(lease_path, { boot_id, tostring(editor_pid), tostring(editor_start_time) })
end

local function lease_is_live(path)
        local ok, lines = pcall(vim.fn.readfile, path, "", 3)
        if not ok then
                return false
        end
        local pid = tonumber(lines[2])
        return lines[1] == boot_id
                and pid ~= nil
                and tostring(lines[3]) == tostring(process_start_time(pid))
end

local function live_leases_unlocked()
        local count = 0
        local handle = vim.uv.fs_scandir(lease_dir)
        if not handle then
                return 0
        end

        while true do
                local name, kind = vim.uv.fs_scandir_next(handle)
                if not name then
                        break
                end
                if kind == "file" and name:sub(-6) == ".lease" then
                        local path = lease_dir .. "/" .. name
                        if lease_is_live(path) then
                                count = count + 1
                        else
                                vim.fn.delete(path)
                        end
                end
        end
        return count
end

local function plugin_binary_path()
        local paths = vim.api.nvim_get_runtime_file("lua/cursortab/init.lua", false)
        if #paths == 0 then
                return nil
        end
        local plugin_dir = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(paths[1])))
        return plugin_dir .. "/server/cursortab"
end

local function cursor_daemon_matches(pid, directory)
        local binary = plugin_binary_path()
        local executable = binary and vim.uv.fs_realpath(binary)
        if not executable or proc_executable(pid) ~= executable then
                return false
        end
        local config = proc_environment(pid, "CURSORTAB_CONFIG") or ""
        return config:find('"state_dir":"' .. vim.pesc(directory) .. '"') ~= nil
end

local function clean_daemon_directory_unlocked(directory)
        local pid = tonumber(vim.trim(read_text(directory .. "/cursortab.pid") or ""))
        if pid and process_is_running(pid) then
                if not cursor_daemon_matches(pid, directory) then
                        return false
                end
                send_signal(pid, "TERM")
                vim.wait(1000, function()
                        return not process_is_running(pid)
                end, 50, true)
                if process_is_running(pid) then
                        return false
                end
        end
        vim.fn.delete(directory, "rf")
        return true
end

local function cleanup_stale_daemons_unlocked()
        local handle = vim.uv.fs_scandir(daemon_root)
        if not handle then
                return
        end
        while true do
                local name, kind = vim.uv.fs_scandir_next(handle)
                if not name then
                        break
                end
                if kind == "directory" then
                        local directory = daemon_root .. "/" .. name
                        local owner = read_json(directory .. "/owner.json")
                        if not identity_is_live(owner) then
                                clean_daemon_directory_unlocked(directory)
                        end
                end
        end

        -- Clean the hostname-wide daemon layout used by the previous version,
        -- but only when no daemon proven to own it is alive.
        local legacy_pid = tonumber(vim.trim(read_text(daemon_root .. "/cursortab.pid") or ""))
        if not legacy_pid or not process_is_running(legacy_pid) then
                for _, name in ipairs({
                        "cursortab.config.json",
                        "cursortab.log",
                        "cursortab.pid",
                        "cursortab.sock",
                        "cursortab.port",
                        "device_id",
                }) do
                        vim.fn.delete(daemon_root .. "/" .. name)
                end
        end
end

local function stop_cursortab()
        local pid_path = daemon_state_dir .. "/cursortab.pid"
        local has_pid_file = vim.fn.filereadable(pid_path) == 1
        if not cursortab_initialized and not has_pid_file then
                effective_profile = "off"
                return true
        end

        local daemon = require("cursortab.daemon")
        if cursortab_initialized then
                require("cursortab.events").clear_all_completions()
        else
                require("cursortab.config").setup({ enabled = false, state_dir = daemon_state_dir })
        end
        daemon.set_enabled(false)

        -- Stop the RPC client job first. CursorTab's stop_daemon trusts a PID
        -- file after only kill -0, so never let it see a live, unverified PID.
        local channel = daemon.get_channel_status().channel_id
        if channel and channel > 0 then
                pcall(vim.fn.jobstop, channel)
        end

        local pid = tonumber(vim.trim(read_text(pid_path) or ""))
        local verified = pid and process_is_running(pid) and cursor_daemon_matches(pid, daemon_state_dir)
        local stopped = true
        if verified then
                send_signal(pid, "TERM")
                vim.wait(2000, function()
                        return not process_is_running(pid)
                end, 50)
                stopped = not process_is_running(pid)
                if not stopped then
                        -- Preserve its PID/socket ownership and refuse replacement.
                        -- The old daemon may still clean these paths when it exits.
                        last_error = "Verified CursorTab daemon did not stop after TERM; it was not force-killed."
                        effective_profile = "off"
                        return false
                end
        elseif pid and process_is_running(pid) then
                -- A recycled/mismatched PID is never signalled. Removing only
                -- our PID file makes the plugin cleanup path signal-free.
                last_error = "Refused to stop an unverified CursorTab daemon PID " .. pid .. "."
        end

        vim.fn.delete(pid_path)
        daemon.stop_daemon() -- With no PID file this only resets channel/stale IPC.
        effective_profile = "off"
        return stopped
end

local function check_prerequisites()
        if vim.fn.executable("llama-server") == 0 then
                return false,
                        "llama-server is missing; profile remains pending",
                        "Install llama.cpp (for example `mise use -g llama.cpp@latest`)."
        end
        if vim.fn.executable("curl") == 0 then
                return false, "curl is missing; profile remains pending", "curl is required for health checks."
        end
        local binary_path = plugin_binary_path()
        if not binary_path or vim.fn.executable(binary_path) == 0 then
                return false,
                        "CursorTab daemon is not built; profile remains pending",
                        "Run `:Lazy build cursortab.nvim` (Go is required)."
        end
        return true
end

local function health_check(callback)
        vim.system({
                "curl",
                "--silent",
                "--fail",
                "--max-time",
                "1",
                URL .. "/health",
        }, { text = true }, function(result)
                vim.schedule(function()
                        callback(result.code == 0)
                end)
        end)
end

local function cursortab_config(profile)
        return {
                enabled = true,
                state_dir = daemon_state_dir,
                contribute_data = false,
                provider = vim.deepcopy(profiles[profile].provider),
        }
end

local function schedule_recovery()
        activation_in_flight = false
        recovery_attempt = recovery_attempt + 1
        local delay = math.min(recovery_base_ms * (2 ^ math.min(recovery_attempt - 1, 4)), 60000)
        next_recovery_at = vim.uv.now() + delay
end

local function reset_recovery()
        activation_in_flight = false
        recovery_attempt = 0
        next_recovery_at = 0
end

local function daemon_rpc_is_ready()
        local daemon = require("cursortab.daemon")
        local channel = daemon.get_channel_status()
        if not channel.connected or not channel.channel_id or channel.channel_id <= 0 then
                return false
        end
        if vim.fn.jobwait({ channel.channel_id }, 0)[1] ~= -1 then
                return false
        end
        local pid = tonumber(vim.trim(read_text(daemon_state_dir .. "/cursortab.pid") or ""))
        return pid ~= nil and cursor_daemon_matches(pid, daemon_state_dir)
end

local function force_start_daemon_now(daemon)
        -- daemon.force_start() also hides its process spawn in defer_fn(..., 0).
        -- Capture and execute that callback synchronously so this lifecycle can
        -- always cancel/stop a spawn before another profile generation begins.
        local original_defer = vim.defer_fn
        local spawn_callback
        vim.defer_fn = function(callback, delay)
                if delay == 0 and not spawn_callback then
                        spawn_callback = callback
                        return
                end
                return original_defer(callback, delay)
        end
        local ok, started = pcall(daemon.force_start)
        vim.defer_fn = original_defer
        if not ok or not started then
                return false
        end
        if spawn_callback then
                local spawn_ok = pcall(spawn_callback)
                if not spawn_ok then
                        return false
                end
                -- The Go daemon publishes its PID before binding its socket.
                -- Close the tiny jobstart/stop gap before yielding to user input.
                vim.wait(1000, function()
                        return vim.fn.filereadable(daemon_state_dir .. "/cursortab.pid") == 1
                end, 10)
        end
        return true
end

local function start_cursortab(profile, activation_generation, announce)
        local config = cursortab_config(profile)
        local daemon = require("cursortab.daemon")
        if not cursortab_initialized then
                -- CursorTab normally defers force_start() with no cancellation
                -- handle. Suppress that one zero-delay callback and start it
                -- explicitly below, under this lifecycle generation.
                local original_defer = vim.defer_fn
                local suppressed_start = false
                vim.defer_fn = function(callback, delay)
                        if delay == 0 and not suppressed_start then
                                suppressed_start = true
                                return
                        end
                        return original_defer(callback, delay)
                end
                local ok, setup_error = pcall(require("cursortab").setup, config)
                vim.defer_fn = original_defer
                if not ok then
                        error(setup_error)
                end
                cursortab_initialized = true
                lifecycle_entry.cursortab_initialized = true
        else
                require("cursortab.config").setup(config)
                daemon.set_enabled(true)
        end

        -- CursorTab computes a buffer's skip-state only on BufEnter/WinEnter and
        -- defaults it to "skip". Setup runs here, after the model is healthy, so
        -- the buffer already open at startup never gets recomputed and
        -- daemon.send_event silently drops its text_changed events. Recompute the
        -- current buffer now so completions work without switching buffers first.
        pcall(function()
                require("cursortab.buffer").update_state()
        end)

        if not force_start_daemon_now(daemon) then
                last_error = "CursorTab daemon could not be launched."
                schedule_recovery()
                return false
        end

        local deadline = vim.uv.now() + 12000
        local function await_rpc()
                if cleaned_up or activation_generation ~= generation or desired_profile ~= profile then
                        return
                end
                if daemon_rpc_is_ready() then
                        effective_profile = profile
                        last_error = nil
                        reset_recovery()
                        if announce then
                                notify("'" .. profile .. "' is active")
                        end
                        return
                end
                if vim.uv.now() >= deadline then
                        stop_cursortab()
                        last_error = "CursorTab daemon did not establish its RPC channel."
                        schedule_recovery()
                        if announce then
                                notify("daemon startup failed; run :CursorTabProfile", vim.log.levels.ERROR)
                        end
                        return
                end
                vim.defer_fn(await_rpc, 100)
        end
        vim.defer_fn(await_rpc, 50)
        return true
end

local function start_watchdog(state)
        -- A detached watchdog covers crashes/SIGKILL, when VimLeavePre cannot remove
        -- the final lease. Two empty scans avoid racing an atomic lease hand-off.
        local proc_start_definition
        if is_macos then
                -- ps lstart matches Lua's process_start_time byte-for-byte.
                proc_start_definition = [[
proc_start() {
        started=$(ps -o lstart= -p "$1" 2>/dev/null)
        [ -n "$started" ] || return 1
        printf '%s\n' "$started"
}
]]
        else
                proc_start_definition = [[
proc_start() {
        [ -r "/proc/$1/stat" ] || return 1
        stat=$(cat "/proc/$1/stat") || return 1
        rest=${stat##*) }
        set -- $rest
        shift 19
        printf '%s\n' "$1"
}
]]
        end
        local script = proc_start_definition .. [[
server_pid=$1
server_start=$2
lease_dir=$3
empty_scans=0
while [ "$(proc_start "$server_pid")" = "$server_start" ]; do
        live=0
        for lease in "$lease_dir"/*.lease; do
                [ -f "$lease" ] || continue
                boot=
                pid=
                start=
                { IFS= read -r boot; IFS= read -r pid; IFS= read -r start; } < "$lease"
                if [ "$boot" = "$CURSORTAB_BOOT_ID" ] && [ "$(proc_start "$pid")" = "$start" ]; then
                        live=1
                else
                        rm -f -- "$lease"
                fi
        done
        if [ "$live" -eq 0 ]; then
                empty_scans=$((empty_scans + 1))
                if [ "$empty_scans" -ge 2 ] && [ "$(proc_start "$server_pid")" = "$server_start" ]; then
                        kill -TERM "$server_pid" 2>/dev/null
                        exit 0
                fi
        else
                empty_scans=0
        fi
        sleep 2
done
]]
        vim.fn.jobstart({
                "sh",
                "-c",
                script,
                "cursortab-watchdog",
                tostring(state.pid),
                tostring(state.start_time),
                lease_dir,
        }, {
                detach = true,
                stdin = "null",
                env = { CURSORTAB_BOOT_ID = boot_id },
        })
end

local function server_command(profile_name)
        local profile = profiles[profile_name]
        local threads = profile.effective_threads
        return {
                "llama-server",
                "-hf",
                profile.model,
                "--host",
                "127.0.0.1",
                "--port",
                tostring(PORT),
                "--parallel",
                "1",
                "--ctx-size",
                tostring(profile.server_context),
                "--n-predict",
                tostring(profile.provider.max_tokens),
                "--threads",
                tostring(threads),
                "--threads-batch",
                tostring(threads),
                "--batch-size",
                "512",
                "--ubatch-size",
                "128",
                "--cache-type-k",
                "q8_0",
                "--cache-type-v",
                "q8_0",
                "--no-mmproj",
                "--no-cache-prompt",
                "--cache-ram",
                "0",
                "--no-cont-batching",
                "--no-webui",
                "--poll",
                "0",
                "--prio",
                "-1",
                "--timeout",
                tostring(math.ceil(profile.provider.completion_timeout / 1000) + 15),
        }
end

local function launch_model_server_unlocked(profile_name, activation_generation)
        local profile = profiles[profile_name]
        vim.fn.writefile({ os.date("=== %Y-%m-%d %H:%M:%S " .. profile_name .. " ===") }, log_path, "a")
        local token = vim.fn.sha256(session_token .. ":server:" .. vim.uv.hrtime())
        local command = server_command(profile_name)
        local wrapped_command = {
                "sh",
                "-c",
                'exec "$@" >> "$CURSORTAB_MODEL_LOG" 2>&1',
                "cursortab-llama",
        }
        vim.list_extend(wrapped_command, command)

        local pid
        local job_id = vim.fn.jobstart(wrapped_command, {
                detach = true,
                stdin = "null",
                env = {
                        CURSORTAB_MODEL_LOG = log_path,
                        CURSORTAB_SERVER_TOKEN = token,
                },
                on_exit = function(_, exit_code)
                        vim.schedule(function()
                                if cleaned_up then
                                        return
                                end
                                local was_current = false
                                pcall(function()
                                        with_host_lock(function()
                                                local current = read_server_state_unlocked()
                                                if current and current.pid == pid and current.token == token then
                                                        was_current = true
                                                        remove_server_state_unlocked(current)
                                                end
                                        end)
                                end)
                                if
                                        was_current
                                        and activation_generation == generation
                                        and desired_profile == profile_name
                                then
                                        stop_cursortab()
                                        last_error = "llama-server exited with code " .. exit_code .. ". See the model log."
                                        notify("model server exited; run :CursorTabProfile", vim.log.levels.ERROR)
                                end
                        end)
                end,
        })
        if job_id <= 0 then
                return nil, "llama-server could not be launched"
        end

        pid = vim.fn.jobpid(job_id)
        local start_time = process_start_time(pid)
        if not start_time then
                send_signal(pid, "TERM")
                return nil, "launched llama-server did not expose a process identity"
        end

        local state = {
                boot_id = boot_id,
                config_id = profile.config_id,
                pid = pid,
                profile = profile_name,
                start_time = start_time,
                token = token,
        }
        -- jobstart initially exposes the wrapper shell, and a command shim may
        -- exec again. Wait for the final argv/token identity, then capture the
        -- actual executable from /proc instead of resolving the shim path.
        vim.wait(1000, function()
                return (
                        server_identity_without_executable_matches(state)
                        and final_server_executable(pid) ~= nil
                ) or not process_is_running(pid)
        end, 10, true)
        if server_identity_without_executable_matches(state) then
                state.executable = final_server_executable(pid)
        end
        if not server_process_matches(state) then
                if process_is_running(pid) and tostring(process_start_time(pid)) == tostring(start_time) then
                        send_signal(pid, "TERM")
                end
                return nil, "llama-server did not complete exec"
        end

        write_json(server_path, state)
        start_watchdog(state)
        return state
end

local function ensure_model_server_unlocked(profile_name, activation_generation)
        local existing = read_server_state_unlocked()
        if existing then
                capture_server_executable_unlocked(existing)
        end
        if existing and server_process_matches(existing) then
                if existing.profile == profile_name and existing.config_id == profiles[profile_name].config_id then
                        return existing, false
                end
                if not stop_model_server_unlocked() then
                        return nil, false, last_error
                end
        elseif existing then
                local running = process_is_running(existing.pid)
                remove_server_state_unlocked(existing)
                if running then
                        return nil, false, "port state belongs to an unverified live process; refusing replacement"
                end
        end

        local state, error_message = launch_model_server_unlocked(profile_name, activation_generation)
        return state, true, error_message
end

local function publish_editor_owner()
        local ok, error_message = pcall(function()
                with_host_lock(function()
                        vim.fn.mkdir(daemon_state_dir, "p")
                        write_json(daemon_owner_path, editor_identity())
                        live_leases_unlocked()
                        cleanup_stale_daemons_unlocked()
                end)
        end)
        owner_published = ok
        return ok, error_message
end

local function wait_until_healthy(profile_name, state, activation_generation, started_at, announce)
        if cleaned_up or activation_generation ~= generation or desired_profile ~= profile_name then
                return
        end
        if not server_process_matches(state) then
                last_error = "llama-server exited before becoming healthy. See the model log."
                schedule_recovery()
                if announce then
                        notify("model startup failed; run :CursorTabProfile", vim.log.levels.ERROR)
                end
                return
        end

        health_check(function(healthy)
                if cleaned_up or activation_generation ~= generation or desired_profile ~= profile_name then
                        return
                end
                if healthy then
                        start_cursortab(profile_name, activation_generation, announce)
                        return
                end
                local timeout = test_start_timeout_ms or profiles[profile_name].start_timeout_ms
                if vim.uv.now() - started_at >= timeout then
                        last_error = "llama-server startup timed out; recovery remains scheduled. See the model log."
                        schedule_recovery()
                        if announce then
                                notify("model startup timed out; recovery scheduled", vim.log.levels.ERROR)
                        end
                        return
                end
                vim.defer_fn(function()
                        wait_until_healthy(profile_name, state, activation_generation, started_at, announce)
                end, 1000)
        end)
end

local function activate(profile_name, persist, quiet)
        if profile_name ~= "off" and not profiles[profile_name] then
                notify("unknown profile '" .. profile_name .. "'", vim.log.levels.ERROR)
                return
        end
        if quiet and activation_in_flight and profile_name == desired_profile then
                return
        end

        desired_profile = profile_name
        generation = generation + 1
        local activation_generation = generation
        activation_in_flight = true
        if profile_name ~= "off" and not owner_published then
                local published, publish_error = publish_editor_owner()
                if not published then
                        last_error = tostring(publish_error)
                        schedule_recovery()
                        if not quiet then
                                notify("could not publish daemon ownership; recovery scheduled", vim.log.levels.ERROR)
                        end
                        return
                end
        end
        local daemon_stopped = stop_cursortab()

        if profile_name == "off" then
                local ok, error_message = pcall(function()
                        with_host_lock(function()
                                if persist then
                                        persist_profile_unlocked("off")
                                elseif read_profile_unlocked() ~= "off" then
                                        return
                                end
                                vim.fn.delete(lease_path)
                                stop_model_server_unlocked()
                        end)
                end)
                reset_recovery()
                if not ok then
                        last_error = tostring(error_message)
                        notify("could not disable profile; run :CursorTabProfile", vim.log.levels.ERROR)
                        return
                end
                effective_profile = "off"
                if persist then
                        notify("profile is off")
                end
                return
        end

        if not daemon_stopped then
                schedule_recovery()
                if not quiet then
                        notify("daemon stop failed; recovery scheduled", vim.log.levels.ERROR)
                end
                return
        end

        local prerequisites_ok, short_error, detail = check_prerequisites()
        local state
        local started = false
        local superseded = false
        local ok, error_message = pcall(function()
                with_host_lock(function()
                        if persist then
                                persist_profile_unlocked(profile_name)
                        elseif read_profile_unlocked() ~= profile_name then
                                superseded = true
                                return
                        end
                        write_lease_unlocked()
                        if prerequisites_ok then
                                local ensure_error
                                state, started, ensure_error = ensure_model_server_unlocked(
                                        profile_name,
                                        activation_generation
                                )
                                if not state then
                                        error(ensure_error or "model server is unavailable")
                                end
                        end
                end)
        end)
        if superseded then
                activation_in_flight = false
                return
        end
        if not ok then
                last_error = tostring(error_message)
                schedule_recovery()
                if not quiet then
                        notify("model activation failed; recovery scheduled", vim.log.levels.ERROR)
                end
                return
        end
        if not prerequisites_ok then
                last_error = detail
                schedule_recovery()
                if not quiet then
                        notify(short_error, vim.log.levels.ERROR)
                end
                return
        end

        if started and not quiet then
                notify("starting '" .. profile_name .. "' (see :CursorTabProfile)")
        end
        wait_until_healthy(profile_name, state, activation_generation, vim.uv.now(), not quiet)
end

local function complete_profile(argument_lead)
        local matches = {}
        for _, profile in ipairs({ "off", "fast", "zeta-2" }) do
                if vim.startswith(profile, argument_lead) then
                        table.insert(matches, profile)
                end
        end
        return matches
end

local function show_status()
        local server
        local clients = 0
        local ok, status_error = pcall(function()
                with_host_lock(function()
                        server = read_server_state_unlocked()
                        clients = live_leases_unlocked()
                end)
        end)
        if not ok then
                last_error = tostring(status_error)
        end

        local pending = desired_profile ~= effective_profile and " (pending)" or ""
        local lines = {
                "CursorTab local model",
                "",
                "Desired:  " .. desired_profile,
                "Effective: " .. effective_profile .. pending,
                "Clients:   " .. clients,
                "Server:    "
                        .. (server and (server.profile .. " (PID " .. server.pid .. ")") or "not running"),
                "Limits:    input="
                        .. (profiles[desired_profile] and profiles[desired_profile].provider.context_size or 0)
                        .. ", output="
                        .. (profiles[desired_profile] and profiles[desired_profile].provider.max_tokens or 0)
                        .. ", timeout="
                        .. (profiles[desired_profile]
                                        and profiles[desired_profile].provider.completion_timeout / 1000
                                or 0)
                        .. "s, server context="
                        .. (profiles[desired_profile] and profiles[desired_profile].server_context or 0),
                "Model log: " .. log_path,
                "Daemon:    " .. daemon_state_dir,
        }
        if last_error then
                table.insert(lines, "")
                table.insert(lines, "Last error: " .. last_error)
        end

        if #vim.api.nvim_list_uis() == 0 then
                print(table.concat(lines, "\n"))
                return
        end
        local buffer = vim.api.nvim_create_buf(false, true)
        vim.bo[buffer].bufhidden = "wipe"
        vim.bo[buffer].modifiable = true
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
        vim.bo[buffer].modifiable = false
        local width = math.max(1, math.min(100, vim.o.columns - 4))
        local height = math.min(#lines, math.max(1, vim.o.lines - 4))
        local window = vim.api.nvim_open_win(buffer, true, {
                relative = "editor",
                row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
                col = math.max(0, math.floor((vim.o.columns - width) / 2)),
                width = width,
                height = height,
                style = "minimal",
                border = "rounded",
                title = " CursorTab status ",
                title_pos = "center",
        })
        vim.wo[window].wrap = false
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buffer, silent = true })
        vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buffer, silent = true })
end

local function cleanup(reloading)
        if cleaned_up then
                return
        end
        cleaned_up = true
        activation_in_flight = false
        generation = generation + 1
        if profile_timer then
                profile_timer:stop()
                if not profile_timer:is_closing() then
                        profile_timer:close()
                end
                profile_timer = nil
        end

        local stop_ok, daemon_stopped = pcall(stop_cursortab)
        pcall(function()
                with_host_lock(function()
                        if not reloading then
                                vim.fn.delete(lease_path)
                                if live_leases_unlocked() == 0 then
                                        stop_model_server_unlocked()
                                end
                        end
                        if stop_ok and daemon_stopped then
                                clean_daemon_directory_unlocked(daemon_state_dir)
                        end
                end)
        end)
        if not reloading and lifecycle_registry[state_dir] == lifecycle_entry then
                lifecycle_registry[state_dir] = nil
        end
end

local function setup_cursortab()
        -- A config reload transfers this process's existing lease and model
        -- attachment, while cancelling the old timer/RPC daemon lifecycle.
        if previous_lifecycle and previous_lifecycle.cleanup then
                previous_lifecycle.cleanup(true)
        end
        lifecycle_entry.cleanup = cleanup
        lifecycle_entry.cursortab_initialized = cursortab_initialized
        lifecycle_registry[state_dir] = lifecycle_entry

        ensure_state_dir()
        local published, setup_error = publish_editor_owner()
        if not published then
                last_error = tostring(setup_error)
        end
        desired_profile = read_profile_unlocked()

        vim.api.nvim_create_user_command("CursorTabProfile", function(arguments)
                if arguments.args == "" then
                        show_status()
                else
                        activate(arguments.args, true)
                end
        end, {
                nargs = "?",
                complete = complete_profile,
                desc = "Show or select the managed local CursorTab profile",
                force = true,
        })

        local autocmd_group = vim.api.nvim_create_augroup("MrkCursorTabLifecycle", { clear = true })
        vim.api.nvim_create_autocmd({ "VimLeavePre", "VimLeave" }, {
                group = autocmd_group,
                callback = function()
                        cleanup(false)
                end,
                desc = "Release this Neovim instance's CursorTab processes",
        })

        profile_timer = vim.uv.new_timer()
        lifecycle_entry.timer = profile_timer
        profile_timer:start(1000, 1000, function()
                vim.schedule(function()
                        if cleaned_up then
                                return
                        end
                        local saved = read_profile_unlocked()
                        if saved ~= desired_profile then
                                activate(saved, false, true)
                        elseif saved ~= "off" and not activation_in_flight then
                                local needs_recovery = effective_profile == "off"
                                if not needs_recovery then
                                        local server = read_json(server_path)
                                        needs_recovery = not server
                                                or server.profile ~= saved
                                                or not server_process_matches(server)
                                                or not daemon_rpc_is_ready()
                                end
                                if needs_recovery and vim.uv.now() >= next_recovery_at then
                                        activate(saved, false, true)
                                end
                        end
                end)
        end)

        activate(desired_profile, false, false)
end

return {
        {
                "cursortab/cursortab.nvim",
                version = "*",
                lazy = false,
                build = "cd server && go build",
                config = setup_cursortab,
        },
}
