local uis = game:GetService("UserInputService")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local lp = players.LocalPlayer
local changing = false

-- 1. УДАЛЕНИЕ СТАРЫХ ВЕРСИЙ (ЧТОБЫ НЕ БЫЛО ДУБЛИКАТОВ)
for _, old in pairs(lp.PlayerGui:GetChildren()) do
    if old.Name == "UniversalGui_Fixed" then old:Destroy() end
end

-- ==========================================
-- 2. НАСТРОЙКА ESP (СОЗДАНИЕ ПОДСВЕТКИ)
-- ==========================================
local spawnsFolder = workspace:FindFirstChild("NPCSpawns")

-- Если папки нет, скрипт не упадет, но ESP работать не будет
if spawnsFolder then
    -- Функция для создания группы подсветки
    local function createEspGroup(name, color)
        -- Ищем или создаем модель
        local group = spawnsFolder:FindFirstChild(name) 
        if not group then
            group = Instance.new("Model", spawnsFolder)
            group.Name = name
        end
        
        -- Создаем или обновляем Highlight
        local hl = group:FindFirstChildOfClass("Highlight")
        if not hl then
            hl = Instance.new("Highlight", group)
        end
        
        hl.FillTransparency = 1 -- Прозрачная заливка (видно только контур)
        hl.OutlineColor = color
        hl.OutlineTransparency = 0
        hl.Enabled = true -- Включено по умолчанию (можно поменять на false)
        
        return group
    end

    -- Создаем группы с твоими цветами
    local groups = {
        Agro = createEspGroup("Agro", Color3.fromRGB(255, 255, 127)),
        Ghoul = createEspGroup("Ghoul", Color3.fromRGB(255, 0, 0)),
        CCG = createEspGroup("CCG", Color3.fromRGB(170, 255, 255)),
        Human = createEspGroup("Human", Color3.fromRGB(134, 255, 145)),
        GYA = createEspGroup("GYA", Color3.fromRGB(191, 149, 255)),
        Boss = createEspGroup("Boss", Color3.fromRGB(255, 255, 255))
    }

    -- Сортировка спавнов по группам (как в твоем первом скрипте)
    task.wait(0.5) -- Ждем прогрузки карты
    for _, obj in pairs(spawnsFolder:GetChildren()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            if obj.Name == "AggroSpawns" then obj.Parent = groups.Agro
            elseif obj.Name == "GhoulSpawns" then obj.Parent = groups.Ghoul
            elseif obj.Name == "CCGSpawns" then obj.Parent = groups.CCG
            elseif obj.Name == "HumanSpawns" then obj.Parent = groups.Human
            elseif obj.Name == "GyakusatsuSpawn" then obj.Parent = groups.GYA
            elseif obj.Name == "BossSpawn" then obj.Parent = groups.Boss
            end
        end
    end
end

-- 2. НАСТРОЙКИ
local cfg = {
    ToggleKey = Enum.KeyCode.RightAlt, -- Кнопка открытия меню
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

-- 3. СОЗДАНИЕ ИНТЕРФЕЙСА
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalGui_Fixed"
ScreenGui.Parent = lp:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 500, 0, 350)
Main.Position = UDim2.new(0.5, -250, 0.5, -175)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- Обводка (Stroke)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Thickness = 2
Stroke.Color = cfg.Themes.Blue -- Цвет по умолчанию

-- --- САЙДБАР (ЛЕВОЕ МЕНЮ) ---
local Sidebar = Instance.new("Frame", Main)
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 130, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

-- Список для выравнивания кнопок в сайдбаре
local SideList = Instance.new("UIListLayout", Sidebar)
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.Padding = UDim.new(0, 5)

-- Отступ сверху для сайдбара
local SidePad = Instance.new("UIPadding", Sidebar)
SidePad.PaddingTop = UDim.new(0, 10)
SidePad.PaddingLeft = UDim.new(0, 5)

-- Контейнер для страниц
local PageContainer = Instance.new("Frame", Main)
PageContainer.Name = "PageContainer"
PageContainer.Position = UDim2.new(0, 140, 0, 10)
PageContainer.Size = UDim2.new(1, -150, 1, -20)
PageContainer.BackgroundTransparency = 1

local pages = {} -- Сюда будем складывать страницы

-- --- ФУНКЦИИ-ПОМОЩНИКИ ---

-- Создание страницы
local function createPage(name, layoutOrder)
    -- 1. Сама страница (скрытая по умолчанию)
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
    
    -- 2. Кнопка в сайдбаре для этой страницы
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
        -- Скрываем все страницы
        for _, p in pairs(pages) do p.Visible = false end
        -- Показываем текущую
        page.Visible = true
        
        -- Эффект нажатия (меняем цвет текста)
        for _, child in pairs(Sidebar:GetChildren()) do
            if child:IsA("TextButton") then child.TextColor3 = Color3.fromRGB(200, 200, 200) end
        end
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    
    pages[name] = page
    return page
end

-- Создание обычной кнопки (ИСПРАВЛЕНО)
local function addButton(parent, text, layoutOrder, callback)
    local btn = Instance.new("TextButton", parent)
    btn.LayoutOrder = layoutOrder
    btn.Size = UDim2.new(1, -5, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255) -- Всегда белый, чтобы не было ошибки nil
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 6)
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Создание текста (заголовка)
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

