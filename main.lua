-- Rayfield UI Framework
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- サービス
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

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
    SecurityLevel = 1,
    Language = "日本語"
}

-- Rayfieldウィンドウ作成
local Window = Rayfield:CreateWindow({
    Name = "🔍 Remote Explorer Pro v2.0",
    LoadingTitle = "高度なRemote探索ツールをロード中...",
    LoadingSubtitle = "by ScriptMaster Pro",
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
    },
    Theme = {
        BackgroundColor = Color3.fromRGB(25, 25, 25),
        HeaderColor = Color3.fromRGB(35, 35, 35),
        TextColor = Color3.fromRGB(255, 255, 255),
        ElementColor = Color3.fromRGB(40, 40, 40)
    }
})

-- タブ作成
local DashboardTab = Window:CreateTab("📊 ダッシュボード", 7733960981)
local ExplorerTab = Window:CreateTab("🔎 エクスプローラー", 7733960981)
local ExecutorTab = Window:CreateTab("⚡ エグゼキューター", 7733960981)
local CaptureTab = Window:CreateTab("🎯 キャプチャ", 7733960981)
local BuilderTab = Window:CreateTab("🛠️ ビルダー", 7733960981)
local SettingsTab = Window:CreateTab("⚙️ 設定", 7733960981)

-- ========== 📊 ダッシュボード ==========
DashboardTab:CreateSection("📈 システム情報")

local statsLabel = DashboardTab:CreateParagraph({
    Title = "📊 システム統計",
    Content = "読み込み中..."
})

local statusLabel = DashboardTab:CreateLabel("🟢 システム状態: 正常")

-- ゲーム情報
local gameInfoLabel = DashboardTab:CreateParagraph({
    Title = "🎮 ゲーム情報",
    Content = "ゲーム: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name .. 
             "\nプレイヤー: " .. Players.LocalPlayer.Name ..
             "\nPlace ID: " .. game.PlaceId
})

-- クイックアクション
DashboardTab:CreateSection("⚡ クイックアクション")

DashboardTab:CreateButton({
    Name = "🔄 即時検索",
    Callback = function()
        Rayfield:Notify({
            Title = "検索開始",
            Content = "RemoteEventを検索しています...",
            Duration = 2,
            Image = 7733960981
        })
        -- 自動検索実行
        task.spawn(function()
            performSearch()
        end)
    end
})

DashboardTab:CreateButton({
    Name = "🧹 キャッシュクリア",
    Callback = function()
        remoteEvents = {}
        remoteFunctions = {}
        capturedData = {}
        executionHistory = {}
        Rayfield:Notify({
            Title = "キャッシュクリア",
            Content = "すべてのキャッシュをクリアしました",
            Duration = 2,
            Image = 7733960981
        })
    end
})

-- リアルタイム更新
task.spawn(function()
    while Window do
        local stats = string.format(
            "🔍 RemoteEvents: %d\n⚡ RemoteFunctions: %d\n💾 キャプチャデータ: %d\n📝 実行履歴: %d\n⏱️ 実行回数: %d",
            #remoteEvents, #remoteFunctions, #capturedData, #executionHistory, executionCount
        )
        statsLabel:Set({Title = "📊 システム統計", Content = stats})
        wait(5)
    end
end)

-- ========== 🔎 エクスプローラー ==========
ExplorerTab:CreateSection("🔍 検索設定")

local searchPathsInput = ExplorerTab:CreateInput({
    Name = "検索パス (カンマ区切り)",
    PlaceholderText = "例: ReplicatedStorage,Workspace,StarterPack",
    RemoveTextAfterFocusLost = false,
    Callback = function(text) end
})

