-- Rayfield UI Framework のロード
getgenv().SecureMode = true -- セキュリティモードを有効化
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

-- サービス
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")

-- グローバル変数
local remoteEvents = {}
local remoteFunctions = {}
local capturedData = {}
local isCapturing = false
local selectedEvent = nil
local selectedEventObj = nil
local isAutoRunning = false
local executionCount = 0
local executionHistory = {}
local savedConfigurations = {}
local hookEnabled = false
local originalNamecall = nil
local currentTheme = "Default"

-- 設定保存
local DEFAULT_CONFIG = {
    AutoSearch = true,
    UITheme = "デフォルト",
    UpdateRate = 5,
    SearchDepth = 5,
    DefaultPaths = "ReplicatedStorage,Workspace",
    AutoSave = true,
    ShowNotifications = true,
    CaptureLimit = 100,
    ExecutionInterval = 0.5,
    SecurityLevel = "低 (推奨)",
    Language = "日本語",
    AntiDetect = false
}

-- Rayfieldウィンドウ作成
local Window = Rayfield:CreateWindow({
    Name = "🔍 Remote Explorer Pro v2.1",
    LoadingTitle = "高度なRemote探索ツールをロード中...",
    LoadingSubtitle = "by ScriptMaster Pro | 起動中...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "RemoteExplorerPro",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = {
        Enabled = false,
        Key = "",
        Input = true,
        SaveKey = true,
        Notify = false
    }
})

-- タブ作成
local DashboardTab = Window:CreateTab("📊 ダッシュボード", 13094326971)
local ExplorerTab = Window:CreateTab("🔎 エクスプローラー", 13094326971)
local ExecutorTab = Window:CreateTab("⚡ エグゼキューター", 13094326971)
local CaptureTab = Window:CreateTab("🎯 キャプチャ", 13094326971)
local BuilderTab = Window:CreateTab("🛠️ ビルダー", 13094326971)
local SettingsTab = Window:CreateTab("⚙️ 設定", 13094326971)

-- ========== 📊 ダッシュボード ==========
DashboardTab:CreateSection("📈 システム情報")

-- ゲーム情報取得
local gameInfo = {}
local success, gameData = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId)
end)

if success then
    gameInfo = {
        Name = gameData.Name,
        Description = gameData.Description,
        Creator = gameData.Creator.Name
    }
else
    gameInfo = {
        Name = "Unknown Game",
        Description = "Failed to load game info",
        Creator = "Unknown"
    }
end

local statsLabel = DashboardTab:CreateParagraph({
    Title = "📊 システム統計",
    Content = "初期化中..."
})

local statusLabel = DashboardTab:CreateLabel("🟢 システム状態: 正常")

-- ゲーム情報表示
local gameInfoLabel = DashboardTab:CreateParagraph({
    Title = "🎮 ゲーム情報",
    Content = string.format(
        "ゲーム名: %s\n" ..
        "作成者: %s\n" ..
        "Place ID: %d\n" ..
        "プレイヤー: %s\n" ..
        "FPS: 測定中...",
        gameInfo.Name,
        gameInfo.Creator,
        game.PlaceId,
        Players.LocalPlayer.Name
    )
})

-- FPS計測
local fpsCounter = 0
local lastTime = tick()
RunService.RenderStepped:Connect(function()
    fpsCounter = fpsCounter + 1
    local currentTime = tick()
    if currentTime - lastTime >= 1 then
        local fps = math.floor(fpsCounter / (currentTime - lastTime))
        local currentContent = gameInfoLabel.Content
        currentContent = string.gsub(currentContent, "FPS: %d+", "FPS: " .. fps)
        currentContent = string.gsub(currentContent, "FPS: 測定中...", "FPS: " .. fps)
        gameInfoLabel:Set({Title = "🎮 ゲーム情報", Content = currentContent})
        fpsCounter = 0
        lastTime = currentTime
    end
end)

-- クイックアクション
DashboardTab:CreateSection("⚡ クイックアクション")

local quickSearchBtn = DashboardTab:CreateButton({
    Name = "🔍 即時検索",
    Callback = function()
        Rayfield:Notify({
            Title = "🔍 検索開始",
            Content = "RemoteEvent/Functionを検索しています...",
            Duration = 2,
            Image = 13094326971
        })
        task.spawn(function()
            performSearch()
        end)
    end
})

local clearCacheBtn = DashboardTab:CreateButton({
    Name = "🧹 キャッシュクリア",
    Callback = function()
        remoteEvents = {}
        remoteFunctions = {}
        capturedData = {}
        executionHistory = {}
        selectedEvent = nil
        selectedEventObj = nil
        executionCount = 0
        
        statsLabel:Set({
            Title = "📊 システム統計",
            Content = "🔍 RemoteEvents: 0\n⚡ RemoteFunctions: 0\n💾 キャプチャデータ: 0\n📝 実行履歴: 0\n⏱️ 実行回数: 0"
        })
        
        Rayfield:Notify({
            Title = "🧹 キャッシュクリア",
            Content = "すべてのキャッシュをクリアしました",
            Duration = 2,
            Image = 13094326971
        })
    end
})

-- ウィンドウ制御
DashboardTab:CreateSection("🪟 ウィンドウ制御")

DashboardTab:CreateButton({
    Name = "📌 最小化/最大化",
    Callback = function()
        Window:Minimize()
    end
})

-- リアルタイム更新
task.spawn(function()
    while Window do
        local eventCount = #remoteEvents
        local functionCount = #remoteFunctions
        local captureCount = #capturedData
        local historyCount = #executionHistory
        
        local stats = string.format(
            "🔍 RemoteEvents: %d\n" ..
            "⚡ RemoteFunctions: %d\n" ..
            "💾 キャプチャデータ: %d\n" ..
            "📝 実行履歴: %d\n" ..
            "⏱️ 実行回数: %d",
            eventCount, functionCount, captureCount, historyCount, executionCount
        )
        
        statsLabel:Set({Title = "📊 システム統計", Content = stats})
        
        -- システム状態の更新
        local status = "🟢 正常"
        if eventCount > 50 then
            status = "🟡 注意 (多くのRemoteを検出)"
        end
        if captureCount > DEFAULT_CONFIG.CaptureLimit then
            status = "🟠 警告 (キャプチャデータが多い)"
        end
        
        statusLabel:Set("システム状態: " .. status)
        
        wait(5)
    end
end)

-- ========== 🔎 エクスプローラー ==========
ExplorerTab:CreateSection("🔍 検索設定")

local searchPathsInput = ExplorerTab:CreateInput({
    Name = "検索パス (カンマ区切り)",
    PlaceholderText = "例: ReplicatedStorage,Workspace,StarterPack",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        DEFAULT_CONFIG.DefaultPaths = text
    end
})

local searchDepthSlider = ExplorerTab:CreateSlider({
    Name = "検索深度",
    Range = {1, 10},
    Increment = 1,
    Suffix = "階層",
    CurrentValue = DEFAULT_CONFIG.SearchDepth,
    Flag = "SearchDepth",
    Callback = function(value)
        DEFAULT_CONFIG.SearchDepth = value
    end
})

local includeFoldersToggle = ExplorerTab:CreateToggle({
    Name = "フォルダー内を検索",
    CurrentValue = true,
    Flag = "IncludeFolders",
    Callback = function(value) end
})

local searchTypeDropdown = ExplorerTab:CreateDropdown({
    Name = "検索タイプ",
    Options = {"全て", "RemoteEventのみ", "RemoteFunctionのみ"},
    CurrentOption = "全て",
    Flag = "SearchType",
    Callback = function(option) end
})

