local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "War Tycoon Hub | تم صنعه من قبل متجر GR المتخصص للسكربتات",
   LoadingTitle = "جاري التحميل...",
   LoadingSubtitle = "RGB المتحرك - متجر GR",
   ConfigurationSaving = { Enabled = false },
   Discord = { Enabled = false },
   KeySystem = false,
   Theme = "Default"
})

-- الخدمات الأساسية
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

---------------------------------------------------------
-- نظام ألوان RGB المتحرك (Dynamic Rainbow / RGB System)
---------------------------------------------------------
local CurrentRGB = Color3.fromRGB(255, 0, 0)
task.spawn(function()
    local hue = 0
    while task.wait(0.03) do
        hue = (hue + 0.008) % 1
        CurrentRGB = Color3.fromHSV(hue, 0.85, 1)
        
        -- تطبيق ألوان RGB المتحركة على الـ FOV ونقطة الايم والهيتبوكس
        pcall(function()
            if FOVCircle then FOVCircle.Color = CurrentRGB end
            if CenterDot then CenterDot.Color = CurrentRGB end
        end)
    end
end)

---------------------------------------------------------
-- 1. تبويب الميزات القتالية والهيتبوكس (Combat & Hitbox)
---------------------------------------------------------
local CombatTab = Window:CreateTab("الميزات القتالية", 4483362458)

-- تكبير الهيتبوكس (Hitbox Expander)
local HitboxEnabled = false
local HitboxSize = 10
local HitboxTransparency = 0.6

CombatTab:CreateToggle({
   Name = "تفعيل تكبير الهيتبوكس (Hitbox)",
   CurrentValue = false,
   Flag = "HitboxToggle",
   Callback = function(Value)
       HitboxEnabled = Value
       if not Value then
           for _, p in ipairs(Players:GetPlayers()) do
               if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                   p.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                   p.Character.HumanoidRootPart.Transparency = 1
               end
           end
       end
   end,
})

CombatTab:CreateSlider({
   Name = "حجم الهيتبوكس (Hitbox Size)",
   Range = {2, 70},
   Increment = 1,
   Suffix = "Size",
   CurrentValue = 10,
   Flag = "HitboxSizeSlider",
   Callback = function(Value)
       HitboxSize = Value
   end,
})

task.spawn(function()
    while task.wait(0.5) do
        if HitboxEnabled then
            pcall(function()
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local root = p.Character.HumanoidRootPart
                        root.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                        root.Transparency = HitboxTransparency
                        root.Color = CurrentRGB
                        root.Material = Enum.Material.ForceField
                        root.CanCollide = false
                    end
                end
            end)
        end
    end
end)

-- نقطة التصويب وسط الشاشة (Crosshair Dot)
local CenterDotEnabled = false
local CenterDot = Drawing.new("Circle")
CenterDot.Visible = false
CenterDot.Radius = 3.5
CenterDot.Thickness = 1.5
CenterDot.Filled = true
CenterDot.Transparency = 1

CombatTab:CreateToggle({
   Name = "تفعيل نقطة الايم وسط الشاشة (RGB)",
   CurrentValue = false,
   Flag = "CenterDotToggle",
   Callback = function(Value)
       CenterDotEnabled = Value
       CenterDot.Visible = Value
   end,
})

RunService.RenderStepped:Connect(function()
    if CenterDotEnabled then
        local viewportSize = Camera.ViewportSize
        CenterDot.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    end
end)

-- كشف اللاعبين عبر الجدران (ESP)
local ESPEnabled = false

local function applyESP(player)
    if player == LocalPlayer then return end
    local function setupHighlight(character)
        if not character then return end
        if not character:FindFirstChild("CustomESP") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "CustomESP"
            highlight.Adornee = character
            highlight.FillColor = CurrentRGB
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.4
            highlight.Enabled = ESPEnabled
            highlight.Parent = character
            
            task.spawn(function()
                while highlight and highlight.Parent do
                    highlight.FillColor = CurrentRGB
                    task.wait(0.1)
                end
            end)
        end
    end
    if player.Character then setupHighlight(player.Character) end
    player.CharacterAdded:Connect(setupHighlight)
end

for _, p in ipairs(Players:GetPlayers()) do applyESP(p) end
Players.PlayerAdded:Connect(applyESP)

CombatTab:CreateToggle({
   Name = "كشف اللاعبين عبر الجدران (ESP RGB)",
   CurrentValue = false,
   Flag = "ESPToggle",
   Callback = function(Value)
       ESPEnabled = Value
       for _, p in ipairs(Players:GetPlayers()) do
           if p.Character and p.Character:FindFirstChild("CustomESP") then
               p.Character.CustomESP.Enabled = Value
           end
       end
   end,
})

