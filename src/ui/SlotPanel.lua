-- src/ui/SlotPanel.lua
-- Панель слотов армии (3-20 ячеек)

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local SlotPanel = {}

local panel = nil
local slotFrames = {}  -- [slotIndex] = {frame, icon, healthBar, statusText}

-- ============================================
-- СОЗДАНИЕ ПАНЕЛИ
-- ============================================

local function CreatePanel()
    if panel then return panel end
    
    local screenGui = player:WaitForChild("PlayerGui"):FindFirstChild("NecromancerUI")
    if not screenGui then return nil end
    
    panel = Instance.new("Frame")
    panel.Name = "SlotPanel"
    panel.Size = UDim2.new(0, 500, 0, 85)
    panel.Position = UDim2.new(0, 10, 1, -95)
    panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    panel.BackgroundTransparency = 0.3
    panel.BorderSizePixel = 0
    panel.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = panel
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 6)
    layout.Parent = panel
    
    return panel
end

-- Создать одну ячейку слота
local function CreateSlotFrame(slotIndex: number)
    local frame = Instance.new("Frame")
    frame.Name = `Slot_{slotIndex}`
    frame.Size = UDim2.new(0, 75, 0, 75)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    frame.BorderSizePixel = 1
    frame.BorderColor3 = Color3.fromRGB(80, 80, 100)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(1, -10, 1, -10)
    icon.Position = UDim2.new(0, 5, 0, 5)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://0"
    icon.Parent = frame
    
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 0, 5)
    healthBar.Position = UDim2.new(0, 0, 1, -5)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Visible = false
    healthBar.Parent = frame
    
    local statusText = Instance.new("TextLabel")
    statusText.Name = "Status"
    statusText.Size = UDim2.new(1, 0, 0, 20)
    statusText.Position = UDim2.new(0, 0, 0, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "⚰️"
    statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusText.TextScaled = true
    statusText.Font = Enum.Font.GothamBold
    statusText.Parent = frame
    
    return frame, {icon = icon, healthBar = healthBar, statusText = statusText}
end

-- ============================================
-- ПУБЛИЧНЫЕ ФУНКЦИИ
-- ============================================

-- Обновить количество и содержимое слотов
function SlotPanel.Update(maxSlots: number, activeSlots: table)
    local container = CreatePanel()
    if not container then return end
    
    -- Создаем недостающие слоты
    for i = 1, maxSlots do
        if not slotFrames[i] then
            local frame, components = CreateSlotFrame(i)
            frame.Parent = container
            slotFrames[i] = {frame = frame, components = components}
        end
    end
    
    -- Скрываем лишние слоты
    for i = maxSlots + 1, #slotFrames do
        if slotFrames[i] then
            slotFrames[i].frame.Visible = false
        end
    end
    
    -- Обновляем содержимое
    for i = 1, maxSlots do
        local slot = slotFrames[i]
        if slot then
            slot.frame.Visible = true
            local unit = activeSlots[i]
            
            if unit then
                -- В слоте есть юнит
                if unit.IsAlive then
                    slot.components.statusText.Text = "❤️"
                    slot.components.healthBar.Visible = true
                    local maxHealth = 100 -- TODO: из BaseStats
                    local percent = math.clamp(unit.CurrentHealth / maxHealth, 0, 1)
                    slot.components.healthBar.Size = UDim2.new(percent, 0, 0, 5)
                    slot.components.healthBar.BackgroundColor3 = unit.CurrentHealth > 30 and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
                else
                    slot.components.statusText.Text = "⚰️"
                    slot.components.healthBar.Visible = false
                end
                -- TODO: установить иконку юнита
            else
                -- Пустой слот
                slot.components.statusText.Text = "➕"
                slot.components.healthBar.Visible = false
            end
        end
    end
end

-- Получить количество слотов
function SlotPanel.GetSlotCount(): number
    return #slotFrames
end

-- Инициализация
function SlotPanel.Init()
    print("[SlotPanel] 🎛️ Инициализация панели слотов")
    CreatePanel()
    print("[SlotPanel] ✅ Готов")
end

return SlotPanel