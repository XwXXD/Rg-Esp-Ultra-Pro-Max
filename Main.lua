local uis = game:GetService("UserInputService")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService") -- Добавлено для анимаций
local lp = players.LocalPlayer
local changing = false

-- 1. УДАЛЕНИЕ СТАРЫХ ВЕРСИЙ
for _, old in pairs(lp.PlayerGui:GetChildren()) do
    if old.Name == "UniversalGui_Fixed" then old:Destroy() end
end

-- ==========================================
-- 2. НАСТРОЙКА ESP
-- ==========================================
local spawnsFolder = workspace:FindFirstChild("NPCSpawns")
if spawnsFolder then
    local function createEspGroup(name, color)
        local group = spawnsFolder:FindFirstChild(name) 
        if not group then
            group = Instance.new("Model", spawnsFolder)
            group.Name = name
        end
        local hl = group:FindFirstChildOfClass("Highlight")
        if not hl then
            hl = Instance.new("Highlight", group)
        end
        hl.FillTransparency = 1 
        hl.OutlineColor = color
        hl.OutlineTransparency = 0
        hl.Enabled = true 
        return group
    end

    local groups = {
        Agro = createEspGroup("Agro", Color3.fromRGB(255, 255, 127)),
        Ghoul = createEspGroup("Ghoul", Color3.fromRGB(255, 0, 0)),
        CCG = createEspGroup("CCG", Color3.fromRGB(170, 255, 255)),
        Human = createEspGroup("Human", Color3.fromRGB(134, 255, 145)),
        GYA = createEspGroup("GYA", Color3.fromRGB(191, 149, 255)),
        Boss = createEspGroup("Boss", Color3.fromRGB(255, 255, 255))
    }

    task.wait(0.5) 
    for _, obj in pairs(spawnsFolder:GetChildren()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            if obj.Name == "AggroSpawns" then obj.Parent = groups.Agro
            elseif obj.Name == "GhoulSpawns" then obj.Parent = groups.Ghoul
            elseif obj.Name == "CCGSpawns" then obj.Parent = groups.CCG
            elseif obj.Name == "HumanSpawns" then obj.Parent = groups.Human
            elseif obj.Name == "GyakusatsuSpawn" then obj.Parent = groups.GYA
            elseif obj.Name == "BossSpawns" then obj.Parent = groups.Boss
            end
        end
    end
end

-- 3. НАСТРОЙКИ
local cfg = {
    ToggleKey = Enum.KeyCode.RightAlt, 
    FlySpeed = 50,
    IsFlying = false,
    Themes = {
        ["Blue"] = Color3.fromRGB(0, 162, 255),
        ["Red"] = Color3.fromRGB(255, 60, 60),
        ["Green"] = Color3.fromRGB(60, 255, 100),
        ["Purple"] = Color3.fromRGB(170, 50, 255),
        ["Gold"] = Color3.fromRGB(255, 215, 0),
        ["White"] = Color3.fromRGB(255, 255, 255)
    }
}

-- 4. СОЗДАНИЕ ИНТЕРФЕЙСА
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalGui_Fixed"
ScreenGui.Parent = lp:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Enabled = true -- Скрыт в начале для анимации появления

-- ПРИВЕТСТВЕННЫЙ ТЕКСТ
local WelcomeLabel = Instance.new("TextLabel", ScreenGui)
WelcomeLabel.Size = UDim2.new(0, 200, 0, 50)
WelcomeLabel.Position = UDim2.new(0.5, -100, 1, 50) -- Начало за экраном (снизу)
WelcomeLabel.BackgroundTransparency = 1
WelcomeLabel.Text = "Esp Ultra Pro Max"
WelcomeLabel.TextColor3 = Color3.new(1, 1, 1)
WelcomeLabel.Font = Enum.Font.GothamBold
WelcomeLabel.TextSize = 40

local Main = Instance.new("Frame", ScreenGui)
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 500, 0, 350)
Main.Position = UDim2.new(0.5, -250, 0.5, -175)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
Main.Visible = false

