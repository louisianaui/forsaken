task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end

    print([[                            .
   ___                      __ __     __ 
  / _ )__ _____  ___  __ __/ // /_ __/ / 
 / _  / // / _ \/ _ \/ // / _  / // / _ \
/____/\_,_/_//_/_//_/\_, /_//_/\_,_/_.__/
                    /___/                
.]])
end)

-- [[ services ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tweenservice = game:GetService("TweenService")
local runservice = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local players = game:GetService("Players")
local pathfindingservice = game:GetService("PathfindingService")

-- [[ ui setup - obsidian library ]]
local Repository = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
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

-- [[ performance optimization ]]
local performancesettings = {
    maxespdistance = 200,
    espupdaterate = 0.2,
    cleanupinterval = 5
}
local lastespupdate = 0
local lastcleanup = 0

-- [[ anti systems ]]
local antislowenabled = false
local antiblindnessenabled = false
local antisubspaceenabled = false
local antihiddenstatsenabled = false
local originalstatvalues = {}
local antifootstepsenabled = false

-- [[ combat systems ]]
local hitboxexpanderenabled = false
local hitboxrange = 37
local slashauraenabled = false
local slashaurarange = 7
local silentaimenabled = false
local silentaimtype = "dusekkar"
local autoblockenabled = false
local autoblockdelay = 110
local lastblocktime = 0
local plasmabeamactive = false
local corruptnatureactive = false

-- [[ pathfinding ]]
local pathtaskid = 0

-- [[ network ]]
local networkmodule = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Network")
local networkevent = networkmodule:WaitForChild("RemoteEvent")

-- [[ killer tracking ]]
local killermodel = nil
local issurvivor = false
local iskiller = false

-- [[ animation tracking ]]
local attackanimations = {
    "rbxassetid://131430497821198",
    "rbxassetid://83829782357897",
    "rbxassetid://126830014841198",
    "rbxassetid://126355327951215",
    "rbxassetid://121086746534252",
    "rbxassetid://105458270463374",
    "rbxassetid://127172483138092",
    "rbxassetid://18885919947",
    "rbxassetid://18885909645",
    "rbxassetid://87259391926321",
    "rbxassetid://106014898528300",
    "rbxassetid://86545133269813",
    "rbxassetid://89448354637442",
    "rbxassetid://90499469533503",
    "rbxassetid://116618003477002",
    "rbxassetid://106086955212611",
    "rbxassetid://107640065977686",
    "rbxassetid://77124578197357",
    "rbxassetid://101771617803133",
    "rbxassetid://134958187822107",
    "rbxassetid://111313169447787",
    "rbxassetid://71685573690338",
    "rbxassetid://129843313690921",
    "rbxassetid://97623143664485",
    "rbxassetid://136007065400978",
    "rbxassetid://86096387000557",
    "rbxassetid://108807732150251",
    "rbxassetid://138040001965654",
    "rbxassetid://73502073176819",
    "rbxassetid://86709774283672",
    "rbxassetid://140703210927645",
    "rbxassetid://96173857867228",
    "rbxassetid://121255898612475",
    "rbxassetid://98031287364865",
    "rbxassetid://119462383658044",
    "rbxassetid://77448521277146",
    "rbxassetid://103741352379819",
    "rbxassetid://131696603025265",
    "rbxassetid://122503338277352",
    "rbxassetid://97648548303678",
    "rbxassetid://94162446513587",
    "rbxassetid://84426150435898",
    "rbxassetid://93069721274110",
    "rbxassetid://114620047310688",
    "rbxassetid://97433060861952",
    "rbxassetid://82183356141401",
    "rbxassetid://100592913030351",
    "rbxassetid://121293883585738",
    "rbxassetid://70447634862911",
    "rbxassetid://92173139187970",
    "rbxassetid://106847695270773",
    "rbxassetid://125403313786645",
    "rbxassetid://81639435858902",
    "rbxassetid://137314737492715",
    "rbxassetid://120112897026015",
    "rbxassetid://82113744478546",
    "rbxassetid://118298475669935",
    "rbxassetid://126681776859538",
    "rbxassetid://129976080405072",
    "rbxassetid://109667959938617",
    "rbxassetid://74707328554358",
    "rbxassetid://133336594357903",
    "rbxassetid://86204001129974",
    "rbxassetid://124243639579224",
    "rbxassetid://70371667919898",
    "rbxassetid://131543461321709",
    "rbxassetid://136323728355613",
    "rbxassetid://109230267448394"
}

-- [[ esp settings ]]
local espsettings = {
    players = {
        enabled = false,
        killers = {
            enabled = false,
            color = Color3.fromRGB(255, 50, 50),
            outline = Color3.fromRGB(0, 0, 0)
        },
        survivors = {
            enabled = false,
            color = Color3.fromRGB(50, 255, 50),
            outline = Color3.fromRGB(0, 0, 0)
        }
    },
    generators = {
        enabled = false,
        color0 = Color3.fromRGB(255, 50, 50),
        color26 = Color3.fromRGB(255, 150, 50),
        color52 = Color3.fromRGB(255, 255, 50),
        color78 = Color3.fromRGB(150, 255, 50),
        outline = Color3.fromRGB(0, 0, 0)
    },
    items = {
        enabled = false,
        bloxycola = {
            enabled = false,
            color = Color3.fromRGB(0, 162, 255),
            outline = Color3.fromRGB(0, 0, 0)
        },
        medkit = {
            enabled = false,
            color = Color3.fromRGB(0, 255, 0),
            outline = Color3.fromRGB(0, 0, 0)
        }
    },
    minions = {
        enabled = false,
        friendly = {
            enabled = false,
            color = Color3.fromRGB(0.1, 0.7, 0.1),
            outline = Color3.fromRGB(0, 0, 0)
        },
        enemy = {
            enabled = false,
            color = Color3.fromRGB(0.7, 0.1, 0.1),
            outline = Color3.fromRGB(0, 0, 0)
        }
    },
    traps = {
        enabled = false,
        tripmine = {
            enabled = false,
            color = Color3.fromRGB(0.9, 0.2, 1),
            outline = Color3.fromRGB(0, 0, 0)
        },
        tripwire = {
            enabled = false,
            color = Color3.fromRGB(0.75, 0.75, 0.75),
            outline = Color3.fromRGB(0, 0, 0)
        }
    }
}

-- [[ ui initialization - obsidian style ]]
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
    Exploits = Window:AddTab("Exploits", "shield-alert"),
    Config = Window:AddTab("Config", "folder-cog")
}

-- [[ main tab ]]
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

MainUtility:AddToggle("MS_SideWalls", { 
    Text = "Side Walls", 
    Default = false, 
    Tooltip = "Spawns collision walls on your left and right sides." 
})

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

-- [[ combat systems ]]
local MainCombat = Tabs.Main:AddRightGroupbox("Combat")
MainCombat:AddToggle("MC_HitboxExpander", { 
    Text = "Hitbox Expander", 
    Default = false,
    Tooltip = "Increases your attack range"
})

local HitboxExpander_True = MainCombat:AddDependencyBox()
HitboxExpander_True:AddSlider("MC_HitboxRange", { 
    Text = "Hitbox Range", 
    Default = 37, 
    Min = 20, 
    Max = 200, 
    Rounding = 0
})
HitboxExpander_True:SetupDependencies({ { Toggles.MC_HitboxExpander, true } })

MainCombat:AddToggle("MC_SlashAura", { 
    Text = "Slash Aura", 
    Default = false,
    Tooltip = "Automatically attacks nearby enemies"
})

local SlashAura_True = MainCombat:AddDependencyBox()
SlashAura_True:AddSlider("MC_SlashAuraRange", { 
    Text = "Aura Range", 
    Default = 7, 
    Min = 4, 
    Max = 11, 
    Rounding = 0
})
SlashAura_True:SetupDependencies({ { Toggles.MC_SlashAura, true } })

MainCombat:AddToggle("MC_SilentAim", { 
    Text = "Silent Aim", 
    Default = false,
    Tooltip = "Automatically aims your attacks"
})

local SilentAim_True = MainCombat:AddDependencyBox()
SilentAim_True:AddDropdown("MC_SilentAimType", {
    Values = {"Dusekkar", "Coolkid"},
    Default = "Dusekkar",
    Text = "Silent Aim Type"
})
SilentAim_True:SetupDependencies({ { Toggles.MC_SilentAim, true } })

MainCombat:AddToggle("MC_AutoBlock", { 
    Text = "Auto Block", 
    Default = false,
    Tooltip = "Automatically blocks incoming attacks"
})

local AutoBlock_True = MainCombat:AddDependencyBox()
AutoBlock_True:AddSlider("MC_AutoBlockDelay", { 
    Text = "Block Delay", 
    Default = 110, 
    Min = 0, 
    Max = 300, 
    Rounding = 0
})
AutoBlock_True:SetupDependencies({ { Toggles.MC_AutoBlock, true } })

-- [[ visuals tab ]]
local VisualsESP = Tabs.Visuals:AddLeftGroupbox("ESP Settings")
VisualsESP:AddToggle("VE_EnableESP", { 
    Text = "Enable ESP", 
    Default = false, 
    Tooltip = "Master toggle for all ESP features." 
})

local PlayerESP = VisualsESP:AddDependencyBox()
PlayerESP:AddToggle("VE_PlayerESP", { 
    Text = "Player ESP", 
    Default = false, 
    Tooltip = "Show ESP for players." 
})
PlayerESP:AddToggle("VE_PlayerESP_Killers", { 
    Text = "Show Killers", 
    Default = false, 
    Tooltip = "Show ESP for killers." 
})
PlayerESP:AddToggle("VE_PlayerESP_Survivors", { 
    Text = "Show Survivors", 
    Default = false, 
    Tooltip = "Show ESP for survivors." 
})
PlayerESP:SetupDependencies({ { Toggles.VE_EnableESP, true } })

VisualsESP:AddToggle("VE_GeneratorESP", { 
    Text = "Generator ESP", 
    Default = false, 
    Tooltip = "Show ESP for generators." 
})

local ItemESP = VisualsESP:AddDependencyBox()
ItemESP:AddToggle("VE_ItemESP", { 
    Text = "Item ESP", 
    Default = false, 
    Tooltip = "Show ESP for items." 
})
ItemESP:AddToggle("VE_ItemESP_BloxyCola", { 
    Text = "Show Bloxy Cola", 
    Default = false, 
    Tooltip = "Show ESP for Bloxy Cola." 
})
ItemESP:AddToggle("VE_ItemESP_Medkit", { 
    Text = "Show Medkits", 
    Default = false, 
    Tooltip = "Show ESP for medkits." 
})
ItemESP:SetupDependencies({ { Toggles.VE_EnableESP, true } })

local MinionESP = VisualsESP:AddDependencyBox()
MinionESP:AddToggle("VE_MinionESP", { 
    Text = "Minion ESP", 
    Default = false, 
    Tooltip = "Show ESP for minions." 
})
MinionESP:AddToggle("VE_MinionESP_Friendly", { 
    Text = "Show Friendly", 
    Default = false, 
    Tooltip = "Show ESP for friendly minions." 
})
MinionESP:AddToggle("VE_MinionESP_Enemy", { 
    Text = "Show Enemy", 
    Default = false, 
    Tooltip = "Show ESP for enemy minions." 
})
MinionESP:SetupDependencies({ { Toggles.VE_EnableESP, true } })

local TrapESP = VisualsESP:AddDependencyBox()
TrapESP:AddToggle("VE_TrapESP", { 
    Text = "Trap ESP", 
    Default = false, 
    Tooltip = "Show ESP for traps." 
})
TrapESP:AddToggle("VE_TrapESP_Tripmine", { 
    Text = "Show Tripmines", 
    Default = false, 
    Tooltip = "Show ESP for tripmines." 
})
TrapESP:AddToggle("VE_TrapESP_Tripwire", { 
    Text = "Show Tripwires", 
    Default = false, 
    Tooltip = "Show ESP for tripwires." 
})
TrapESP:SetupDependencies({ { Toggles.VE_EnableESP, true } })

local VisualsFOV = Tabs.Visuals:AddRightGroupbox("Field of View")
VisualsFOV:AddToggle("VF_CustomFOV", { 
    Text = "Custom FOV", 
    Default = false, 
    Tooltip = "Override the default field of view." 
})

local VF_CustomFOV_True = VisualsFOV:AddDependencyBox()
VF_CustomFOV_True:AddSlider("VF_FOVValue", { 
    Text = "Field Of View", 
    Default = 80, 
    Min = 10, 
    Max = 120, 
    Rounding = 0, 
    Compact = true,
    Suffix = "°"
})
VF_CustomFOV_True:SetupDependencies({ { Toggles.VF_CustomFOV, true } })

-- [[ exploits tab ]]
local ExploitsRemovals = Tabs.Exploits:AddLeftGroupbox("Visual Removals")
ExploitsRemovals:AddToggle("ER_AntiJohndoeTrail", { 
    Text = "Anti-John Doe Trail", 
    Default = false
})

ExploitsRemovals:AddToggle("ER_AntiJohndoeFootprint", { 
    Text = "Anti-John Doe Footprint", 
    Default = false
})

ExploitsRemovals:AddToggle("ER_NoliClones", { 
    Text = "Noli Fake Clones", 
    Default = false
})

ExploitsRemovals:AddToggle("ER_NoliSurvivorAbilities", { 
    Text = "Noli Fake Abilities", 
    Default = false
})

local ExploitsAutomation = Tabs.Exploits:AddRightGroupbox("Automation")
ExploitsAutomation:AddToggle("EA_1xPopups", { 
    Text = "Close Popups", 
    Default = false
})

-- [[ anti systems ]]
local ExploitsAnti = Tabs.Exploits:AddLeftGroupbox("Anti Systems")
ExploitsAnti:AddToggle("EA_AntiSlow", { 
    Text = "Anti Slow", 
    Default = false
})

ExploitsAnti:AddToggle("EA_AntiBlindness", { 
    Text = "Anti Blindness", 
    Default = false
})

ExploitsAnti:AddToggle("EA_AntiSubspace", { 
    Text = "Anti Subspace", 
    Default = false
})

ExploitsAnti:AddToggle("EA_AntiFootsteps", { 
    Text = "Anti Footsteps", 
    Default = false
})

-- [[ performance optimization functions ]]
local function safepcall(success, ...)
    local args = {...}
    if success or args[1] ~= nil then
    end
end

local function isinrange(position)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    local distance = (character.HumanoidRootPart.Position - position).Magnitude
    return distance <= performancesettings.maxespdistance
end

-- [[ esp management ]]
local function createesp(object, color, name, outlinecolor)
    local adorneepart = object:FindFirstChild("HumanoidRootPart") or object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")
    if not adorneepart or not isinrange(adorneepart.Position) then return end
    
    if espobjects[object] then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "BunnyHubESP"
    highlight.Adornee = object
    highlight.FillColor = color
    highlight.OutlineColor = outlinecolor or color
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = game.CoreGui
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BunnyHubLabel"
    billboard.Adornee = adorneepart
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = game.CoreGui
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = color
    label.TextSize = 18
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0
    label.Parent = billboard
    
    label.TextTransparency = 1
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 1
    
    tweenservice:Create(highlight, TweenInfo.new(1.5), {FillTransparency = 0.6}):Play()
    tweenservice:Create(highlight, TweenInfo.new(1.5), {OutlineTransparency = 0.35}):Play()
    tweenservice:Create(label, TweenInfo.new(1.5), {TextTransparency = 0}):Play()
    
    espobjects[object] = {
        highlight = highlight, 
        billboard = billboard, 
        label = label,
        type = name,
        object = object,
        adorneepart = adorneepart
    }
    
    return highlight, label
end

local function removeesp(object)
    if espobjects[object] then
        local esp = espobjects[object]
        
        if esp.highlight then
            tweenservice:Create(esp.highlight, TweenInfo.new(1.5), {FillTransparency = 1}):Play()
            tweenservice:Create(esp.highlight, TweenInfo.new(1.5), {OutlineTransparency = 1}):Play()
            task.delay(1.5, function()
                if esp.highlight then esp.highlight:Destroy() end
            end)
        end
        
        if esp.billboard then
            tweenservice:Create(esp.billboard.TextLabel, TweenInfo.new(1.5), {TextTransparency = 1}):Play()
            task.delay(1.5, function()
                if esp.billboard then esp.billboard:Destroy() end
            end)
        end
        
        espobjects[object] = nil
    end
end

local function clearesp()
    for object, esp in pairs(espobjects) do
        removeesp(object)
    end
end

-- [[ esp helper functions ]]
local function cleartypeesp(esptype)
    for object, esp in pairs(espobjects) do
        if esp.type then
            if esptype == "player" and (string.find(esp.type, "Killer") or string.find(esp.type, "Survivor")) then
                removeesp(object)
            elseif esptype == "killer" and string.find(esp.type, "Killer") then
                removeesp(object)
            elseif esptype == "survivor" and string.find(esp.type, "Survivor") then
                removeesp(object)
            elseif esptype == "generator" and string.find(esp.type, "Generator") then
                removeesp(object)
            elseif esptype == "item" and (esp.type == "BloxyCola" or esp.type == "Medkit") then
                removeesp(object)
            elseif esptype == "bloxycola" and esp.type == "BloxyCola" then
                removeesp(object)
            elseif esptype == "medkit" and esp.type == "Medkit" then
                removeesp(object)
            elseif esptype == "minion" and string.find(esp.type, "Minion") then
                removeesp(object)
            elseif esptype == "friendlyminion" and esp.type == "Friendly Minion" then
                removeesp(object)
            elseif esptype == "enemyminion" and esp.type == "Enemy Minion" then
                removeesp(object)
            elseif esptype == "trap" and (esp.type == "Tripmine" or esp.type == "Tripwire") then
                removeesp(object)
            elseif esptype == "tripmine" and esp.type == "Tripmine" then
                removeesp(object)
            elseif esptype == "tripwire" and esp.type == "Tripwire" then
                removeesp(object)
            end
        end
    end
end

local function setupautoesp()
    if workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Ingame") then
        workspace.Map.Ingame.DescendantAdded:Connect(function(v)
            if v:IsA("Model") and v.Name == "Generator" then
                local progress = v:WaitForChild("Progress", 9e9)
                local mainpart = v:WaitForChild("Main", 9e9)
                
                if espenabled and espsettings.generators.enabled then
                    createesp(v, espsettings.generators.color0, "Generator (0/4)", espsettings.generators.outline)
                end
                
                local progressChanged
                progressChanged = progress:GetPropertyChangedSignal("Value"):Connect(function()
                    if progress.Value >= 100 then
                        removeesp(v)
                        progressChanged:Disconnect()
                    end
                end)
                
                v.Destroying:Once(function()
                    if progressChanged then progressChanged:Disconnect() end
                end)
            end
        end)
    end
    
    if workspace:FindFirstChild("Players") then
        workspace.Players.Killers.ChildAdded:Connect(function(v)
            task.delay(1, function()
                if v == character then return end
                if espenabled and espsettings.players.enabled and espsettings.players.killers.enabled and v:IsA("Model") and v:FindFirstChild("Humanoid") then
                    local username = v:GetAttribute("Username") or "Killer"
                    createesp(v, espsettings.players.killers.color, username, espsettings.players.killers.outline)
                end
            end)
        end)
        
        workspace.Players.Survivors.ChildAdded:Connect(function(v)
            task.delay(1, function()
                if v == character then return end
                if espenabled and espsettings.players.enabled and espsettings.players.survivors.enabled and v:IsA("Model") and v:FindFirstChild("Humanoid") then
                    local username = v:GetAttribute("Username") or "Survivor"
                    createesp(v, espsettings.players.survivors.color, username, espsettings.players.survivors.outline)
                end
            end)
        end)
    end
    
    workspace.Map.Ingame.ChildAdded:Connect(function(v)
        if not v:IsA("Model") then return end
        task.wait()
        
        if espenabled then
            if v:GetAttribute("ExecutionsDisabled") and v:FindFirstChild("Humanoid") and espsettings.minions.enabled and espsettings.minions.friendly.enabled then
                createesp(v, espsettings.minions.friendly.color, "Friendly Minion", espsettings.minions.friendly.outline)
            elseif v:GetAttribute("Team") and v:GetAttribute("Team") == "Killers" and v:FindFirstChild("Humanoid") and espsettings.minions.enabled and espsettings.minions.enemy.enabled then
                createesp(v, espsettings.minions.enemy.color, "Enemy Minion", espsettings.minions.enemy.outline)
            elseif v.Name == "SubspaceTripmine" and espsettings.traps.enabled and espsettings.traps.tripmine.enabled then
                local subspacebox = v:WaitForChild("SubspaceBox", 9e9)
                createesp(v, espsettings.traps.tripmine.color, "Tripmine", espsettings.traps.tripmine.outline)
            elseif string.find(v.Name, "TaphTripwire") and espsettings.traps.enabled and espsettings.traps.tripwire.enabled then
                local wire = v:WaitForChild("Wire", 9e9)
                createesp(v, espsettings.traps.tripwire.color, "Tripwire", espsettings.traps.tripwire.outline)
            end
        end
    end)
end

setupautoesp()

-- [[ player esp system ]]
local function updateplayeresp()
    if not espenabled or not espsettings.players.enabled then return end
    
    local killersfolder = workspace:FindFirstChild("Players")
    if killersfolder and killersfolder:FindFirstChild("Killers") then
        for _, killer in pairs(killersfolder.Killers:GetChildren()) do
            if killer:IsA("Model") and killer:FindFirstChild("Humanoid") and killer.Humanoid.Health > 0 then
                if espsettings.players.killers.enabled then
                    local username = killer:GetAttribute("Username") or "Killer"
                    if not espobjects[killer] then
                        createesp(killer, espsettings.players.killers.color, username, espsettings.players.killers.outline)
                    else
                        if espobjects[killer].billboard then
                            espobjects[killer].billboard.TextLabel.Text = username
                        end
                    end
                elseif espobjects[killer] then
                    removeesp(killer)
                end
            elseif killer:IsA("Model") and espobjects[killer] then
                removeesp(killer)
            end
        end
    end
    
    local survivorsfolder = workspace:FindFirstChild("Players")
    if survivorsfolder and survivorsfolder:FindFirstChild("Survivors") then
        for _, survivor in pairs(survivorsfolder.Survivors:GetChildren()) do
            if survivor:IsA("Model") and survivor:FindFirstChild("Humanoid") and survivor.Humanoid.Health > 0 then
                if espsettings.players.survivors.enabled then
                    local username = survivor:GetAttribute("Username") or "Survivor"
                    if not espobjects[survivor] then
                        createesp(survivor, espsettings.players.survivors.color, username, espsettings.players.survivors.outline)
                    else
                        if espobjects[survivor].billboard then
                            espobjects[survivor].billboard.TextLabel.Text = username
                        end
                    end
                elseif espobjects[survivor] then
                    removeesp(survivor)
                end
            elseif survivor:IsA("Model") and espobjects[survivor] then
                removeesp(survivor)
            end
        end
    end
end

-- [[ minion esp system ]]
local function updateminionesp()
    if not espenabled or not espsettings.minions.enabled then return end
    
    for _, v in workspace.Map.Ingame:GetChildren() do
        if v:IsA("Model") then
            if v:GetAttribute("ExecutionsDisabled") and v:FindFirstChild("Humanoid") and espsettings.minions.friendly.enabled then
                if not espobjects[v] then
                    createesp(v, espsettings.minions.friendly.color, "Friendly Minion", espsettings.minions.friendly.outline)
                end
            elseif v:GetAttribute("Team") and v:GetAttribute("Team") == "Killers" and v:FindFirstChild("Humanoid") and espsettings.minions.enabled and espsettings.minions.enemy.enabled then
                if not espobjects[v] then
                    createesp(v, espsettings.minions.enemy.color, "Enemy Minion", espsettings.minions.enemy.outline)
                end
            end
        end
    end
end

-- [[ item esp system ]]
local function updateitemesp()
    if not espenabled or not espsettings.items.enabled then return end
    
    local mapfolder = workspace:FindFirstChild("Map")
    if not mapfolder then return end
    local ingame = mapfolder:FindFirstChild("Ingame") 
    if not ingame then return end
    local map = ingame:FindFirstChild("Map")
    if not map then return end
    
    for _, item in pairs(map:GetDescendants()) do
        if item:IsA("Tool") then
            if item.Name == "BloxyCola" and espsettings.items.bloxycola.enabled then
                if not espobjects[item] then
                    createesp(item, espsettings.items.bloxycola.color, "BloxyCola", espsettings.items.bloxycola.outline)
                end
            elseif item.Name == "Medkit" and espsettings.items.medkit.enabled then
                if not espobjects[item] then
                    createesp(item, espsettings.items.medkit.color, "Medkit", espsettings.items.medkit.outline)
                end
            end
        end
    end
end

-- [[ trap esp system ]]
local function updatetrapesp()
    if not espenabled or not espsettings.traps.enabled then return end
    
    for _, item in pairs(workspace:GetDescendants()) do
        if item:IsA("Part") then
            local parent = item.Parent
            if item.Name == "SubspaceBox" and espsettings.traps.tripmine.enabled then
                if parent and not espobjects[parent] then
                    createesp(parent, espsettings.traps.tripmine.color, "Tripmine", espsettings.traps.tripmine.outline)
                end
            elseif item.Name == "Wire" and string.find(parent and parent.Name or "", "TaphTripwire") and espsettings.traps.tripwire.enabled then
                if parent and not espobjects[parent] then
                    createesp(parent, espsettings.traps.tripwire.color, "Tripwire", espsettings.traps.tripwire.outline)
                end
            end
        end
    end
end

-- [[ generator esp system ]]
local function updategeneratoresp()
    if not espenabled or not espsettings.generators.enabled then return end
    
    local mapfolder = workspace:FindFirstChild("Map")
    if not mapfolder then return end
    local ingame = mapfolder:FindFirstChild("Ingame")
    if not ingame then return end
    local map = ingame:FindFirstChild("Map")
    if not map then return end
    
    for _, generatormodel in pairs(map:GetChildren()) do
        if generatormodel.Name == "Generator" and generatormodel:IsA("Model") then
            local progress = generatormodel:FindFirstChild("Progress")
            local mainpart = generatormodel.PrimaryPart or generatormodel:FindFirstChildWhichIsA("BasePart")
            
            if progress and progress:IsA("NumberValue") and mainpart then
                if progress.Value < 100 then
                    local color, status
                    if progress.Value == 0 then 
                        color = espsettings.generators.color0
                        status = "0/4"
                    elseif progress.Value == 26 then 
                        color = espsettings.generators.color26
                        status = "1/4"
                    elseif progress.Value == 52 then 
                        color = espsettings.generators.color52
                        status = "2/4"
                    elseif progress.Value == 78 then 
                        color = espsettings.generators.color78
                        status = "3/4"
                    else
                        color = Color3.fromRGB(100, 255, 100)
                        status = "Almost Done"
                    end
                    
                    if not espobjects[generatormodel] then
                        createesp(generatormodel, color, "Generator (" .. status .. ")", espsettings.generators.outline)
                        espobjects[generatormodel].isgenerator = true
                    else
                        if espobjects[generatormodel].highlight then
                            espobjects[generatormodel].highlight.FillColor = color
                            espobjects[generatormodel].highlight.OutlineColor = color
                        end
                        if espobjects[generatormodel].billboard then
                            espobjects[generatormodel].billboard.TextLabel.Text = "Generator (" .. status .. ")"
                            espobjects[generatormodel].billboard.TextLabel.TextColor3 = color
                        end
                    end
                else
                    if espobjects[generatormodel] then 
                        removeesp(generatormodel) 
                    end
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
    
    for object, esp in pairs(espobjects) do
        if not object or not object.Parent then
            removeesp(object)
        end
    end
    
    if espsettings.players.enabled then updateplayeresp() end
    if espsettings.generators.enabled then updategeneratoresp() end
    if espsettings.items.enabled then updateitemesp() end
    if espsettings.minions.enabled then updateminionesp() end
    if espsettings.traps.enabled then updatetrapesp() end
end

-- [[ anti systems functions ]]
local function applyantislow()
    if not antislowenabled then return end
    
    safepcall(pcall(function()
        if character and character:FindFirstChild("SpeedMultipliers") then
            for _, multiplier in pairs(character.SpeedMultipliers:GetChildren()) do
                if multiplier:IsA("NumberValue") and multiplier.Value < 1 then
                    multiplier.Value = 1
                end
            end
        end
    end))
end

local function applyantiblindness()
    if not antiblindnessenabled then return end
    
    safepcall(pcall(function()
        local blur = game.Lighting:FindFirstChild("BlindnessBlur")
        if blur then
            blur:Destroy()
        end
    end))
end

local function applyantisubspace()
    if not antisubspaceenabled then return end
    
    safepcall(pcall(function()
        local effects = {
            "SubspaceVFXBlur",
            "SubspaceVFXColorCorrection"
        }
        
        for _, effectname in pairs(effects) do
            local effect = game.Lighting:FindFirstChild(effectname)
            if effect then
                effect:Destroy()
            end
        end
    end))
end

local function applyantifootsteps()
    if not antifootstepsenabled then return end
    
    safepcall(pcall(function()
        local footstepsound = character and character:FindFirstChild("FootstepSound")
        if footstepsound then
            footstepsound:Destroy()
        end
    end))
end

-- [[ combat systems functions ]]
local function applyhitboxexpander()
    if not hitboxexpanderenabled or not character then return end
    
    safepcall(pcall(function()
        local humanoid = character:FindFirstChild("Humanoid")
        local rootpart = character:FindFirstChild("HumanoidRootPart")
        
        if not humanoid or not rootpart then return end
        
        local isattacking = false
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            if track.Animation then
                local animid = tostring(track.Animation.AnimationId)
                for _, attackanim in pairs(attackanimations) do
                    if animid:find(attackanim:match("%d+")) and track.IsPlaying then
                        isattacking = true
                        break
                    end
                end
            end
            if isattacking then break end
        end
        
        if isattacking then
            local closesttarget = nil
            local closestdistance = hitboxrange
            
            local survivors = workspace.Players:FindFirstChild("Survivors")
            if survivors then
                for _, survivor in pairs(survivors:GetChildren()) do
                    if survivor:IsA("Model") and survivor ~= character then
                        local humanoidrootpart = survivor:FindFirstChild("HumanoidRootPart")
                        if humanoidrootpart then
                            local distance = (rootpart.Position - humanoidrootpart.Position).Magnitude
                            if distance < closestdistance then
                                closestdistance = distance
                                closesttarget = survivor
                            end
                        end
                    end
                end
            end
            
            if closesttarget then
                local targetroot = closesttarget:FindFirstChild("HumanoidRootPart")
                if targetroot then
                    local direction = (targetroot.Position - rootpart.Position).Unit
                    rootpart.Velocity = direction * 50
                end
            end
        end
    end))
end

local function applyslashaura()
    if not slashauraenabled or not character then return end
    
    safepcall(pcall(function()
        local rootpart = character:FindFirstChild("HumanoidRootPart")
        if not rootpart then return end
        
        local isplayerinkiller = workspace.Players.Killers:FindFirstChild(player.Name) ~= nil
        
        if isplayerinkiller then
            local survivors = workspace.Players:FindFirstChild("Survivors")
            if survivors then
                for _, survivor in pairs(survivors:GetChildren()) do
                    if survivor:IsA("Model") then
                        local targetroot = survivor:FindFirstChild("HumanoidRootPart")
                        if targetroot then
                            local distance = (rootpart.Position - targetroot.Position).Magnitude
                            if distance <= slashaurarange then
                                networkevent:FireServer("UseActorAbility", {buffer.fromstring('"Slash"')})
                                break
                            end
                        end
                    end
                end
            end
        else
            local killers = workspace.Players:FindFirstChild("Killers")
            if killers then
                for _, killer in pairs(killers:GetChildren()) do
                    if killer:IsA("Model") then
                        local targetroot = killer:FindFirstChild("HumanoidRootPart")
                        if targetroot then
                            local distance = (rootpart.Position - targetroot.Position).Magnitude
                            if distance <= slashaurarange then
                                networkevent:FireServer("UseActorAbility", {buffer.fromstring('"Punch"')})
                                break
                            end
                        end
                    end
                end
            end
        end
    end))
end

local function setupautoblock()
    if not autoblockenabled then return end
    
    safepcall(pcall(function()
        local killers = workspace.Players:FindFirstChild("Killers")
        if killers then
            for _, killer in pairs(killers:GetChildren()) do
                if killer:IsA("Model") then
                    local humanoid = killer:FindFirstChild("Humanoid")
                    if humanoid then
                        local animator = humanoid:FindFirstChildOfClass("Animator")
                        if animator then
                            animator.AnimationPlayed:Connect(function(animationtrack)
                                if animationtrack.Animation then
                                    local animid = tostring(animationtrack.Animation.AnimationId)
                                    for _, attackanim in pairs(attackanimations) do
                                        if animid:find(attackanim:match("%d+")) then
                                            local killerroot = killer:FindFirstChild("HumanoidRootPart")
                                            local playerroot = character and character:FindFirstChild("HumanoidRootPart")
                                            
                                            if killerroot and playerroot then
                                                local distance = (killerroot.Position - playerroot.Position).Magnitude
                                                if distance <= 13 then
                                                    task.wait(autoblockdelay / 1000)
                                                    
                                                    if autoblockenabled and character then
                                                        networkevent:FireServer("UseActorAbility", {buffer.fromstring('"Block"')})
                                                    end
                                                end
                                            end
                                            break
                                        end
                                    end
                                end
                            end)
                        end
                    end
                end
            end
        end
    end))
end

local function setupsilentaim()
    if not silentaimenabled then return end
    
    safepcall(pcall(function()
        local mouseposmodule = require(ReplicatedStorage.Systems.Player.Miscellaneous.GetPlayerMousePosition)
        
        if mouseposmodule and mouseposmodule.GetMousePos then
            local originalgetmousepos = mouseposmodule.GetMousePos
            
            mouseposmodule.GetMousePos = function(...)
                if not silentaimenabled then
                    return originalgetmousepos(...)
                end
                
                local closesttarget = nil
                local closestdistance = math.huge
                
                local isplayerinkiller = workspace.Players.Killers:FindFirstChild(player.Name) ~= nil
                
                if isplayerinkiller then
                    local survivors = workspace.Players:FindFirstChild("Survivors")
                    if survivors then
                        for _, survivor in pairs(survivors:GetChildren()) do
                            if survivor:IsA("Model") and survivor ~= character then
                                local targetroot = survivor:FindFirstChild("HumanoidRootPart")
                                if targetroot then
                                    local distance = (character.HumanoidRootPart.Position - targetroot.Position).Magnitude
                                    if distance < closestdistance then
                                        closestdistance = distance
                                        closesttarget = survivor
                                    end
                                end
                            end
                        end
                    end
                else
                    local killers = workspace.Players:FindFirstChild("Killers")
                    if killers then
                        for _, killer in pairs(killers:GetChildren()) do
                            if killer:IsA("Model") then
                                local targetroot = killer:FindFirstChild("HumanoidRootPart")
                                if targetroot then
                                    local distance = (character.HumanoidRootPart.Position - targetroot.Position).Magnitude
                                    if distance < closestdistance then
                                        closestdistance = distance
                                        closesttarget = killer
                                    end
                                end
                            end
                        end
                    end
                end
                
                if closesttarget and closesttarget:FindFirstChild("HumanoidRootPart") then
                    if silentaimtype == "Dusekkar" then
                        return closesttarget.HumanoidRootPart.Position
                    else
                        local offset = Vector3.new(
                            math.random(-2, 2),
                            math.random(0, 1),
                            math.random(-2, 2)
                        )
                        return closesttarget.HumanoidRootPart.Position + offset
                    end
                end
                
                return originalgetmousepos(...)
            end
        end
    end))
end

-- [[ side walls feature ]]
local sidewallsenabled = false
local invisiblewalls = false
local leftwall = nil
local rightwall = nil

local function updatesidewalls()
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    if leftwall then leftwall:Destroy() leftwall = nil end
    if rightwall then rightwall:Destroy() rightwall = nil end
    
    if sidewallsenabled then
        local humanoidrootpart = character.HumanoidRootPart
        
        local rightposition = humanoidrootpart.Position + (humanoidrootpart.CFrame.RightVector * 3)
        local leftposition = humanoidrootpart.Position + (humanoidrootpart.CFrame.RightVector * -3)
        
        rightwall = Instance.new("Part")
        rightwall.Name = "RightSideWall"
        rightwall.Size = Vector3.new(1, 6, 1)
        rightwall.Position = rightposition
        rightwall.Anchored = true
        rightwall.CanCollide = true
        rightwall.Material = Enum.Material.ForceField
        rightwall.Color = Color3.fromRGB(0, 100, 255)
        
        leftwall = Instance.new("Part")
        leftwall.Name = "LeftSideWall"
        leftwall.Size = Vector3.new(1, 6, 1)
        leftwall.Position = leftposition
        leftwall.Anchored = true
        leftwall.CanCollide = true
        leftwall.Material = Enum.Material.ForceField
        leftwall.Color = Color3.fromRGB(0, 100, 255)
        
        if invisiblewalls then
            rightwall.Transparency = 1
            leftwall.Transparency = 1
        else
            rightwall.Transparency = 0.3
            leftwall.Transparency = 0.3
        end
        
        rightwall.Parent = workspace
        leftwall.Parent = workspace
        
        Library:Notify({
            Title = "Side Walls",
            Description = "Collision walls spawned" .. (invisiblewalls and " (invisible)" or ""),
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

Toggles.MS_SideWalls:OnChanged(function(value)
    sidewallsenabled = value
    updatesidewalls()
end)

Toggles.MS_SideWallsInvisible:OnChanged(function(value)
    invisiblewalls = value
    if sidewallsenabled then
        if leftwall then leftwall.Transparency = value and 1 or 0.3 end
        if rightwall then rightwall.Transparency = value and 1 or 0.3 end
        
        Library:Notify({
            Title = "Side Walls",
            Description = value and "Walls are now invisible" or "Walls are now visible",
            Time = 2
        })
    end
end)

local wallsconnection = runservice.Heartbeat:Connect(function()
    if sidewallsenabled and character and character:FindFirstChild("HumanoidRootPart") then
        local humanoidrootpart = character.HumanoidRootPart
        
        if leftwall then
            local leftposition = humanoidrootpart.Position + (humanoidrootpart.CFrame.RightVector * -2)
            leftwall.Position = leftposition
            leftwall.CFrame = CFrame.lookAt(leftposition, humanoidrootpart.Position)
        end
        
        if rightwall then
            local rightposition = humanoidrootpart.Position + (humanoidrootpart.CFrame.RightVector * 2)
            rightwall.Position = rightposition
            rightwall.CFrame = CFrame.lookAt(rightposition, humanoidrootpart.Position)
        end
    end
end)

-- [[ walkspeed cancel function ]]
local function createcancelwall()
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local humanoidrootpart = character.HumanoidRootPart
    local lookvector = humanoidrootpart.CFrame.LookVector
    local spawnposition = humanoidrootpart.Position + (lookvector * 4)
    
    local wall = Instance.new("Part")
    wall.Name = "WalkspeedCancelWall"
    wall.Size = Vector3.new(10, 10, 1)
    wall.Position = spawnposition
    wall.CFrame = CFrame.lookAt(spawnposition, humanoidrootpart.Position)
    wall.Anchored = true
    wall.CanCollide = true
    wall.Transparency = 0.3
    wall.Material = Enum.Material.ForceField
    wall.Color = Color3.fromRGB(255, 0, 0)
    wall.Parent = workspace
    
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

Options.MM_WalkspeedCancel:OnClick(function()
    createcancelwall()
end)

Options.MM_WalkspeedCancel:OnChanged(function()
    createcancelwall()
end)

-- [[ simple removal system ]]
local function removebadstuff()
    if Toggles.ER_AntiJohndoeTrail.Value then
        for _, thing in workspace:GetDescendants() do
            if thing.Name == "Trail" then
                thing.CanTouch = false
            end
        end
    end
    
    if Toggles.ER_AntiJohndoeFootprint.Value then
        for _, thing in workspace:GetDescendants() do
            if thing.Name == "Shadow" then
                thing.CanTouch = false
            end
        end
    end
end

local function closeannoyingpopups()
    if Toggles.EA_1xPopups.Value then
        local gui = player.PlayerGui
        if gui and gui:FindFirstChild("TemporaryUI") then
            local popup = gui.TemporaryUI:FindFirstChild("1x1x1x1Popup")
            if popup then
                popup:Destroy()
            end
        end
    end
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
        pcall(function()
            local sprintingmodule = require(ReplicatedStorage.Systems.Character.Game.Sprinting)
            if sprintingmodule then
                sprintingmodule.StaminaLossDisabled = true
            end
        end)    
        Library:Notify({Title = "Infinite Stamina Enabled", Description = "You now have unlimited stamina", Time = 3})
    else
        pcall(function()
            local sprintingmodule = require(ReplicatedStorage.Systems.Character.Game.Sprinting)
            if sprintingmodule then
                sprintingmodule.StaminaLossDisabled = false
            end
        end)  
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
        Library:Notify({Title = "ESP Disabled", Description = "All ESP features disabled", Time = 3})
    else
        Library:Notify({Title = "ESP Enabled", Description = "ESP features activated", Time = 3})
        updateesp()
    end
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

-- [[ esp toggle connections ]]
Toggles.VE_PlayerESP:OnChanged(function(value)
    espsettings.players.enabled = value
    if not value then cleartypeesp("player") end
    if espenabled then updateesp() end
end)

Toggles.VE_PlayerESP_Killers:OnChanged(function(value)
    espsettings.players.killers.enabled = value
    if not value then cleartypeesp("killer") end
    if espenabled then updateesp() end
end)

Toggles.VE_PlayerESP_Survivors:OnChanged(function(value)
    espsettings.players.survivors.enabled = value
    if not value then cleartypeesp("survivor") end
    if espenabled then updateesp() end
end)

Toggles.VE_GeneratorESP:OnChanged(function(value)
    espsettings.generators.enabled = value
    if not value then cleartypeesp("generator") end
    if espenabled then updateesp() end
end)

Toggles.VE_ItemESP:OnChanged(function(value)
    espsettings.items.enabled = value
    if not value then cleartypeesp("item") end
    if espenabled then updateesp() end
end)

Toggles.VE_ItemESP_BloxyCola:OnChanged(function(value)
    espsettings.items.bloxycola.enabled = value
    if not value then cleartypeesp("bloxycola") end
    if espenabled then updateesp() end
end)

Toggles.VE_ItemESP_Medkit:OnChanged(function(value)
    espsettings.items.medkit.enabled = value
    if not value then cleartypeesp("medkit") end
    if espenabled then updateesp() end
end)

Toggles.VE_MinionESP:OnChanged(function(value)
    espsettings.minions.enabled = value
    if not value then cleartypeesp("minion") end
    if espenabled then updateesp() end
end)

Toggles.VE_MinionESP_Friendly:OnChanged(function(value)
    espsettings.minions.friendly.enabled = value
    if not value then cleartypeesp("friendlyminion") end
    if espenabled then updateesp() end
end)

Toggles.VE_MinionESP_Enemy:OnChanged(function(value)
    espsettings.minions.enemy.enabled = value
    if not value then cleartypeesp("enemyminion") end
    if espenabled then updateesp() end
end)

Toggles.VE_TrapESP:OnChanged(function(value)
    espsettings.traps.enabled = value
    if not value then cleartypeesp("trap") end
    if espenabled then updateesp() end
end)

Toggles.VE_TrapESP_Tripmine:OnChanged(function(value)
    espsettings.traps.tripmine.enabled = value
    if not value then cleartypeesp("tripmine") end
    if espenabled then updateesp() end
end)

Toggles.VE_TrapESP_Tripwire:OnChanged(function(value)
    espsettings.traps.tripwire.enabled = value
    if not value then cleartypeesp("tripwire") end
    if espenabled then updateesp() end
end)

-- [[ anti systems toggle connections ]]
Toggles.EA_AntiSlow:OnChanged(function(value)
    antislowenabled = value
    Library:Notify({
        Title = "Anti Slow",
        Description = value and "Enabled" or "Disabled",
        Time = 3
    })
end)

Toggles.EA_AntiBlindness:OnChanged(function(value)
    antiblindnessenabled = value
    Library:Notify({
        Title = "Anti Blindness",
        Description = value and "Enabled" or "Disabled",
        Time = 3
    })
end)

Toggles.EA_AntiSubspace:OnChanged(function(value)
    antisubspaceenabled = value
    Library:Notify({
        Title = "Anti Subspace",
        Description = value and "Enabled" or "Disabled",
        Time = 3
    })
end)

Toggles.EA_AntiFootsteps:OnChanged(function(value)
    antifootstepsenabled = value
    Library:Notify({
        Title = "Anti Footsteps",
        Description = value and "Enabled" or "Disabled",
        Time = 3
    })
end)

-- [[ combat systems toggle connections ]]
Toggles.MC_HitboxExpander:OnChanged(function(value)
    hitboxexpanderenabled = value
    Library:Notify({
        Title = "Hitbox Expander",
        Description = value and "Enabled" or "Disabled",
        Time = 3
    })
end)

Options.MC_HitboxRange:OnChanged(function(value)
    hitboxrange = value
end)

Toggles.MC_SlashAura:OnChanged(function(value)
    slashauraenabled = value
    Library:Notify({
        Title = "Slash Aura",
        Description = value and "Enabled" or "Disabled",
        Time = 3
    })
end)

Options.MC_SlashAuraRange:OnChanged(function(value)
    slashaurarange = value
end)

Toggles.MC_SilentAim:OnChanged(function(value)
    silentaimenabled = value
    if value then
        setupsilentaim()
    end
    Library:Notify({
        Title = "Silent Aim",
        Description = value and "Enabled" or "Disabled",
        Time = 3
    })
end)

Options.MC_SilentAimType:OnChanged(function(value)
    silentaimtype = value
end)

Toggles.MC_AutoBlock:OnChanged(function(value)
    autoblockenabled = value
    if value then
        setupautoblock()
    end
    Library:Notify({
        Title = "Auto Block",
        Description = value and "Enabled" or "Disabled",
        Time = 3
    })
end)

Options.MC_AutoBlockDelay:OnChanged(function(value)
    autoblockdelay = value
end)

-- [[ exploit toggle notifications ]]
Toggles.ER_AntiJohndoeTrail:OnChanged(function(value)
    Library:Notify({
        Title = "John Doe Trail",
        Description = value and "Removed" or "Enabled",
        Time = 3
    })
end)

Toggles.ER_AntiJohndoeFootprint:OnChanged(function(value)
    Library:Notify({
        Title = "John Doe Footprint", 
        Description = value and "Removed" or "Enabled",
        Time = 3
    })
end)

Toggles.ER_NoliClones:OnChanged(function(value)
    Library:Notify({
        Title = "Noli Clones",
        Description = value and "Blocked" or "Enabled", 
        Time = 3
    })
end)

Toggles.ER_NoliSurvivorAbilities:OnChanged(function(value)
    Library:Notify({
        Title = "Noli Abilities",
        Description = value and "Blocked" or "Enabled",
        Time = 3
    })
end)

Toggles.EA_1xPopups:OnChanged(function(value)
    Library:Notify({
        Title = "Popup Closer",
        Description = value and "Enabled" or "Disabled",
        Time = 3
    })
end)

-- [[ config tab setup ]]
task.spawn(function()
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
        
        if staminaconnection then staminaconnection:Disconnect() end
        if puzzleuiconnection then puzzleuiconnection:Disconnect() end
        if espconnection then espconnection:Disconnect() end
        if wallsconnection then wallsconnection:Disconnect() end
        
        clearesp()
    end)

    MenuProperties:AddLabel("Menu bind"):AddKeyPicker("MP_MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
    MenuProperties:AddDivider()
    MenuProperties:AddToggle("MP_ShowKeybinds", { Text = "Show Keybinds", Default = false })

    Toggles.MP_ShowKeybinds:OnChanged(function()
        Library.KeybindFrame.Visible = Toggles.MP_ShowKeybinds.Value
    end)

    Library.ToggleKeybind = Options.MP_MenuKeybind

    local BunnyTheme = {
        BackgroundColor = Color3.fromRGB(28, 28, 28),
        OutlineColor = Color3.fromRGB(55, 55, 55),
        MainColor = Color3.fromRGB(36, 36, 36),
        AccentColor = Color3.fromRGB(61, 180, 136),
        FontColor = Color3.new(1, 1, 1),
        FontFace = "RobotoMono"
    }

    ThemeManager:SetLibrary(Library)
    ThemeManager:SetFolder("Bunny/Themes")
    ThemeManager:SetDefaultTheme(BunnyTheme)
    ThemeManager:ApplyToTab(Tabs.Config)
    ThemeManager:ThemeUpdate()

    SaveManager:SetLibrary(Library)
    SaveManager:SetFolder("Bunny/Forsaken")
    SaveManager:BuildConfigSection(Tabs.Config)
    SaveManager:IgnoreThemeSettings()
    SaveManager:LoadAutoloadConfig()
end)

-- [[ main loops ]]
local espconnection = runservice.Heartbeat:Connect(function()
    local currenttime = tick()
    
    if currenttime - lastespupdate >= performancesettings.espupdaterate then
        updateesp()
        lastespupdate = currenttime
    end
    
    if currenttime - lastcleanup >= performancesettings.cleanupinterval then
        removebadstuff()
        closeannoyingpopups()
        lastcleanup = currenttime
    end
    
    applyantislow()
    applyantiblindness()
    applyantisubspace()
    applyantifootsteps()
    applyhitboxexpander()
    applyslashaura()
end)

-- [[ respawn handling ]]
player.CharacterAdded:Connect(function(newcharacter) 
    character = newcharacter 
    repeat runservice.Heartbeat:Wait() until character:FindFirstChild("HumanoidRootPart") 
end)

-- [[ initial notification ]]
Library:Notify({Title = "BunnyHub" .. ScriptVersion .. " Loaded", Description = "All features are now active!", Time = 6})
