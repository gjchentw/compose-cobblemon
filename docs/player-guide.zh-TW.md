# 玩家指南

裝一個 pack，按 Play，加入伺服器。你不需要自己安裝 Fabric、Fabric API 或任何 mod：pack 已經包含全部。

## 你需要準備

- Minecraft Java 版帳號。
- 至少 8 GB RAM 的電腦（遊戲本身建議給 6 GB）。
- 以下任一啟動器：
  - [Modrinth App](https://modrinth.com/app)（建議）
  - [Prism Launcher](https://prismlauncher.org/)
- 你的 Minecraft 帳號名稱已加入伺服器白名單。請向管理員申請。

## 1. 下載 pack

打開 [Releases 頁面](../../releases/latest)，下載名為 `cobblemon-X.Y.Z.mrpack` 的檔案（X.Y.Z 是 pack 版本）。

## 2. 安裝 pack

**Modrinth App**

1. 打開 Modrinth App，點 **+**（建立 profile）。
2. 選 **From file**，挑選剛下載的 `.mrpack`，或直接把檔案拖進視窗。
3. 等下載完成。profile 會出現在你的 library。

**Prism Launcher**

1. 點 **Add Instance**，再點 **Import**。
2. 瀏覽到剛下載的 `.mrpack` 並確認。
3. 等下載完成。

## 3. 給遊戲足夠的記憶體

把 Java 最大記憶體設為 4 GB（最低）或 6 GB（建議）。超過 8 GB 沒有幫助，反而可能卡頓。

- Modrinth App：**Settings > Java and memory > Maximum memory**，或在 profile 的 **Options** 裡個別設定。
- Prism Launcher：對 instance 按右鍵，**Edit > Settings > Java > Memory**，把 **Maximum memory allocation** 設為 4096 或 6144 MiB。

## 4. 開始遊戲

1. 在 profile 上按 **Play**。第一次啟動要等一分鐘載入 mod。
2. 主選單選 **Multiplayer**。**Cobblemon Server** 已經在清單裡。
3. 選它，點 **Join Server**。

如果清單裡沒有伺服器，點 **Add Server**，輸入管理員給你的位址。

## 更新 pack

當伺服器清單的 MOTD 顯示的 pack 版本（例如 `Pack 1.1.0`）和你安裝的不同，表示伺服器已升級：

1. 從 Releases 頁面下載新的 `.mrpack`。
2. 照步驟 2 再裝成一個新的 profile。
3. 從新的 profile 進遊戲。什麼都不會遺失：你的寶可夢、物品和進度都在伺服器上。

新 profile 的客戶端設定（視距、按鍵）會回到 pack 預設值。

## 疑難排解

| 症狀 | 意思 | 處理方式 |
|---|---|---|
| 「You are not white-listed on this server!」 | 管理員還沒加你的帳號 | 把你正確的 Minecraft 帳號名稱給管理員 |
| 加入時出現 mod 或版本不符的訊息 | 你的 pack 版本和伺服器不同 | 看 MOTD，安裝相同版本的 pack |
| 載入中當掉 | 記憶體不夠 | 依步驟 3 設為 6 GB，並更新顯示卡驅動 |
| FPS 很低 | 預設值對你的電腦太高 | 在 **Options > Video Settings** 把 Render Distance 降到 8、Simulation Distance 降到 5 |
| 看不到寶可夢或戰鬥沒反應 | 連線不穩或伺服器正在重啟 | 等一分鐘再重新連線 |

回報問題時，請附上你安裝的 pack 版本與錯誤訊息的原文。
