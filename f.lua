if not game:IsLoaded() then game.Loaded:Wait() end

-- [[ services ]]
local players = game:GetService("Players")
local runservice = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local tweenservice = game:GetService("TweenService")

-- [[ ui setup - Obsidian Library ]]
local Repository = "https://raw.githubuserDescription.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(Repository .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repository .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repository .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- [[ system variables ]]
local staminaenabled = false
local staminaconnection = nil

-- [[ generator system ]]
local autocompleteenabled = false
local completiondelay = 1
local currentgenerator = nil
local generatorconnection = nil
local puzzleuiconnection = nil
local iscompletinggenerator = false
local lastcompletiontime = 0
local completioncooldown = 2.5

-- [[ fov system ]]
local fovenabled = true
local originalfov = 80

-- [[ esp system ]]
local espobjects = {}
local espenabled = false

-- [[ ui initialization - Obsidian Style ]]
local ScriptVersion = "v1.0.0"
local Window = Library:CreateWindow({
    Title = "BunnyHub", 
    Icon = nil, 
    Footer = ScriptVersion, 
    Center = true, 
    AutoShow = true, 
    Size = UDim2.fromOffset(750, 550)
})

local Tabs = {
    Main = Window:AddTab("Main", "house"),
    Visuals = Window:AddTab("Visuals", "scan-eye"),
    Config = Window:AddTab("Config", "folder-cog")
}

-- [[ Main Tab ]]
local MainCharacter = Tabs.Main:AddLeftGroupbox("Character Modifications")
MainCharacter:AddToggle("MC_InfiniteStamina", { 
    Text = "Infinite Stamina", 
    Default = false, 
    Tooltip = "Provides unlimited stamina for sprinting." 
})

local MainUtility = Tabs.Main:AddRightGroupbox("Utility")
MainUtility:AddLabel("Walkspeed Cancel"):AddKeyPicker("MM_WalkspeedCancel", { 
    Default = "C", 
    NoUI = false, 
    Text = "Spawn cancel wall" 
})

-- Add Side Walls toggle to Utility groupbox
MainUtility:AddToggle("MS_SideWalls", { 
    Text = "Side Walls", 
    Default = false, 
    Tooltip = "Spawns collision walls on your left and right sides." 
})

-- Add invisibility sub-toggle
local MS_SideWalls_Invisible = MainUtility:AddDependencyBox()
MS_SideWalls_Invisible:AddToggle("MS_SideWallsInvisible", { 
    Text = "Invisible Walls", 
    Default = false, 
    Tooltip = "Makes the side walls invisible but keeps collision." 
})
MS_SideWalls_Invisible:SetupDependencies({ { Toggles.MS_SideWalls, true } })

local MainGenerator = Tabs.Main:AddLeftGroupbox("Generator Automation")
MainGenerator:AddToggle("MG_AutoComplete", { 
    Text = "Auto-Complete Generators", 
    Default = false, 
    Tooltip = "Automatically completes generator puzzles." 
})

local MG_AutoComplete_True = MainGenerator:AddDependencyBox()
MG_AutoComplete_True:AddSlider("MG_CompletionDelay", { 
    Text = "Completion Delay", 
    Default = 2.5, 
    Min = 2.5, 
    Max = 8, 
    Rounding = 0.5, 
    Compact = true,
    Suffix = "s"
})
MG_AutoComplete_True:SetupDependencies({ { Toggles.MG_AutoComplete, true } })

-- [[ Side Walls Feature ]]
local sideWallsEnabled = false
local invisibleWalls = false
local leftWall = nil
local rightWall = nil

