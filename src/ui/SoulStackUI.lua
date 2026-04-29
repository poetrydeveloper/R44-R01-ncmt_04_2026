-- src/ui/SoulStackUI.lua
-- Отображение стека карточек (можно скрыть/показать)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local screenGui = player:WaitForChild("PlayerGui"):FindFirstChild("NecromancerUI")

local UIManager = require(script.Parent.UIManager)

-- ============================================
-- Создание панели стека
-- ============================================

local SoulStackUI = {}

local panel = nil
local isVisible = true
local cardButtons = {}  -- [cardId] = button

local function CreateSoulStackPanel()
    if panel then return end
    
    panel = Instance.new("Frame")
    panel.Name = "SoulStackPanel"
    panel.Size = UDim2.new(0, 300, 0, 400)
    panel.Position = UDim2.new(1, -310, 0, 10)
    panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    panel.BackgroundTransparency = 0.1
    panel.BorderSizePixel = 0
    panel.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = panel
    
    -- Заголовок с кнопкой сворачивания
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    header.Parent = panel
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.8, 0, 1, 0)
    title.Position = UDim2.new(0, 5, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "📇 Стек душ"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.Parent = header
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 30, 1, 0)
    toggleButton.Position = UDim2.new(1, -30, 0, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    toggleButton.Text = "▼"
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.Parent = header
    
    -- Скроллинг для списка карточек
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Size = UDim2.new(1, 0, 1, -30)
    scrollFrame.Position = UDim2.new(0, 0, 0, 30)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.Parent = panel
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = scrollFrame
    
    -- Кнопка сворачивания
    local isExpanded = true
    toggleButton.MouseButton1Click:Connect(function()
        isExpanded = not isExpanded
        scrollFrame.Visible = isExpanded
        toggleButton.Text = isExpanded and "▼" or "▲"
        panel.Size = isExpanded and UDim2.new(0, 300, 0, 400) or UDim2.new(0, 300, 0, 30)
    end)
    
    return panel, scrollFrame, listLayout
end

-- Создать карточку для отображения
local function CreateCardButton(cardId: string, unitTypeId: string, modifiers: table)
    local button = Instance.new("TextButton")
    button.Name = `Card_{cardId}`
    button.Size = UDim2.new(0.9, 0, 0, 60)
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    button.BorderSizePixel = 0
    button.Text = ""
    button.Parent = nil  -- Будет добавлен в список позже
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    -- Название юнита
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 20)
    nameLabel.Position = UDim2.new(0, 5, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = unitTypeId
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = button
    
    -- Иконки баффов
    local buffText = ""
    for buffName, _ in pairs(modifiers or {}) do
        buffText = buffText .. "✨ "
    end
    if buffText ~= "" then
        local buffLabel = Instance.new("TextLabel")
        buffLabel.Size = UDim2.new(1, -10, 0, 15)
        buffLabel.Position = UDim2.new(0, 5, 0, 25)
        buffLabel.BackgroundTransparency = 1
        buffLabel.Text = buffText
        buffLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        buffLabel.TextXAlignment = Enum.TextXAlignment.Left
        buffLabel.Font = Enum.Font.Gotham
        buffLabel.Parent = button
    end
    
    -- Кнопка выбора (для мержа)
    local selectCheckbox = Instance.new("ImageButton")
    selectCheckbox.Name = "SelectCheckbox"
    selectCheckbox.Size = UDim2.new(0, 25, 0, 25)
    selectCheckbox.Position = UDim2.new(1, -35, 0.5, -12)
    selectCheckbox.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    selectCheckbox.Image = "rbxassetid://0"  -- Пустая галочка
    selectCheckbox.Parent = button
    
    local selected = false
    selectCheckbox.MouseButton1Click:Connect(function()
        selected = not selected
        selectCheckbox.Image = selected and "rbxassetid://0" or "rbxassetid://0"  -- TODO: иконки галочки
        button.BackgroundColor3 = selected and Color3.fromRGB(0, 100, 150) or Color3.fromRGB(40, 40, 50)
    end)
    
    return button, {selectCheckbox = selectCheckbox, selected = selected}
end

-- ============================================
-- ПУБЛИЧНЫЕ ФУНКЦИИ
-- ============================================

-- Обновить отображение стека карточек
function SoulStackUI.UpdateSoulStack(soulStack: table)
    if not panel then
        CreateSoulStackPanel()
    end
    
    -- Очищаем старые кнопки
    for _, btn in pairs(cardButtons) do
        btn:Destroy()
    end
    cardButtons = {}
    
    local scrollFrame = panel:FindFirstChild("ScrollFrame")
    if not scrollFrame then return end
    
    -- Создаем новые карточки
    local yOffset = 0
    for cardId, card in pairs(soulStack) do
        local button, _ = CreateCardButton(cardId, card.UnitTypeId, card.Modifiers)
        button.Parent = scrollFrame
        cardButtons[cardId] = button
        yOffset = yOffset + 65
    end
    
    -- Обновляем размер Canvas
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(yOffset, 400))
end

-- Получить выбранные карточки
function SoulStackUI.GetSelectedCards(): { string }
    local selected = {}
    for cardId, button in pairs(cardButtons) do
        local selectCheckbox = button:FindFirstChild("SelectCheckbox")
        if selectCheckbox and selectCheckbox.Image == "rbxassetid://0" then  -- TODO: проверка на выделение
            table.insert(selected, cardId)
        end
    end
    return selected
end

-- Очистить выделение
function SoulStackUI.ClearSelection()
    for cardId, button in pairs(cardButtons) do
        local selectCheckbox = button:FindFirstChild("SelectCheckbox")
        if selectCheckbox then
            selectCheckbox.Image = "rbxassetid://0"
            button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        end
    end
end

-- Показать/скрыть панель
function SoulStackUI.SetVisible(visible: boolean)
    if panel then
        panel.Visible = visible
    end
    isVisible = visible
end

function SoulStackUI.IsVisible(): boolean
    return isVisible
end

-- Инициализация
function SoulStackUI.Init()
    print("[SoulStackUI] 📇 Инициализация стека карточек")
    CreateSoulStackPanel()
    SoulStackUI.SetVisible(true)
    print("[SoulStackUI] ✅ Готов")
end

return SoulStackUI