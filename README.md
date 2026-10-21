# 🎃 萬聖節怪物召喚機 (HalloweenMonster)

用 SwiftUI 寫的 iOS App：每按一次「召喚怪物 👻」，就從網路抓一張怪物圖片，並隨機產生怪物名字、種族、能力、弱點和恐怖指數。

## 圖片來源

- **Robohash 怪物**：[robohash.org](https://robohash.org) 的 `set2`（怪物頭像），每次用隨機種子產生不同的怪物。
- **維基共享資源**：用 [Wikimedia Commons API](https://commons.wikimedia.org/w/api.php) 搜尋 “halloween monster”、“werewolf illustration” 這類關鍵字，隨機挑一張圖。如果搜尋失敗，會改用 Robohash。

其他功能：收藏喜歡的怪物、夜空和蝙蝠動畫背景；畫面變寬時（iPhone Duo 展開、橫向）會改成圖片和資料左右並排。

## 專案結構

```
project.yml                     XcodeGen 設定（CI 會用它產生 HalloweenMonster.xcodeproj）
HalloweenMonster/               App 原始碼
HalloweenMonsterUITests/        UI 測試，負責在錄影時操作 App
scripts/                        CI 用的腳本（選 Xcode、建立 iPhone Duo 模擬器、錄影）
.github/workflows/              GitHub Actions workflow
recordings/                     CI 錄好的操作影片
```

在 Mac 上開發時，先執行 `brew install xcodegen && xcodegen generate`，再打開 `HalloweenMonster.xcodeproj`。

## 在 GitHub Actions 上錄影

`.github/workflows/record-iphone-duo.yml` 在 `xcode-27` runner 上執行：

1. 選擇 runner 上最新的 Xcode 27.x（iPhone Duo 模擬器要 Xcode 27.1 以上）。
2. 用 XcodeGen 產生專案。
3. 建立並開機「iPhone Duo」模擬器。如果 runner 上沒有對應的 iOS runtime，會先執行 `xcodebuild -downloadPlatform iOS` 下載。
4. 編譯 App 和 UI 測試。
5. 用 `xcrun simctl io recordVideo` 錄下 UI 測試操作 App 的過程。
6. 把影片上傳成 artifact `iphone-duo-demo`，並 commit 到 `recordings/iphone-duo-demo.mov`。

推送到 `main` 或 `claude/**` 分支時會自動執行，也可以在 Actions 頁面手動執行（workflow_dispatch）。