local function updateSideWalls()
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    -- Remove existing walls
    if leftWall then leftWall:Destroy() leftWall = nil end
    if rightWall then rightWall:Destroy() rightWall = nil end
    
    if sideWallsEnabled then
        local humanoidRootPart = character.HumanoidRootPart
        
        -- Calculate positions in studs to left and right of player
        local rightPosition = humanoidRootPart.Position + (humanoidRootPart.CFrame.RightVector * 3)
        local leftPosition = humanoidRootPart.Position + (humanoidRootPart.CFrame.RightVector * -3)
        
        -- Create right wall
        rightWall = Instance.new("Part")
        rightWall.Name = "RightSideWall"
        rightWall.Size = Vector3.new(1, 6, 1) -- Thin but tall
        rightWall.Position = rightPosition
        rightWall.Anchored = true
        rightWall.CanCollide = true
        rightWall.Material = Enum.Material.ForceField
        rightWall.Color = Color3.fromRGB(0, 100, 255)
        
        -- Create left wall  
        leftWall = Instance.new("Part")
        leftWall.Name = "LeftSideWall"
        leftWall.Size = Vector3.new(1, 6, 1) -- Thin but tall
        leftWall.Position = leftPosition
        leftWall.Anchored = true
        leftWall.CanCollide = true
        leftWall.Material = Enum.Material.ForceField
        leftWall.Color = Color3.fromRGB(0, 100, 255)
        
        -- Apply invisibility setting
        if invisibleWalls then
            rightWall.Transparency = 1
            leftWall.Transparency = 1
        else
            rightWall.Transparency = 0.3
            leftWall.Transparency = 0.3
        end
        
        rightWall.Parent = workspace
        leftWall.Parent = workspace
        
        Library:Notify({
            Title = "Side Walls",
            Description = "Collision walls spawned" .. (invisibleWalls and " (invisible)" or ""),
            Time = 2
        })
    else
        Library:Notify({
            Title = "Side Walls", 
            Description = "Side walls removed",
            Time = 2
        })
    end
end

-- Connect the toggle
Toggles.MS_SideWalls:OnChanged(function(value)
    sideWallsEnabled = value
    updateSideWalls()
end)

-- Connect the toggles
Toggles.MS_SideWalls:OnChanged(function(value)
    sideWallsEnabled = value
    updateSideWalls()
end)

Toggles.MS_SideWallsInvisible:OnChanged(function(value)
    invisibleWalls = value
    if sideWallsEnabled then
        -- Update transparency of existing walls
        if leftWall then leftWall.Transparency = value and 1 or 0.3 end
        if rightWall then rightWall.Transparency = value and 1 or 0.3 end
        
        Library:Notify({
            Title = "Side Walls",
            Description = value and "Walls are now invisible" or "Walls are now visible",
            Time = 2
        })
    end
end)

-- Update walls when player moves (keeps walls at correct positions and rotation)
local wallsConnection = runservice.Heartbeat:Connect(function()
    if sideWallsEnabled and character and character:FindFirstChild("HumanoidRootPart") then
        local humanoidRootPart = character.HumanoidRootPart
        
        if leftWall then
            local leftPosition = humanoidRootPart.Position + (humanoidRootPart.CFrame.RightVector * -2)
            leftWall.Position = leftPosition
            leftWall.CFrame = CFrame.lookAt(leftPosition, humanoidRootPart.Position) -- Face player
        end
        
        if rightWall then
            local rightPosition = humanoidRootPart.Position + (humanoidRootPart.CFrame.RightVector * 2)
            rightWall.Position = rightPosition
            rightWall.CFrame = CFrame.lookAt(rightPosition, humanoidRootPart.Position) -- Face player
        end
    end
end)