local searchDepthSlider = ExplorerTab:CreateSlider({
    Name = "検索深度",
    Range = {1, 10},
    Increment = 1,
    Suffix = "階層",
    CurrentValue = 5,
    Flag = "SearchDepth",
    Callback = function(value) end
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
            -- オブジェクトを取得
            for _, event in ipairs(remoteEvents) do
                if event.Name .. " (" .. event.Path .. ")" == option then
                    selectedEventObj = event.Object
                    break
                end
            end
            for _, func in ipairs(remoteFunctions) do
                if func.Name .. " (" .. func.Path .. ")" == option then
                    selectedEventObj = func.Object
                    break
                end
            end
            
            if selectedEventObj then
                Rayfield:Notify({
                    Title = "Remote選択",
                    Content = selectedEvent .. " を選択しました",
                    Duration = 2,
                    Image = 7733960981
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
    if searchPathsInput.Value ~= "" then
        for path in string.gmatch(searchPathsInput.Value, "([^,]+)") do
            table.insert(paths, path:gsub("^%s*(.-)%s*$", "%1"))
        end
    else
        paths = {"ReplicatedStorage", "Workspace", "StarterPack", "StarterPlayer", "ServerStorage"}
    end
    
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
                    Path = currentPath:sub(2),
                    Object = child,
                    Parent = child.Parent,
                    ClassName = child.ClassName
                })
            elseif child:IsA("RemoteFunction") and (searchAll or searchFunctions) then
                table.insert(remoteFunctions, {
                    Name = child.Name,
                    Path = currentPath:sub(2),
                    Object = child,
                    Parent = child.Parent,
                    ClassName = child.ClassName
                })
            end
            
            -- フォルダー内を検索
            if includeFoldersToggle.CurrentValue then
                searchRecursive(child, depth, currentDepth + 1, currentPath)
            end
        end
    end
    
    -- 検索実行
    for _, pathName in ipairs(paths) do
        local parent = game:FindFirstChild(pathName)
        if parent then
            searchRecursive(parent, searchDepthSlider.Value, 1, "")
        end
    end
    
    -- 結果表示
    local resultText = ""
    local totalFound = #remoteEvents + #remoteFunctions
    
    if totalFound > 0 then
        resultText = string.format("✅ 検索完了: %d件見つかりました\n\n", totalFound)
        
        if #remoteEvents > 0 then
            resultText = resultText .. string.format("📡 RemoteEvents (%d件):\n", #remoteEvents)
            for i, event in ipairs(remoteEvents) do
                resultText = resultText .. string.format("%d. %s\n   パス: %s\n", i, event.Name, event.Path)
            end
            resultText = resultText .. "\n"
        end
        
        if #remoteFunctions > 0 then
            resultText = resultText .. string.format("⚡ RemoteFunctions (%d件):\n", #remoteFunctions)
            for i, func in ipairs(remoteFunctions) do
                resultText = resultText .. string.format("%d. %s\n   パス: %s\n", i, func.Name, func.Path)
            end
        end
    else
        resultText = "❌ RemoteEvent/Functionが見つかりませんでした"
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
    
    Rayfield:Notify({
        Title = "検索完了",
        Content = string.format("%d件のRemoteを見つけました", totalFound),
        Duration = 3,
        Image = 7733960981
    })
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
                "📦 アーカイブ済み: %s",
                selectedEventObj.Name,
                selectedEventObj.ClassName,
                selectedEventObj:GetFullName(),
                selectedEventObj.Parent.Name,
                selectedEventObj:GetDebugId(),
                tostring(selectedEventObj.Archivable)
            )
            
            detailsTextbox:Set({Title = "Remote詳細: " .. selectedEventObj.Name, Content = details})
        else
            Rayfield:Notify({
                Title = "エラー",
                Content = "先にRemoteを選択してください",
                Duration = 3,
                Image = 7733960981
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
    CurrentValue = 0.5,
    Flag = "ExecInterval",
    Callback = function(value) end
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
    local success, result = pcall(function()
        return loadstring("return " .. input)()
    end)
    
    if success then
        return result
    else
        -- 単純な文字列の場合
        if input:match('^".*"$') or input:match("^'.*'$") then
            return input:sub(2, -2)
        end
        
        -- 数値の場合
        if tonumber(input) then
            return tonumber(input)
        end
        
        -- ブーリアンの場合
        if input:lower() == "true" then return true end
        if input:lower() == "false" then return false end
        if input:lower() == "nil" then return nil end
        
        -- それ以外はそのまま返す
        return input
    end
end

-- 実行関数
local function executeRemote()
    if not selectedEventObj then
        Rayfield:Notify({
            Title = "エラー",
            Content = "先にRemoteを選択してください",
            Duration = 3,
            Image = 7733960981
        })
        return
    end
    
    local argsText = argsInput.Value
    local args = {}
    
    if argsText ~= "" then
        local parsed = parseArguments(argsText)
        if type(parsed) == "table" then
            args = parsed
        else
            args = {parsed}
        end
    end
    
    -- 実行
    local success, result = pcall(function()
        if selectedEventObj:IsA("RemoteEvent") then
            selectedEventObj:FireServer(unpack(args))
        elseif selectedEventObj:IsA("RemoteFunction") then
            return selectedEventObj:InvokeServer(unpack(args))
        end
    end)
    
    executionCount = executionCount + 1
    execCountLabel:Set("実行回数: " .. executionCount)
    
    local logEntry = string.format(
        "[%s] %s.%s\n" ..
        "引数: %s\n" ..
        "結果: %s\n" ..
        "------------------------\n",
        os.date("%H:%M:%S"),
        selectedEventObj.Name,
        selectedEventObj:IsA("RemoteEvent") and "FireServer" or "InvokeServer",
        tostring(argsText):sub(1, 50),
        success and "✅ 成功" or "❌ 失敗: " .. tostring(result)
    )
    
    table.insert(executionHistory, {
        Time = os.date("%Y-%m-%d %H:%M:%S"),
        Remote = selectedEventObj.Name,
        Type = selectedEventObj.ClassName,
        Arguments = argsText,
        Success = success,
        Result = result
    })
    
    -- ログ更新（最新5件のみ表示）
    local currentLog = execLogTextbox.Content
    local lines = {}
    for line in currentLog:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    
    while #lines > 20 do
        table.remove(lines, 1)
    end
    
    table.insert(lines, 1, logEntry)
    execLogTextbox:Set({
        Title = "実行ログ (" .. #executionHistory .. "件)",
        Content = table.concat(lines, "\n")
    })
    
    Rayfield:Notify({
        Title = success and "✅ 実行成功" or "❌ 実行失敗",
        Content = selectedEventObj.Name .. " を実行しました",
        Duration = 2,
        Image = 7733960981
    })
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
            task.spawn(function()
                local count = 0
                local maxCount = execCountSlider.Value
                while isAutoRunning and count < maxCount do
                    executeRemote()
                    count = count + 1
                    wait(execIntervalSlider.Value)
                end
                isAutoRunning = false
                autoExecToggle:Set(false)
            end)
        end
    end
})

-- ログクリアボタン
ExecutorTab:CreateButton({
    Name = "🧹 ログクリア",
    Callback = function()
        execLogTextbox:Set({Title = "実行ログ (0件)", Content = ""})
        Rayfield:Notify({
            Title = "ログクリア",
            Content = "実行ログをクリアしました",
            Duration = 2,
            Image = 7733960981
        })
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
    CurrentValue = 100,
    Flag = "CaptureLimit",
    Callback = function(value) end
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

-- キャプチャ開始関数
local function startCapture()
    capturedData = {}
    hookEnabled = true
    
    -- メタテーブルフック
    local mt = getrawmetatable(game)
    originalNamecall = mt.__namecall
    
    if setreadonly then setreadonly(mt, false) end
    
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if isCapturing and hookEnabled then
            if (method == "FireServer" or method == "InvokeServer") and 
               (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
                
                local remoteName = self.Name
                local filter = captureFilterInput.Value
                
                -- フィルター適用
                if filter == "" or remoteName:match(filter) then
                    local captureEntry = {
                        Timestamp = os.time(),
                        Time = os.date("%H:%M:%S"),
                        Type = self.ClassName,
                        Name = remoteName,
                        Path = self:GetFullName(),
                        Method = method,
                        Arguments = args,
                        ArgumentsCount = #args
                    }
                    
                    table.insert(capturedData, captureEntry)
                    
                    -- 制限チェック
                    if #capturedData > captureLimitSlider.Value then
                        table.remove(capturedData, 1)
                    end
                    
                    -- ログ更新
                    local logEntry = string.format(
                        "[%s] %s.%s(%d args)\n%s\n------------------------\n",
                        captureEntry.Time,
                        remoteName,
                        method,
                        #args,
                        args[1] and tostring(args[1]):sub(1, 100) or "なし"
                    )
                    
                    local currentLog = captureLogTextbox.Content
                    local lines = {}
                    for line in currentLog:gmatch("[^\n]+") do
                        table.insert(lines, line)
                    end
                    
                    while #lines > 15 do
                        table.remove(lines, 1)
                    end
                    
                    table.insert(lines, 1, logEntry)
                    captureLogTextbox:Set({
                        Title = "キャプチャログ (" .. #capturedData .. "件)",
                        Content = table.concat(lines, "\n")
                    })
                end
            end
        end
        
        return originalNamecall(self, ...)
    end
    
    Rayfield:Notify({
        Title = "キャプチャ開始",
        Content = "Remote通信のキャプチャを開始しました",
        Duration = 2,
        Image = 7733960981
    })
end

-- キャプチャ停止関数
local function stopCapture()
    hookEnabled = false
    if originalNamecall then
        local mt = getrawmetatable(game)
        if setreadonly then setreadonly(mt, false) end
        mt.__namecall = originalNamecall
    end
    
    Rayfield:Notify({
        Title = "キャプチャ停止",
        Content = string.format("%d件のデータをキャプチャしました", #capturedData),
        Duration = 3,
        Image = 7733960981
    })
end

-- キャプチャデータ表示ボタン
CaptureTab:CreateButton({
    Name = "📋 詳細表示",
    Callback = function()
        if #capturedData > 0 then
            local details = "📊 キャプチャデータ詳細\n\n"
            for i, data in ipairs(capturedData) do
                details = details .. string.format(
                    "%d. [%s] %s.%s\n   パス: %s\n   引数: %d個\n\n",
                    i, data.Time, data.Name, data.Method, data.Path, data.ArgumentsCount
                )
            end
            
            local ViewWindow = Rayfield:CreateWindow({
                Name = "📊 キャプチャデータ詳細",
                LoadingTitle = "データをロード中...",
                LoadingSubtitle = "",
                ConfigurationSaving = {Enabled = false},
                Discord = {Enabled = false},
                KeySystem = false,
            })
            
            local DataTab = ViewWindow:CreateTab("データ", 7733960981)
            
            DataTab:CreateParagraph({
                Title = "キャプチャデータ (" .. #capturedData .. "件)",
                Content = details
            })
            
            DataTab:CreateButton({
                Name = "📤 JSONエクスポート",
                Callback = function()
                    local json = HttpService:JSONEncode(capturedData)
                    setclipboard(json)
                    Rayfield:Notify({
                        Title = "エクスポート完了",
                        Content = "JSONデータをクリップボードにコピーしました",
                        Duration = 3,
                        Image = 7733960981
                    })
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
                Title = "データなし",
                Content = "キャプチャデータがありません",
                Duration = 2,
                Image = 7733960981
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
    Options = {"自動実行", "手動実行", "イベント駆動"},
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
            Title = "エラー",
            Content = "対象のRemoteEventを選択してください",
            Duration = 3,
            Image = 7733960981
        })
        return
    end
    
    local scriptTemplate = ""
    
    if scriptType == "自動実行" then
        scriptTemplate = string.format([[
-- %s - 自動実行スクリプト
-- 生成日時: %s

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- RemoteEventのパス (要調整)
local remoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("YourRemoteEvent")

local running = false
local interval = 0.5 -- 実行間隔

local function executeAction()
    -- ここに実行する引数を設定
    local args = {
        "arg1",
        123,
        true,
        key = "value"
    }
    
    local success, error = pcall(function()
        remoteEvent:FireServer(unpack(args))
    end)
    
    if not success then
        warn("実行エラー:", error)
    end
end

-- 自動実行ループ
task.spawn(function()
    while running do
        executeAction()
        task.wait(interval)
    end
end)

-- コントロール用関数
local AutoFarm = {
    Start = function()
        if not running then
            running = true
            print("自動実行を開始しました")
        end
    end,
    
    Stop = function()
        running = false
        print("自動実行を停止しました")
    end,
    
    SetInterval = function(newInterval)
        interval = newInterval
        print("実行間隔を設定:", interval)
    end
}

return AutoFarm
]], scriptName, os.date("%Y-%m-%d %H:%M:%S"))
    elseif scriptType == "手動実行" then
        scriptTemplate = string.format([[
-- %s - 手動実行スクリプト
-- 生成日時: %s

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- RemoteEventのパス (要調整)
local remoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("YourRemoteEvent")

-- GUIを作成
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "%sGUI"

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 300, 0, 200)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local executeButton = Instance.new("TextButton", mainFrame)
executeButton.Size = UDim2.new(0.8, 0, 0.3, 0)
executeButton.Position = UDim2.new(0.1, 0, 0.35, 0)
executeButton.Text = "実行"
executeButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)

executeButton.MouseButton1Click:Connect(function()
    local args = {
        "action",
        player.Name,
        os.time()
    }
    
    local success, error = pcall(function()
        remoteEvent:FireServer(unpack(args))
    end)
    
    if success then
        print("実行成功!")
    else
        warn("実行失敗:", error)
    end
end)

-- ホットキー設定 (例: Fキー)
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F and not UserInputService:GetFocusedTextBox() then
        executeButton:Activate()
    end
end)

print("%s がロードされました。Fキーで実行できます。")
]], scriptName, os.date("%Y-%m-%d %H:%M:%S"), scriptName, scriptName)
    end
    
    generatedScriptTextbox:Set({
        Title = "生成されたスクリプト",
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
        if generatedScriptTextbox.Content ~= "ここに生成されたスクリプトが表示されます" then
            setclipboard(generatedScriptTextbox.Content)
            Rayfield:Notify({
                Title = "コピー完了",
                Content = "スクリプトをクリップボードにコピーしました",
                Duration = 2,
                Image = 7733960981
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
        -- テーマ変更ロジックをここに追加
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
    CurrentOption = "低 (推奨)",
    Flag = "SecurityLevel",
    Callback = function(option)
        DEFAULT_CONFIG.SecurityLevel = option
    end
})

SettingsTab:CreateToggle({
    Name = "アンチ検知モード",
    CurrentValue = false,
    Flag = "AntiDetect",
    Callback = function(value)
        if value then
            Rayfield:Notify({
                Title = "警告",
                Content = "アンチ検知モードは安定性に影響する場合があります",
                Duration = 5,
                Image = 7733960981
            })
        end
    end
})

SettingsTab:CreateSection("💾 データ管理")

SettingsTab:CreateButton({
    Name = "💾 設定を保存",
    Callback = function()
        Rayfield:Notify({
            Title = "設定保存",
            Content = "設定を保存しました",
            Duration = 2,
            Image = 7733960981
        })
    end
})

SettingsTab:CreateButton({
    Name = "🔄 設定をリセット",
    Callback = function()
        Rayfield:Notify({
            Title = "確認",
            Content = "すべての設定をリセットしますか？",
            Duration = 5,
            Image = 7733960981,
            Actions = {
                {
                    Title = "はい",
                    Callback = function()
                        -- リセットロジック
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
                            SecurityLevel = 1,
                            Language = "日本語"
                        }
                        
                        -- UI要素をリセット
                        searchDepthSlider:Set(5)
                        execIntervalSlider:Set(0.5)
                        captureLimitSlider:Set(100)
                        
                        Rayfield:Notify({
                            Title = "リセット完了",
                            Content = "設定をデフォルトに戻しました",
                            Duration = 3,
                            Image = 7733960981
                        })
                    end
                },
                {
                    Title = "いいえ",
                    Callback = function()
                        Rayfield:Notify({
                            Title = "キャンセル",
                            Content = "リセットをキャンセルしました",
                            Duration = 2,
                            Image = 7733960981
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
            RemoteEvents = remoteEvents,
            RemoteFunctions = remoteFunctions,
            SavedEvents = {}
        }
        
        local json = HttpService:JSONEncode(exportData)
        setclipboard(json)
        
        Rayfield:Notify({
            Title = "エクスポート完了",
            Content = "設定データをクリップボードにコピーしました",
            Duration = 3,
            Image = 7733960981
        })
    end
})

-- 初期化
task.spawn(function()
    wait(1)
    
    -- 起動時の検索
    if DEFAULT_CONFIG.AutoSearch then
        searchPathsInput.Value = DEFAULT_CONFIG.DefaultPaths
        performSearch()
    end
    
    -- ビルダーのドロップダウンを更新
    local builderOptions = {"選択してください..."}
    for _, event in ipairs(remoteEvents) do
        table.insert(builderOptions, event.Name)
    end
    targetEventDropdown:Refresh(builderOptions, "選択してください...")
    
    -- 起動通知
    Rayfield:Notify({
        Title = "🔄 Remote Explorer Pro 起動完了",
        Content = string.format(
            "バージョン: 2.0\n" ..
            "RemoteEvents: %d件\n" ..
            "RemoteFunctions: %d件\n\n" ..
            "各タブから機能を利用できます",
            #remoteEvents, #remoteFunctions
        ),
        Duration = 6,
        Image = 7733960981
    })
end)

-- タブ切り替え時のイベント
local currentTab = "Dashboard"
Window.TabSelected:Connect(function(tab)
    currentTab = tab
end)

-- 安全な終了処理
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == Window.Name then
        -- クリーンアップ
        isCapturing = false
        isAutoRunning = false
        hookEnabled = false
        
        if originalNamecall then
            local mt = getrawmetatable(game)
            if setreadonly then setreadonly(mt, false) end
            mt.__namecall = originalNamecall
        end
    end
end)

print("🎮 Remote Explorer Pro v2.0 が正常に起動しました")
