--[[
============================================================
 V3INN GOLD // PERFORMANCE + COMMAND AUDITOR
============================================================

Purpose:
  • Premium gold/black V3INN interface
  • Client-side FPS/performance optimizer for YOUR Roblox game
  • Live FPS + ping + memory display
  • Safe performance presets
  • Scans ONLY client-visible descendants for command-like
    definitions and reports what it finds
  • Does NOT execute, invoke, bypass, or exploit admin commands
  • Does NOT inspect ServerScriptService / ServerStorage
    because LocalScripts cannot legitimately read those services

Recommended placement:
  StarterPlayer > StarterPlayerScripts > LocalScript

This is designed as a development/admin-audit utility for an
experience you control.
============================================================
]]

----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------

local Config = {
    Name = "V3INN",
    Subtitle = "GOLD // PERFORMANCE",
    Version = "1.0.0",

    Width = 760,
    Height = 490,

    MenuKey = Enum.KeyCode.RightShift,

    MinFPS = 1,
    MaxFPS = 240,

    DefaultPreset = "Balanced",

    Colors = {
        Black = Color3.fromRGB(7, 7, 9),
        Black2 = Color3.fromRGB(11, 11, 14),
        Panel = Color3.fromRGB(16, 16, 20),
        Panel2 = Color3.fromRGB(22, 22, 27),
        Border = Color3.fromRGB(57, 50, 31),

        Gold = Color3.fromRGB(214, 170, 67),
        GoldBright = Color3.fromRGB(255, 213, 95),
        GoldDark = Color3.fromRGB(124, 91, 25),

        Text = Color3.fromRGB(245, 242, 232),
        SubText = Color3.fromRGB(150, 146, 134),

        Green = Color3.fromRGB(112, 220, 143),
        Red = Color3.fromRGB(225, 93, 98),
        Orange = Color3.fromRGB(231, 165, 74),
    }
}

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------

local State = {
    MenuOpen = true,
    Minimized = false,

    FPSBoost = false,
    Preset = Config.DefaultPreset,

    FPS = 0,
    Ping = 0,
    Memory = 0,

    Scanning = false,
    ScanFinished = false,
    CommandCount = 0,
    ScanResults = {},

    SelectedPage = "Performance",

    Destroyed = false,
}

----------------------------------------------------------------
-- SINGLE INSTANCE
----------------------------------------------------------------

local SINGLETON = "__V3INN_GOLD_PERFORMANCE"

local previous = PlayerGui:FindFirstChild(SINGLETON)

if previous then
    previous:SetAttribute("Terminate", true)
    task.wait(0.05)
    pcall(function()
        previous:Destroy()
    end)
end

local Singleton = Instance.new("Folder")
Singleton.Name = SINGLETON
Singleton:SetAttribute("Terminate", false)
Singleton.Parent = PlayerGui

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------

local function New(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    if parent then
        object.Parent = parent
    end

    return object
end

local function Corner(parent, radius)
    return New("UICorner", {
        CornerRadius = UDim.new(0, radius)
    }, parent)
end

local function Stroke(parent, color, transparency, thickness)
    return New("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1
    }, parent)
end

local function Tween(object, properties, duration, style, direction)
    return TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.25,
            style or Enum.EasingStyle.Quint,
            direction or Enum.EasingDirection.Out
        ),
        properties
    )
end

local function IsTerminated()
    return not Singleton.Parent
        or Singleton:GetAttribute("Terminate") == true
end

----------------------------------------------------------------
-- GUI ROOT
----------------------------------------------------------------

local Gui = New("ScreenGui", {
    Name = "V3INN_Gold_Performance",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 500
}, PlayerGui)

----------------------------------------------------------------
-- FPS HUD
----------------------------------------------------------------

local FPSGui = New("ScreenGui", {
    Name = "V3INN_Gold_Performance_HUD",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 490
}, PlayerGui)

local HUD = New("Frame", {
    Size = UDim2.fromOffset(185, 64),
    Position = UDim2.new(1, -205, 0, 20),
    BackgroundColor3 = Config.Colors.Black2,
    BorderSizePixel = 0
}, FPSGui)

Corner(HUD, 11)
Stroke(HUD, Config.Colors.Border, 0.15, 1)

local HUDTitle = New("TextLabel", {
    Position = UDim2.fromOffset(13, 8),
    Size = UDim2.new(1, -26, 0, 17),
    BackgroundTransparency = 1,
    Text = "V3INN  //  PERFORMANCE",
    TextColor3 = Config.Colors.GoldBright,
    TextSize = 9,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, HUD)

local HUDStats = New("TextLabel", {
    Position = UDim2.fromOffset(13, 27),
    Size = UDim2.new(1, -26, 0, 25),
    BackgroundTransparency = 1,
    Text = "FPS --    PING --    RAM --",
    TextColor3 = Config.Colors.Text,
    TextSize = 10,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left
}, HUD)

local HUDLine = New("Frame", {
    Position = UDim2.fromOffset(13, 55),
    Size = UDim2.new(1, -26, 0, 2),
    BackgroundColor3 = Config.Colors.Gold,
    BorderSizePixel = 0
}, HUD)

Corner(HUDLine, 2)

----------------------------------------------------------------
-- MAIN WINDOW
----------------------------------------------------------------

local Main = New("Frame", {
    Size = UDim2.fromOffset(Config.Width, Config.Height),
    Position = UDim2.new(0.5, -Config.Width / 2, 0.5, -Config.Height / 2),
    BackgroundColor3 = Config.Colors.Black,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, Gui)

Corner(Main, 15)
Stroke(Main, Config.Colors.Border, 0.05, 1)

----------------------------------------------------------------
-- HEADER
----------------------------------------------------------------

local Header = New("Frame", {
    Size = UDim2.new(1, 0, 0, 70),
    BackgroundColor3 = Config.Colors.Panel,
    BorderSizePixel = 0
}, Main)

local HeaderGradient = New("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Config.Colors.Panel),
        ColorSequenceKeypoint.new(0.55, Config.Colors.Panel2),
        ColorSequenceKeypoint.new(1, Config.Colors.Panel)
    })
}, Header)

local GoldLine = New("Frame", {
    Position = UDim2.new(0, 0, 1, -2),
    Size = UDim2.new(1, 0, 0, 2),
    BackgroundColor3 = Config.Colors.Gold,
    BorderSizePixel = 0
}, Header)

local GoldGradient = New("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Config.Colors.GoldDark),
        ColorSequenceKeypoint.new(0.5, Config.Colors.GoldBright),
        ColorSequenceKeypoint.new(1, Config.Colors.GoldDark)
    })
}, GoldLine)

local Logo = New("TextLabel", {
    Position = UDim2.fromOffset(24, 13),
    Size = UDim2.fromOffset(150, 27),
    BackgroundTransparency = 1,
    Text = "V3INN",
    TextColor3 = Config.Colors.Text,
    TextSize = 22,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextXAlignment.Left
}, Header)