-- [[ Walkspeed Cancel function ]]
local function createCancelWall()
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local humanoidRootPart = character.HumanoidRootPart
    local lookVector = humanoidRootPart.CFrame.LookVector
    local spawnPosition = humanoidRootPart.Position + (lookVector * 4) -- 4 studs in front
    
    -- Create the wall
    local wall = Instance.new("Part")
    wall.Name = "WalkspeedCancelWall"
    wall.Size = Vector3.new(10, 10, 1) -- Wide and tall, but thin
    wall.Position = spawnPosition

    -- Make wall face the player
    wall.CFrame = CFrame.lookAt(spawnPosition, humanoidRootPart.Position)

    wall.Anchored = true
    wall.CanCollide = true
    wall.Transparency = 0.3
    wall.Material = Enum.Material.ForceField
    wall.Color = Color3.fromRGB(0, 100, 255)
    wall.Parent = workspace
    
    -- Create a sparkle effect
    local sparkles = Instance.new("Sparkles")
    sparkles.SparkleColor = Color3.new(1, 1, 1)
    sparkles.Parent = wall
    
    -- Auto-destroy after half a second
    task.delay(0.5, function()
        if wall and wall.Parent then
            wall:Destroy()
        end
    end)
    
    Library:Notify({
        Title = "Walkspeed Cancel",
        Description = "Temporary wall spawned for 0.5 seconds",
        Time = 2
    })
end

-- Connect the keybind
Options.MM_WalkspeedCancel:OnClick(function()
    createCancelWall()
end)

Options.MM_WalkspeedCancel:OnChanged(function()
    createCancelWall()
end)

-- [[ Visuals Tab ]]
local VisualsESP = Tabs.Visuals:AddLeftGroupbox("ESP Settings")
VisualsESP:AddToggle("VE_EnableESP", { 
    Text = "Enable ESP", 
    Default = false, 
    Tooltip = "Shows visual indicators for players, generators, and items." 
})

local VisualsFOV = Tabs.Visuals:AddRightGroupbox("Field of View")
VisualsFOV:AddToggle("VF_CustomFOV", { 
    Text = "Custom FOV", 
    Default = false, 
    Tooltip = "Override the default field of view." 
})

local VF_CustomFOV_True = VisualsFOV:AddDependencyBox()
VF_CustomFOV_True:AddSlider("VF_FOVValue", { 
    Text = "Field Of View", 
    Default = 70, 
    Min = 70, 
    Max = 120, 
    Rounding = 0, 
    Compact = true,
    Suffix = "°"
})
VF_CustomFOV_True:SetupDependencies({ { Toggles.VF_CustomFOV, true } })

-- [[ esp management ]]
local function createesp(object, color, name)
    if espobjects[object] then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "BunnyHubESP"
    highlight.Adornee = object
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = game.CoreGui
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BunnyHubLabel"
    billboard.Adornee = object
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = game.CoreGui
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = color
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard
    
    espobjects[object] = {highlight = highlight, billboard = billboard, type = name}
end

local function removeesp(object)
    if espobjects[object] then
        if espobjects[object].highlight then espobjects[object].highlight:Destroy() end
        if espobjects[object].billboard then espobjects[object].billboard:Destroy() end
        espobjects[object] = nil
    end
end

local function clearesp()
    for object, esp in pairs(espobjects) do
        removeesp(object)
    end
end

-- [[ player esp ]]
local function updateplayeresp()
    if not espenabled then return end
    
    -- Killers
    local killersfolder = workspace:FindFirstChild("Players")
    if killersfolder and killersfolder:FindFirstChild("Killers") then
        for _, killer in pairs(killersfolder.Killers:GetChildren()) do
            if killer:IsA("Model") then
                -- Highlight the entire model, not just rootpart
                if not espobjects[killer] then
                    createesp(killer, Color3.fromRGB(255, 0, 0), "Killer")
                end
            end
        end
    end
    
    -- Survivors
    local survivorsfolder = workspace:FindFirstChild("Players")
    if survivorsfolder and survivorsfolder:FindFirstChild("Survivors") then
        for _, survivor in pairs(survivorsfolder.Survivors:GetChildren()) do
            if survivor:IsA("Model") then
                -- Highlight the entire model, not just rootpart
                if not espobjects[survivor] then
                    createesp(survivor, Color3.fromRGB(0, 255, 0), "Survivor")
                end
            end
        end
    end
end