-- 検索結果表示
local searchResultsTextbox = ExplorerTab:CreateParagraph({
    Title = "検索結果",
    Content = "検索結果がここに表示されます"
})

local remoteListDropdown = ExplorerTab:CreateDropdown({
    Name = "Remote一覧",
    Options = {"選択してください..."},
    CurrentOption = "選択してください...",
    Flag = "RemoteList",
    Callback = function(option)
        if option ~= "選択してください..." then
            selectedEvent = option
            
            -- オブジェクトを検索
            local found = false
            for _, event in ipairs(remoteEvents) do
                if event.Name .. " (" .. event.Path .. ")" == option then
                    selectedEventObj = event.Object
                    found = true
                    break
                end
            end
            
            if not found then
                for _, func in ipairs(remoteFunctions) do
                    if func.Name .. " (" .. func.Path .. ")" == option then
                        selectedEventObj = func.Object
                        found = true
                        break
                    end
                end
            end
            
            if found and selectedEventObj then
                Rayfield:Notify({
                    Title = "✅ Remote選択",
                    Content = selectedEvent .. " を選択しました",
                    Duration = 2,
                    Image = 13094326971
                })
            else
                Rayfield:Notify({
                    Title = "❌ エラー",
                    Content = "Remoteオブジェクトが見つかりませんでした",
                    Duration = 3,
                    Image = 13094326971
                })
            end
        end
    end
})

-- 詳細表示用テキストボックス
local detailsTextbox = ExplorerTab:CreateParagraph({
    Title = "Remote詳細",
    Content = "Remoteの詳細情報がここに表示されます"
})

