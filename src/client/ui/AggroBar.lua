-- src/ui/AggroBar.lua
-- Шкала гнева деревни

local AggroBar = {}

local barFrame = nil
local fillFrame = nil
local textLabel = nil
local currentGui = nil

-- ============================================
-- СОЗДАНИЕ
-- ============================================

local function CreateAggroBar()
    if barFrame then return barFrame end
    
    if not currentGui then
        warn("[AggroBar] Ошибка: Попытка создания без ScreenGui!")
        return nil
    end
    
    barFrame = Instance.new("Frame")
    barFrame.Name = "AggroBar"
    barFrame.Size = UDim2.new(0, 200, 0, 20)
    barFrame.Position = UDim2.new(0.5, -100, 0, 50)
    barFrame.BackgroundColor3 = Color3.fromRGB(30, 20, 20)
    barFrame.BorderSizePixel = 0
    barFrame.Parent = currentGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = barFrame
    
    fillFrame = Instance.new("Frame")
    fillFrame.Name = "Fill"
    fillFrame.Size = UDim2.new(0, 0, 1, 0)
    fillFrame.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    fillFrame.BorderSizePixel = 0
    fillFrame.Parent = barFrame
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = fillFrame
    
    textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "😠 0%"
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = barFrame
    
    return barFrame
end

-- ============================================
-- ПУБЛИЧНЫЕ ФУНКЦИИ
-- ============================================

function AggroBar.Update(aggroLevel: number, maxAggro: number)
    if not barFrame then
        CreateAggroBar()
    end
    
    if not fillFrame then return end
    
    local percent = math.clamp(aggroLevel / maxAggro, 0, 1)
    fillFrame.Size = UDim2.new(percent, 0, 1, 0)
    
    if percent < 0.3 then
        fillFrame.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        textLabel.Text = `😊 ${math.floor(percent * 100)}%`
    elseif percent < 0.7 then
        fillFrame.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
        textLabel.Text = `😠 ${math.floor(percent * 100)}%`
    else
        fillFrame.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        textLabel.Text = `👿 ${math.floor(percent * 100)}%`
    end
end

function AggroBar.SetVisible(visible: boolean)
    if barFrame then
        barFrame.Visible = visible
    end
end

function AggroBar.Init(gui: Instance)
    print("[AggroBar] 📊 Инициализация шкалы агрессии")
    currentGui = gui
    CreateAggroBar()
    AggroBar.Update(0, 100)
    print("[AggroBar] ✅ Готов")
end

return AggroBar