local Subtitle = New("TextLabel", {
    Position = UDim2.fromOffset(25, 39),
    Size = UDim2.fromOffset(230, 17),
    BackgroundTransparency = 1,
    Text = Config.Subtitle .. "  //  ENV STUDIO",
    TextColor3 = Config.Colors.Gold,
    TextSize = 9,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, Header)

local Status = New("Frame", {
    Position = UDim2.new(1, -255, 0, 18),
    Size = UDim2.fromOffset(115, 32),
    BackgroundColor3 = Config.Colors.Panel2,
    BorderSizePixel = 0
}, Header)

Corner(Status, 8)
Stroke(Status, Config.Colors.Border, 0.35, 1)

local StatusDot = New("Frame", {
    Position = UDim2.fromOffset(11, 12),
    Size = UDim2.fromOffset(8, 8),
    BackgroundColor3 = Config.Colors.Green,
    BorderSizePixel = 0
}, Status)

Corner(StatusDot, 8)

local StatusText = New("TextLabel", {
    Position = UDim2.fromOffset(28, 6),
    Size = UDim2.fromOffset(78, 20),
    BackgroundTransparency = 1,
    Text = "ONLINE",
    TextColor3 = Config.Colors.SubText,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, Status)

local Minimize = New("TextButton", {
    Position = UDim2.new(1, -93, 0, 14),
    Size = UDim2.fromOffset(32, 32),
    BackgroundColor3 = Config.Colors.Panel2,
    Text = "—",
    TextColor3 = Config.Colors.SubText,
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false
}, Header)

Corner(Minimize, 8)

local Close = New("TextButton", {
    Position = UDim2.new(1, -52, 0, 14),
    Size = UDim2.fromOffset(32, 32),
    BackgroundColor3 = Config.Colors.Panel2,
    Text = "×",
    TextColor3 = Config.Colors.SubText,
    TextSize = 17,
    Font = Enum.Font.GothamMedium,
    AutoButtonColor = false
}, Header)

Corner(Close, 8)

----------------------------------------------------------------
-- SIDEBAR
----------------------------------------------------------------

local Sidebar = New("Frame", {
    Position = UDim2.fromOffset(0, 70),
    Size = UDim2.new(0, 180, 1, -70),
    BackgroundColor3 = Config.Colors.Panel,
    BorderSizePixel = 0
}, Main)

New("UIPadding", {
    PaddingTop = UDim.new(0, 16),
    PaddingLeft = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 12)
}, Sidebar)

New("UIListLayout", {
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder
}, Sidebar)

local Content = New("Frame", {
    Position = UDim2.fromOffset(180, 70),
    Size = UDim2.new(1, -180, 1, -70),
    BackgroundColor3 = Config.Colors.Black,
    BorderSizePixel = 0
}, Main)

New("UIPadding", {
    PaddingTop = UDim.new(0, 23),
    PaddingLeft = UDim.new(0, 28),
    PaddingRight = UDim.new(0, 28)
}, Content)

local Tabs = {}
local Pages = {}

----------------------------------------------------------------
-- PAGE SYSTEM
----------------------------------------------------------------

local function CreatePage(name)
    local page = New("ScrollingFrame", {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Config.Colors.Gold,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false
    }, Content)

    New("UIListLayout", {
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)

    Pages[name] = page
    return page
end

local function BuildTabIcon(iconLabel, iconType)
    -- Graphical icons built entirely from Roblox UI primitives.
    -- This avoids missing-font glyphs such as ◈, ⌘ and ◇.

    iconLabel.Text = ""

    local function part(props)
        props.BackgroundColor3 = iconLabel.TextColor3
        props.BorderSizePixel = 0
        return New("Frame", props, iconLabel)
    end

    local function circle(props)
        local frame = part(props)
        Corner(frame, 1)
        return frame
    end

    local function outline(frame, thickness)
        Stroke(frame, iconLabel.TextColor3, 0.05, thickness or 1)
        frame.BackgroundTransparency = 1
    end

    if iconType == "performance" then
        local glow = circle({
            Position = UDim2.fromOffset(5, 10),
            Size = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 0.9,
        })
        outline(glow, 1)

        local diamond = part({
            Position = UDim2.fromOffset(7, 12),
            Size = UDim2.fromOffset(10, 10),
            Rotation = 45,
        })
        Corner(diamond, 0.18)

        circle({
            Position = UDim2.fromOffset(10, 15),
            Size = UDim2.fromOffset(4, 4),
        })

    elseif iconType == "audit" then
        local lens = circle({
            Position = UDim2.fromOffset(4, 8),
            Size = UDim2.fromOffset(13, 13),
            BackgroundTransparency = 1,
        })
        outline(lens, 1.5)

        local handle = part({
            Position = UDim2.fromOffset(15, 20),
            Size = UDim2.fromOffset(7, 2),
            Rotation = 45,
        })
        Corner(handle, 1)

        circle({
            Position = UDim2.fromOffset(9, 13),
            Size = UDim2.fromOffset(3, 3),
            BackgroundTransparency = 0.2,
        })

    elseif iconType == "diagnostics" then
        for _, data in ipairs({
            {6, 15, 3, 9},
            {11, 11, 3, 13},
            {16, 7, 3, 17},
        }) do
            part({
                Position = UDim2.fromOffset(data[1], data[2]),
                Size = UDim2.fromOffset(data[3], data[4]),
            })
        end

        part({
            Position = UDim2.fromOffset(4, 20),
            Size = UDim2.fromOffset(17, 1),
            BackgroundTransparency = 0.35,
        })

    elseif iconType == "settings" then
        local core = circle({
            Position = UDim2.fromOffset(8, 12),
            Size = UDim2.fromOffset(8, 8),
            BackgroundTransparency = 1,
        })
        outline(core, 1.4)

        for angle = 0, 315, 45 do
            local tooth = part({
                Position = UDim2.fromOffset(10, 5),
                Size = UDim2.fromOffset(4, 7),
                Rotation = angle,
            })
            Corner(tooth, 0.35)
        end

    elseif iconType == "environment" then
        circle({
            Position = UDim2.fromOffset(8, 12),
            Size = UDim2.fromOffset(8, 8),
        })

        for angle = 0, 315, 45 do
            local ray = part({
                Position = UDim2.fromOffset(10, 4),
                Size = UDim2.fromOffset(3, 6),
                Rotation = angle,
            })
            Corner(ray, 1)
        end

        local horizon = part({
            Position = UDim2.fromOffset(4, 24),
            Size = UDim2.fromOffset(16, 2),
            BackgroundTransparency = 0.25,
        })
        Corner(horizon, 1)
    end

    -- Existing tab selection code changes TextColor3 on the icon
    -- container. Mirror that color into all graphical primitives.
    local function syncIconColor()
        local color = iconLabel.TextColor3

        for _, child in ipairs(iconLabel:GetDescendants()) do
            if child:IsA("Frame") then
                child.BackgroundColor3 = color

                local stroke = child:FindFirstChildOfClass("UIStroke")
                if stroke then
                    stroke.Color = color
                end
            end
        end
    end

    iconLabel:GetPropertyChangedSignal("TextColor3"):Connect(syncIconColor)
    syncIconColor()
end

local function CreateTab(name, icon, order)
    local button = New("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 43),
        BackgroundColor3 = Config.Colors.Panel,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = order
    }, Sidebar)

    Corner(button, 9)

    local iconLabel = New("TextLabel", {
        Position = UDim2.fromOffset(13, 0),
        Size = UDim2.fromOffset(24, 43),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Config.Colors.SubText,
        TextSize = 14,
        Font = Enum.Font.GothamBold
    }, button)

    BuildTabIcon(iconLabel, icon)

    local label = New("TextLabel", {
        Position = UDim2.fromOffset(43, 0),
        Size = UDim2.new(1, -50, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Config.Colors.SubText,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left
    }, button)

    Tabs[name] = {
        Button = button,
        Icon = iconLabel,
        Label = label
    }

    return button
end

CreateTab("Performance", "performance", 1)
CreateTab("Command Audit", "audit", 2)
CreateTab("Diagnostics", "diagnostics", 3)
CreateTab("Settings", "settings", 4)

local PerformancePage = CreatePage("Performance")
local CommandPage = CreatePage("Command Audit")
local DiagnosticsPage = CreatePage("Diagnostics")
local SettingsPage = CreatePage("Settings")

----------------------------------------------------------------
-- UI HELPERS
----------------------------------------------------------------

local function HeaderBlock(parent, title, description)
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundTransparency = 1
    }, parent)

    New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Config.Colors.Text,
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, holder)

    New("TextLabel", {
        Position = UDim2.fromOffset(0, 30),
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = description,
        TextColor3 = Config.Colors.SubText,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    }, holder)

    return holder
end

