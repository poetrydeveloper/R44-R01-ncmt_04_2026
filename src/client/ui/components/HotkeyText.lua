-- src/ui/components/HotkeyText.lua
-- Компонент: текст с хоткеями

local HotkeyText = {}

function HotkeyText.New(parent: Instance)
    local text = Instance.new("TextLabel")
    text.Name = "HotkeyText"
    text.Size = UDim2.new(0, 200, 0, 20)
    text.Position = UDim2.new(1, -210, 1, -25)
    text.BackgroundTransparency = 1
    text.Text = "[C] Куб  [M] Слияние  [H] Скрыть стек"
    text.TextColor3 = Color3.fromRGB(150, 150, 150)
    text.TextSize = 12
    text.Font = Enum.Font.Gotham
    text.TextXAlignment = Enum.TextXAlignment.Right
    text.Parent = parent
    
    return text
end

return HotkeyText