-- [[ item esp ]]
local function updateitemesp()
    if not espenabled then return end
    
    -- Check if map exists
    local mapfolder = workspace:FindFirstChild("Map")
    if not mapfolder then return end
    local ingame = mapfolder:FindFirstChild("Ingame") 
    if not ingame then return end
    local map = ingame:FindFirstChild("Map")
    if not map then return end
    
    -- Clear existing item ESP first
    for object, esp in pairs(espobjects) do
        if esp.type == "BloxyCola" or esp.type == "Medkit" then
            removeesp(object)
        end
    end
    
    -- Look for actual spawned tools, not spawn parts
    for _, item in pairs(map:GetChildren()) do
        if item:IsA("Tool") then
            if item.Name == "BloxyCola" then
                -- Highlight the entire tool
                createesp(item, Color3.fromRGB(0, 162, 255), "BloxyCola")
            elseif item.Name == "Medkit" then
                -- Highlight the entire tool
                createesp(item, Color3.fromRGB(0, 255, 0), "Medkit")
            end
        end
    end
end

-- [[ generator esp ]]
local function updategeneratoresp()
    if not espenabled then return end
    
    -- Check if map exists
    local mapfolder = workspace:FindFirstChild("Map")
    if not mapfolder then return end
    local ingame = mapfolder:FindFirstChild("Ingame")
    if not ingame then return end
    local map = ingame:FindFirstChild("Map")
    if not map then return end
    
    local generators = map:GetChildren()
    
    for _, generatormodel in pairs(generators) do
        if generatormodel.Name == "Generator" and generatormodel:IsA("Model") then
            local progress = generatormodel:FindFirstChild("Progress")
            
            if progress and progress:IsA("NumberValue") then
                if progress.Value < 100 then
                    local color
                    if progress.Value == 0 then color = Color3.fromRGB(255, 50, 50)
                    elseif progress.Value == 26 then color = Color3.fromRGB(255, 150, 50)
                    elseif progress.Value == 52 then color = Color3.fromRGB(255, 255, 50)
                    elseif progress.Value == 78 then color = Color3.fromRGB(150, 255, 50) end
                    
                    if not espobjects[generatormodel] then
                        createesp(generatormodel, color, "Generator (" .. progress.Value .. "/4)")
                        espobjects[generatormodel].isgenerator = true
                    else
                        if espobjects[generatormodel].highlight then
                            espobjects[generatormodel].highlight.FillColor = color
                            espobjects[generatormodel].highlight.OutlineColor = color
                        end
                        if espobjects[generatormodel].billboard then
                            espobjects[generatormodel].billboard.TextLabel.Text = "Generator (" .. progress.Value .. "/4)"
                        end
                    end
                else
                    if espobjects[generatormodel] then removeesp(generatormodel) end
                end
            end
        end
    end
end

-- [[ esp update ]]
local function updateesp()
    if not espenabled then 
        clearesp()
        return 
    end
    
    -- Clean up removed objects
    for object, esp in pairs(espobjects) do
        if not object or not object.Parent then
            removeesp(object)
        end
    end
    
    -- Update all ESP types (they handle their own map checks)
    updateplayeresp()
    updategeneratoresp()
    updateitemesp()
end

-- [[ generator completion ]]
local function findcurrentgenerator()
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local playerpos = character.HumanoidRootPart.Position
    local closestgenerator = nil
    local closestdistance = math.huge
    
    local generators = workspace.Map.Ingame.Map:GetChildren()
    
    for _, generatormodel in pairs(generators) do
        if generatormodel.Name == "Generator" and generatormodel:IsA("Model") then
            local mainpart = generatormodel.PrimaryPart or generatormodel:FindFirstChildWhichIsA("BasePart")
            if mainpart then
                local distance = (playerpos - mainpart.Position).Magnitude
                if distance < closestdistance and distance < 15 then
                    closestdistance = distance
                    closestgenerator = generatormodel
                end
            end
        end
    end
    
    return closestgenerator
end

