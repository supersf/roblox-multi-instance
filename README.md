# Roblox Multi-Instance Unlocker

**Languages:** [English](README.md) | [繁體中文](README.zh.md)

A lightweight PowerShell tool that lets you run multiple Roblox clients simultaneously on Windows, without patching the game, injecting DLLs, or modifying any Roblox files.

---

## How It Works

Roblox enforces a single-instance limit using a named Windows synchronization object called `ROBLOX_singletonEvent`. When a second copy launches, it detects this event and forwards the request to the already-running client instead of starting a new process.

This tool uses Microsoft's official Sysinternals `handle64.exe` to close that specific event handle inside the running Roblox process. Once closed, the OS treats the name as available again, and subsequent launches run as fully independent processes. The first Roblox client is **not affected** and keeps running normally.

---

## Requirements

| Item | Notes |
|---|---|
| OS | Windows 10 / 11 |
| Shell | Windows PowerShell 5.1+ (built in) |
| Privileges | Administrator (the script auto-requests UAC) |
| External tool | Sysinternals `handle64.exe` (see Setup) |
| Accounts | **Two or more** Roblox accounts — the same account cannot be in two games at the same time due to server-side rules |

---

## Setup

1. **Clone or download** this repository
2. That's it — no manual setup required

On first run, the script will automatically download Sysinternals `handle64.exe` from Microsoft's official server (`https://download.sysinternals.com/files/Handle.zip`) and place it in a local `handle_tool/` folder. Subsequent runs reuse the same file.

If you prefer to download it yourself (e.g. offline machine), grab the zip from the URL above and extract `handle64.exe` into `handle_tool/` next to the script.

---

## Usage

Two language versions are provided:

- `RobloxUnlock.bat` — English (default)
- `RobloxUnlock.zh.bat` — Traditional Chinese (繁體中文)

Both do exactly the same thing — pick whichever you prefer.

1. **Launch the first Roblox client normally** — open the Roblox website in a browser, log in with account A, and click Play on any game.
2. **Wait** until the first Roblox window is fully loaded (either in-game or at the menu).
3. **Double-click `RobloxUnlock.bat`** (or `RobloxUnlock.zh.bat`) and accept the UAC elevation prompt.
4. You should see the green message:
   ```
   [Success] Event has been fully released!
   ```
5. **Launch the second Roblox client** in a different browser (or a private/incognito window) logged in as account B. It will start as an independent process.
6. To open a third or fourth instance, simply repeat steps 3 and 5.

---

## Troubleshooting

**The script reports `Access denied` or `[Failed]` when closing handles**
You did not run the script as Administrator. The `.bat` file should trigger a UAC prompt automatically — make sure you click **Yes**, not No.

**The second Roblox kicks out the first one**
You are most likely launching both copies with the same Roblox account. The server only allows one active session per account. Use two different accounts.

**`Cannot find handle64.exe` / download failed**
The script normally downloads `handle64.exe` automatically on first run. If the download fails (no internet, firewall, corporate proxy), manually download https://download.sysinternals.com/files/Handle.zip, extract `handle64.exe`, and place it in the `handle_tool/` subfolder next to the script.

**`No process is holding the event`**
You ran the unlock script before launching Roblox. Launch the first Roblox client first, then run the unlock script.

**The first Roblox crashes after running the script**
This is rare. The script only closes a single named-event handle and does not touch any other process state. If it happens reproducibly, please open an issue with your Roblox version.

---

## Limitations

- One Roblox account cannot be in two games simultaneously (server-side rule, cannot be bypassed)
- Each new instance launch requires re-running the unlock
- A few games with custom anti-cheat may flag or kick multi-instance players
- This tool does not provide account management — use a third-party account manager if you need to switch accounts quickly

---

## How It Works (Technical)

1. The script enumerates all open handles named `\Sessions\<n>\BaseNamedObjects\ROBLOX_singletonEvent` using `handle64.exe -a`.
2. For each match, it calls `handle64.exe -c <handle_id> -p <pid> -y`, which uses `DuplicateHandle` with `DUPLICATE_CLOSE_SOURCE` to close the handle from outside the owning process. This requires `PROCESS_DUP_HANDLE` access, which is why elevation is needed.
3. After all matching handles are closed, the named event is destroyed by the kernel (no more references), and a subsequent Roblox launch will create a fresh one and run independently.

---

## Disclaimer

This tool only manipulates Windows kernel object handles. It does **not** patch, inject, or modify any Roblox binary, memory, or network traffic.

That said, running multiple Roblox clients is not an officially supported configuration. Roblox's Terms of Use do not explicitly forbid it, but Roblox may change client behavior in future updates that breaks this tool. Use at your own risk.

This project is not affiliated with or endorsed by Roblox Corporation.

---

## Credits

- [Sysinternals Handle](https://learn.microsoft.com/sysinternals/downloads/handle) by Mark Russinovich (Microsoft)

---

## License

MIT — see [LICENSE](LICENSE) for details.