-- الايم بوت (Smooth Aimbot)
local AimbotEnabled = false
local AimPart = "Head"
local FOVEnabled = false
local FOVRadius = 150
local AimSmoothness = 0.25

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Radius = FOVRadius
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Transparency = 0.8

local function getClosestTarget()
    local target = nil
    local shortestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local part = player.Character:FindFirstChild(AimPart)
            
            if humanoid and humanoid.Health > 0 and part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDistance then
                        if not FOVEnabled or dist <= FOVRadius then
                            shortestDistance = dist
                            target = part
                        end
                    end
                end
            end
        end
    end
    return target
end

CombatTab:CreateToggle({
   Name = "تفعيل الايم بوت (Aimbot)",
   CurrentValue = false,
   Flag = "AimbotToggle",
   Callback = function(Value)
       AimbotEnabled = Value
   end,
})

CombatTab:CreateDropdown({
   Name = "تحديد نقطة الايم",
   Options = {"Head", "HumanoidRootPart"},
   CurrentOption = "Head",
   Flag = "AimPartDropdown",
   Callback = function(Option)
       AimPart = Option
   end,
})

CombatTab:CreateSlider({
   Name = "سلاسة الايم (Aimbot Smoothness)",
   Range = {1, 10},
   Increment = 1,
   Suffix = "Smooth",
   CurrentValue = 4,
   Flag = "AimSmoothSlider",
   Callback = function(Value)
       AimSmoothness = Value / 16
   end,
})

CombatTab:CreateToggle({
   Name = "تفعيل دائرة الايم المتحركة (RGB FOV)",
   CurrentValue = false,
   Flag = "FOVToggle",
   Callback = function(Value)
       FOVEnabled = Value
       FOVCircle.Visible = Value
   end,
})

CombatTab:CreateSlider({
   Name = "حجم دائرة الايم",
   Range = {50, 600},
   Increment = 10,
   Suffix = "px",
   CurrentValue = 150,
   Flag = "FOVSlider",
   Callback = function(Value)
       FOVRadius = Value
       FOVCircle.Radius = Value
   end,
})

RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = mousePos

    if AimbotEnabled then
        local targetPart = getClosestTarget()
        if targetPart then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPart.Position), AimSmoothness)
        end
    end
end)

---------------------------------------------------------
-- 2. تبويب الحركة والطيران (Movement & Physics)
---------------------------------------------------------
local MoveTab = Window:CreateTab("الحركة والطيران", 4483362458)

local flying = false
local flySpeed = 50
local flyBV, flyBG

MoveTab:CreateToggle({
   Name = "تفعيل الطيران (Fly)",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
       flying = Value
       local char = LocalPlayer.Character
       if not char or not char:FindFirstChild("HumanoidRootPart") then return end
       local root = char.HumanoidRootPart
       local hum = char:FindFirstChildOfClass("Humanoid")

       if flying then
           if hum then hum.PlatformStand = true end
           flyBV = Instance.new("BodyVelocity")
           flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
           flyBV.Velocity = Vector3.new(0, 0, 0)
           flyBV.Parent = root

           flyBG = Instance.new("BodyGyro")
           flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
           flyBG.CFrame = Camera.CFrame
           flyBG.Parent = root

           task.spawn(function()
               while flying and char and root.Parent do
                   local moveDir = Vector3.new(0, 0, 0)
                   if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
                   if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
                   if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
                   if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
                   
                   flyBV.Velocity = moveDir * flySpeed
                   flyBG.CFrame = Camera.CFrame
                   task.wait()
               end
               if flyBV then flyBV:Destroy() end
               if flyBG then flyBG:Destroy() end
               if hum then hum.PlatformStand = false end
           end)
       else
           if flyBV then flyBV:Destroy() end
           if flyBG then flyBG:Destroy() end
           if hum then hum.PlatformStand = false end
       end
   end,
})

MoveTab:CreateSlider({
   Name = "سرعة الطيران",
   Range = {10, 400},
   Increment = 5,
   Suffix = "Speed",
   CurrentValue = 50,
   Flag = "FlySpeedSlider",
   Callback = function(Value)
       flySpeed = Value
   end,
})

-- ميزة الاختراق والعبور من الجدران (Noclip)
local NoclipEnabled = false
MoveTab:CreateToggle({
   Name = "تفعيل الاختراق والعبور من الجدران (Noclip)",
   CurrentValue = false,
   Flag = "NoclipToggle",
   Callback = function(Value)
       NoclipEnabled = Value
   end,
})

RunService.Stepped:Connect(function()
    if NoclipEnabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- القفز اللانهائي (Infinite Jump)
local InfiniteJumpEnabled = false
MoveTab:CreateToggle({
   Name = "القفز اللانهائي في الهواء (Infinite Jump)",
   CurrentValue = false,
   Flag = "InfJumpToggle",
   Callback = function(Value)
       InfiniteJumpEnabled = Value
   end,
})

UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState("Jumping") end
    end
end)