local function completecurrentpuzzle()
    if not autocompleteenabled then return end
    if iscompletinggenerator then return end
    
    local puzzleui = player.PlayerGui:FindFirstChild("PuzzleUI")
    if not puzzleui or not puzzleui.Enabled then return end
    
    if tick() - lastcompletiontime < completioncooldown then return end
    
    local generator = findcurrentgenerator()
    if not generator then return end
    
    local progress = generator:FindFirstChild("Progress")
    if not progress or not progress:IsA("NumberValue") then return end
    
    local currentprogress = progress.Value
    if currentprogress >= 104 then return end
    
    local remotes = generator:FindFirstChild("Remotes")
    if not remotes then return end
    
    local rereomote = remotes:FindFirstChild("RE")
    if not rereomote then return end
    
    local completionsneeded = 4 - math.floor(currentprogress / 26)
    if completionsneeded <= 0 then return end
    
    iscompletinggenerator = true
    lastcompletiontime = tick()
    
    task.spawn(function()
        for i = 1, completionsneeded do
            task.wait(completiondelay)
            
            local success, err = pcall(function() 
                rereomote:FireServer()
            end)
            
            if not success then
                warn("Generator completion error: " .. tostring(err))
            end
        end
        
        iscompletinggenerator = false
        
        -- Get final progress after all completions
        local finalprogress = progress.Value
        Library:Notify({
            Title = "Generator Completed", 
            Description = "Progress: " .. currentprogress .. " → " .. finalprogress .. "/104", 
            Time = 3
        })
    end)
end

-- [[ puzzle detection ]]
local function setuppuzzledetection()
    if puzzleuiconnection then 
        puzzleuiconnection:Disconnect() 
        puzzleuiconnection = nil 
    end
    
    puzzleuiconnection = runservice.Heartbeat:Connect(function()
        if not autocompleteenabled then return end
        if iscompletinggenerator then return end
        
        local puzzleui = player.PlayerGui:FindFirstChild("PuzzleUI")
        if puzzleui and puzzleui.Enabled then 
            completecurrentpuzzle() 
        end
    end)
end

-- [[ fov control ]]
local function updatefov(value)
    if not fovenabled then return end
    
    local success, result = pcall(function()
        local playerdata = player.PlayerData
        if playerdata and playerdata.Settings and playerdata.Settings.Game then
            local fieldofview = playerdata.Settings.Game.FieldOfView
            fieldofview.Value = value
            fieldofview:SetAttribute("MaxValue", 120)
        end
    end)
end

-- [[ toggle callbacks ]]
Toggles.MC_InfiniteStamina:OnChanged(function(value)
    staminaenabled = value
    if value then
        staminaconnection = runservice.Heartbeat:Connect(function()
            pcall(function() require(game.ReplicatedStorage.Systems.Character.Game.Sprinting).StaminaLossDisabled = true end)
        end)
        Library:Notify({Title = "Infinite Stamina Enabled", Description = "You now have unlimited stamina", Time = 3})
    else
        if staminaconnection then staminaconnection:Disconnect() staminaconnection = nil end
        pcall(function() require(game.ReplicatedStorage.Systems.Character.Game.Sprinting).StaminaLossDisabled = false end)
        Library:Notify({Title = "Infinite Stamina Disabled", Description = "Stamina consumption is now normal", Time = 3})
    end
end)

Toggles.MG_AutoComplete:OnChanged(function(value)
    autocompleteenabled = value
    if value then
        setuppuzzledetection()
        Library:Notify({Title = "Auto-Complete Enabled", Description = "Generators will complete automatically", Time = 3})
    else
        if puzzleuiconnection then puzzleuiconnection:Disconnect() puzzleuiconnection = nil end
        Library:Notify({Title = "Auto-Complete Disabled", Description = "Manual generator completion required", Time = 3})
    end
end)

Options.MG_CompletionDelay:OnChanged(function(value)
    completiondelay = value
end)

Toggles.VE_EnableESP:OnChanged(function(value)
    espenabled = value
    if not value then 
        clearesp()
    end
    Library:Notify({Title = "ESP " .. (value and "Enabled" or "Disabled"), Description = "Visual indicators are now " .. (value and "visible" or "hidden"), Time = 3})
end)

