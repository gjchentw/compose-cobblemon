# Pack 安裝與更新指南

裝一個 pack，按 Play，加入伺服器。你不需要自己安裝 Fabric、Fabric API 或任何 mod：pack 已經包含全部。進遊戲之後要做什麼，寫在[遊玩指南](play-guide.zh-TW.md)。

## 你需要準備

- Minecraft Java 版帳號。
- 一台跑得動遊戲的電腦：見[遊玩指南](play-guide.zh-TW.md#你的電腦需要)的「你的電腦需要」。
- 以下任一啟動器：
  - [Modrinth App](https://modrinth.com/app)（建議）
  - [Prism Launcher](https://prismlauncher.org/)
- 你的 Minecraft 帳號名稱已加入伺服器白名單。請向管理員申請。

## 1. 下載 pack

管理員會傳給你一個連結。打開它，瀏覽器就會下載 `cobblemon.mrpack`。這個連結不會變，永遠給你最新的 pack，更新時還會用到，請留著。

## 2. 安裝 pack

**Modrinth App**

1. 打開 Modrinth App，點 **+**（建立 profile）。
2. 選 **From file**，挑選剛下載的 `.mrpack`，或直接把檔案拖進視窗。
3. 等下載完成。profile 會出現在你的 library。

**Prism Launcher**

1. 點 **Add Instance**，再點 **Import**。
2. 瀏覽到剛下載的 `.mrpack` 並確認。
3. 等下載完成。

## 3. 設定遊戲的記憶體

第一次啟動前，先給遊戲足夠的記憶體。要給多少、在啟動器的哪裡設定，寫在遊玩指南：[給遊戲足夠的記憶體](play-guide.zh-TW.md#給遊戲足夠的記憶體)。

## 4. 加入伺服器

1. 在 profile 上按 **Play**。第一次啟動要等一分鐘載入 mod。
2. 主選單選 **Multiplayer**。伺服器已經在清單裡，名稱最後的括號是你的 pack 版本，例如 `Cobblemon Server (2026.11.18-95db987)`。
3. 選它，點 **Join Server**。

如果清單裡沒有伺服器，點 **Add Server**，輸入管理員給你的位址。

進來了。接著看[遊玩指南](play-guide.zh-TW.md)：進遊戲後的前幾分鐘、按鍵，以及遊戲出狀況時怎麼辦。

## 更新 pack

伺服器清單會顯示兩個版本：伺服器項目名稱裡的是你的 pack 版本，名稱下面那一行（MOTD，例如 `Pack 2026.11.18-95db987`）是伺服器的版本。兩者不同，表示伺服器已升級：

1. 從同一個連結重新下載 `cobblemon.mrpack`。
2. 照步驟 2 再裝成一個新的 profile。
3. 從新的 profile 進遊戲。什麼都不會遺失：你的寶可夢、物品和進度都在伺服器上。

新 profile 的客戶端設定（視距、按鍵）會回到 pack 預設值。

## 疑難排解

| 症狀 | 意思 | 處理方式 |
|---|---|---|
| 「You are not white-listed on this server!」 | 管理員還沒加你的帳號 | 把你正確的 Minecraft 帳號名稱給管理員 |
| 加入時出現 mod 或版本不符的訊息 | 你的 pack 版本和伺服器不同 | 比對項目名稱裡的版本和 MOTD；不同就更新 pack（見「更新 pack」） |

遊戲本身的問題（當機、FPS 很低、看不到寶可夢）寫在[遊玩指南](play-guide.zh-TW.md#疑難排解)。

回報問題時，請附上你的 pack 版本（在伺服器項目的名稱裡）與錯誤訊息的原文。
