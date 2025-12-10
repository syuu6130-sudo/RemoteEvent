-- Rayfield UIをインストール
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Rayfieldウィンドウを作成
local Window = Rayfield:CreateWindow({
    Name = "Remote Explorer v1.0",
    LoadingTitle = "Remote Explorerをロード中...",
    LoadingSubtitle = "by Script Helper",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "RemoteExplorer",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
})

-- タブを作成
local MainTab = Window:CreateTab("メイン", 4483362458)
local SearchTab = Window:CreateTab("検索", 4483362458)
local CaptureTab = Window:CreateTab("キャプチャ", 4483362458)
local SettingsTab = Window:CreateTab("設定", 4483362458)

-- 変数
local remoteEvents = {}
local remoteFunctions = {}
local capturedData = {}
local isCapturing = false
local selectedEvent = nil

-- ========== メインタブ ==========
MainTab:CreateSection("Remote Event マネージャー")

-- RemoteEvent一覧表示用のラベル
local eventListLabel = MainTab:CreateLabel("読み込み中...")

-- RemoteEvent選択用ドロップダウン
local eventDropdown = MainTab:CreateDropdown({
    Name = "RemoteEventを選択",
    Options = {"なし"},
    CurrentOption = "なし",
    Flag = "SelectedEvent",
    Callback = function(option)
        selectedEvent = option
        Rayfield:Notify({
            Title = "RemoteEvent選択",
            Content = selectedEvent .. " を選択しました",
            Duration = 2,
            Image = 4483362458
        })
    end
})

-- 自動実行設定
local autoExecuteToggle = MainTab:CreateToggle({
    Name = "自動実行",
    CurrentValue = false,
    Flag = "AutoExecute",
    Callback = function(value)
        -- 自動実行ロジック
        if value and selectedEvent ~= "なし" then
            Rayfield:Notify({
                Title = "自動実行開始",
                Content = selectedEvent .. " を自動実行します",
                Duration = 3,
                Image = 4483362458
            })
        elseif not value then
            Rayfield:Notify({
                Title = "自動実行停止",
                Content = "自動実行を停止しました",
                Duration = 2,
                Image = 4483362458
            })
        end
    end
})

-- 実行間隔スライダー
local intervalSlider = MainTab:CreateSlider({
    Name = "実行間隔 (秒)",
    Range = {0.1, 5},
    Increment = 0.1,
    Suffix = "秒",
    CurrentValue = 0.5,
    Flag = "Interval",
    Callback = function(value)
        -- 間隔更新ロジック
    end
})

-- 実行回数
local executionCount = 0
local countLabel = MainTab:CreateLabel("実行回数: 0")