Toggles.VF_CustomFOV:OnChanged(function(value)
    fovenabled = value
    if not value then 
        updatefov(originalfov) 
    else
        updatefov(Options.VF_FOVValue.Value)
    end
    Library:Notify({Title = "Custom FOV " .. (value and "Enabled" or "Disabled"), Description = value and "FOV controls active" or "FOV reset to default", Time = 3})
end)

Options.VF_FOVValue:OnChanged(function(value)
    if fovenabled then 
        updatefov(value) 
    end
end)

-- [[ config tab setup ]]
task.spawn(function()
    -- Apply custom UI styling like your friend's script
    Library.ScreenGui.Main.ScrollingFrame.Transparency = 0.3
    Library.ScreenGui.Main.Container.Transparency = 0.8
    Library.ScreenGui.Main.Transparency = 0.7
    for _, v in Library.ScreenGui.Main:GetChildren() do
        if not (v:IsA("Frame") and v:FindFirstChild("UICorner") and v:FindFirstChild("Frame") and v.Frame:FindFirstChild("UICorner")) then continue end
        v.Transparency = 0.3
        v.Frame.Transparency = 0.75
    end

    Library:SetWatermarkVisibility(true)
    Library:SetWatermark(`[ {ScriptVersion} ] BunnyHub `)
    Library.ShowCustomCursor = false

    local MenuProperties = Tabs.Config:AddLeftGroupbox("Menu")
    MenuProperties:AddButton("Unload", function()
        Library:Unload()
        
        -- Cleanup connections
        if staminaconnection then staminaconnection:Disconnect() end
        if puzzleuiconnection then puzzleuiconnection:Disconnect() end
        if espconnection then espconnection:Disconnect() end
        if wallsConnection then wallsConnection:Disconnect() end
        
        clearesp()
    end)

    MenuProperties:AddLabel("Menu bind"):AddKeyPicker("MP_MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
    MenuProperties:AddDivider()
    MenuProperties:AddToggle("MP_ShowKeybinds", { Text = "Show Keybinds", Default = false })

    Toggles.MP_ShowKeybinds:OnChanged(function()
        Library.KeybindFrame.Visible = Toggles.MP_ShowKeybinds.Value
    end)

    Library.ToggleKeybind = Options.MP_MenuKeybind

    -- Theme setup
    local BreweryTheme = {
        BackgroundColor = Color3.fromRGB(15, 15, 15),
        OutlineColor = Color3.fromRGB(40, 40, 40),
        MainColor = Color3.fromRGB(25, 25, 25),
        AccentColor = Color3.new(0.8, 0.2, 0.8), -- Purple accent for Brewery
        FontColor = Color3.new(1, 1, 1),
        FontFace = "BuilderSans"
    }

    ThemeManager:SetLibrary(Library)
    ThemeManager:SetFolder("Brewery/Themes")
    ThemeManager:SetDefaultTheme(BreweryTheme)
    ThemeManager:ApplyToTab(Tabs.Config)
    ThemeManager:ThemeUpdate()

    SaveManager:SetLibrary(Library)
    SaveManager:SetFolder("Brewery/SANDBOX")
    SaveManager:BuildConfigSection(Tabs.Config)
    SaveManager:IgnoreThemeSettings()
    SaveManager:LoadAutoloadConfig()
end)

-- [[ main loops ]]
local espconnection = runservice.Heartbeat:Connect(updateesp)

-- [[ respawn handling ]]
player.CharacterAdded:Connect(function(newcharacter) 
    character = newcharacter 
    repeat runservice.Heartbeat:Wait() until character:FindFirstChild("HumanoidRootPart") 
end)

-- [[ initial notification ]]
Library:Notify({Title = "BunnyHub" .. ScriptVersion .. " Loaded", Description = "All features are now active!", Time = 6})