local Stroke = Instance.new("UIStroke", Main)
Stroke.Thickness = 2
Stroke.Color = cfg.Themes.Blue 

-- --- САЙДБАР ---
local Sidebar = Instance.new("Frame", Main)
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 130, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

local SideList = Instance.new("UIListLayout", Sidebar)
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.Padding = UDim.new(0, 5)

local SidePad = Instance.new("UIPadding", Sidebar)
SidePad.PaddingTop = UDim.new(0, 10)
SidePad.PaddingLeft = UDim.new(0, 5)

local PageContainer = Instance.new("Frame", Main)
PageContainer.Name = "PageContainer"
PageContainer.Position = UDim2.new(0, 140, 0, 10)
PageContainer.Size = UDim2.new(1, -150, 1, -20)
PageContainer.BackgroundTransparency = 1

local pages = {}

-- --- ФУНКЦИИ-ПОМОЩНИКИ ---

local function createPage(name, layoutOrder)
    local page = Instance.new("ScrollingFrame", PageContainer)
    page.Name = name .. "_Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.ScrollBarThickness = 2
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0,0,0,0)
    
    local pList = Instance.new("UIListLayout", page)
    pList.SortOrder = Enum.SortOrder.LayoutOrder
    pList.Padding = UDim.new(0, 8)
    
    local tabBtn = Instance.new("TextButton", Sidebar)
    tabBtn.Name = name .. "_Tab"
    tabBtn.Size = UDim2.new(1, -10, 0, 40)
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 14
    tabBtn.LayoutOrder = layoutOrder
    
    tabBtn.MouseButton1Click:Connect(function()
        for _, p in pairs(pages) do p.Visible = false end
        page.Visible = true
        for _, child in pairs(Sidebar:GetChildren()) do
            if child:IsA("TextButton") then child.TextColor3 = Color3.fromRGB(200, 200, 200) end
        end
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    
    pages[name] = page
    return page
end

local function addButton(parent, text, layoutOrder, callback)
    local btn = Instance.new("TextButton", parent)
    btn.LayoutOrder = layoutOrder
    btn.Size = UDim2.new(1, -5, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function addLabel(parent, text, layoutOrder)
    local lbl = Instance.new("TextLabel", parent)
    lbl.LayoutOrder = layoutOrder
    lbl.Size = UDim2.new(1, 0, 0, 25)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextSize = 13
end

-- --- НАПОЛНЕНИЕ ---
local pInfo = createPage("INFO", 1)
addLabel(pInfo, "  Esp Ultra Pro Max (EUPM):", 1)
addButton(pInfo, "Name: " .. lp.Name, 2, function() end)
addButton(pInfo, "Display: " .. lp.DisplayName, 3, function() end)
addButton(pInfo, "EUPM ver. 1.0", 4, function() end)

local pEsp = createPage("ESP", 2)
local espOrder = 1
local function createEspBtn(name)
    local btn = addButton(pEsp, "Toggle " .. name, espOrder, function() end)
    local function updateVisual(state)
        btn.BackgroundColor3 = state and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(255, 60, 60)
    end
    btn.MouseButton1Click:Connect(function()
        local folder = workspace:FindFirstChild("NPCSpawns")
        if folder then
            local model = folder:FindFirstChild(name)
            if model then
                local hl = model:FindFirstChildOfClass("Highlight")
                if hl then hl.Enabled = not hl.Enabled updateVisual(hl.Enabled) end
            end
        end
    end)
    espOrder = espOrder + 1
end
createEspBtn("Ghoul")
createEspBtn("CCG")
createEspBtn("Agro")
createEspBtn("Human")
createEspBtn("GYA")
createEspBtn("Boss")

local pMisc = createPage("MISC", 3)
addButton(pMisc, "Speed 100", 1, function() lp.Character.Humanoid.WalkSpeed = 100 end)
local flyBtn = addButton(pMisc, "Fly: OFF", 4, function()
    cfg.IsFlying = not cfg.IsFlying
    if cfg.IsFlying then
        local root = lp.Character:WaitForChild("HumanoidRootPart")
        local bv = Instance.new("BodyVelocity", root)
        bv.Name = "FlyVelocity"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        local bg = Instance.new("BodyGyro", root)
        bg.Name = "FlyGyro"
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        task.spawn(function()
            while cfg.IsFlying and root do
                runService.RenderStepped:Wait()
                local cam = workspace.CurrentCamera.CFrame
                local moveDir = Vector3.zero
                if uis:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.LookVector end
                if uis:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.LookVector end
                if uis:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.RightVector end
                if uis:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.RightVector end
                bv.Velocity = moveDir * cfg.FlySpeed
                bg.CFrame = cam
            end
            if root:FindFirstChild("FlyVelocity") then root.FlyVelocity:Destroy() end
            if root:FindFirstChild("FlyGyro") then root.FlyGyro:Destroy() end
        end)
    end
end)

runService.RenderStepped:Connect(function()
    if flyBtn then
        flyBtn.Text = cfg.IsFlying and "Fly: ON" or "Fly: OFF"
        flyBtn.BackgroundColor3 = cfg.IsFlying and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(35, 35, 35)
    end
end)

local pSet = createPage("SETTINGS", 4)
local themeGridFrame = Instance.new("Frame", pSet)
themeGridFrame.Size = UDim2.new(1, 0, 0, 100)
themeGridFrame.BackgroundTransparency = 1
local grid = Instance.new("UIGridLayout", themeGridFrame)
grid.CellSize = UDim2.new(0, 100, 0, 35)

for name, color in pairs(cfg.Themes) do
    local tBtn = Instance.new("TextButton", themeGridFrame)
    tBtn.Text = name
    tBtn.BackgroundColor3 = color
    tBtn.TextColor3 = Color3.new(0,0,0)
    Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0,6)
    tBtn.MouseButton1Click:Connect(function() Stroke.Color = color end)
end

local bindBtn = addButton(pSet, "Key: " .. cfg.ToggleKey.Name, 4, function() end)
bindBtn.MouseButton1Click:Connect(function()
    changing = true
    bindBtn.Text = "Press any key..."
    local conn
    conn = uis.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            cfg.ToggleKey = input.KeyCode
            bindBtn.Text = "Key: " .. input.KeyCode.Name
            task.wait(0.1)
            changing = false
            conn:Disconnect()
        end
    end)
end)