local function Section(parent, title)
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1
    }, parent)

    New("TextLabel", {
        Position = UDim2.fromOffset(2, 7),
        Size = UDim2.new(1, -4, 0, 16),
        BackgroundTransparency = 1,
        Text = string.upper(title),
        TextColor3 = Config.Colors.Gold,
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, holder)

    return holder
end

local function Card(parent, height)
    local card = New("Frame", {
        Size = UDim2.new(1, -4, 0, height or 74),
        BackgroundColor3 = Config.Colors.Panel,
        BorderSizePixel = 0
    }, parent)

    Corner(card, 10)
    Stroke(card, Config.Colors.Border, 0.45, 1)

    return card
end

local function Toggle(parent, title, description, default, callback)
    local card = Card(parent, 70)

    New("TextLabel", {
        Position = UDim2.fromOffset(15, 12),
        Size = UDim2.new(1, -100, 0, 20),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Config.Colors.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)

    New("TextLabel", {
        Position = UDim2.fromOffset(15, 34),
        Size = UDim2.new(1, -115, 0, 25),
        BackgroundTransparency = 1,
        Text = description,
        TextColor3 = Config.Colors.SubText,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)

    local button = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(48, 26),
        BackgroundColor3 = default and Config.Colors.Gold or Config.Colors.Off,
        Text = "",
        AutoButtonColor = false
    }, card)

    Corner(button, 20)

    local knob = New("Frame", {
        Size = UDim2.fromOffset(20, 20),
        Position = default
            and UDim2.new(1, -23, 0.5, -10)
            or UDim2.new(0, 3, 0.5, -10),
        BackgroundColor3 = Config.Colors.Text,
        BorderSizePixel = 0
    }, button)

    Corner(knob, 20)

    local state = default

    local function Set(value)
        state = value

        Tween(button, {
            BackgroundColor3 = value and Config.Colors.Gold or Config.Colors.Off
        }, 0.18):Play()

        Tween(knob, {
            Position = value
                and UDim2.new(1, -23, 0.5, -10)
                or UDim2.new(0, 3, 0.5, -10)
        }, 0.18):Play()

        if callback then
            callback(value)
        end
    end

    button.Activated:Connect(function()
        Set(not state)
    end)

    return {
        Set = Set,
        Get = function()
            return state
        end
    }
end

local function Action(parent, title, description, callback)
    local card = Card(parent, 70)

    New("TextLabel", {
        Position = UDim2.fromOffset(15, 12),
        Size = UDim2.new(1, -160, 0, 20),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Config.Colors.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)

    New("TextLabel", {
        Position = UDim2.fromOffset(15, 34),
        Size = UDim2.new(1, -170, 0, 24),
        BackgroundTransparency = 1,
        Text = description,
        TextColor3 = Config.Colors.SubText,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)

    local button = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(105, 34),
        BackgroundColor3 = Config.Colors.GoldDark,
        Text = "RUN",
        TextColor3 = Config.Colors.Text,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false
    }, card)

    Corner(button, 8)

    button.MouseEnter:Connect(function()
        Tween(button, {
            BackgroundColor3 = Config.Colors.Gold
        }, 0.12):Play()
    end)

    button.MouseLeave:Connect(function()
        Tween(button, {
            BackgroundColor3 = Config.Colors.GoldDark
        }, 0.12):Play()
    end)

    button.Activated:Connect(function()
        if callback then
            callback()
        end
    end)

    return card
end

local function Slider(parent, title, minimum, maximum, default, callback)
    local card = Card(parent, 84)

    New("TextLabel", {
        Position = UDim2.fromOffset(15, 11),
        Size = UDim2.new(1, -100, 0, 20),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Config.Colors.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)

    local valueLabel = New("TextLabel", {
        Position = UDim2.new(1, -75, 0, 11),
        Size = UDim2.fromOffset(60, 20),
        BackgroundTransparency = 1,
        Text = tostring(default),
        TextColor3 = Config.Colors.GoldBright,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right
    }, card)

    local track = New("TextButton", {
        Position = UDim2.fromOffset(15, 52),
        Size = UDim2.new(1, -30, 0, 7),
        BackgroundColor3 = Config.Colors.Panel2,
        Text = "",
        AutoButtonColor = false
    }, card)

    Corner(track, 7)

    local initial = math.clamp(
        (default - minimum) / (maximum - minimum),
        0,
        1
    )

    local fill = New("Frame", {
        Size = UDim2.new(initial, 0, 1, 0),
        BackgroundColor3 = Config.Colors.Gold,
        BorderSizePixel = 0
    }, track)

    Corner(fill, 7)

    local knob = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(initial, 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Config.Colors.Text,
        BorderSizePixel = 0
    }, track)

    Corner(knob, 14)

    local dragging = false
    local value = default

    local function Update(x)
        local pct = math.clamp(
            (x - track.AbsolutePosition.X) / track.AbsoluteSize.X,
            0,
            1
        )

        value = math.floor(minimum + (maximum - minimum) * pct + 0.5)

        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valueLabel.Text = tostring(value)

        if callback then
            callback(value)
        end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            Update(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            Update(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = false
        end
    end)

    return {
        Get = function()
            return value
        end
    }
end

----------------------------------------------------------------
-- NOTIFICATIONS
----------------------------------------------------------------

local NotificationHolder = New("Frame", {
    Position = UDim2.new(1, -330, 0, 100),
    Size = UDim2.fromOffset(310, 400),
    BackgroundTransparency = 1
}, FPSGui)

New("UIListLayout", {
    Padding = UDim.new(0, 8),
    VerticalAlignment = Enum.VerticalAlignment.Top
}, NotificationHolder)

local function Notify(title, message, kind)
    local accent = Config.Colors.Gold

    if kind == "success" then
        accent = Config.Colors.Green
    elseif kind == "warning" then
        accent = Config.Colors.Orange
    elseif kind == "error" then
        accent = Config.Colors.Red
    end

    local box = New("Frame", {
        Size = UDim2.new(1, 0, 0, 68),
        BackgroundColor3 = Config.Colors.Panel,
        BorderSizePixel = 0
    }, NotificationHolder)

    Corner(box, 10)
    Stroke(box, Config.Colors.Border, 0.25, 1)

    local bar = New("Frame", {
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(3, 68),
        BackgroundColor3 = accent,
        BorderSizePixel = 0
    }, box)

    Corner(bar, 3)

    New("TextLabel", {
        Position = UDim2.fromOffset(15, 10),
        Size = UDim2.new(1, -25, 0, 19),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Config.Colors.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, box)

    New("TextLabel", {
        Position = UDim2.fromOffset(15, 31),
        Size = UDim2.new(1, -25, 0, 27),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = Config.Colors.SubText,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left
    }, box)

    box.Position = UDim2.fromOffset(35, 0)

    Tween(box, {
        Position = UDim2.fromOffset(0, 0)
    }, 0.28):Play()

    task.delay(4, function()
        if box.Parent then
            local out = Tween(box, {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(35, 0)
            }, 0.25)

            out:Play()
            out.Completed:Connect(function()
                box:Destroy()
            end)
        end
    end)
end

----------------------------------------------------------------
-- PERFORMANCE ENGINE
----------------------------------------------------------------

local Original = {
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
    Brightness = Lighting.Brightness,
}

local ModifiedInstances = {}

local function SetSafeVisualMode(enabled)
    if enabled then
        Original.GlobalShadows = Lighting.GlobalShadows
        Original.FogEnd = Lighting.FogEnd

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000

        for _, object in ipairs(workspace:GetDescendants()) do
            if object:IsA("ParticleEmitter")
                or object:IsA("Trail")
                or object:IsA("Beam") then

                if ModifiedInstances[object] == nil then
                    ModifiedInstances[object] = object.Enabled
                end

                object.Enabled = false
            end
        end

        for _, object in ipairs(workspace:GetDescendants()) do
            if object:IsA("BasePart") then
                if ModifiedInstances[object] == nil then
                    ModifiedInstances[object] = object.Material
                end

                -- Keep geometry intact; only switch expensive material
                -- rendering to a cheaper material.
                if object.Material == Enum.Material.Neon
                    or object.Material == Enum.Material.Glass then
                    object.Material = Enum.Material.SmoothPlastic
                end
            end
        end
    else
        Lighting.GlobalShadows = Original.GlobalShadows
        Lighting.FogEnd = Original.FogEnd

        for object, originalValue in pairs(ModifiedInstances) do
            if object and object.Parent then
                if object:IsA("ParticleEmitter")
                    or object:IsA("Trail")
                    or object:IsA("Beam") then

                    object.Enabled = originalValue
                elseif object:IsA("BasePart")
                    and typeof(originalValue) == "EnumItem" then

                    object.Material = originalValue
                end
            end
        end

        table.clear(ModifiedInstances)
    end
end

local function ApplyPreset(name)
    State.Preset = name

    if name == "Quality" then
        SetSafeVisualMode(false)
    elseif name == "Balanced" then
        SetSafeVisualMode(State.FPSBoost)
    elseif name == "Performance" then
        State.FPSBoost = true
        SetSafeVisualMode(true)
    elseif name == "Maximum" then
        State.FPSBoost = true
        SetSafeVisualMode(true)

        -- Disable local post-processing effects only.
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                if ModifiedInstances[effect] == nil then
                    ModifiedInstances[effect] = effect.Enabled
                end
                effect.Enabled = false
            end
        end
    end

    Notify(
        "Performance Preset",
        name .. " preset applied.",
        "success"
    )
end

----------------------------------------------------------------
-- PERFORMANCE PAGE
----------------------------------------------------------------

HeaderBlock(
    PerformancePage,
    "Performance",
    "Tune client-side rendering and monitor your live performance."
)

Section(PerformancePage, "BOOST")

local BoostToggle = Toggle(
    PerformancePage,
    "FPS Optimizer",
    "Reduce selected client-side rendering costs without touching gameplay logic.",
    false,
    function(enabled)
        State.FPSBoost = enabled
        SetSafeVisualMode(enabled)

        Notify(
            "FPS Optimizer",
            enabled and "Optimization enabled." or "Optimization disabled.",
            enabled and "success" or "warning"
        )
    end
)

Action(
    PerformancePage,
    "Maximum Performance",
    "Apply the strongest safe client-side visual reduction.",
    function()
        ApplyPreset("Maximum")
        BoostToggle.Set(true)
    end
)

Section(PerformancePage, "PRESETS")

local presetCard = Card(PerformancePage, 118)

local presetButtons = {}

local presets = {
    {"Quality", 0},
    {"Balanced", 1},
    {"Performance", 2},
    {"Maximum", 3},
}

for i, info in ipairs(presets) do
    local name = info[1]

    local button = New("TextButton", {
        Position = UDim2.fromOffset(12 + ((i - 1) * 145), 18),
        Size = UDim2.fromOffset(132, 38),
        BackgroundColor3 = name == State.Preset
            and Config.Colors.GoldDark
            or Config.Colors.Panel2,
        Text = name,
        TextColor3 = Config.Colors.Text,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false
    }, presetCard)

    Corner(button, 8)

    presetButtons[name] = button

    button.Activated:Connect(function()
        ApplyPreset(name)

        for presetName, presetButton in pairs(presetButtons) do
            presetButton.BackgroundColor3 =
                presetName == name
                and Config.Colors.GoldDark
                or Config.Colors.Panel2
        end
    end)
end

New("TextLabel", {
    Position = UDim2.fromOffset(15, 68),
    Size = UDim2.new(1, -30, 0, 35),
    BackgroundTransparency = 1,
    Text = "Maximum is intended for low-end testing. Some visual effects may be reduced.",
    TextColor3 = Config.Colors.SubText,
    TextSize = 9,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left
}, presetCard)

Section(PerformancePage, "LIVE METRICS")

local metricsCard = Card(PerformancePage, 112)

local MetricFPS = New("TextLabel", {
    Position = UDim2.fromOffset(16, 16),
    Size = UDim2.fromOffset(145, 35),
    BackgroundTransparency = 1,
    Text = "FPS\n--",
    TextColor3 = Config.Colors.Text,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, metricsCard)

local MetricPing = New("TextLabel", {
    Position = UDim2.fromOffset(180, 16),
    Size = UDim2.fromOffset(145, 35),
    BackgroundTransparency = 1,
    Text = "PING\n--",
    TextColor3 = Config.Colors.Text,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, metricsCard)

local MetricMemory = New("TextLabel", {
    Position = UDim2.fromOffset(344, 16),
    Size = UDim2.fromOffset(145, 35),
    BackgroundTransparency = 1,
    Text = "MEMORY\n--",
    TextColor3 = Config.Colors.Text,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, metricsCard)

local MetricPreset = New("TextLabel", {
    Position = UDim2.fromOffset(508, 16),
    Size = UDim2.fromOffset(140, 35),
    BackgroundTransparency = 1,
    Text = "PRESET\n" .. State.Preset,
    TextColor3 = Config.Colors.GoldBright,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, metricsCard)

----------------------------------------------------------------
-- COMMAND AUDIT
----------------------------------------------------------------

HeaderBlock(
    CommandPage,
    "Command Audit",
    "Scan client-visible game code for command-like definitions."
)

Section(CommandPage, "IMPORTANT")

local auditInfo = Card(CommandPage, 86)

New("TextLabel", {
    Position = UDim2.fromOffset(15, 13),
    Size = UDim2.new(1, -30, 0, 55),
    BackgroundTransparency = 1,
    Text = "This audit only examines code that the client can legitimately see, such as ReplicatedStorage and PlayerGui. It does not read hidden server scripts or attempt to execute admin commands.",
    TextColor3 = Config.Colors.SubText,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left
}, auditInfo)

local scanStatusCard = Card(CommandPage, 82)

local ScanStatus = New("TextLabel", {
    Position = UDim2.fromOffset(15, 12),
    Size = UDim2.new(1, -160, 0, 22),
    BackgroundTransparency = 1,
    Text = "NOT SCANNED",
    TextColor3 = Config.Colors.SubText,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, scanStatusCard)

local ScanCount = New("TextLabel", {
    Position = UDim2.fromOffset(15, 38),
    Size = UDim2.new(1, -160, 0, 18),
    BackgroundTransparency = 1,
    Text = "0 possible command definitions",
    TextColor3 = Config.Colors.SubText,
    TextSize = 9,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left
}, scanStatusCard)

local ScanButton = New("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -14, 0.5, 0),
    Size = UDim2.fromOffset(120, 36),
    BackgroundColor3 = Config.Colors.GoldDark,
    Text = "SCAN CODE",
    TextColor3 = Config.Colors.Text,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false
}, scanStatusCard)

Corner(ScanButton, 8)

local ResultsFrame = New("Frame", {
    Size = UDim2.new(1, -4, 0, 230),
    BackgroundColor3 = Config.Colors.Panel,
    BorderSizePixel = 0
}, CommandPage)

Corner(ResultsFrame, 10)
Stroke(ResultsFrame, Config.Colors.Border, 0.45, 1)

local ResultsTitle = New("TextLabel", {
    Position = UDim2.fromOffset(15, 12),
    Size = UDim2.new(1, -30, 0, 22),
    BackgroundTransparency = 1,
    Text = "AUDIT RESULTS  //  FINDINGS",
    TextColor3 = Config.Colors.Gold,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, ResultsFrame)

local ResultsScroll = New("ScrollingFrame", {
    Position = UDim2.fromOffset(12, 42),
    Size = UDim2.new(1, -24, 1, -54),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = Config.Colors.Gold,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, ResultsFrame)

New("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder
}, ResultsScroll)

local function ClearResults()
    for _, child in ipairs(ResultsScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    table.clear(State.ScanResults)
    State.CommandCount = 0
end

local function AddResult(path, kind, evidence)
    State.CommandCount += 1

    local row = New("Frame", {
        Size = UDim2.new(1, -4, 0, 52),
        BackgroundColor3 = Config.Colors.Panel2,
        BorderSizePixel = 0
    }, ResultsScroll)

    Corner(row, 7)

    New("TextLabel", {
        Position = UDim2.fromOffset(10, 7),
        Size = UDim2.new(1, -100, 0, 17),
        BackgroundTransparency = 1,
        Text = kind .. "  •  " .. path,
        TextColor3 = Config.Colors.Text,
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)

    New("TextLabel", {
        Position = UDim2.fromOffset(10, 26),
        Size = UDim2.new(1, -20, 0, 17),
        BackgroundTransparency = 1,
        Text = evidence,
        TextColor3 = Config.Colors.SubText,
        TextSize = 8,
        Font = Enum.Font.Gotham,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)

    table.insert(State.ScanResults, {
        Path = path,
        Kind = kind,
        Evidence = evidence
    })
end

local CommandKeywords = {
    "admin",
    "command",
    "commands",
    "cmd",
    "permission",
    "permissions",
    "moderator",
    "moderation",
    "owner",
    "rank",
    "staff",
    "kick",
    "ban",
    "mute",
    "teleport",
}

local function LooksCommandLike(name)
    local lower = string.lower(name)

    for _, keyword in ipairs(CommandKeywords) do
        if string.find(lower, keyword, 1, true) then
            return true
        end
    end

    return false
end

local function ScanVisibleCode()
    if State.Scanning then
        return
    end

    State.Scanning = true
    State.ScanFinished = false

    ClearResults()

    ScanStatus.Text = "SCANNING..."
    ScanStatus.TextColor3 = Config.Colors.GoldBright
    ScanCount.Text = "Inspecting client-visible objects..."

    Notify(
        "Command Audit",
        "Scanning client-visible code and definitions...",
        "warning"
    )

    task.spawn(function()
        local containers = {
            ReplicatedStorage,
            PlayerGui,
        }

        local inspected = 0

        for _, container in ipairs(containers) do
            if IsTerminated() then
                return
            end

            for _, object in ipairs(container:GetDescendants()) do
                if IsTerminated() then
                    return
                end

                inspected += 1

                if object:IsA("RemoteEvent")
                    or object:IsA("RemoteFunction") then

                    if LooksCommandLike(object.Name) then
                        AddResult(
                            object:GetFullName(),
                            "REMOTE",
                            "Name matches a command/permission keyword."
                        )
                    end

                elseif object:IsA("ModuleScript")
                    or object:IsA("LocalScript") then

                    if LooksCommandLike(object.Name) then
                        AddResult(
                            object:GetFullName(),
                            object.ClassName,
                            "Name matches a command-related keyword."
                        )
                    end
                end

                if inspected % 100 == 0 then
                    task.wait()
                end
            end
        end

        State.Scanning = false
        State.ScanFinished = true

        ScanStatus.Text = "SCAN COMPLETE"
        ScanStatus.TextColor3 = Config.Colors.Green
        ScanCount.Text = tostring(State.CommandCount)
            .. " possible command-related definitions found."

        if State.CommandCount > 0 then
            Notify(
                "Command Audit",
                tostring(State.CommandCount)
                    .. " command-like definitions found. Review them in the audit panel.",
                "success"
            )
        else
            Notify(
                "Command Audit",
                "No command-like definitions were found in client-visible objects.",
                "warning"
            )
        end
    end)
end

ScanButton.Activated:Connect(ScanVisibleCode)

----------------------------------------------------------------
-- DIAGNOSTICS
----------------------------------------------------------------

HeaderBlock(
    DiagnosticsPage,
    "Diagnostics",
    "Useful runtime information for your own development testing."
)

Section(DiagnosticsPage, "CLIENT")

local diagCard = Card(DiagnosticsPage, 160)

local DiagText = New("TextLabel", {
    Position = UDim2.fromOffset(15, 15),
    Size = UDim2.new(1, -30, 1, -30),
    BackgroundTransparency = 1,
    Text = "Collecting diagnostics...",
    TextColor3 = Config.Colors.SubText,
    TextSize = 10,
    Font = Enum.Font.Code,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top
}, diagCard)

local function GetPing()
    local ok, value = pcall(function()
        return Player:GetNetworkPing() * 1000
    end)

    if ok then
        return math.floor(value + 0.5)
    end

    return 0
end

local function GetMemory()
    local ok, value = pcall(function()
        return Stats:GetTotalMemoryUsageMb()
    end)

    if ok then
        return math.floor(value * 10 + 0.5) / 10
    end

    return 0
end

----------------------------------------------------------------
-- SETTINGS
----------------------------------------------------------------

HeaderBlock(
    SettingsPage,
    "Settings",
    "Customize the V3INN Gold performance interface."
)

Section(SettingsPage, "HUD")

local HUDToggle = Toggle(
    SettingsPage,
    "Performance HUD",
    "Keep FPS, ping and memory visible even when the menu is closed.",
    true,
    function(enabled)
        HUD.Visible = enabled
    end
)

Toggle(
    SettingsPage,
    "Gold Pulse",
    "Animate the gold accent line.",
    true,
    function(enabled)
        State.GoldPulse = enabled
    end
)

Action(
    SettingsPage,
    "Reset Performance",
    "Restore visual settings changed by the optimizer.",
    function()
        SetSafeVisualMode(false)
        State.FPSBoost = false
        State.Preset = "Balanced"

        Notify(
            "Performance",
            "Client-side visual changes restored.",
            "success"
        )
    end
)

Action(
    SettingsPage,
    "Run Command Audit",
    "Open the audit page and scan client-visible definitions.",
    function()
        for pageName, page in pairs(Pages) do
            page.Visible = pageName == "Command Audit"
        end

        for tabName, tab in pairs(Tabs) do
            local selected = tabName == "Command Audit"

            tab.Button.BackgroundColor3 =
                selected
                and Config.Colors.Panel2
                or Config.Colors.Panel

            tab.Icon.TextColor3 =
                selected
                and Config.Colors.Gold
                or Config.Colors.SubText

            tab.Label.TextColor3 =
                selected
                and Config.Colors.Text
                or Config.Colors.SubText
        end
    end
)


----------------------------------------------------------------
-- V3INN GOLD // LOCAL ENVIRONMENT STUDIO
----------------------------------------------------------------
-- This section is intentionally separate from the performance engine.
-- It creates a fifth "Environment" tab in the V3INN menu.
--
-- Everything here is LOCAL presentation:
--   * no RemoteEvent calls
--   * no RemoteFunction calls
--   * no server map edits
--   * no changes to other players
--
-- Presets:
--   Default
--   Night Blue
--   Cloudy Morning
--   About To Rain
--   Wet Grass
--   Snow
--   Rocks
----------------------------------------------------------------

local EnvironmentStudio = {
    Current = "Default",
    ActiveSky = nil,
    ActiveAtmosphere = nil,
    ActiveColor = nil,
    OriginalSky = nil,
    OriginalAtmosphere = nil,
    OriginalColor = nil,
    OriginalClockTime = Lighting.ClockTime,
    OriginalBrightness = Lighting.Brightness,
    OriginalAmbient = Lighting.Ambient,
    OriginalOutdoorAmbient = Lighting.OutdoorAmbient,
    OriginalTerrainColors = {},
}

----------------------------------------------------------------
-- CAPTURE ORIGINAL LOCAL LOOK
----------------------------------------------------------------

do
    local sky = Lighting:FindFirstChildOfClass("Sky")
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    local color = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")

    if sky then
        EnvironmentStudio.OriginalSky = sky:Clone()
    end

    if atmosphere then
        EnvironmentStudio.OriginalAtmosphere = atmosphere:Clone()
    end

    if color then
        EnvironmentStudio.OriginalColor = color:Clone()
    end

    if workspace.Terrain then
        local terrain = workspace.Terrain

        for _, material in ipairs({
            Enum.Material.Grass,
            Enum.Material.Rock,
            Enum.Material.Sand,
            Enum.Material.Ground,
            Enum.Material.Snow,
        }) do
            pcall(function()
                EnvironmentStudio.OriginalTerrainColors[material] =
                    terrain:GetMaterialColor(material)
            end)
        end
    end
end

----------------------------------------------------------------
-- PRESET DATA
----------------------------------------------------------------

local EnvironmentStudioPresets = {
    ["Default"] = {
        ClockTime = nil,
        Brightness = nil,
        Ambient = nil,
        OutdoorAmbient = nil,

        Atmosphere = nil,
        Color = nil,
        Sky = nil,

        Ground = nil,
    },

    ["Night Blue"] = {
        ClockTime = 0.5,
        Brightness = 1.1,
        Ambient = Color3.fromRGB(36, 45, 80),
        OutdoorAmbient = Color3.fromRGB(20, 30, 58),

        Atmosphere = {
            Density = 0.38,
            Offset = 0.05,
            Color = Color3.fromRGB(62, 92, 160),
            Decay = Color3.fromRGB(18, 28, 62),
            Haze = 1.5,
            Glare = 0,
        },

        Color = {
            Brightness = -0.08,
            Contrast = 0.10,
            Saturation = -0.04,
            TintColor = Color3.fromRGB(170, 195, 255),
        },

        Sky = {
            CelestialBodiesShown = true,
            StarCount = 5000,
            SunAngularSize = 8,
            MoonAngularSize = 11,
        },

        Ground = {
            Grass = Color3.fromRGB(42, 65, 46),
            Rock = Color3.fromRGB(58, 61, 70),
            Sand = Color3.fromRGB(90, 85, 69),
            Ground = Color3.fromRGB(47, 61, 48),
            Snow = Color3.fromRGB(150, 164, 180),
        },
    },

    ["Cloudy Morning"] = {
        ClockTime = 8.0,
        Brightness = 1.6,
        Ambient = Color3.fromRGB(150, 158, 170),
        OutdoorAmbient = Color3.fromRGB(125, 133, 145),

        Atmosphere = {
            Density = 0.52,
            Offset = 0.15,
            Color = Color3.fromRGB(200, 208, 218),
            Decay = Color3.fromRGB(125, 135, 148),
            Haze = 2.1,
            Glare = 0,
        },

        Color = {
            Brightness = 0.03,
            Contrast = -0.04,
            Saturation = -0.08,
            TintColor = Color3.fromRGB(225, 232, 238),
        },

        Sky = {
            CelestialBodiesShown = false,
            StarCount = 0,
            SunAngularSize = 5,
            MoonAngularSize = 5,
        },

        Ground = {
            Grass = Color3.fromRGB(82, 108, 72),
            Rock = Color3.fromRGB(106, 107, 105),
            Sand = Color3.fromRGB(174, 168, 145),
            Ground = Color3.fromRGB(88, 103, 77),
            Snow = Color3.fromRGB(195, 202, 211),
        },
    },

    ["About To Rain"] = {
        ClockTime = 17.5,
        Brightness = 1.0,
        Ambient = Color3.fromRGB(78, 87, 102),
        OutdoorAmbient = Color3.fromRGB(55, 63, 76),

        Atmosphere = {
            Density = 0.62,
            Offset = 0.05,
            Color = Color3.fromRGB(105, 119, 140),
            Decay = Color3.fromRGB(52, 61, 76),
            Haze = 3.2,
            Glare = 0,
        },

        Color = {
            Brightness = -0.06,
            Contrast = 0.08,
            Saturation = -0.15,
            TintColor = Color3.fromRGB(190, 205, 225),
        },

        Sky = {
            CelestialBodiesShown = false,
            StarCount = 0,
            SunAngularSize = 3,
            MoonAngularSize = 3,
        },

        Ground = {
            Grass = Color3.fromRGB(45, 76, 50),
            Rock = Color3.fromRGB(70, 75, 81),
            Sand = Color3.fromRGB(105, 101, 86),
            Ground = Color3.fromRGB(48, 65, 52),
            Snow = Color3.fromRGB(160, 169, 182),
        },
    },

    ["Wet Grass"] = {
        ClockTime = 9.5,
        Brightness = 1.8,
        Ambient = Color3.fromRGB(105, 122, 105),
        OutdoorAmbient = Color3.fromRGB(82, 100, 82),

        Atmosphere = {
            Density = 0.30,
            Offset = 0.1,
            Color = Color3.fromRGB(178, 196, 184),
            Decay = Color3.fromRGB(90, 112, 94),
            Haze = 1.0,
            Glare = 0,
        },

        Color = {
            Brightness = 0,
            Contrast = 0.06,
            Saturation = 0.08,
            TintColor = Color3.fromRGB(225, 242, 226),
        },

        Sky = {
            CelestialBodiesShown = true,
            StarCount = 0,
            SunAngularSize = 10,
            MoonAngularSize = 5,
        },

        Ground = {
            Grass = Color3.fromRGB(38, 91, 44),
            Rock = Color3.fromRGB(68, 75, 69),
            Sand = Color3.fromRGB(127, 119, 91),
            Ground = Color3.fromRGB(43, 78, 46),
            Snow = Color3.fromRGB(190, 200, 194),
        },
    },

    ["Snow"] = {
        ClockTime = 11.0,
        Brightness = 2.1,
        Ambient = Color3.fromRGB(188, 198, 212),
        OutdoorAmbient = Color3.fromRGB(160, 171, 187),

        Atmosphere = {
            Density = 0.39,
            Offset = 0.2,
            Color = Color3.fromRGB(215, 225, 240),
            Decay = Color3.fromRGB(160, 170, 188),
            Haze = 1.2,
            Glare = 0.1,
        },

        Color = {
            Brightness = 0.06,
            Contrast = -0.02,
            Saturation = -0.18,
            TintColor = Color3.fromRGB(228, 238, 255),
        },

        Sky = {
            CelestialBodiesShown = false,
            StarCount = 0,
            SunAngularSize = 7,
            MoonAngularSize = 6,
        },

        Ground = {
            Grass = Color3.fromRGB(205, 218, 228),
            Rock = Color3.fromRGB(166, 174, 183),
            Sand = Color3.fromRGB(213, 218, 225),
            Ground = Color3.fromRGB(214, 221, 229),
            Snow = Color3.fromRGB(235, 239, 245),
        },
    },

    ["Rocks"] = {
        ClockTime = 14.0,
        Brightness = 1.45,
        Ambient = Color3.fromRGB(118, 118, 118),
        OutdoorAmbient = Color3.fromRGB(92, 92, 92),

        Atmosphere = {
            Density = 0.31,
            Offset = 0.08,
            Color = Color3.fromRGB(177, 181, 184),
            Decay = Color3.fromRGB(104, 107, 110),
            Haze = 1.0,
            Glare = 0,
        },

        Color = {
            Brightness = -0.02,
            Contrast = 0.10,
            Saturation = -0.22,
            TintColor = Color3.fromRGB(225, 225, 225),
        },

        Sky = {
            CelestialBodiesShown = true,
            StarCount = 0,
            SunAngularSize = 10,
            MoonAngularSize = 5,
        },

        Ground = {
            Grass = Color3.fromRGB(84, 91, 80),
            Rock = Color3.fromRGB(82, 84, 87),
            Sand = Color3.fromRGB(121, 118, 110),
            Ground = Color3.fromRGB(91, 93, 94),
            Snow = Color3.fromRGB(173, 177, 181),
        },
    },
}

----------------------------------------------------------------
-- ENVIRONMENT CLEANUP
----------------------------------------------------------------

local function DestroyEnvironmentObjects()
    if EnvironmentStudio.ActiveSky then
        pcall(function()
            EnvironmentStudio.ActiveSky:Destroy()
        end)
        EnvironmentStudio.ActiveSky = nil
    end

    if EnvironmentStudio.ActiveAtmosphere then
        pcall(function()
            EnvironmentStudio.ActiveAtmosphere:Destroy()
        end)
        EnvironmentStudio.ActiveAtmosphere = nil
    end

    if EnvironmentStudio.ActiveColor then
        pcall(function()
            EnvironmentStudio.ActiveColor:Destroy()
        end)
        EnvironmentStudio.ActiveColor = nil
    end
end

----------------------------------------------------------------
-- APPLY GROUND PALETTE
----------------------------------------------------------------

local function ApplyGroundPalette(palette)
    if not palette or not workspace.Terrain then
        return
    end

    local terrain = workspace.Terrain

    local mapping = {
        [Enum.Material.Grass] = palette.Grass,
        [Enum.Material.Rock] = palette.Rock,
        [Enum.Material.Sand] = palette.Sand,
        [Enum.Material.Ground] = palette.Ground,
        [Enum.Material.Snow] = palette.Snow,
    }

    for material, color in pairs(mapping) do
        if color then
            pcall(function()
                terrain:SetMaterialColor(material, color)
            end)
        end
    end
end

----------------------------------------------------------------
-- APPLY ENVIRONMENT PRESET
----------------------------------------------------------------

local function ApplyEnvironmentStudioPreset(name)
    local preset = EnvironmentStudioPresets[name]

    if not preset then
        Notify("Environment", "Unknown environment preset.", "error")
        return
    end

    DestroyEnvironmentObjects()

    if name == "Default" then
        Lighting.ClockTime = EnvironmentStudio.OriginalClockTime
        Lighting.Brightness = EnvironmentStudio.OriginalBrightness
        Lighting.Ambient = EnvironmentStudio.OriginalAmbient
        Lighting.OutdoorAmbient = EnvironmentStudio.OriginalOutdoorAmbient

        if EnvironmentStudio.OriginalSky then
            local restored = EnvironmentStudio.OriginalSky:Clone()
            restored.Name = "V3INN_LocalRestoredSky"
            restored.Parent = Lighting
            EnvironmentStudio.ActiveSky = restored
        end

        if EnvironmentStudio.OriginalAtmosphere then
            local restored = EnvironmentStudio.OriginalAtmosphere:Clone()
            restored.Name = "V3INN_LocalRestoredAtmosphere"
            restored.Parent = Lighting
            EnvironmentStudio.ActiveAtmosphere = restored
        end

        if EnvironmentStudio.OriginalColor then
            local restored = EnvironmentStudio.OriginalColor:Clone()
            restored.Name = "V3INN_LocalRestoredColor"
            restored.Parent = Lighting
            EnvironmentStudio.ActiveColor = restored
        end

        if workspace.Terrain then
            for material, color in pairs(EnvironmentStudio.OriginalTerrainColors) do
                pcall(function()
                    workspace.Terrain:SetMaterialColor(material, color)
                end)
            end
        end

        EnvironmentStudio.Current = "Default"

        Notify(
            "Environment",
            "Original local environment restored.",
            "success"
        )

        return
    end

    if preset.ClockTime then
        Lighting.ClockTime = preset.ClockTime
    end

    if preset.Brightness then
        Lighting.Brightness = preset.Brightness
    end

    if preset.Ambient then
        Lighting.Ambient = preset.Ambient
    end

    if preset.OutdoorAmbient then
        Lighting.OutdoorAmbient = preset.OutdoorAmbient
    end

    if preset.Atmosphere then
        local atmosphere = Instance.new("Atmosphere")
        atmosphere.Name = "V3INN_LocalEnvironmentAtmosphere"
        atmosphere.Density = preset.Atmosphere.Density
        atmosphere.Offset = preset.Atmosphere.Offset
        atmosphere.Color = preset.Atmosphere.Color
        atmosphere.Decay = preset.Atmosphere.Decay
        atmosphere.Haze = preset.Atmosphere.Haze
        atmosphere.Glare = preset.Atmosphere.Glare
        atmosphere.Parent = Lighting

        EnvironmentStudio.ActiveAtmosphere = atmosphere
    end

    if preset.Color then
        local color = Instance.new("ColorCorrectionEffect")
        color.Name = "V3INN_LocalEnvironmentColor"
        color.Brightness = preset.Color.Brightness
        color.Contrast = preset.Color.Contrast
        color.Saturation = preset.Color.Saturation
        color.TintColor = preset.Color.TintColor
        color.Parent = Lighting

        EnvironmentStudio.ActiveColor = color
    end

    if preset.Sky then
        local sky = Instance.new("Sky")
        sky.Name = "V3INN_LocalEnvironmentSky"

        sky.CelestialBodiesShown =
            preset.Sky.CelestialBodiesShown

        sky.StarCount =
            preset.Sky.StarCount

        sky.SunAngularSize =
            preset.Sky.SunAngularSize

        sky.MoonAngularSize =
            preset.Sky.MoonAngularSize

        -- Keep the game's existing sky textures if available.
        -- This gives the preset its atmosphere without replacing
        -- the game's artwork with a fake/unrelated map.
        local currentSky = Lighting:FindFirstChildOfClass("Sky")

        if currentSky then
            sky.SkyboxBk = currentSky.SkyboxBk
            sky.SkyboxDn = currentSky.SkyboxDn
            sky.SkyboxFt = currentSky.SkyboxFt
            sky.SkyboxLf = currentSky.SkyboxLf
            sky.SkyboxRt = currentSky.SkyboxRt
            sky.SkyboxUp = currentSky.SkyboxUp
        end

        sky.Parent = Lighting
        EnvironmentStudio.ActiveSky = sky
    end

    ApplyGroundPalette(preset.Ground)

    EnvironmentStudio.Current = name

    Notify(
        "Environment",
        name .. " applied locally.",
        "success"
    )
end

----------------------------------------------------------------
-- ENVIRONMENT PAGE
----------------------------------------------------------------

local EnvironmentPage = CreatePage("Environment")
local EnvironmentTab = CreateTab("Environment", "environment", 5)

HeaderBlock(
    EnvironmentPage,
    "Environment Studio",
    "Change the world mood locally without changing the actual game."
)

Section(EnvironmentPage, "ATMOSPHERE")

local environmentInfoCard = Card(EnvironmentPage, 78)

New("TextLabel", {
    Position = UDim2.fromOffset(15, 12),
    Size = UDim2.new(1, -30, 0, 52),
    BackgroundTransparency = 1,
    Text =
        "LOCAL ONLY  •  Other players are unaffected  •  "
        .. "No remotes are used. Pick a sky/weather mood and "
        .. "a matching ground palette.",
    TextColor3 = Config.Colors.SubText,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
}, environmentInfoCard)

Section(EnvironmentPage, "WEATHER / SKY MOODS")

local environmentCard = Card(EnvironmentPage, 205)

local environmentNames = {
    "Default",
    "Night Blue",
    "Cloudy Morning",
    "About To Rain",
    "Wet Grass",
    "Snow",
    "Rocks",
}

local environmentButtons = {}

for index, name in ipairs(environmentNames) do
    local column = (index - 1) % 2
    local row = math.floor((index - 1) / 2)

    local button = New("TextButton", {
        Position = UDim2.fromOffset(
            15 + column * 286,
            13 + row * 45
        ),
        Size = UDim2.fromOffset(270, 35),
        BackgroundColor3 =
            name == "Default"
            and Config.Colors.GoldDark
            or Config.Colors.Panel2,
        Text = name,
        TextColor3 = Config.Colors.Text,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
    }, environmentCard)

    Corner(button, 8)
    Stroke(button, Config.Colors.Border, 0.65, 1)

    environmentButtons[name] = button

    button.MouseEnter:Connect(function()
        Tween(button, {
            BackgroundColor3 = Config.Colors.GoldDark
        }, 0.12):Play()
    end)

    button.MouseLeave:Connect(function()
        Tween(button, {
            BackgroundColor3 =
                EnvironmentStudio.Current == name
                and Config.Colors.GoldDark
                or Config.Colors.Panel2
        }, 0.12):Play()
    end)

    button.Activated:Connect(function()
        ApplyEnvironmentStudioPreset(name)

        for presetName, presetButton in pairs(environmentButtons) do
            presetButton.BackgroundColor3 =
                presetName == EnvironmentStudio.Current
                and Config.Colors.GoldDark
                or Config.Colors.Panel2
        end
    end)
end

Section(EnvironmentPage, "GROUND PALETTES")

local groundCard = Card(EnvironmentPage, 125)

local groundDescriptions = {
    {
        "WET GRASS",
        "Deep green / darker wet-looking terrain",
        "Wet Grass",
    },
    {
        "SNOW",
        "Bright snowy terrain palette",
        "Snow",
    },
    {
        "ROCKS",
        "Grey stone / muted ground",
        "Rocks",
    },
    {
        "PLAIN GRASS",
        "Natural green daytime palette",
        "Cloudy Morning",
    },
}

for index, info in ipairs(groundDescriptions) do
    local column = (index - 1) % 2
    local row = math.floor((index - 1) / 2)

    local button = New("TextButton", {
        Position = UDim2.fromOffset(
            15 + column * 286,
            10 + row * 48
        ),
        Size = UDim2.fromOffset(270, 39),
        BackgroundColor3 = Config.Colors.Panel2,
        Text = info[1] .. "  •  " .. info[2],
        TextColor3 = Config.Colors.Text,
        TextSize = 8,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
    }, groundCard)

    Corner(button, 8)

    button.Activated:Connect(function()
        ApplyEnvironmentStudioPreset(info[3])
    end)
end

Section(EnvironmentPage, "CURRENT")

local environmentStatusCard = Card(EnvironmentPage, 70)

local environmentStatus = New("TextLabel", {
    Position = UDim2.fromOffset(15, 12),
    Size = UDim2.new(1, -30, 0, 22),
    BackgroundTransparency = 1,
    Text = "CURRENT: DEFAULT",
    TextColor3 = Config.Colors.GoldBright,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, environmentStatusCard)

local environmentStatusNote = New("TextLabel", {
    Position = UDim2.fromOffset(15, 35),
    Size = UDim2.new(1, -30, 0, 20),
    BackgroundTransparency = 1,
    Text = "Visual changes are local to this client.",
    TextColor3 = Config.Colors.SubText,
    TextSize = 9,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
}, environmentStatusCard)

----------------------------------------------------------------
-- ENVIRONMENT STATUS UPDATE
----------------------------------------------------------------

local function UpdateEnvironmentStatus()
    if environmentStatus then
        environmentStatus.Text =
            "CURRENT: "
            .. string.upper(EnvironmentStudio.Current)
    end
end

----------------------------------------------------------------
-- ENVIRONMENT TAB
----------------------------------------------------------------

EnvironmentTab.Activated:Connect(function()
    ShowPage("Environment")
    UpdateEnvironmentStatus()
end)

----------------------------------------------------------------
-- ENVIRONMENT MONITOR
----------------------------------------------------------------

task.spawn(function()
    while not IsTerminated() do
        task.wait(0.25)

        if environmentStatus
            and EnvironmentStudio.Current then

            environmentStatus.Text =
                "CURRENT: "
                .. string.upper(EnvironmentStudio.Current)
        end
    end
end)

----------------------------------------------------------------
-- ENVIRONMENT CLEANUP
----------------------------------------------------------------

local function RestoreEnvironmentStudio()
    pcall(function()
        DestroyEnvironmentObjects()

        Lighting.ClockTime =
            EnvironmentStudio.OriginalClockTime

        Lighting.Brightness =
            EnvironmentStudio.OriginalBrightness

        Lighting.Ambient =
            EnvironmentStudio.OriginalAmbient

        Lighting.OutdoorAmbient =
            EnvironmentStudio.OriginalOutdoorAmbient

        if workspace.Terrain then
            for material, color in pairs(
                EnvironmentStudio.OriginalTerrainColors
            ) do
                pcall(function()
                    workspace.Terrain:SetMaterialColor(
                        material,
                        color
                    )
                end)
            end
        end
    end)
end

----------------------------------------------------------------
-- END LOCAL ENVIRONMENT STUDIO
----------------------------------------------------------------

----------------------------------------------------------------
-- TAB SWITCHING
----------------------------------------------------------------

local function ShowPage(name)
    State.SelectedPage = name

    for pageName, page in pairs(Pages) do
        page.Visible = pageName == name
    end

    for tabName, tab in pairs(Tabs) do
        local selected = tabName == name

        Tween(tab.Button, {
            BackgroundColor3 = selected
                and Config.Colors.Panel2
                or Config.Colors.Panel
        }, 0.18):Play()

        Tween(tab.Icon, {
            TextColor3 = selected
                and Config.Colors.Gold
                or Config.Colors.SubText
        }, 0.18):Play()

        Tween(tab.Label, {
            TextColor3 = selected
                and Config.Colors.Text
                or Config.Colors.SubText
        }, 0.18):Play()
    end
end

for name, tab in pairs(Tabs) do
    tab.Button.Activated:Connect(function()
        ShowPage(name)
    end)
end

ShowPage("Performance")

----------------------------------------------------------------
-- DRAGGING
----------------------------------------------------------------

local dragging = false
local dragStart
local startPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

----------------------------------------------------------------
-- MINIMIZE
----------------------------------------------------------------

local NormalSize = Main.Size
local MinimizedSize = UDim2.fromOffset(Config.Width, 70)

Minimize.Activated:Connect(function()
    State.Minimized = not State.Minimized

    if State.Minimized then
        Tween(Main, {
            Size = MinimizedSize
        }, 0.3):Play()

        Minimize.Text = "+"
    else
        Tween(Main, {
            Size = NormalSize
        }, 0.3):Play()

        Minimize.Text = "—"
    end
end)

----------------------------------------------------------------
-- CLOSE
----------------------------------------------------------------

Close.Activated:Connect(function()
    State.MenuOpen = false

    Tween(Main, {
        Size = UDim2.fromOffset(Config.Width, 0)
    }, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In):Play()

    task.delay(0.24, function()
        if not IsTerminated() then
            Gui.Enabled = false
        end
    end)
end)

----------------------------------------------------------------
-- KEYBOARD TOGGLE
----------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or IsTerminated() then
        return
    end

    if input.KeyCode == Config.MenuKey then
        State.MenuOpen = not State.MenuOpen

        if State.MenuOpen then
            Gui.Enabled = true
            Main.Size = UDim2.fromOffset(Config.Width, 0)

            Tween(Main, {
                Size = State.Minimized
                    and MinimizedSize
                    or NormalSize
            }, 0.28):Play()
        else
            Tween(Main, {
                Size = UDim2.fromOffset(Config.Width, 0)
            }, 0.2):Play()

            task.delay(0.21, function()
                if not IsTerminated() then
                    Gui.Enabled = false
                end
            end)
        end
    end
end)

----------------------------------------------------------------
-- LIVE METRICS
----------------------------------------------------------------

local frameCounter = 0
local fpsTimer = 0

RunService.RenderStepped:Connect(function(dt)
    if IsTerminated() then
        return
    end

    frameCounter += 1
    fpsTimer += dt

    if fpsTimer >= 0.5 then
        State.FPS = math.floor(
            frameCounter / fpsTimer + 0.5
        )

        frameCounter = 0
        fpsTimer = 0

        State.Ping = GetPing()
        State.Memory = GetMemory()

        MetricFPS.Text =
            "FPS\n" .. tostring(State.FPS)

        MetricPing.Text =
            "PING\n" .. tostring(State.Ping) .. " ms"

        MetricMemory.Text =
            "MEMORY\n" .. tostring(State.Memory) .. " MB"

        MetricPreset.Text =
            "PRESET\n" .. State.Preset

        HUDStats.Text =
            "FPS " .. tostring(State.FPS)
            .. "    PING " .. tostring(State.Ping)
            .. "    RAM " .. tostring(State.Memory) .. "MB"

        DiagText.Text =
            "V3INN CLIENT DIAGNOSTICS\n\n"
            .. "Player: " .. Player.Name .. "\n"
            .. "FPS: " .. tostring(State.FPS) .. "\n"
            .. "Ping: " .. tostring(State.Ping) .. " ms\n"
            .. "Memory: " .. tostring(State.Memory) .. " MB\n"
            .. "Preset: " .. State.Preset .. "\n"
            .. "FPS Optimizer: " .. tostring(State.FPSBoost) .. "\n"
            .. "Command Audit Results: " .. tostring(State.CommandCount)
    end
end)

----------------------------------------------------------------
-- GOLD PULSE
----------------------------------------------------------------

task.spawn(function()
    while not IsTerminated() do
        if State.GoldPulse then
            Tween(GoldLine, {
                BackgroundTransparency = 0.05
            }, 0.9):Play()

            task.wait(0.9)

            Tween(GoldLine, {
                BackgroundTransparency = 0.3
            }, 0.9):Play()

            task.wait(0.9)
        else
            GoldLine.BackgroundTransparency = 0
            task.wait(0.2)
        end
    end
end)

----------------------------------------------------------------
-- GOLD HOVER EFFECTS
----------------------------------------------------------------

local function AddHover(button)
    local original = button.BackgroundColor3

    button.MouseEnter:Connect(function()
        Tween(button, {
            BackgroundColor3 = Config.Colors.Panel2
        }, 0.12):Play()
    end)

    button.MouseLeave:Connect(function()
        Tween(button, {
            BackgroundColor3 = original
        }, 0.12):Play()
    end)
end

AddHover(Minimize)
AddHover(Close)
AddHover(ScanButton)

----------------------------------------------------------------
-- INTRO ANIMATION
----------------------------------------------------------------

Main.Size = UDim2.fromOffset(Config.Width, 0)

task.delay(0.08, function()
    if not IsTerminated() then
        Tween(Main, {
            Size = NormalSize
        }, 0.45):Play()
    end
end)

----------------------------------------------------------------
-- STARTUP
----------------------------------------------------------------

Notify(
    "V3INN Gold",
    "Performance console initialized.",
    "success"
)

Notify(
    "Command Audit",
    "Run the audit manually to inspect client-visible definitions.",
    "warning"
)

----------------------------------------------------------------
-- TERMINATION WATCHER
----------------------------------------------------------------

task.spawn(function()
    while Gui.Parent and not IsTerminated() do
        task.wait(0.1)
    end

    if IsTerminated() then
        State.Destroyed = true

        -- Restore any visual changes made by this script.
        pcall(function()
            SetSafeVisualMode(false)
        end)

        pcall(function()
            Gui:Destroy()
        end)

        pcall(function()
            FPSGui:Destroy()
        end)
    end
end)

----------------------------------------------------------------
-- CLEANUP
----------------------------------------------------------------

script.Destroying:Connect(function()
    State.Destroyed = true

    pcall(function()
        RestoreEnvironmentStudio()
    end)

    pcall(function()
        SetSafeVisualMode(false)
    end)

    pcall(function()
        if Singleton and Singleton.Parent then
            Singleton:Destroy()
        end
    end)

    pcall(function()
        if Gui and Gui.Parent then
            Gui:Destroy()
        end
    end)

    pcall(function()
        if FPSGui and FPSGui.Parent then
            FPSGui:Destroy()
        end
    end)
end)

-- End of V3INN Gold Performance Console.

----------------------------------------------------------------
-- V3INN GOLD // PREMIUM TYPOGRAPHY PASS
----------------------------------------------------------------
-- A visual polish layer for the entire interface.
----------------------------------------------------------------

local function V3INNStyleText(object)
    if not object:IsA("TextLabel")
        and not object:IsA("TextButton")
        and not object:IsA("TextBox") then
        return
    end

    object.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

    if object.TextSize >= 18 then
        object.TextStrokeTransparency = 0.72
        object.Font = Enum.Font.GothamBlack
    elseif object.TextSize >= 11 then
        object.TextStrokeTransparency = 0.82
        object.Font = Enum.Font.GothamBold
    else
        object.TextStrokeTransparency = 0.9
    end
end

local function V3INNAddGoldTextGradient(object)
    if not object:IsA("TextLabel")
        and not object:IsA("TextButton") then
        return
    end

    if object.TextSize < 18 then
        return
    end

    if object:FindFirstChild("V3INN_GoldText") then
        return
    end

    local gradient = Instance.new("UIGradient")
    gradient.Name = "V3INN_GoldText"
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Config.Colors.Text),
        ColorSequenceKeypoint.new(0.45, Config.Colors.GoldBright),
        ColorSequenceKeypoint.new(1, Config.Colors.Text),
    })
    gradient.Parent = object
end

local function V3INNApplyPremiumTypography(root)
    for _, object in ipairs(root:GetDescendants()) do
        if object:IsA("TextLabel")
            or object:IsA("TextButton")
            or object:IsA("TextBox") then

            V3INNStyleText(object)

            if object.TextSize >= 18 then
                V3INNAddGoldTextGradient(object)
            end
        end
    end
end

V3INNApplyPremiumTypography(Gui)

----------------------------------------------------------------
-- PREMIUM HEADER
----------------------------------------------------------------

if Logo then
    Logo.Text = "V3INN"
    Logo.TextSize = 24
    Logo.Font = Enum.Font.GothamBlack
    Logo.TextColor3 = Config.Colors.Text
    Logo.TextStrokeTransparency = 0.7

    V3INNAddGoldTextGradient(Logo)
end

if Subtitle then
    Subtitle.Text = "GOLD  //  PERFORMANCE  //  ENV STUDIO"
    Subtitle.TextColor3 = Config.Colors.GoldBright
    Subtitle.TextSize = 8
    Subtitle.Font = Enum.Font.GothamBold
end

----------------------------------------------------------------
-- PREMIUM TAB LABELS
----------------------------------------------------------------

for _, tab in pairs(Tabs) do
    if tab.Label then
        tab.Label.Font = Enum.Font.GothamMedium
        tab.Label.TextSize = 10
        tab.Label.TextXAlignment = Enum.TextXAlignment.Left
    end

    if tab.Icon then
        tab.Icon.Font = Enum.Font.GothamBold
        tab.Icon.TextSize = 13
    end
end

----------------------------------------------------------------
-- PREMIUM BUTTON HOVER
----------------------------------------------------------------

for _, object in ipairs(Gui:GetDescendants()) do
    if object:IsA("TextButton") then
        object.AutoButtonColor = false

        object.MouseEnter:Connect(function()
            if object.Parent and object.Visible then
                local stroke = object:FindFirstChildOfClass("UIStroke")

                if stroke then
                    Tween(stroke, {
                        Transparency = 0.05,
                    }, 0.12):Play()
                end
            end
        end)

        object.MouseLeave:Connect(function()
            if object.Parent then
                local stroke = object:FindFirstChildOfClass("UIStroke")

                if stroke then
                    Tween(stroke, {
                        Transparency = 0.35,
                    }, 0.18):Play()
                end
            end
        end)
    end
end

----------------------------------------------------------------
-- PREMIUM MICRO HEADINGS
----------------------------------------------------------------

for _, object in ipairs(Gui:GetDescendants()) do
    if object:IsA("TextLabel") then
        local value = string.upper(object.Text)

        if string.find(value, "//", 1, true)
            and object.TextSize <= 10 then

            object.TextColor3 = Config.Colors.Gold
            object.Font = Enum.Font.GothamBold
            object.TextTransparency = 0.02
        end
    end
end

----------------------------------------------------------------
-- PREMIUM NOTIFICATION TYPOGRAPHY
----------------------------------------------------------------

for _, object in ipairs(FPSGui:GetDescendants()) do
    if object:IsA("TextLabel")
        or object:IsA("TextButton") then

        object.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        object.TextStrokeTransparency = 0.86
    end
end

----------------------------------------------------------------
-- END PREMIUM TYPOGRAPHY PASS
----------------------------------------------------------------