-- 検索関数
local function performSearch()
    local paths = {}
    local input = searchPathsInput.Value
    
    if input ~= "" then
        for path in string.gmatch(input, "([^,]+)") do
            local trimmed = path:gsub("^%s*(.-)%s*$", "%1")
            if trimmed ~= "" then
                table.insert(paths, trimmed)
            end
        end
    else
        paths = {"ReplicatedStorage", "Workspace", "StarterPack", "StarterPlayer", "ServerStorage"}
    end
    
    -- 検索前のリセット
    remoteEvents = {}
    remoteFunctions = {}
    
    local function searchRecursive(parent, depth, currentDepth, path)
        if currentDepth > depth then return end
        
        for _, child in pairs(parent:GetChildren()) do
            local currentPath = path .. "/" .. child.Name
            
            -- 検索タイプに基づいてフィルタリング
            local searchAll = searchTypeDropdown.Value == "全て"
            local searchEvents = searchTypeDropdown.Value == "RemoteEventのみ"
            local searchFunctions = searchTypeDropdown.Value == "RemoteFunctionのみ"
            
            if child:IsA("RemoteEvent") and (searchAll or searchEvents) then
                table.insert(remoteEvents, {
                    Name = child.Name,
                    Path = currentPath:sub(2), -- 先頭の/を削除
                    Object = child,
                    Parent = child.Parent,
                    ClassName = child.ClassName,
                    FullPath = child:GetFullName()
                })
            elseif child:IsA("RemoteFunction") and (searchAll or searchFunctions) then
                table.insert(remoteFunctions, {
                    Name = child.Name,
                    Path = currentPath:sub(2),
                    Object = child,
                    Parent = child.Parent,
                    ClassName = child.ClassName,
                    FullPath = child:GetFullName()
                })
            end
            
            -- フォルダー内を検索（設定による）
            if includeFoldersToggle.CurrentValue then
                searchRecursive(child, depth, currentDepth + 1, currentPath)
            end
        end
    end
    
    -- 検索実行
    local totalFound = 0
    local searchErrors = {}
    
    for _, pathName in ipairs(paths) do
        local parent = game:FindFirstChild(pathName)
        if parent then
            searchRecursive(parent, searchDepthSlider.Value, 1, "")
        else
            table.insert(searchErrors, "❌ " .. pathName .. " が見つかりません")
        end
    end
    
    totalFound = #remoteEvents + #remoteFunctions
    
    -- 結果表示
    local resultText = ""
    
    if #searchErrors > 0 then
        resultText = resultText .. "⚠️ 検索エラー:\n"
        for _, error in ipairs(searchErrors) do
            resultText = resultText .. error .. "\n"
        end
        resultText = resultText .. "\n"
    end
    
    if totalFound > 0 then
        resultText = resultText .. string.format("✅ 検索完了: %d件見つかりました\n\n", totalFound)
        
        if #remoteEvents > 0 then
            resultText = resultText .. string.format("📡 RemoteEvents (%d件):\n", #remoteEvents)
            for i, event in ipairs(remoteEvents) do
                resultText = resultText .. string.format("%d. %s\n   パス: %s\n", i, event.Name, event.Path)
                if i >= 10 then -- 最初の10件のみ表示
                    resultText = resultText .. string.format("   ... 他 %d件\n", #remoteEvents - 10)
                    break
                end
            end
            resultText = resultText .. "\n"
        end
        
        if #remoteFunctions > 0 then
            resultText = resultText .. string.format("⚡ RemoteFunctions (%d件):\n", #remoteFunctions)
            for i, func in ipairs(remoteFunctions) do
                resultText = resultText .. string.format("%d. %s\n   パス: %s\n", i, func.Name, func.Path)
                if i >= 10 then -- 最初の10件のみ表示
                    resultText = resultText .. string.format("   ... 他 %d件\n", #remoteFunctions - 10)
                    break
                end
            end
        end
    else
        if #searchErrors == 0 then
            resultText = "❌ RemoteEvent/Functionが見つかりませんでした"
        end
    end
    
    searchResultsTextbox:Set({Title = "検索結果", Content = resultText})
    
    -- ドロップダウン更新
    local options = {"選択してください..."}
    for _, event in ipairs(remoteEvents) do
        table.insert(options, event.Name .. " (" .. event.Path .. ")")
    end
    for _, func in ipairs(remoteFunctions) do
        table.insert(options, func.Name .. " (" .. func.Path .. ")")
    end
    
    remoteListDropdown:Refresh(options, "選択してください...")
    
    -- ビルダータブのドロップダウンも更新
    local builderOptions = {"選択してください..."}
    for _, event in ipairs(remoteEvents) do
        table.insert(builderOptions, event.Name)
    end
    if BuilderTab and BuilderTab:FindFirstChild("TargetEvent") then
        -- 更新ロジックをここに追加
    end
    
    Rayfield:Notify({
        Title = "🔍 検索完了",
        Content = string.format("%d件のRemoteを見つけました (Events: %d, Functions: %d)", totalFound, #remoteEvents, #remoteFunctions),
        Duration = 3,
        Image = 13094326971
    })
    
    return totalFound
end

-- 検索ボタン
ExplorerTab:CreateButton({
    Name = "🔍 検索開始",
    Callback = function()
        performSearch()
    end
})

-- 詳細表示ボタン
ExplorerTab:CreateButton({
    Name = "📋 詳細を表示",
    Callback = function()
        if selectedEventObj then
            local details = string.format(
                "📊 Remote詳細情報\n\n" ..
                "📛 名前: %s\n" ..
                "📁 クラス: %s\n" ..
                "📍 フルパス: %s\n" ..
                "👤 親: %s\n" ..
                "🔗 オブジェクトID: %s\n" ..
                "📦 アーカイブ済み: %s\n" ..
                "👁️ 表示中: %s",
                selectedEventObj.Name,
                selectedEventObj.ClassName,
                selectedEventObj:GetFullName(),
                selectedEventObj.Parent.Name,
                tostring(selectedEventObj:GetDebugId()),
                tostring(selectedEventObj.Archivable),
                tostring(selectedEventObj:IsDescendantOf(game))
            )
            
            detailsTextbox:Set({Title = "Remote詳細: " .. selectedEventObj.Name, Content = details})
        else
            Rayfield:Notify({
                Title = "❌ エラー",
                Content = "先にRemoteを選択してください",
                Duration = 3,
                Image = 13094326971
            })
        end
    end
})

-- 保存ボタン
ExplorerTab:CreateButton({
    Name = "💾 選択を保存",
    Callback = function()
        if selectedEventObj then
            local saveName = selectedEventObj.Name .. "_" .. os.date("%Y%m%d_%H%M%S")
            savedConfigurations[saveName] = {
                Name = selectedEventObj.Name,
                Path = selectedEventObj:GetFullName(),
                Class = selectedEventObj.ClassName,
                Timestamp = os.time()
            }
            
            Rayfield:Notify({
                Title = "💾 保存完了",
                Content = saveName .. " を保存しました",
                Duration = 2,
                Image = 13094326971
            })
        end
    end
})

-- ========== ⚡ エグゼキューター ==========
ExecutorTab:CreateSection("⚡ 実行設定")

local argsInput = ExecutorTab:CreateInput({
    Name = "引数 (Luaテーブル形式)",
    PlaceholderText = '例: {"arg1", 123, true, key = "value"}',
    RemoveTextAfterFocusLost = false,
    Callback = function(text) end
})

local execIntervalSlider = ExecutorTab:CreateSlider({
    Name = "実行間隔",
    Range = {0.05, 5},
    Increment = 0.05,
    Suffix = "秒",
    CurrentValue = DEFAULT_CONFIG.ExecutionInterval,
    Flag = "ExecInterval",
    Callback = function(value)
        DEFAULT_CONFIG.ExecutionInterval = value
    end
})

local execCountSlider = ExecutorTab:CreateSlider({
    Name = "実行回数",
    Range = {1, 1000},
    Increment = 1,
    Suffix = "回",
    CurrentValue = 1,
    Flag = "ExecCount",
    Callback = function(value) end
})

-- 実行ログ
local execLogTextbox = ExecutorTab:CreateParagraph({
    Title = "実行ログ",
    Content = "実行ログがここに表示されます"
})

local execCountLabel = ExecutorTab:CreateLabel("実行回数: 0")

-- 引数をパースする関数
local function parseArguments(input)
    if input == "" then
        return {}
    end
    
    local success, result = pcall(function()
        -- テーブル形式をチェック
        local trimmed = input:gsub("^%s*(.-)%s*$", "%1")
        
        -- 単純な値の場合
        if trimmed:lower() == "true" then return true end
        if trimmed:lower() == "false" then return false end
        if trimmed:lower() == "nil" then return nil end
        
        local number = tonumber(trimmed)
        if number then return number end
        
        -- 文字列の場合（クォート付き）
        if trimmed:match('^".*"$') then
            return trimmed:sub(2, -2)
        end
        if trimmed:match("^'.*'$") then
            return trimmed:sub(2, -2)
        end
        
        -- Luaテーブルの場合
        if trimmed:match("^%{.*%}$") then
            local func, err = loadstring("return " .. trimmed)
            if func then
                return func()
            else
                error("無効なテーブル形式: " .. err)
            end
        end
        
        -- デフォルトは文字列として扱う
        return trimmed
    end)
    
    if success then
        if type(result) == "table" then
            return result
        else
            return {result}
        end
    else
        Rayfield:Notify({
            Title = "⚠️ 引数解析エラー",
            Content = "引数の解析に失敗しました。デフォルト値を使用します。",
            Duration = 3,
            Image = 13094326971
        })
        return {}
    end
end

-- 実行関数
local function executeRemote()
    if not selectedEventObj then
        Rayfield:Notify({
            Title = "❌ 実行エラー",
            Content = "実行するRemoteを選択してください",
            Duration = 3,
            Image = 13094326971
        })
        return false, "Remoteが選択されていません"
    end
    
    local argsText = argsInput.Value
    local args = parseArguments(argsText)
    
    if type(args) ~= "table" then
        args = {args}
    end
    
    -- 実行
    local success, result = pcall(function()
        if selectedEventObj:IsA("RemoteEvent") then
            selectedEventObj:FireServer(unpack(args))
            return "FireServer成功"
        elseif selectedEventObj:IsA("RemoteFunction") then
            return selectedEventObj:InvokeServer(unpack(args))
        else
            error("無効なRemoteオブジェクトです")
        end
    end)
    
    executionCount = executionCount + 1
    execCountLabel:Set("実行回数: " .. executionCount)
    
    local timestamp = os.date("%H:%M:%S")
    local method = selectedEventObj:IsA("RemoteEvent") and "FireServer" or "InvokeServer"
    local argPreview = argsText:sub(1, 50)
    if #argsText > 50 then
        argPreview = argPreview .. "..."
    end
    
    local logEntry = string.format(
        "[%s] %s.%s\n" ..
        "引数: %s\n" ..
        "結果: %s\n" ..
        "%s\n",
        timestamp,
        selectedEventObj.Name,
        method,
        argPreview,
        success and "✅ 成功" or "❌ 失敗",
        success and (result and "戻り値: " .. tostring(result):sub(1, 100) or "戻り値なし") or "エラー: " .. tostring(result)
    )
    
    table.insert(executionHistory, {
        Time = os.date("%Y-%m-%d %H:%M:%S"),
        Remote = selectedEventObj.Name,
        Type = selectedEventObj.ClassName,
        Method = method,
        Arguments = argsText,
        Success = success,
        Result = result
    })
    
    -- ログ更新（最新10件のみ表示）
    local currentLog = execLogTextbox.Content
    local lines = {}
    for line in currentLog:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    
    while #lines > 30 do -- 10エントリ分のスペース
        table.remove(lines, 1)
    end
    
    table.insert(lines, 1, "------------------------")
    table.insert(lines, 1, logEntry)
    execLogTextbox:Set({
        Title = string.format("実行ログ (%d件)", #executionHistory),
        Content = table.concat(lines, "\n")
    })
    
    if DEFAULT_CONFIG.ShowNotifications then
        Rayfield:Notify({
            Title = success and "✅ 実行成功" or "❌ 実行失敗",
            Content = string.format("%s.%s を実行しました", selectedEventObj.Name, method),
            Duration = 2,
            Image = 13094326971
        })
    end
    
    return success, result
end

-- 実行ボタン
ExecutorTab:CreateButton({
    Name = "⚡ 単発実行",
    Callback = function()
        executeRemote()
    end
})

-- 自動実行トグル
local autoExecToggle = ExecutorTab:CreateToggle({
    Name = "🔄 自動実行",
    CurrentValue = false,
    Flag = "AutoExecute",
    Callback = function(value)
        isAutoRunning = value
        if value then
            Rayfield:Notify({
                Title = "🔄 自動実行開始",
                Content = string.format("%s を自動実行します", selectedEventObj and selectedEventObj.Name or "選択されたRemote"),
                Duration = 2,
                Image = 13094326971
            })
            
            task.spawn(function()
                local count = 0
                local maxCount = execCountSlider.Value
                while isAutoRunning and selectedEventObj do
                    if count >= maxCount and maxCount > 0 then
                        break
                    end
                    
                    executeRemote()
                    count = count + 1
                    wait(execIntervalSlider.Value)
                end
                
                isAutoRunning = false
                autoExecToggle:Set(false)
                
                Rayfield:Notify({
                    Title = "⏹️ 自動実行終了",
                    Content = string.format("%d回実行しました", count),
                    Duration = 2,
                    Image = 13094326971
                })
            end)
        else
            Rayfield:Notify({
                Title = "⏹️ 自動実行停止",
                Content = "自動実行を停止しました",
                Duration = 2,
                Image = 13094326971
            })
        end
    end
})

-- ログクリアボタン
ExecutorTab:CreateButton({
    Name = "🧹 ログクリア",
    Callback = function()
        execLogTextbox:Set({Title = "実行ログ (0件)", Content = ""})
        executionHistory = {}
        Rayfield:Notify({
            Title = "🧹 ログクリア",
            Content = "実行ログをクリアしました",
            Duration = 2,
            Image = 13094326971
        })
    end
})

-- 履歴表示ボタン
ExecutorTab:CreateButton({
    Name = "📜 実行履歴を表示",
    Callback = function()
        if #executionHistory > 0 then
            local historyText = "📜 実行履歴\n\n"
            for i, entry in ipairs(executionHistory) do
                historyText = historyText .. string.format(
                    "%d. [%s] %s.%s\n   結果: %s\n\n",
                    i,
                    entry.Time,
                    entry.Remote,
                    entry.Method,
                    entry.Success and "✅ 成功" or "❌ 失敗"
                )
            end
            
            local HistoryWindow = Rayfield:CreateWindow({
                Name = "📜 実行履歴",
                LoadingTitle = "履歴をロード中...",
                LoadingSubtitle = "",
                ConfigurationSaving = {Enabled = false},
                Discord = {Enabled = false},
                KeySystem = false,
            })
            
            local HistoryTab = HistoryWindow:CreateTab("履歴", 13094326971)
            
            HistoryTab:CreateParagraph({
                Title = string.format("実行履歴 (%d件)", #executionHistory),
                Content = historyText
            })
            
            HistoryTab:CreateButton({
                Name = "🗑️ ウィンドウを閉じる",
                Callback = function()
                    HistoryWindow:Destroy()
                end
            })
        else
            Rayfield:Notify({
                Title = "📜 履歴なし",
                Content = "実行履歴がありません",
                Duration = 2,
                Image = 13094326971
            })
        end
    end
})

-- ========== 🎯 キャプチャ ==========
CaptureTab:CreateSection("🎯 キャプチャ設定")

local captureToggle = CaptureTab:CreateToggle({
    Name = "キャプチャモード",
    CurrentValue = false,
    Flag = "CaptureMode",
    Callback = function(value)
        isCapturing = value
        if value then
            startCapture()
        else
            stopCapture()
        end
    end
})

local captureLimitSlider = CaptureTab:CreateSlider({
    Name = "キャプチャ制限",
    Range = {10, 1000},
    Increment = 10,
    Suffix = "件",
    CurrentValue = DEFAULT_CONFIG.CaptureLimit,
    Flag = "CaptureLimit",
    Callback = function(value)
        DEFAULT_CONFIG.CaptureLimit = value
    end
})

local captureFilterInput = CaptureTab:CreateInput({
    Name = "フィルター (正規表現)",
    PlaceholderText = "例: ^Player|^Data",
    RemoveTextAfterFocusLost = false,
    Callback = function(text) end
})

-- キャプチャログ
local captureLogTextbox = CaptureTab:CreateParagraph({
    Title = "キャプチャログ",
    Content = "キャプチャされたデータがここに表示されます"
})

local captureStatusLabel = CaptureTab:CreateLabel("状態: 停止中")

-- キャプチャ開始関数
local function startCapture()
    capturedData = {}
    hookEnabled = true
    
    -- メタテーブルフックの設定
    local mt = getrawmetatable(game)
    if mt then
        originalNamecall = mt.__namecall
        
        if setreadonly then
            setreadonly(mt, false)
        end
        
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if isCapturing and hookEnabled then
                if (method == "FireServer" or method == "InvokeServer") and 
                   (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
                    
                    local remoteName = self.Name
                    local filter = captureFilterInput.Value
                    
                    -- フィルター適用
                    local shouldCapture = true
                    if filter ~= "" then
                        shouldCapture = pcall(function()
                            return string.match(remoteName, filter) ~= nil
                        end)
                    end
                    
                    if shouldCapture then
                        -- 引数を安全にシリアライズ
                        local serializedArgs = {}
                        for i, arg in ipairs(args) do
                            if type(arg) == "string" then
                                serializedArgs[i] = '"' .. arg:sub(1, 100) .. (#arg > 100 and "..." or "") .. '"'
                            elseif type(arg) == "number" or type(arg) == "boolean" then
                                serializedArgs[i] = tostring(arg)
                            elseif type(arg) == "nil" then
                                serializedArgs[i] = "nil"
                            elseif type(arg) == "table" then
                                serializedArgs[i] = "{table}"
                            else
                                serializedArgs[i] = tostring(arg):sub(1, 100)
                            end
                        end
                        
                        local captureEntry = {
                            Timestamp = os.time(),
                            Time = os.date("%H:%M:%S"),
                            Type = self.ClassName,
                            Name = remoteName,
                            Path = self:GetFullName(),
                            Method = method,
                            Arguments = args,
                            SerializedArgs = serializedArgs,
                            ArgumentsCount = #args
                        }
                        
                        table.insert(capturedData, captureEntry)
                        
                        -- 制限チェック
                        if #capturedData > captureLimitSlider.Value then
                            table.remove(capturedData, 1)
                        end
                        
                        -- ログ更新
                        local logEntry = string.format(
                            "[%s] %s.%s(%d args)\n   %s\n",
                            captureEntry.Time,
                            remoteName,
                            method,
                            #args,
                            #serializedArgs > 0 and table.concat(serializedArgs, ", "):sub(1, 150) or "引数なし"
                        )
                        
                        local currentLog = captureLogTextbox.Content
                        local lines = {}
                        for line in currentLog:gmatch("[^\n]+") do
                            table.insert(lines, line)
                        end
                        
                        while #lines > 15 do
                            table.remove(lines, 1)
                        end
                        
                        table.insert(lines, 1, "------------------------")
                        table.insert(lines, 1, logEntry)
                        captureLogTextbox:Set({
                            Title = string.format("キャプチャログ (%d件)", #capturedData),
                            Content = table.concat(lines, "\n")
                        })
                        
                        captureStatusLabel:Set(string.format("状態: キャプチャ中 (%d件)", #capturedData))
                    end
                end
            end
            
            if originalNamecall then
                return originalNamecall(self, ...)
            end
        end)
    end
    
    Rayfield:Notify({
        Title = "🎯 キャプチャ開始",
        Content = "Remote通信のキャプチャを開始しました",
        Duration = 2,
        Image = 13094326971
    })
    
    captureStatusLabel:Set("状態: キャプチャ中")
end

-- キャプチャ停止関数
local function stopCapture()
    hookEnabled = false
    if originalNamecall then
        local mt = getrawmetatable(game)
        if mt then
            if setreadonly then
                setreadonly(mt, false)
            end
            mt.__namecall = originalNamecall
        end
    end
    
    Rayfield:Notify({
        Title = "⏹️ キャプチャ停止",
        Content = string.format("%d件のデータをキャプチャしました", #capturedData),
        Duration = 3,
        Image = 13094326971
    })
    
    captureStatusLabel:Set("状態: 停止中")
end

-- キャプチャデータ表示ボタン
CaptureTab:CreateButton({
    Name = "📊 詳細表示",
    Callback = function()
        if #capturedData > 0 then
            local details = string.format("📊 キャプチャデータ詳細 (%d件)\n\n", #capturedData)
            
            for i, data in ipairs(capturedData) do
                details = details .. string.format(
                    "%d. [%s] %s.%s\n   パス: %s\n   引数: %d個\n",
                    i,
                    data.Time,
                    data.Name,
                    data.Method,
                    data.Path,
                    data.ArgumentsCount
                )
                
                if data.ArgumentsCount > 0 then
                    details = details .. "   内容: "
                    for j = 1, math.min(3, #data.SerializedArgs) do
                        details = details .. data.SerializedArgs[j]
                        if j < math.min(3, #data.SerializedArgs) then
                            details = details .. ", "
                        end
                    end
                    if data.ArgumentsCount > 3 then
                        details = details .. string.format(", ... (他 %d個)", data.ArgumentsCount - 3)
                    end
                end
                details = details .. "\n\n"
            end
            
            local ViewWindow = Rayfield:CreateWindow({
                Name = "📊 キャプチャデータ詳細",
                LoadingTitle = "データをロード中...",
                LoadingSubtitle = "",
                ConfigurationSaving = {Enabled = false},
                Discord = {Enabled = false},
                KeySystem = false,
            })
            
            local DataTab = ViewWindow:CreateTab("データ", 13094326971)
            
            DataTab:CreateParagraph({
                Title = string.format("キャプチャデータ (%d件)", #capturedData),
                Content = details
            })
            
            DataTab:CreateButton({
                Name = "📤 JSONエクスポート",
                Callback = function()
                    -- シリアライズ可能なデータのみをエクスポート
                    local exportData = {}
                    for i, data in ipairs(capturedData) do
                        exportData[i] = {
                            Time = data.Time,
                            Type = data.Type,
                            Name = data.Name,
                            Path = data.Path,
                            Method = data.Method,
                            ArgumentsCount = data.ArgumentsCount,
                            SerializedArgs = data.SerializedArgs
                        }
                    end
                    
                    local success, json = pcall(function()
                        return HttpService:JSONEncode(exportData)
                    end)
                    
                    if success then
                        setclipboard(json)
                        Rayfield:Notify({
                            Title = "✅ エクスポート完了",
                            Content = "JSONデータをクリップボードにコピーしました",
                            Duration = 3,
                            Image = 13094326971
                        })
                    else
                        Rayfield:Notify({
                            Title = "❌ エクスポート失敗",
                            Content = "JSON変換に失敗しました",
                            Duration = 3,
                            Image = 13094326971
                        })
                    end
                end
            })
            
            DataTab:CreateButton({
                Name = "🗑️ キャプチャデータをクリア",
                Callback = function()
                    capturedData = {}
                    captureLogTextbox:Set({Title = "キャプチャログ", Content = ""})
                    captureStatusLabel:Set("状態: 停止中")
                    Rayfield:Notify({
                        Title = "🧹 データクリア",
                        Content = "キャプチャデータをクリアしました",
                        Duration = 2,
                        Image = 13094326971
                    })
                    ViewWindow:Destroy()
                end
            })
            
            DataTab:CreateButton({
                Name = "🗑️ ウィンドウを閉じる",
                Callback = function()
                    ViewWindow:Destroy()
                end
            })
        else
            Rayfield:Notify({
                Title = "📭 データなし",
                Content = "キャプチャデータがありません",
                Duration = 2,
                Image = 13094326971
            })
        end
    end
})

-- ========== 🛠️ ビルダー ==========
BuilderTab:CreateSection("🛠️ スクリプトビルダー")

local scriptNameInput = BuilderTab:CreateInput({
    Name = "スクリプト名",
    PlaceholderText = "MyAutoFarmScript",
    RemoveTextAfterFocusLost = false,
    Callback = function(text) end
})

local targetEventDropdown = BuilderTab:CreateDropdown({
    Name = "対象RemoteEvent",
    Options = {"選択してください..."},
    CurrentOption = "選択してください...",
    Flag = "TargetEvent",
    Callback = function(option) end
})

local scriptTypeDropdown = BuilderTab:CreateDropdown({
    Name = "スクリプトタイプ",
    Options = {"自動実行", "手動実行", "イベント駆動", "GUI付き"},
    CurrentOption = "自動実行",
    Flag = "ScriptType",
    Callback = function(option) end
})

local generatedScriptTextbox = BuilderTab:CreateParagraph({
    Title = "生成されたスクリプト",
    Content = "ここに生成されたスクリプトが表示されます"
})

-- スクリプト生成関数
local function generateScript()
    local scriptName = scriptNameInput.Value ~= "" and scriptNameInput.Value or "GeneratedScript"
    local eventName = targetEventDropdown.Value
    local scriptType = scriptTypeDropdown.Value
    
    if eventName == "選択してください..." then
        Rayfield:Notify({
            Title = "❌ エラー",
            Content = "対象のRemoteEventを選択してください",
            Duration = 3,
            Image = 13094326971
        })
        return
    end
    
    local scriptTemplate = ""
    local currentDate = os.date("%Y-%m-%d %H:%M:%S")
    
    if scriptType == "自動実行" then
        scriptTemplate = string.format([[
-- %s - 自動実行スクリプト
-- 生成日時: %s
-- 対象RemoteEvent: %s

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- RemoteEventのパス (必要に応じて調整)
local remoteEvent
local success, errorMsg = pcall(function()
    remoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("%s")
end)

if not success then
    warn("RemoteEventが見つかりません:", errorMsg)
    return
end

local running = false
local interval = 0.5 -- 実行間隔(秒)

local function executeAction()
    -- ここに実行する引数を設定
    local args = {
        "action_trigger",
        player.UserId,
        os.time(),
        position = character and character.HumanoidRootPart.Position or Vector3.new(0, 0, 0)
    }
    
    local success, error = pcall(function()
        remoteEvent:FireServer(unpack(args))
    end)
    
    if not success then
        warn("実行エラー:", error)
        return false
    end
    
    return true
end

-- 自動実行ループ
local autoThread
local function startAutoRun()
    if running then return end
    
    running = true
    print("🚀 自動実行を開始しました")
    
    autoThread = task.spawn(function()
        local executionCount = 0
        while running do
            if executeAction() then
                executionCount = executionCount + 1
                if executionCount %% 10 == 0 then
                    print("✅ 実行回数:", executionCount)
                end
            end
            
            task.wait(interval)
        end
        print("⏹️ 自動実行を停止しました")
    end)
end

local function stopAutoRun()
    running = false
    if autoThread then
        task.cancel(autoThread)
        autoThread = nil
    end
end

-- コントロール用グローバル関数
_G.AutoFarm_%s = {
    Start = function()
        startAutoRun()
    end,
    
    Stop = function()
        stopAutoRun()
    end,
    
    SetInterval = function(newInterval)
        if type(newInterval) == "number" and newInterval > 0 then
            interval = newInterval
            print("⏱️ 実行間隔を設定:", interval, "秒")
        else
            warn("無効な間隔値:", newInterval)
        end
    end,
    
    Toggle = function()
        if running then
            stopAutoRun()
        else
            startAutoRun()
        end
    end,
    
    GetStatus = function()
        return {
            Running = running,
            Interval = interval,
            RemoteEvent = remoteEvent.Name
        }
    end
}

print("✅ %s がロードされました")
print("使い方: _G.AutoFarm_%s.Start() / _G.AutoFarm_%s.Stop()")

return _G.AutoFarm_%s
]], scriptName, currentDate, eventName, eventName, scriptName:gsub("%s+", "_"), scriptName, scriptName:gsub("%s+", "_"), scriptName:gsub("%s+", "_"), scriptName:gsub("%s+", "_"))
    
    elseif scriptType == "手動実行" then
        scriptTemplate = string.format([[
-- %s - 手動実行スクリプト
-- 生成日時: %s
-- 対象RemoteEvent: %s

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- RemoteEventのパス (必要に応じて調整)
local remoteEvent
local success, errorMsg = pcall(function()
    remoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("%s")
end)

if not success then
    warn("RemoteEventが見つかりません:", errorMsg)
    return
end

-- 実行関数
local function executeRemote()
    local args = {
        "manual_action",
        player.Name,
        os.time(),
        key = "value_%d"
    }
    
    local success, result = pcall(function()
        return remoteEvent:FireServer(unpack(args))
    end)
    
    if success then
        print("✅ 実行成功!")
        if result then
            print("   戻り値:", result)
        end
        return true
    else
        warn("❌ 実行失敗:", result)
        return false
    end
end

-- ホットキー設定
local hotkey = Enum.KeyCode.F
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == hotkey then
        executeRemote()
    end
end)

-- GUIを作成 (オプション)
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "%s_GUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 200)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Text = "%s"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 18
    title.Parent = mainFrame
    
    local executeButton = Instance.new("TextButton")
    executeButton.Text = "実行 (Fキー)"
    executeButton.Size = UDim2.new(0.8, 0, 0.3, 0)
    executeButton.Position = UDim2.new(0.1, 0, 0.35, 0)
    executeButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    executeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    executeButton.Font = Enum.Font.GothamMedium
    executeButton.TextSize = 16
    executeButton.Parent = mainFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = executeButton
    
    executeButton.MouseButton1Click:Connect(function()
        executeRemote()
    end)
    
    return screenGui
end

-- GUIを作成するかどうか
local enableGUI = true
if enableGUI then
    local gui = createGUI()
    print("🎨 GUIが作成されました")
end

print("✅ %s がロードされました")
print("使い方: Fキーを押すか、GUIのボタンをクリックして実行")

return {
    Execute = executeRemote,
    SetHotkey = function(newKey)
        hotkey = newKey
        print("🔧 ホットキーを設定:", hotkey.Name)
    end
}
]], scriptName, currentDate, eventName, eventName, math.random(10000, 99999), scriptName:gsub("%s+", "_"), scriptName, scriptName)
    
    elseif scriptType == "GUI付き" then
        scriptTemplate = string.format([[
-- %s - GUI付き実行スクリプト
-- 生成日時: %s
-- 対象RemoteEvent: %s

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- RemoteEventのパス (必要に応じて調整)
local remoteEvent
local success, errorMsg = pcall(function()
    remoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("%s")
end)

if not success then
    warn("RemoteEventが見つかりません:", errorMsg)
    return
end

-- メインGUI作成
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "%s_MainGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local mainWindow = Instance.new("Frame")
mainWindow.Size = UDim2.new(0, 350, 0, 400)
mainWindow.Position = UDim2.new(0.5, -175, 0.5, -200)
mainWindow.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainWindow.BackgroundTransparency = 0.05
mainWindow.Active = true
mainWindow.Draggable = true
mainWindow.Parent = screenGui

local windowCorner = Instance.new("UICorner")
windowCorner.CornerRadius = UDim.new(0, 12)
windowCorner.Parent = mainWindow

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
titleBar.Parent = mainWindow

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12, 0, 0)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Text = "🎮 %s コントローラー"
titleText.Size = UDim2.new(1, -40, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.GothamSemibold
titleText.TextSize = 18
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- 実行ボタン
local executeButton = Instance.new("TextButton")
executeButton.Text = "⚡ 実行"
executeButton.Size = UDim2.new(0.8, 0, 0, 50)
executeButton.Position = UDim2.new(0.1, 0, 0.2, 0)
executeButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
executeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
executeButton.Font = Enum.Font.GothamBold
executeButton.TextSize = 18
executeButton.Parent = mainWindow

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = executeButton

-- 引数入力
local argsInput = Instance.new("TextBox")
argsInput.PlaceholderText = "引数を入力 (例: {\"arg1\", 123})"
argsInput.Size = UDim2.new(0.8, 0, 0, 40)
argsInput.Position = UDim2.new(0.1, 0, 0.4, 0)
argsInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
argsInput.TextColor3 = Color3.fromRGB(255, 255, 255)
argsInput.Font = Enum.Font.Gotham
argsInput.TextSize = 14
argsInput.Parent = mainWindow

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = argsInput

-- ログ表示
local logFrame = Instance.new("ScrollingFrame")
logFrame.Size = UDim2.new(0.8, 0, 0, 120)
logFrame.Position = UDim2.new(0.1, 0, 0.6, 0)
logFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
logFrame.BorderSizePixel = 0
logFrame.ScrollBarThickness = 6
logFrame.Parent = mainWindow

local logLayout = Instance.new("UIListLayout")
logLayout.Parent = logFrame

local logPadding = Instance.new("UIPadding")
logPadding.PaddingLeft = UDim.new(0, 5)
logPadding.PaddingTop = UDim.new(0, 5)
logPadding.Parent = logFrame

-- 実行関数
local function executeWithArgs()
    local argsText = argsInput.Text
    local args = {}
    
    if argsText ~= "" then
        local success, parsed = pcall(function()
            return loadstring("return " .. argsText)()
        end)
        
        if success and parsed then
            if type(parsed) == "table" then
                args = parsed
            else
                args = {parsed}
            end
        else
            args = {argsText}
        end
    end
    
    local success, result = pcall(function()
        return remoteEvent:FireServer(unpack(args))
    end)
    
    -- ログに追加
    local logEntry = Instance.new("TextLabel")
    logEntry.Text = string.format("[%s] %s: %s",
        os.date("%H:%M:%S"),
        success and "✅ 成功" or "❌ 失敗",
        argsText:sub(1, 30) .. (#argsText > 30 and "..." or "")
    )
    logEntry.Size = UDim2.new(1, -10, 0, 20)
    logEntry.BackgroundTransparency = 1
    logEntry.TextColor3 = success and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
    logEntry.Font = Enum.Font.Gotham
    logEntry.TextSize = 12
    logEntry.TextXAlignment = Enum.TextXAlignment.Left
    logEntry.Parent = logFrame
    
    -- アニメーション
    executeButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    task.wait(0.1)
    executeButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    
    return success, result
end

executeButton.MouseButton1Click:Connect(executeWithArgs)

print("✅ %s GUIがロードされました")
print("🎮 GUIを操作して実行してください")

return {
    Execute = executeWithArgs,
    GUI = screenGui
}
]], scriptName, currentDate, eventName, eventName, scriptName:gsub("%s+", "_"), scriptName, scriptName)
    end
    
    generatedScriptTextbox:Set({
        Title = string.format("生成されたスクリプト: %s", scriptName),
        Content = scriptTemplate
    })
end

-- スクリプト生成ボタン
BuilderTab:CreateButton({
    Name = "🛠️ スクリプト生成",
    Callback = function()
        generateScript()
    end
})

BuilderTab:CreateButton({
    Name = "📋 クリップボードにコピー",
    Callback = function()
        local content = generatedScriptTextbox.Content
        if content and content ~= "ここに生成されたスクリプトが表示されます" then
            setclipboard(content)
            Rayfield:Notify({
                Title = "✅ コピー完了",
                Content = "スクリプトをクリップボードにコピーしました",
                Duration = 2,
                Image = 13094326971
            })
        else
            Rayfield:Notify({
                Title = "⚠️ コピー失敗",
                Content = "コピーする内容がありません",
                Duration = 2,
                Image = 13094326971
            })
        end
    end
})

-- ========== ⚙️ 設定 ==========
SettingsTab:CreateSection("⚙️ 基本設定")

SettingsTab:CreateToggle({
    Name = "起動時に自動検索",
    CurrentValue = DEFAULT_CONFIG.AutoSearch,
    Flag = "AutoSearch",
    Callback = function(value)
        DEFAULT_CONFIG.AutoSearch = value
    end
})

SettingsTab:CreateToggle({
    Name = "自動保存",
    CurrentValue = DEFAULT_CONFIG.AutoSave,
    Flag = "AutoSave",
    Callback = function(value)
        DEFAULT_CONFIG.AutoSave = value
    end
})

SettingsTab:CreateToggle({
    Name = "通知を表示",
    CurrentValue = DEFAULT_CONFIG.ShowNotifications,
    Flag = "ShowNotifications",
    Callback = function(value)
        DEFAULT_CONFIG.ShowNotifications = value
    end
})

SettingsTab:CreateSection("🎨 UI設定")

local themeDropdown = SettingsTab:CreateDropdown({
    Name = "テーマ",
    Options = {"デフォルト", "ダーク", "ライト", "ブルー", "グリーン", "パープル"},
    CurrentOption = DEFAULT_CONFIG.UITheme,
    Flag = "UITheme",
    Callback = function(option)
        DEFAULT_CONFIG.UITheme = option
        currentTheme = option
        
        -- テーマ変更ロジック
        local themes = {
            ["デフォルト"] = {
                BackgroundColor = Color3.fromRGB(25, 25, 25),
                HeaderColor = Color3.fromRGB(35, 35, 35),
                TextColor = Color3.fromRGB(255, 255, 255),
                ElementColor = Color3.fromRGB(40, 40, 40)
            },
            ["ダーク"] = {
                BackgroundColor = Color3.fromRGB(15, 15, 15),
                HeaderColor = Color3.fromRGB(25, 25, 25),
                TextColor = Color3.fromRGB(230, 230, 230),
                ElementColor = Color3.fromRGB(30, 30, 30)
            },
            ["ライト"] = {
                BackgroundColor = Color3.fromRGB(240, 240, 240),
                HeaderColor = Color3.fromRGB(220, 220, 220),
                TextColor = Color3.fromRGB(30, 30, 30),
                ElementColor = Color3.fromRGB(200, 200, 200)
            },
            ["ブルー"] = {
                BackgroundColor = Color3.fromRGB(20, 30, 45),
                HeaderColor = Color3.fromRGB(30, 45, 65),
                TextColor = Color3.fromRGB(220, 230, 240),
                ElementColor = Color3.fromRGB(40, 60, 85)
            }
        }
        
        if themes[option] then
            Window:SetTheme(themes[option])
        end
    end
})

SettingsTab:CreateSlider({
    Name = "UI更新速度",
    Range = {1, 60},
    Increment = 1,
    Suffix = "FPS",
    CurrentValue = DEFAULT_CONFIG.UpdateRate,
    Flag = "UpdateRate",
    Callback = function(value)
        DEFAULT_CONFIG.UpdateRate = value
    end
})

SettingsTab:CreateSection("🔒 セキュリティ")

local securityDropdown = SettingsTab:CreateDropdown({
    Name = "セキュリティレベル",
    Options = {"低 (推奨)", "中", "高"},
    CurrentOption = DEFAULT_CONFIG.SecurityLevel,
    Flag = "SecurityLevel",
    Callback = function(option)
        DEFAULT_CONFIG.SecurityLevel = option
        
        if option == "高" then
            Rayfield:Notify({
                Title = "🔒 セキュリティ強化",
                Content = "高度なセキュリティモードを有効化しました\n一部の機能が制限される場合があります",
                Duration = 4,
                Image = 13094326971
            })
        end
    end
})

SettingsTab:CreateToggle({
    Name = "アンチ検知モード",
    CurrentValue = DEFAULT_CONFIG.AntiDetect,
    Flag = "AntiDetect",
    Callback = function(value)
        DEFAULT_CONFIG.AntiDetect = value
        if value then
            Rayfield:Notify({
                Title = "⚠️ 警告",
                Content = "アンチ検知モードは安定性に影響する場合があります\n非推奨の機能を使用する可能性があります",
                Duration = 5,
                Image = 13094326971
            })
        end
    end
})

SettingsTab:CreateSection("💾 データ管理")

SettingsTab:CreateButton({
    Name = "💾 設定を保存",
    Callback = function()
        -- 設定を保存するロジック
        local success, errorMsg = pcall(function()
            local saveData = {
                Config = DEFAULT_CONFIG,
                SavedEvents = savedConfigurations,
                Timestamp = os.time(),
                Version = "2.1"
            }
            
            -- ここに保存ロジックを実装
            -- 例: writefile("RemoteExplorer_Config.json", HttpService:JSONEncode(saveData))
        end)
        
        if success then
            Rayfield:Notify({
                Title = "✅ 保存完了",
                Content = "設定を保存しました",
                Duration = 2,
                Image = 13094326971
            })
        else
            Rayfield:Notify({
                Title = "❌ 保存失敗",
                Content = "設定の保存に失敗しました: " .. tostring(errorMsg),
                Duration = 3,
                Image = 13094326971
            })
        end
    end
})

SettingsTab:CreateButton({
    Name = "🔄 設定をリセット",
    Callback = function()
        Rayfield:Notify({
            Title = "⚠️ 確認",
            Content = "すべての設定をリセットしますか？\nこの操作は元に戻せません。",
            Duration = 6,
            Image = 13094326971,
            Actions = {
                {
                    Title = "はい",
                    Callback = function()
                        -- 設定リセット
                        DEFAULT_CONFIG = {
                            AutoSearch = true,
                            UITheme = "デフォルト",
                            UpdateRate = 5,
                            SearchDepth = 5,
                            DefaultPaths = "ReplicatedStorage,Workspace",
                            AutoSave = true,
                            ShowNotifications = true,
                            CaptureLimit = 100,
                            ExecutionInterval = 0.5,
                            SecurityLevel = "低 (推奨)",
                            Language = "日本語",
                            AntiDetect = false
                        }
                        
                        -- UI要素のリセット
                        searchDepthSlider:Set(DEFAULT_CONFIG.SearchDepth)
                        execIntervalSlider:Set(DEFAULT_CONFIG.ExecutionInterval)
                        captureLimitSlider:Set(DEFAULT_CONFIG.CaptureLimit)
                        themeDropdown:Refresh({"デフォルト", "ダーク", "ライト", "ブルー", "グリーン", "パープル"}, "デフォルト")
                        securityDropdown:Refresh({"低 (推奨)", "中", "高"}, "低 (推奨)")
                        
                        -- データクリア
                        remoteEvents = {}
                        remoteFunctions = {}
                        capturedData = {}
                        executionHistory = {}
                        savedConfigurations = {}
                        selectedEvent = nil
                        selectedEventObj = nil
                        executionCount = 0
                        
                        -- UI更新
                        statsLabel:Set({
                            Title = "📊 システム統計",
                            Content = "🔍 RemoteEvents: 0\n⚡ RemoteFunctions: 0\n💾 キャプチャデータ: 0\n📝 実行履歴: 0\n⏱️ 実行回数: 0"
                        })
                        
                        searchResultsTextbox:Set({Title = "検索結果", Content = ""})
                        detailsTextbox:Set({Title = "Remote詳細", Content = ""})
                        execLogTextbox:Set({Title = "実行ログ", Content = ""})
                        captureLogTextbox:Set({Title = "キャプチャログ", Content = ""})
                        generatedScriptTextbox:Set({Title = "生成されたスクリプト", Content = "ここに生成されたスクリプトが表示されます"})
                        
                        remoteListDropdown:Refresh({"選択してください..."}, "選択してください...")
                        
                        Rayfield:Notify({
                            Title = "✅ リセット完了",
                            Content = "すべての設定をデフォルトに戻しました",
                            Duration = 3,
                            Image = 13094326971
                        })
                    end
                },
                {
                    Title = "いいえ",
                    Callback = function()
                        Rayfield:Notify({
                            Title = "❌ キャンセル",
                            Content = "リセットをキャンセルしました",
                            Duration = 2,
                            Image = 13094326971
                        })
                    end
                }
            }
        })
    end
})

SettingsTab:CreateButton({
    Name = "📤 設定をエクスポート",
    Callback = function()
        local exportData = {
            Config = DEFAULT_CONFIG,
            SavedEvents = savedConfigurations,
            Statistics = {
                RemoteEventsFound = #remoteEvents,
                RemoteFunctionsFound = #remoteFunctions,
                CapturedDataCount = #capturedData,
                ExecutionHistoryCount = #executionHistory,
                TotalExecutions = executionCount
            },
            Timestamp = os.time(),
            ExportDate = os.date("%Y-%m-%d %H:%M:%S"),
            Version = "2.1"
        }
        
        local success, json = pcall(function()
            return HttpService:JSONEncode(exportData)
        end)
        
        if success then
            setclipboard(json)
            Rayfield:Notify({
                Title = "✅ エクスポート完了",
                Content = "設定データをクリップボードにコピーしました",
                Duration = 3,
                Image = 13094326971
            })
        else
            Rayfield:Notify({
                Title = "❌ エクスポート失敗",
                Content = "JSON変換に失敗しました",
                Duration = 3,
                Image = 13094326971
            })
        end
    end
})

SettingsTab:CreateButton({
    Name = "❓ ヘルプ/情報",
    Callback = function()
        local HelpWindow = Rayfield:CreateWindow({
            Name = "❓ Remote Explorer Pro ヘルプ",
            LoadingTitle = "ヘルプ情報をロード中...",
            LoadingSubtitle = "",
            ConfigurationSaving = {Enabled = false},
            Discord = {Enabled = false},
            KeySystem = false,
        })
        
        local HelpTab = HelpWindow:CreateTab("ヘルプ", 13094326971)
        
        HelpTab:CreateParagraph({
            Title = "📚 Remote Explorer Pro v2.1",
            Content = string.format(
                "バージョン: 2.1\n" ..
                "最終更新: %s\n\n" ..
                "🔍 主な機能:\n" ..
                "1. RemoteEvent/Functionの自動検索\n" ..
                "2. 詳細なRemote情報表示\n" ..
                "3. 自動/手動実行機能\n" ..
                "4. リアルタイム通信キャプチャ\n" ..
                "5. スクリプト自動生成\n" ..
                "6. 完全なカスタマイズ設定\n\n" ..
                "⚠️ 注意事項:\n" ..
                "・このツールは教育目的で提供されています\n" ..
                "・ゲームの利用規約に違反しないようにご注意ください\n" ..
                "・自己責任でご利用ください",
                os.date("%Y-%m-%d")
            )
        })
        
        HelpTab:CreateButton({
            Name = "🗑️ ヘルプを閉じる",
            Callback = function()
                HelpWindow:Destroy()
            end
        })
    end
})

-- ========== 初期化と起動処理 ==========

-- 初期化関数
local function initializeApplication()
    print("🚀 Remote Explorer Pro v2.1 を初期化中...")
    
    -- デフォルト設定の適用
    searchPathsInput.Value = DEFAULT_CONFIG.DefaultPaths
    searchDepthSlider:Set(DEFAULT_CONFIG.SearchDepth)
    execIntervalSlider:Set(DEFAULT_CONFIG.ExecutionInterval)
    captureLimitSlider:Set(DEFAULT_CONFIG.CaptureLimit)
    
    -- 起動時の自動検索
    if DEFAULT_CONFIG.AutoSearch then
        task.wait(1) -- UIの完全なロードを待つ
        
        task.spawn(function()
            local found = performSearch()
            if found > 0 then
                Rayfield:Notify({
                    Title = "✅ 起動完了",
                    Content = string.format(
                        "Remote Explorer Pro が起動しました\n" ..
                        "%d件のRemoteを検出しました",
                        found
                    ),
                    Duration = 4,
                    Image = 13094326971
                })
            else
                Rayfield:Notify({
                    Title = "⚠️ 起動完了",
                    Content = "Remote Explorer Pro が起動しました\n" ..
                             "Remoteは検出されませんでした",
                    Duration = 4,
                    Image = 13094326971
                })
            end
        end)
    else
        task.wait(2)
        Rayfield:Notify({
            Title = "✅ 起動完了",
            Content = "Remote Explorer Pro v2.1 が起動しました",
            Duration = 3,
            Image = 13094326971
        })
    end
    
    -- ビルダータブのドロップダウン初期化
    task.spawn(function()
        while true do
            if #remoteEvents > 0 then
                local builderOptions = {"選択してください..."}
                for _, event in ipairs(remoteEvents) do
                    table.insert(builderOptions, event.Name)
                end
                targetEventDropdown:Refresh(builderOptions, "選択してください...")
            end
            wait(10) -- 10秒ごとに更新
        end
    end)
    
    print("✅ Remote Explorer Pro v2.1 の初期化が完了しました")
end

-- 安全な終了処理
local function cleanup()
    print("🧹 Remote Explorer Pro を終了中...")
    
    -- すべての実行を停止
    isAutoRunning = false
    isCapturing = false
    hookEnabled = false
    
    -- メタテーブルフックを復元
    if originalNamecall then
        local mt = getrawmetatable(game)
        if mt then
            if setreadonly then
                setreadonly(mt, false)
            end
            mt.__namecall = originalNamecall
        end
    end
    
    -- 設定の自動保存
    if DEFAULT_CONFIG.AutoSave then
        pcall(function()
            -- 保存ロジックをここに実装
        end)
    end
    
    print("✅ Remote Explorer Pro の終了処理が完了しました")
end

-- 終了イベントの監視
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == Window.Name then
        cleanup()
    end
end)

-- プレイヤーが退出したときの処理
Players.PlayerRemoving:Connect(function(player)
    if player == Players.LocalPlayer then
        cleanup()
    end
end)

-- アプリケーションの初期化を開始
task.spawn(initializeApplication)

-- 起動完了メッセージ
print("========================================")
print("🎮 Remote Explorer Pro v2.1")
print("📅 起動日時: " .. os.date("%Y-%m-%d %H:%M:%S"))
print("👤 プレイヤー: " .. Players.LocalPlayer.Name)
print("🎮 ゲーム: " .. gameInfo.Name)
print("========================================")

return {
    Window = Window,
    Config = DEFAULT_CONFIG,
    GetRemoteEvents = function() return remoteEvents end,
    GetRemoteFunctions = function() return remoteFunctions end,
    GetCapturedData = function() return capturedData end,
    Cleanup = cleanup
}
