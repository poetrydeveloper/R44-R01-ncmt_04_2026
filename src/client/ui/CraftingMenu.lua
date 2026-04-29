-- src/ui/CraftingMenu.lua
-- Окно слияния карточек (мержа)

local CraftingMenu = {}

local menuFrame = nil
local isOpen = false
local currentGui = nil
local SoulStackUI = nil
local NetworkBridge = nil

-- ============================================
-- СОЗДАНИЕ ОКНА
-- ============================================

local function CreateMenu()
    if menuFrame then return menuFrame end
    
    if not currentGui then
        warn("[CraftingMenu] Ошибка: Попытка создания без ScreenGui!")
        return nil
    end
    
    menuFrame = Instance.new("Frame")
    menuFrame.Name = "CraftingMenu"
    menuFrame.Size = UDim2.new(0, 350, 0, 250)
    menuFrame.Position = UDim2.new(0.5, -175, 0.5, -125)
    menuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    menuFrame.BorderSizePixel = 1
    menuFrame.BorderColor3 = Color3.fromRGB(100, 100, 150)
    menuFrame.Visible = false
    menuFrame.Parent = currentGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = menuFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    title.Text = "🔮 Слияние карточек"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.Parent = menuFrame
    
    local instruction = Instance.new("TextLabel")
    instruction.Size = UDim2.new(1, -20, 0, 30)
    instruction.Position = UDim2.new(0, 10, 0, 45)
    instruction.BackgroundTransparency = 1
    instruction.Text = "Выберите 2 или 3 карточки в стеке душ"
    instruction.TextColor3 = Color3.fromRGB(180, 180, 180)
    instruction.TextSize = 14
    instruction.Font = Enum.Font.Gotham
    instruction.Parent = menuFrame
    
    local mergeButton = Instance.new("TextButton")
    mergeButton.Name = "MergeButton"
    mergeButton.Size = UDim2.new(0.4, 0, 0, 40)
    mergeButton.Position = UDim2.new(0.3, 0, 1, -55)
    mergeButton.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
    mergeButton.Text = "✨ СЛИТЬ ✨"
    mergeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    mergeButton.Font = Enum.Font.GothamBold
    mergeButton.TextScaled = true
    mergeButton.Parent = menuFrame
    
    local mergeCorner = Instance.new("UICorner")
    mergeCorner.CornerRadius = UDim.new(0, 8)
    mergeCorner.Parent = mergeButton
    
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextScaled = true
    closeButton.Parent = menuFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    mergeButton.MouseButton1Click:Connect(function()
        if SoulStackUI then
            local selectedCards = SoulStackUI.GetSelectedCards()
            if #selectedCards >= 2 and #selectedCards <= 3 then
                if NetworkBridge then
                    NetworkBridge.RequestMerge(selectedCards)
                end
                SoulStackUI.ClearSelection()
                CraftingMenu.Close()
            else
                print("[CraftingMenu] Нужно выбрать 2 или 3 карточки")
            end
        end
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        CraftingMenu.Close()
    end)
    
    return menuFrame
end

-- ============================================
-- ПУБЛИЧНЫЕ ФУНКЦИИ
-- ============================================

function CraftingMenu.Open()
    if not menuFrame then
        CreateMenu()
    end
    if menuFrame then
        menuFrame.Visible = true
        isOpen = true
        print("[CraftingMenu] 🔮 Окно слияния открыто")
    end
end

function CraftingMenu.Close()
    if menuFrame then
        menuFrame.Visible = false
        isOpen = false
        print("[CraftingMenu] 🔮 Окно слияния закрыто")
    end
end

function CraftingMenu.Toggle()
    if isOpen then
        CraftingMenu.Close()
    else
        CraftingMenu.Open()
    end
end

function CraftingMenu.Init(gui: Instance, soulStackUI: any, networkBridge: any)
    print("[CraftingMenu] 🔮 Инициализация окна слияния")
    currentGui = gui
    SoulStackUI = soulStackUI
    NetworkBridge = networkBridge
    CreateMenu()
    print("[CraftingMenu] ✅ Готов")
end

return CraftingMenu