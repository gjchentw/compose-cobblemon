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

管理員會把發布頁面的連結傳給你。打開它，下載名為 `cobblemon-X.Y.Z.mrpack` 的檔案（X.Y.Z 是 pack 版本）。

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

## 5. 進遊戲後的前幾分鐘

1. **選初始寶可夢。** 按 **M**，畫面會列出可以選的寶可夢，挑一隻。牠會出現在畫面左側的隊伍裡。
2. **放出來。** 用 **上**、**下** 方向鍵選隊伍裡的位置，按 **R** 放出寶可夢，再按一次 **R** 收回。**O** 可以隱藏或顯示隊伍。
3. **戰鬥。** 寶可夢放出來的狀態下，看著野生寶可夢按 **R** 發起挑戰，然後在戰鬥畫面選招式。野生寶可夢出現在草地、水裡和洞穴，有些只在晚上或特定生態域出現。
4. **捕捉。** 精靈球用球果（長在球果樹上）和金屬合成。想看任何東西的配方：打開物品欄，把游標移到物品上按 **R**（EMI 會顯示怎麼做）。先在戰鬥中削弱野生寶可夢，輪到你時用右鍵把精靈球丟向牠。
5. **治療。** 睡床會治好整隊。也可以合成治療機放在家裡。
6. **保管。** 合成 PC 方塊，放隊伍六隻以外的寶可夢。
7. **騎乘。** 有些寶可夢可以騎：放出來後對牠按右鍵。騎乘中按住 **左 Alt** 可以自由轉頭看。
8. **和其他玩家交換或對戰。** 蹲下對另一位玩家按右鍵會打開互動選單，選 Trade 或 Battle。
9. **迷路或卡住？** 睡床可以設定重生點。按 **T** 開聊天求助，管理員可以把你傳送回來。

其他內容，從進化到培育，都在 [Cobblemon wiki](https://wiki.cobblemon.com)。

## 值得知道的按鍵

| 按鍵 | 功能 |
|---|---|
| M | Cobblemon：第一次用來選初始寶可夢，之後打開所選寶可夢的資料 |
| R | Cobblemon：放出或收回所選寶可夢；看著野生寶可夢時發起戰鬥 |
| 上、下 | Cobblemon：選隊伍裡的上一隻、下一隻 |
| O | Cobblemon：隱藏或顯示隊伍 |
| 左 Alt（按住） | Cobblemon：騎乘時自由轉頭 |
| V | Xaero's 世界地圖（預設是 M，為了不擋住 Cobblemon 的畫面改到 V） |
| Z | Xaero's 小地圖：放大小地圖 |
| B、U、Y | Xaero's：新增路徑點、路徑點清單、小地圖設定 |
| E、T | 物品欄、聊天 |
| R、U（在選單裡） | EMI：游標所指物品的配方、以及它的用途 |

所有按鍵都可以在 **Options > Controls > Key Binds** 更改。

## 更新 pack

當伺服器清單的 MOTD 顯示的 pack 版本（例如 `Pack 1.1.0`）和你安裝的不同，表示伺服器已升級：

1. 從管理員傳來的連結下載新的 `.mrpack`。
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
