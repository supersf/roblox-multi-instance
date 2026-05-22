# Roblox 多開解鎖器

**語言：** [English](README.md) | [繁體中文](README.zh.md)

一個輕量級的 PowerShell 工具，讓你可以在 Windows 上同時執行多個 Roblox 用戶端，**不需要**修改 Roblox 任何檔案、不需要注入 DLL、也不會接觸遊戲本體。

---

## 運作原理

Roblox 使用一個名為 `ROBLOX_singletonEvent` 的具名 Windows 同步物件來限制單一執行個體。當第二個 Roblox 啟動時，會偵測到這個事件已存在，於是把啟動請求轉送給已在執行的用戶端，而不會建立新的處理程序。

本工具使用 Microsoft 官方的 Sysinternals `handle64.exe`，將執行中的 Roblox 處理程序內部那個事件的控制代碼關閉。一旦關閉，作業系統會視該名稱為可用狀態，後續啟動的 Roblox 就會作為完全獨立的處理程序執行。**已在執行的第一個 Roblox 完全不受影響**，可繼續正常遊玩。

---

## 系統需求

| 項目 | 說明 |
|---|---|
| 作業系統 | Windows 10 / 11 |
| Shell | Windows PowerShell 5.1 以上（內建） |
| 權限 | 系統管理員（指令碼會自動請求 UAC） |
| 外部工具 | Sysinternals `handle64.exe`（見「安裝」） |
| 帳號 | **兩個或以上**的 Roblox 帳號 — 因伺服器限制，同一個帳號無法同時在兩個遊戲中 |

---

## 安裝

1. **複製或下載** 本儲存庫
2. 完成 — 不需要其他手動設定

首次執行時，指令碼會自動從 Microsoft 官方伺服器（`https://download.sysinternals.com/files/Handle.zip`）下載 Sysinternals `handle64.exe`，並放入本地的 `handle_tool/` 資料夾。之後每次執行都會直接重複使用該檔案。

若你想自行下載（例如離線機器），請從上述網址取得壓縮檔，解壓後將 `handle64.exe` 放到指令碼旁邊的 `handle_tool/` 資料夾即可。

---

## 使用步驟

本工具提供兩種語言版本：

- `RobloxUnlock.bat` — 英文（預設）
- `RobloxUnlock.zh.bat` — 繁體中文

兩者功能完全相同，請依自己喜好選擇。

1. **正常啟動第一個 Roblox** — 開啟瀏覽器登入帳號 A，並點選任一遊戲的 Play 按鈕。
2. **等待**第一個 Roblox 視窗完全載入（進入遊戲內或停留在主畫面均可）。
3. **雙擊 `RobloxUnlock.zh.bat`**（或英文版的 `RobloxUnlock.bat`）並同意 UAC 提權要求。
4. 看到綠色訊息表示成功：
   ```
   [成功] 事件已徹底釋放！
   ```
5. **啟動第二個 Roblox** — 使用另一個瀏覽器（或 InPrivate / 無痕視窗）登入帳號 B 後點擊 Play，會作為獨立處理程序執行。
6. 想開第三、第四個？重複步驟 3 和 5 即可。

---

## 疑難排解

**指令碼顯示「拒絕存取」或「[失敗]」**
你沒有以系統管理員身分執行。`.bat` 檔案會自動觸發 UAC 視窗，請務必點選**「是」**。

**第二個 Roblox 把第一個擠掉了**
最常見的原因：兩個瀏覽器都登入了同一個 Roblox 帳號。Roblox 伺服器只允許每個帳號同時一個遊戲連線，請改用不同的帳號。

**找不到 `handle64.exe` 或下載失敗**
指令碼會在首次執行時自動下載 `handle64.exe`。若下載失敗（無網路、防火牆、企業代理伺服器），請手動下載 https://download.sysinternals.com/files/Handle.zip，解壓後將 `handle64.exe` 放入指令碼旁邊的 `handle_tool/` 資料夾。

**「找不到任何處理程序佔用該事件」**
你在啟動 Roblox 之前就執行了解鎖指令碼。請先啟動第一個 Roblox，再執行本工具。

**第一個 Roblox 在執行指令碼後當機**
這種情況極為少見。本工具僅關閉單一具名事件的控制代碼，不會接觸任何其他處理程序狀態。若可重現，請附上你的 Roblox 版本號開 issue 回報。

---

## 限制

- 同一個 Roblox 帳號無法同時在兩個遊戲中（伺服器規則，無法繞過）
- 每次想再開新的執行個體都要重新執行一次解鎖
- 少數內建反作弊機制的遊戲可能會偵測並踢出多開玩家
- 本工具不提供帳號管理功能 — 若需要快速切換帳號，建議搭配第三方帳號管理工具使用

---

## 技術細節

1. 指令碼使用 `handle64.exe -a` 列舉系統中所有名稱為 `\Sessions\<n>\BaseNamedObjects\ROBLOX_singletonEvent` 的控制代碼。
2. 對於每一個符合的項目，呼叫 `handle64.exe -c <handle_id> -p <pid> -y`，內部透過 `DuplicateHandle` 搭配 `DUPLICATE_CLOSE_SOURCE` 旗標，從外部處理程序關閉指定的控制代碼。此操作需要 `PROCESS_DUP_HANDLE` 存取權，所以必須提權。
3. 所有符合的控制代碼關閉後，核心物件的參考計數歸零，具名事件即被銷毀。下次 Roblox 啟動時會建立一個全新的事件並獨立執行。

---

## 免責聲明

本工具僅操作 Windows 核心物件的控制代碼，**不會**修補、注入或修改任何 Roblox 程式碼、記憶體或網路流量。

不過要注意，同時執行多個 Roblox 用戶端並非官方支援的設定。Roblox 使用條款並未明文禁止，但未來 Roblox 改版時可能變更用戶端行為導致本工具失效。請自行斟酌使用風險。

本專案與 Roblox Corporation 無關聯，亦未獲其認可。

---

## 致謝

- [Sysinternals Handle](https://learn.microsoft.com/zh-tw/sysinternals/downloads/handle) — 作者 Mark Russinovich（Microsoft）

---

## 授權

MIT — 詳見 [LICENSE](LICENSE) 檔案。