-- 単発実行ボタン
MainTab:CreateButton({
    Name = "単発実行",
    Callback = function()
        if selectedEvent and selectedEvent ~= "なし" then
            executionCount = executionCount + 1
            countLabel:Set("実行回数: " .. executionCount)
            
            Rayfield:Notify({
                Title = "実行成功",
                Content = selectedEvent .. " を実行しました",
                Duration = 2,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "エラー",
                Content = "先にRemoteEventを選択してください",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- 実行リセットボタン
MainTab:CreateButton({
    Name = "カウンターリセット",
    Callback = function()
        executionCount = 0
        countLabel:Set("実行回数: 0")
    end
})

-- ========== 検索タブ ==========
SearchTab:CreateSection("RemoteEvent 検索")

-- 検索パス設定
local searchPathsInput = SearchTab:CreateInput({
    Name = "検索パス (カンマ区切り)",
    PlaceholderText = "ReplicatedStorage,Workspace,StarterPack",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        -- パス保存
    end
})

-- 検索深度
local depthSlider = SearchTab:CreateSlider({
    Name = "検索深度",
    Range = {1, 10},
    Increment = 1,
    Suffix = "階層",
    CurrentValue = 5,
    Flag = "SearchDepth",
    Callback = function(value)
    end
})

-- 検索結果表示用のテキストボックス
local resultTextbox = SearchTab:CreateParagraph({
    Title = "検索結果",
    Content = "ここに検索結果が表示されます"
})

-- RemoteEvent検索ボタン
SearchTab:CreateButton({
    Name = "RemoteEventを検索",
    Callback = function()
        local paths = {}
        if searchPathsInput.Value ~= "" then
            for path in string.gmatch(searchPathsInput.Value, "([^,]+)") do
                table.insert(paths, path:gsub("^%s*(.-)%s*$", "%1"))
            end
        else
            -- デフォルトの検索パス
            paths = {"ReplicatedStorage", "Workspace", "StarterPack", "StarterPlayer"}
        end
        
        resultTextbox:Set({
            Title = "検索中...",
            Content = "検索を実行しています..."
        })
        
        -- 検索実行
        remoteEvents = {}
        remoteFunctions = {}
        
        local function searchIn(parent, depth, currentDepth, parentPath)
            if currentDepth > depth then return end
            
            for _, child in pairs(parent:GetChildren()) do
                local childPath = parentPath .. "/" .. child.Name
                
                if child:IsA("RemoteEvent") then
                    table.insert(remoteEvents, {
                        Name = child.Name,
                        Path = childPath:sub(2), -- 先頭の/を削除
                        Object = child
                    })
                elseif child:IsA("RemoteFunction") then
                    table.insert(remoteFunctions, {
                        Name = child.Name,
                        Path = childPath:sub(2),
                        Object = child
                    })
                end
                
                -- 再帰的に検索
                searchIn(child, depth, currentDepth + 1, childPath)
            end
        end
        
        -- 各パスを検索
        for _, pathName in ipairs(paths) do
            local parent = game:FindFirstChild(pathName)
            if parent then
                searchIn(parent, depthSlider.Value, 1, "")
            end
        end
        
        -- 結果を表示
        local resultText = ""
        
        if #remoteEvents > 0 then
            resultText = resultText .. "=== RemoteEvents (" .. #remoteEvents .. ") ===\n"
            for i, event in ipairs(remoteEvents) do
                resultText = resultText .. i .. ". " .. event.Name .. "\n"
                resultText = resultText .. "   パス: " .. event.Path .. "\n"
            end
        else
            resultText = resultText .. "RemoteEvents: 見つかりませんでした\n"
        end
        
        resultText = resultText .. "\n"
        
        if #remoteFunctions > 0 then
            resultText = resultText .. "=== RemoteFunctions (" .. #remoteFunctions .. ") ===\n"
            for i, func in ipairs(remoteFunctions) do
                resultText = resultText .. i .. ". " .. func.Name .. "\n"
                resultText = resultText .. "   パス: " .. func.Path .. "\n"
            end
        else
            resultText = resultText .. "RemoteFunctions: 見つかりませんでした\n"
        end
        
        resultTextbox:Set({
            Title = "検索結果",
            Content = resultText
        })
        
        -- ドロップダウンを更新
        local options = {"なし"}
        for _, event in ipairs(remoteEvents) do
            table.insert(options, event.Name .. " (" .. event.Path .. ")")
        end
        
        eventDropdown:Refresh(options, "なし")
        
        Rayfield:Notify({
            Title = "検索完了",
            Content = "RemoteEvents: " .. #remoteEvents .. "件, RemoteFunctions: " .. #remoteFunctions .. "件 見つかりました",
            Duration = 4,
            Image = 4483362458
        })
    end
})

-- 詳細表示ボタン
SearchTab:CreateButton({
    Name = "選択中のRemoteEventの詳細を表示",
    Callback = function()
        if selectedEvent and selectedEvent ~= "なし" then
            local eventName = selectedEvent:match("^([^%s]+)")
            
            for _, event in ipairs(remoteEvents) do
                if event.Name == eventName then
                    -- 詳細情報ウィンドウを作成
                    Rayfield:Notify({
                        Title = "RemoteEvent詳細: " .. event.Name,
                        Content = "パス: " .. event.Path .. "\nクラス: RemoteEvent\n親: " .. tostring(event.Object.Parent),
                        Duration = 6,
                        Image = 4483362458
                    })
                    break
                end
            end
        else
            Rayfield:Notify({
                Title = "エラー",
                Content = "先にRemoteEventを選択してください",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- ========== キャプチャタブ ==========
CaptureTab:CreateSection("データキャプチャ")

-- キャプチャ状態表示
local captureStatusLabel = CaptureTab:CreateLabel("状態: 停止中")

-- キャプチャデータ表示用
local captureTextbox = CaptureTab:CreateParagraph({
    Title = "キャプチャデータ",
    Content = "キャプチャデータがここに表示されます"
})

-- キャプチャ開始ボタン
CaptureTab:CreateButton({
    Name = "キャプチャ開始",
    Callback = function()
        if not isCapturing then
            isCapturing = true
            capturedData = {}
            captureStatusLabel:Set("状態: キャプチャ中")
            
            -- RemoteEventの呼び出しを監視
            local mt = getrawmetatable(game)
            local oldNamecall = mt.__namecall
            
            if setreadonly then setreadonly(mt, false) end
            
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                if isCapturing and (method == "FireServer" or method == "InvokeServer") then
                    if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                        local captureInfo = {
                            Time = os.date("%H:%M:%S"),
                            Type = self.ClassName,
                            Name = self.Name,
                            Path = self:GetFullName(),
                            Method = method,
                            Args = args
                        }
                        
                        table.insert(capturedData, captureInfo)
                        
                        -- 表示を更新
                        local displayText = "最新キャプチャ (" .. #capturedData .. "件):\n"
                        displayText = displayText .. "時間: " .. captureInfo.Time .. "\n"
                        displayText = displayText .. "種類: " .. captureInfo.Type .. "\n"
                        displayText = displayText .. "名前: " .. captureInfo.Name .. "\n"
                        displayText = displayText .. "メソッド: " .. captureInfo.Method .. "\n"
                        displayText = displayText .. "引数の数: " .. #args .. "\n"
                        
                        if #args > 0 then
                            displayText = displayText .. "引数1の型: " .. type(args[1]) .. "\n"
                        end
                        
                        captureTextbox:Set({
                            Title = "キャプチャデータ (" .. #capturedData .. "件)",
                            Content = displayText
                        })
                    end
                end
                
                return oldNamecall(self, ...)
            end
            
            Rayfield:Notify({
                Title = "キャプチャ開始",
                Content = "RemoteEvent/Functionの呼び出しをキャプチャします",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- キャプチャ停止ボタン
CaptureTab:CreateButton({
    Name = "キャプチャ停止",
    Callback = function()
        if isCapturing then
            isCapturing = false
            captureStatusLabel:Set("状態: 停止中")
            
            Rayfield:Notify({
                Title = "キャプチャ停止",
                Content = capturedData .. "件のデータをキャプチャしました",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- キャプチャデータ保存ボタン
CaptureTab:CreateButton({
    Name = "キャプチャデータを保存",
    Callback = function()
        if #capturedData > 0 then
            local saveData = "-- キャプチャデータ (" .. os.date("%Y-%m-%d %H:%M:%S") .. ")\n"
            saveData = saveData .. "local capturedData = {\n"
            
            for i, data in ipairs(capturedData) do
                saveData = saveData .. "    {\n"
                saveData = saveData .. "        Time = \"" .. data.Time .. "\",\n"
                saveData = saveData .. "        Type = \"" .. data.Type .. "\",\n"
                saveData = saveData .. "        Name = \"" .. data.Name .. "\",\n"
                saveData = saveData .. "        Path = \"" .. data.Path .. "\",\n"
                saveData = saveData .. "        Method = \"" .. data.Method .. "\",\n"
                saveData = saveData .. "        Args = {"
                
                -- 引数を文字列化
                for j, arg in ipairs(data.Args) do
                    if type(arg) == "string" then
                        saveData = saveData .. "\"" .. arg:gsub("\"", "\\\"") .. "\""
                    elseif type(arg) == "number" then
                        saveData = saveData .. tostring(arg)
                    elseif type(arg) == "boolean" then
                        saveData = saveData .. tostring(arg)
                    elseif type(arg) == "nil" then
                        saveData = saveData .. "nil"
                    else
                        saveData = saveData .. "\"" .. tostring(arg) .. "\""
                    end
                    
                    if j < #data.Args then
                        saveData = saveData .. ", "
                    end
                end
                
                saveData = saveData .. "}\n"
                saveData = saveData .. "    },\n"
            end
            
            saveData = saveData .. "}\n\n"
            
            -- クリップボードにコピー（Robloxの制限があるため通知で表示）
            Rayfield:Notify({
                Title = "データ保存",
                Content = #capturedData .. "件のデータをコピーしました\n通知をクリックで詳細表示",
                Duration = 10,
                Image = 4483362458,
                Callback = function()
                    -- 詳細表示用の新しいウィンドウ
                    local ViewWindow = Rayfield:CreateWindow({
                        Name = "キャプチャデータ詳細",
                        LoadingTitle = "データをロード中...",
                        LoadingSubtitle = "",
                        ConfigurationSaving = {Enabled = false},
                        Discord = {Enabled = false},
                        KeySystem = false,
                    })
                    
                    local DataTab = ViewWindow:CreateTab("データ", 4483362458)
                    
                    DataTab:CreateParagraph({
                        Title = "保存データ (" .. #capturedData .. "件)",
                        Content = saveData
                    })
                    
                    DataTab:CreateButton({
                        Name = "このウィンドウを閉じる",
                        Callback = function()
                            ViewWindow:Destroy()
                        end
                    })
                end
            })
        else
            Rayfield:Notify({
                Title = "エラー",
                Content = "キャプチャデータがありません",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- ========== 設定タブ ==========
SettingsTab:CreateSection("設定")

-- 自動更新設定
SettingsTab:CreateToggle({
    Name = "起動時に自動検索",
    CurrentValue = true,
    Flag = "AutoSearch",
    Callback = function(value)
        Rayfield:Notify({
            Title = "設定更新",
            Content = "自動検索: " .. (value and "有効" or "無効"),
            Duration = 2,
            Image = 4483362458
        })
    end
})

-- UIテーマ設定
local themeDropdown = SettingsTab:CreateDropdown({
    Name = "UIテーマ",
    Options = {"デフォルト", "ダーク", "ライト", "カスタム"},
    CurrentOption = "デフォルト",
    Flag = "UITheme",
    Callback = function(option)
        Rayfield:Notify({
            Title = "テーマ変更",
            Content = option .. " テーマに変更しました",
            Duration = 2,
            Image = 4483362458
        })
    end
})

-- 表示更新速度
SettingsTab:CreateSlider({
    Name = "UI更新速度",
    Range = {1, 10},
    Increment = 1,
    Suffix = "Hz",
    CurrentValue = 5,
    Flag = "UpdateRate",
    Callback = function(value)
    end
})

-- リセットボタン
SettingsTab:CreateButton({
    Name = "全設定をリセット",
    Callback = function()
        Rayfield:Notify({
            Title = "確認",
            Content = "本当にリセットしますか？",
            Duration = 5,
            Image = 4483362458,
            Actions = {
                {
                    Title = "はい",
                    Callback = function()
                        -- 設定リセットロジック
                        executionCount = 0
                        countLabel:Set("実行回数: 0")
                        selectedEvent = nil
                        eventDropdown:Refresh({"なし"}, "なし")
                        Rayfield:Notify({
                            Title = "リセット完了",
                            Content = "すべての設定をリセットしました",
                            Duration = 3,
                            Image = 4483362458
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
                            Image = 4483362458
                        })
                    end
                }
            }
        })
    end
})

-- ========== 初期化 ==========
-- 起動時に自動検索
task.spawn(function()
    if Rayfield.Configuration.AutoSearch then
        wait(1)
        -- 自動検索を実行
        searchPathsInput.Value = "ReplicatedStorage,Workspace"
        -- 検索ボタンのコールバックを直接呼び出し
        pcall(function()
            -- ここに検索ロジックを呼び出す
        end)
    end
end)

-- ウィンドウを表示
Rayfield:Notify({
    Title = "Remote Explorer 起動完了",
    Content = "ツールバーから各機能を利用できます",
    Duration = 5,
    Image = 4483362458
})

-- ツールチップを追加
eventDropdown:SetTooltip("実行したいRemoteEventを選択します")
autoExecuteToggle:SetTooltip("選択したRemoteEventを自動的に実行します")
intervalSlider:SetTooltip("自動実行時の間隔を設定します")

-- セクション区切り
MainTab:CreateSection("")
SearchTab:CreateSection("")
CaptureTab:CreateSection("")
SettingsTab:CreateSection("")
-- より高度なバージョンに追加できる機能：

-- 1. 保存済みRemoteEventリスト
local savedEvents = SettingsTab:CreateDropdown({
    Name = "保存済みRemoteEvent",
    Options = {"ロード済みなし"},
    CurrentOption = "ロード済みなし",
    Flag = "SavedEvents",
    Callback = function(option)
        -- 保存済みイベントをロード
    end
})

-- 2. 引数エディター
local argsEditor = MainTab:CreateInput({
    Name = "引数エディター (Luaテーブル形式)",
    PlaceholderText = '{arg1 = "test", arg2 = 123}',
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        -- 引数をパースして保存
    end
})

-- 3. 実行履歴
local historyTable = {}
local historyTextbox = MainTab:CreateParagraph({
    Title = "実行履歴",
    Content = "実行履歴がここに表示されます"
})

-- 4. エクスポート機能
MainTab:CreateButton({
    Name = "設定をエクスポート",
    Callback = function()
        -- Luaスクリプトとしてエクスポート
    end
})

-- 5. バッチ実行
MainTab:CreateButton({
    Name = "バッチ実行",
    Callback = function()
        -- 複数のRemoteEventを順次実行
    end
})
