-- src/ui/components/CraftingButton.lua
-- Компонент: кнопка открытия меню слияния

local CraftingButton = {}

function CraftingButton.New(parent: Instance, onClick: () -> ())
    local button = Instance.new("ImageButton")
    button.Name = "CraftingButton"
    button.Size = UDim2.new(0, 50, 0, 50)
    button.Position = UDim2.new(1, -65, 1, -80)
    button.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
    button.BorderSizePixel = 0
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "🔮"
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.TextScaled = true
    icon.Font = Enum.Font.GothamBold
    icon.Parent = button
    
    if onClick then
        button.MouseButton1Click:Connect(onClick)
    end
    
    return button
end

return CraftingButton