-- --- ЛОГИКА АНИМАЦИЙ ---

local function ToggleMenu(state)
    local targetSize = state and UDim2.new(0, 500, 0, 350) or UDim2.new(0, 0, 0, 0)
    local targetPos = state and UDim2.new(0.5, -250, 0.5, -175) or UDim2.new(0.5, 0, 0.5, 0)
    
    local tween = tweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = targetSize,
        Position = targetPos
    })
    if not state then
                 tween:Play()
        tween.Completed:Wait()
        Main.Visible = false
    end

    if state then 
        Main.Visible = true 
         tween:Play()
    end
end

-- ВСТУПИТЕЛЬНАЯ АНИМАЦИЯ (Приветствие -> Появление меню)
task.spawn(function()
    task.wait(1)
    -- Прилет текста
    tweenService:Create(WelcomeLabel, TweenInfo.new(20, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
        Rotation = 360
    }):Play()

    tweenService:Create(WelcomeLabel, TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -100, 0.5, -25)
    }):Play()
    
    task.wait(1.5)
    
    -- Уменьшение в 0
    local shrink = tweenService:Create(WelcomeLabel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })
    shrink:Play()
    shrink.Completed:Wait()
    WelcomeLabel:Destroy()
    
    -- Появление основного GUI
    Main.Size = UDim2.new(0,0,0,0)
    Main.Position = UDim2.new(0.5,0,0.5,0)
    ToggleMenu(true)
end)

-- --- DRAG ---
local dragging, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
Main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
uis.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- --- ОТКРЫТИЕ НА КЛАВИШУ ---
uis.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == cfg.ToggleKey and not changing then
        ToggleMenu(not ScreenGui.Enabled)
    end
end)

pages["INFO"].Visible = true