-- --- НАПОЛНЕНИЕ СТРАНИЦ ---

-- 1. INFO
local pInfo = createPage("INFO", 1)
addLabel(pInfo, "  User Information:", 1)
addButton(pInfo, "Name: " .. lp.Name, 2, function() end)
addButton(pInfo, "Display: " .. lp.DisplayName, 3, function() end)
addButton(pInfo, "ID: " .. lp.UserId, 4, function() end)
addButton(pInfo, "Script Ver. 0.1.0", 5, function() end)

-- 2. ESP
local pEsp = createPage("ESP", 2)
local espOrder = 1
local function createEspBtn(name)
    addButton(pEsp, "Toggle " .. name, espOrder, function()
        local folder = workspace:FindFirstChild("NPCSpawns")
        if folder then
            local model = folder:FindFirstChild(name)
            if model then
                local hl = model:FindFirstChildOfClass("Highlight")
                if hl then hl.Enabled = not hl.Enabled end
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

-- 3. MISC (ИСПРАВЛЕН FLY)
local pMisc = createPage("MISC", 3)
addButton(pMisc, "Speed 100", 1, function() lp.Character.Humanoid.WalkSpeed = 100 end)
addButton(pMisc, "Jump 150", 2, function() lp.Character.Humanoid.JumpPower = 150 end)
addButton(pMisc, "Reset Speed", 3, function() lp.Character.Humanoid.WalkSpeed = 16 lp.Character.Humanoid.JumpPower = 50 end)

-- Исправленная кнопка полета
local flyBtn = addButton(pMisc, "Fly: OFF", 4, function()
    cfg.IsFlying = not cfg.IsFlying
    
    -- Меняем текст напрямую через переменную (устраняет ошибку 'got or')
    if cfg.IsFlying then
        -- Включаем полет
        local root = lp.Character:WaitForChild("HumanoidRootPart")
        local bv = Instance.new("BodyVelocity", root)
        bv.Name = "FlyVelocity"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        
        local bg = Instance.new("BodyGyro", root)
        bg.Name = "FlyGyro"
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 9000
        
        -- Цикл полета
        task.spawn(function()
            local flyButtonRef = pMisc:FindFirstChildOfClass("TextButton") -- заглушка
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
            -- Очистка при выключении
            if root:FindFirstChild("FlyVelocity") then root.FlyVelocity:Destroy() end
            if root:FindFirstChild("FlyGyro") then root.FlyGyro:Destroy() end
        end)
    end
end)

-- Обновляем текст кнопки полета в цикле, чтобы не было ошибок доступа
runService.RenderStepped:Connect(function()
    if flyBtn then
        flyBtn.Text = cfg.IsFlying and "Fly: ON" or "Fly: OFF"
        flyBtn.BackgroundColor3 = cfg.IsFlying and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(35, 35, 35)
    end
end)

-- 4. SETTINGS
local pSet = createPage("SETTINGS", 4)

addLabel(pSet, "  Themes:", 1)

-- Сетка для цветов
local themeGridFrame = Instance.new("Frame", pSet)
themeGridFrame.LayoutOrder = 2
themeGridFrame.Size = UDim2.new(1, 0, 0, 100) -- Высота под кнопки
themeGridFrame.BackgroundTransparency = 1
local grid = Instance.new("UIGridLayout", themeGridFrame)
grid.CellSize = UDim2.new(0, 100, 0, 35)
grid.CellPadding = UDim2.new(0, 10, 0, 10)

for name, color in pairs(cfg.Themes) do
    local tBtn = Instance.new("TextButton", themeGridFrame)
    tBtn.Text = name
    tBtn.BackgroundColor3 = color
    tBtn.TextColor3 = Color3.new(0,0,0) -- Черный текст на цветном фоне
    tBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0,6)
    
    tBtn.MouseButton1Click:Connect(function()
        Stroke.Color = color
    end)
end

addLabel(pSet, "  Keybind:", 3)
local bindBtn = addButton(pSet, "Key: " .. cfg.ToggleKey.Name, 4, function()
    -- Логика смены клавиши
end)
bindBtn.MouseButton1Click:Connect(function()
    bindBtn.Text = "Press any key..."
    changing = true
    local conn
    conn = uis.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            cfg.ToggleKey = input.KeyCode
            bindBtn.Text = "Key: " .. input.KeyCode.Name
            changing = false
            conn:Disconnect()
        end
    end)
end)

-- --- СИСТЕМА DRAG (ПЕРЕТАСКИВАНИЕ) ---
local dragging, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
Main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
uis.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- --- ОТКРЫТИЕ НА КЛАВИШУ ---
uis.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == cfg.ToggleKey and changing == false then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

-- Выбираем первую страницу при запуске
pages["INFO"].Visible = true
