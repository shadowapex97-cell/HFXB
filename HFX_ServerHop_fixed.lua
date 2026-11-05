-- منع تكرار الواجهة عند إعادة تشغيل السكربت
if game.CoreGui:FindFirstChild("HFX_TopTextUI") then game.CoreGui:FindFirstChild("HFX_TopTextUI"):Destroy() end
if game.CoreGui:FindFirstChild("DevilFruitESP_Folder") then game.CoreGui:FindFirstChild("DevilFruitESP_Folder"):Destroy() end

-- إنشاء مجلد لتخزين المؤشرات البرمجية
local ESPFolder = Instance.new("Folder", game.CoreGui)
ESPFolder.Name = "DevilFruitESP_Folder"

-- 1. إنشاء واجهة النص العلوي للشاشة (HFX)
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "HFX_TopTextUI"
ScreenGui.ResetOnSpawn = false

local TopText = Instance.new("TextLabel", ScreenGui)
TopText.Name = "TopText"
TopText.Size = UDim2.new(0, 150, 0, 40)
TopText.Position = UDim2.new(0.5, -75, 0, 15)
TopText.BackgroundTransparency = 1
TopText.Text = "HFX"
TopText.Font = Enum.Font.GothamBold
TopText.TextSize = 28
TopText.TextStrokeTransparency = 0.1
TopText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

-- محرك الـ RGB لتحريك ألوان النص العلوي (HFX)
task.spawn(function()
    local hue = 0
    while task.wait() do
        hue = (hue + 1.5) % 360
        local color = Color3.fromHSV(hue / 360, 1, 1)
        TopText.TextColor3 = color
    end
end)

-- [ميزة الانتقال]: جلب سيرفر عام آخر والانتقال إليه
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local function JumpToNewServer()
    TopText.Text = "HOPPING..."

    local placeId = game.PlaceId
    local currentJobId = game.JobId
    local cursor = ""
    local visited = {}

    -- تجربة صفحات السيرفرات العامة، مع استبعاد السيرفر الحالي والممتلئ
    for page = 1, 3 do
        local url = "https://games.roblox.com/v1/games/"
            .. tostring(placeId)
            .. "/servers/Public?sortOrder=Asc&limit=100"

        if cursor ~= "" then
            url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
        end

        local requestOK, response = pcall(function()
            return game:HttpGet(url)
        end)

        if not requestOK or type(response) ~= "string" then
            TopText.Text = "HOP FAILED"
            warn("HFX Server Hop: تعذر جلب قائمة السيرفرات.")
            return
        end

        local decodeOK, result = pcall(function()
            return HttpService:JSONDecode(response)
        end)

        if not decodeOK or type(result) ~= "table" or type(result.data) ~= "table" then
            TopText.Text = "HOP FAILED"
            warn("HFX Server Hop: استجابة السيرفرات غير صالحة.")
            return
        end

        for _, server in ipairs(result.data) do
            local serverId = server.id
            local playing = tonumber(server.playing) or 0
            local maxPlayers = tonumber(server.maxPlayers) or 0

            if type(serverId) == "string"
                and serverId ~= currentJobId
                and not visited[serverId]
                and maxPlayers > playing then

                visited[serverId] = true

                local teleportOK, teleportError = pcall(function()
                    TeleportService:TeleportToPlaceInstance(
                        placeId,
                        serverId,
                        game.Players.LocalPlayer
                    )
                end)

                if teleportOK then
                    return
                else
                    warn("HFX Server Hop: فشلت محاولة الانتقال: " .. tostring(teleportError))
                end
            end
        end

        cursor = result.nextPageCursor or ""
        if cursor == "" then
            break
        end
    end

    TopText.Text = "NO SERVER"
    warn("HFX Server Hop: لم يتم العثور على سيرفر متاح.")
end

-- 2. دالة كاشف الفواكه الشيطانية بحدود RGB وميزة الرؤية خلف الجدران
local foundFruitsCount = 0 -- عداد لمعرفة هل توجد فواكه في السيرفر أم لا

local function CreateESP(fruit)
    if fruit:IsA("Tool") or fruit:IsA("Model") then
        if string.find(string.lower(fruit.Name), "fruit") and not string.find(string.lower(fruit.Name), "dealer") then

            local handle = fruit:FindFirstChild("Handle") or fruit:FindFirstChildOfClass("Part") or fruit:FindFirstChildOfClass("MeshPart")
            if handle and not handle:FindFirstChild("FruitESP") then
                foundFruitsCount = foundFruitsCount + 1 -- تم العثور على فاكهة

                local BillboardGui = Instance.new("BillboardGui", handle)
                BillboardGui.Name = "FruitESP"
                BillboardGui.AlwaysOnTop = true
                BillboardGui.Size = UDim2.new(0, 200, 0, 50)
                BillboardGui.Adornee = handle
                BillboardGui.ExtentsOffset = Vector3.new(0, 2.5, 0)

                local TextLabel = Instance.new("TextLabel", BillboardGui)
                TextLabel.Size = UDim2.new(1, 0, 1, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.Font = Enum.Font.GothamBold
                TextLabel.TextSize = 15
                TextLabel.TextStrokeTransparency = 0.2
                TextLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

                local Highlight = Instance.new("Highlight")
                Highlight.Name = fruit.Name .. "_Highlight"
                Highlight.Parent = ESPFolder
                Highlight.Adornee = fruit
                Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                Highlight.OutlineTransparency = 0
                Highlight.FillTransparency = 0.75

                task.spawn(function()
                    local fruitHue = 0
                    while fruit:IsDescendantOf(workspace) and handle:FindFirstChild("FruitESP") do
                        fruitHue = (fruitHue + 1.5) % 360
                        local dynamicColor = Color3.fromHSV(fruitHue / 360, 1, 1)

                        Highlight.OutlineColor = dynamicColor
                        Highlight.FillColor = dynamicColor
                        TextLabel.TextColor3 = dynamicColor

                        local player = game.Players.LocalPlayer
                        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            local distance = math.floor((player.Character.HumanoidRootPart.Position - handle.Position).Magnitude)
                            TextLabel.Text = "🍇 " .. fruit.Name .. "\n[" .. tostring(distance) .. "m]"
                        end
                        task.wait(0.03)
                    end
                    Highlight:Destroy()
                end)
            end
        end
    end
end

-- فحص الماب فور تشغيل السكربت لرصد الفواكه المرسبنة مسبقاً
for _, object in ipairs(workspace:GetChildren()) do
    CreateESP(object)
end

-- فحص السيرفر التلقائي (إذا لم يجد أي فاكهة، ينتقل)
task.defer(function()
    task.wait(2)
    if foundFruitsCount == 0 then
        JumpToNewServer()
    end
end)

-- مراقبة السيرفر حياً لظهور أي فواكه جديدة تلقائياً
workspace.ChildAdded:Connect(function(child)
    task.wait(0.5)
    CreateESP(child)
end)

-- إعادة تشغيل السكربت بعد الانتقال (ضع رابط GitHub RAW بعد رفع الملف)
local queue_on_teleport =
    (syn and syn.queue_on_teleport)
    or (fluxus and fluxus.queue_on_teleport)
    or queue_on_teleport

if queue_on_teleport then
    game.Players.LocalPlayer.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.Started then
            queue_on_teleport([[
                loadstring(game:HttpGet("PUT_YOUR_GITHUB_RAW_URL_HERE"))()
            ]])
        end
    end)
end
