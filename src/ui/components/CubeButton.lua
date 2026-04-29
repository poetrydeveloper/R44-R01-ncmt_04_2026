-- src/ui/components/CubeButton.lua
-- Компонент: кнопка входа в куб

local CubeButton = {}

local function Create(parent: Instance)
    local button = Instance.new("ImageButton")
    button.Name = "CubeButton"
    button.Size = UDim2.new(0, 140, 0, 55)
    button.Position = UDim2.new(0.5, -70, 1, -80)
    button.BackgroundColor3 = Color3.fromRGB(0, 120, 180)
    button.BorderSizePixel = 0
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button
    
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 35, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "🧊"
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.TextScaled = true
    icon.Font = Enum.Font.GothamBold
    icon.Parent = button
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Position = UDim2.new(0, 40, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "ВОЙТИ В КУБ"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = button
    
    local cooldownText = Instance.new("TextLabel")
    cooldownText.Name = "CooldownText"
    cooldownText.Size = UDim2.new(1, 0, 1, 0)
    cooldownText.BackgroundTransparency = 1
    cooldownText.Text = ""
    cooldownText.TextColor3 = Color3.fromRGB(255, 200, 0)
    cooldownText.TextScaled = true
    cooldownText.Font = Enum.Font.GothamBold
    cooldownText.Visible = false
    cooldownText.Parent = button
    
    return {
        Button = button,
        Label = label,
        CooldownText = cooldownText,
    }
end

function CubeButton.New(parent: Instance, onClick: () -> ())
    local self = {}
    self.components = Create(parent)
    self.Active = false
    
    if onClick then
        self.components.Button.MouseButton1Click:Connect(onClick)
    end
    
    function self.Update(canEnter: boolean, cooldownRemaining: number)
        if cooldownRemaining > 0 then
            self.components.Button.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            self.components.Label.Text = "КУЛДАУН"
            self.components.CooldownText.Visible = true
            self.components.CooldownText.Text = `${math.ceil(cooldownRemaining)} сек`
            self.Active = false
        else
            self.components.Button.BackgroundColor3 = canEnter and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(80, 80, 100)
            self.components.Label.Text = canEnter and "ВОЙТИ В КУБ" or "НЕТ МАНЫ"
            self.components.CooldownText.Visible = false
            self.Active = canEnter
        end
    end
    
    function self.IsActive(): boolean
        return self.Active
    end
    
    function self.Click()
        if self.Active then
            self.components.Button:Click()
        end
    end
    
    return self
end

return CubeButton