MoveTab:CreateSlider({
   Name = "سرعة المشي (WalkSpeed)",
   Range = {16, 300},
   Increment = 2,
   Suffix = "Speed",
   CurrentValue = 16,
   Flag = "WalkSpeedSlider",
   Callback = function(Value)
       pcall(function()
           LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = Value
       end)
   end,
})

MoveTab:CreateSlider({
   Name = "قوة القفز (JumpPower)",
   Range = {50, 400},
   Increment = 5,
   Suffix = "Power",
   CurrentValue = 50,
   Flag = "JumpPowerSlider",
   Callback = function(Value)
       pcall(function()
           LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = Value
       end)
   end,
})

---------------------------------------------------------
-- 3. تبويب الانتقال السريع (Teleport & Bases)
---------------------------------------------------------
local TeleportTab = Window:CreateTab("الانتقال السريع", 4483362458)

TeleportTab:CreateButton({
   Name = "الانتقال إلى أعلى السماء (High Sky Safe Zone)",
   Callback = function()
       pcall(function()
           local root = LocalPlayer.Character.HumanoidRootPart
           root.CFrame = root.CFrame + Vector3.new(0, 600, 0)
       end)
   end,
})

TeleportTab:CreateButton({
   Name = "الانتقال إلى لاعب عشوائي",
   Callback = function()
       pcall(function()
           local allPlayers = Players:GetPlayers()
           local randomPlayer = allPlayers[math.random(1, #allPlayers)]
           if randomPlayer ~= LocalPlayer and randomPlayer.Character and randomPlayer.Character:FindFirstChild("HumanoidRootPart") then
               LocalPlayer.Character.HumanoidRootPart.CFrame = randomPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(3, 2, 3)
           end
       end)
   end,
})

---------------------------------------------------------
-- 4. تبويب الإضافات والميزات العامة (Extra Features)
---------------------------------------------------------
local ExtraTab = Window:CreateTab("إضافات وميزات", 4483362458)

-- إضاءة كاملة (Fullbright)
ExtraTab:CreateToggle({
   Name = "تفعيل إضاءة الخريطة (Fullbright)",
   CurrentValue = false,
   Flag = "FullbrightToggle",
   Callback = function(Value)
       if Value then
           Lighting.Brightness = 2
           Lighting.ClockTime = 14
           Lighting.GlobalShadows = false
           Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
       else
           Lighting.Brightness = 1
           Lighting.GlobalShadows = true
           Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
       end
   end,
})

-- النقر التلقائي (Auto Clicker)
local AutoClickerEnabled = false
ExtraTab:CreateToggle({
   Name = "تفعيل النقر التلقائي (Auto Clicker)",
   CurrentValue = false,
   Flag = "AutoClickerToggle",
   Callback = function(Value)
       AutoClickerEnabled = Value
   end,
})

task.spawn(function()
    while task.wait(0.04) do
        if AutoClickerEnabled then
            pcall(function()
                mouse1click()
            end)
        end
    end
end)

-- تسريع المركبات والسيارات (Vehicle Speed Boost)
ExtraTab:CreateButton({
   Name = "تسريع المركبة الحالية (Vehicle Speed Boost)",
   Callback = function()
       pcall(function()
           local seat = LocalPlayer.Character.Humanoid.SeatPart
           if seat and seat.Parent then
               local car = seat.Parent
               if car:IsA("Model") then
                   car:TranslateBy(car.PrimaryPart.CFrame.LookVector * 15)
               end
           end
       end)
   end,
})

-- مجال رؤية الكاميرا (Camera FOV)
ExtraTab:CreateSlider({
   Name = "مجال رؤية الكاميرا (Camera FOV)",
   Range = {70, 120},
   Increment = 1,
   Suffix = "FOV",
   CurrentValue = 70,
   Flag = "CamFOVSlider",
   Callback = function(Value)
       Camera.FieldOfView = Value
   end,
})

ExtraTab:CreateButton({
   Name = "إعادة تعيين الشخصية (Reset Character)",
   Callback = function()
       pcall(function()
           LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health = 0
       end)
   end,
})

ExtraTab:CreateButton({
   Name = "منع السقوط التلقائي (Anti-Fall/Void)",
   Callback = function()
       pcall(function()
           local char = LocalPlayer.Character
           if char and char:FindFirstChild("HumanoidRootPart") then
               char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame + Vector3.new(0, 25, 0)
           end
       end)
   end,
})

-- إشعار التشغيل
Rayfield:Notify({
   Title = "تم تشغيل سكربت متجر GR بنجاح! 🚀",
   Content = "تم صنعه من قبل متجر GR المتخصص للسكربتات. استمتع بالميزات!",
   Duration = 5,
   Image = 4483362458,
})
