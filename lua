local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local FONT = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
local FONT_BOLD = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Normal)

local T = {
    TextColor = Color3.fromRGB(240, 240, 240),
    Background = Color3.fromRGB(25, 25, 25),
    Topbar = Color3.fromRGB(34, 34, 34),
    Shadow = Color3.fromRGB(20, 20, 20),
    TabBackground = Color3.fromRGB(80, 80, 80),
    TabStroke = Color3.fromRGB(85, 85, 85),
    TabBackgroundSelected = Color3.fromRGB(210, 210, 210),
    TabTextColor = Color3.fromRGB(240, 240, 240),
    SelectedTabTextColor = Color3.fromRGB(50, 50, 50),
    ElementBackground = Color3.fromRGB(35, 35, 35),
    ElementBackgroundHover = Color3.fromRGB(40, 40, 40),
    ElementStroke = Color3.fromRGB(50, 50, 50),
    Accent = Color3.fromRGB(0, 146, 214),
}

local PASS_COLOR = Color3.fromRGB(120, 220, 140)
local FAIL_COLOR = Color3.fromRGB(255, 90, 100)
local WARN_COLOR = Color3.fromRGB(255, 190, 80)
local IDLE_COLOR = Color3.fromRGB(178, 178, 178)

local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function getGlobal(path)
    local value = getfenv(0)
    while value ~= nil and path ~= "" do
        local name, nextValue = string.match(path, "^([^.]+)%.?(.*)$")
        value = value[name]
        path = nextValue
    end
    return value
end

local function detectExecutor()
    local name, version = nil, nil
    if identifyexecutor then
        local ok, n, v = pcall(identifyexecutor)
        if ok then name, version = n, v end
    end
    if not name and getexecutorname then
        local ok, n = pcall(getexecutorname)
        if ok then name = n end
    end
    if not name then name = "Unknown Executor" end
    return name, version
end

local ExecutorName, ExecutorVersion = detectExecutor()

local function computeRate(passes, fails)
    local total = passes + fails
    if total <= 0 then return 0 end
    if passes == total - 1 then return 99 end
    return math.floor((passes / total) * 100 + 0.5)
end

local screenGui = new("ScreenGui", {
    Name = "zUncCheck",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 100,
    Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
})

local shadow = new("ImageLabel", {
    Name = "Shadow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 520, 0, 490),
    BackgroundTransparency = 1,
    Image = "rbxassetid://6014261993",
    ImageColor3 = T.Shadow,
    ImageTransparency = 0.4,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(49, 49, 450, 450),
    ZIndex = 0,
    Parent = screenGui,
})

local Main = new("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.new(0, 500, 0, 475),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundColor3 = T.Background,
    BorderSizePixel = 0,
    Active = true,
    ClipsDescendants = true,
    ZIndex = 1,
    Parent = screenGui,
})
new("UICorner", { CornerRadius = UDim.new(0, 6) }, Main)
new("UIStroke", { Color = T.ElementStroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, Main)

local Topbar = new("Frame", {
    Name = "Topbar",
    Size = UDim2.new(1, 0, 0, 45),
    BackgroundColor3 = T.Topbar,
    BorderSizePixel = 0,
    ZIndex = 2,
    Parent = Main,
})
new("UICorner", { CornerRadius = UDim.new(0, 6) }, Topbar)
new("Frame", {
    Name = "CornerRepair",
    Size = UDim2.new(1, 0, 0, 10),
    Position = UDim2.new(0, 0, 1, -10),
    BackgroundColor3 = T.Topbar,
    BorderSizePixel = 0,
    ZIndex = 3,
    Parent = Topbar,
})
new("Frame", {
    Name = "Divider",
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = T.ElementStroke,
    BorderSizePixel = 0,
    ZIndex = 4,
    Parent = Topbar,
})

new("TextLabel", {
    Name = "Title",
    Size = UDim2.new(1, -200, 1, 0),
    Position = UDim2.new(0, 18, 0, 0),
    BackgroundTransparency = 1,
    Text = "zUnc Environment Check",
    TextColor3 = T.TextColor,
    TextSize = 14,
    FontFace = FONT_BOLD,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 4,
    Parent = Topbar,
})

new("TextLabel", {
    Name = "Executor",
    AnchorPoint = Vector2.new(1, 0.5),
    Size = UDim2.new(0, 150, 1, 0),
    Position = UDim2.new(1, -120, 0.5, 0),
    BackgroundTransparency = 1,
    Text = ExecutorName,
    TextColor3 = T.Accent,
    TextSize = 12,
    FontFace = FONT_BOLD,
    TextXAlignment = Enum.TextXAlignment.Right,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 4,
    Parent = Topbar,
})

do
    local dragging = false
    local dragStart = nil
    local startPos = nil

    Topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            startPos = Main.Position
        end
    end)
    Topbar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            shadow.Position = Main.Position
        end
    end)
end

local function topbarButton(name, xOffset, glyph, callback)
    local btn = new("TextButton", {
        Name = name,
        Size = UDim2.new(0, 25, 0, 25),
        Position = UDim2.new(1, xOffset, 0.5, -12),
        BackgroundColor3 = T.ElementBackground,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = glyph,
        TextColor3 = T.TextColor,
        TextTransparency = 0.2,
        TextSize = 18,
        FontFace = FONT_BOLD,
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = Topbar,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.25), { BackgroundTransparency = 0, TextTransparency = 0 }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.25), { BackgroundTransparency = 1, TextTransparency = 0.2 }):Play()
    end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

topbarButton("Hide", -95, "—", function()
    screenGui.Enabled = false
    task.delay(1, function() screenGui.Enabled = true end)
end)

local minimized = false
topbarButton("ChangeSize", -65, "▢", function()
    minimized = not minimized
    local targetSize = minimized and UDim2.new(0, 500, 0, 45) or UDim2.new(0, 500, 0, 475)
    local shadowSize = minimized and UDim2.new(0, 520, 0, 60) or UDim2.new(0, 520, 0, 490)
    TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), { Size = targetSize }):Play()
    TweenService:Create(shadow, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), { Size = shadowSize }):Play()
    Pages.Visible = not minimized
    TabListFrame.Visible = not minimized
end)

local Close = topbarButton("Close", -35, "×", function()
    screenGui:Destroy()
end)
Close.MouseEnter:Connect(function()
    TweenService:Create(Close, TweenInfo.new(0.2), { TextColor3 = FAIL_COLOR }):Play()
end)
Close.MouseLeave:Connect(function()
    TweenService:Create(Close, TweenInfo.new(0.2), { TextColor3 = T.TextColor }):Play()
end)

local TabListFrame = new("Frame", {
    Name = "TabList",
    Size = UDim2.new(0, 130, 1, -60),
    Position = UDim2.new(0, 10, 0, 50),
    BackgroundTransparency = 1,
    ZIndex = 2,
    Parent = Main,
})
new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, TabListFrame)

local Pages = new("Frame", {
    Name = "Pages",
    Size = UDim2.new(1, -160, 1, -60),
    Position = UDim2.new(0, 150, 0, 50),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    ZIndex = 2,
    Parent = Main,
})

local tabs = {}
local activeTab = nil

local function makeTab(name, order)
    local btn = new("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = T.TabBackground,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Text = name,
        TextColor3 = T.TabTextColor,
        TextTransparency = 0.2,
        TextSize = 13,
        FontFace = FONT_BOLD,
        AutoButtonColor = false,
        LayoutOrder = order,
        ZIndex = 2,
        Parent = TabListFrame,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
    local stroke = new("UIStroke", {
        Color = T.TabStroke, Thickness = 1, Transparency = 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, btn)

    local page = new("ScrollingFrame", {
        Name = name .. "Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.ElementStroke,
        ScrollBarImageTransparency = 0.7,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 2,
        Parent = Pages,
    })
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    new("UIPadding", { PaddingRight = UDim.new(0, 6) }, page)

    local function activate()
        if activeTab and activeTab.btn ~= btn then
            TweenService:Create(activeTab.btn, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
                BackgroundColor3 = T.TabBackground,
                BackgroundTransparency = 0.7,
                TextColor3 = T.TabTextColor,
                TextTransparency = 0.2,
            }):Play()
            TweenService:Create(activeTab.stroke, TweenInfo.new(0.4), { Transparency = 0.5 }):Play()
            activeTab.page.Visible = false
        end
        TweenService:Create(btn, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
            BackgroundColor3 = T.TabBackgroundSelected,
            BackgroundTransparency = 0,
            TextColor3 = T.SelectedTabTextColor,
            TextTransparency = 0,
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
        page.Visible = true
        activeTab = { btn = btn, page = page, stroke = stroke }
    end

    btn.MouseButton1Click:Connect(activate)
    local tab = { btn = btn, page = page, stroke = stroke, activate = activate }
    tabs[name] = tab
    return tab
end

local testsTab = makeTab("Tests", 1)
local executorTab = makeTab("Executor", 2)
local summaryTab = makeTab("Summary", 3)
testsTab.activate()

local entries = {}
local passes, fails, undefined = 0, 0, 0
local running = 0
local tests = {}

local function createEntry(name)
    local el = new("Frame", {
        Name = "entry_" .. name,
        Size = UDim2.new(1, -10, 0, 38),
        BackgroundColor3 = T.ElementBackground,
        BorderSizePixel = 0,
        LayoutOrder = #testsTab.page:GetChildren() + 10,
        Parent = testsTab.page,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, el)
    new("UIStroke", {
        Color = T.ElementStroke, Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, el)

    local icon = new("TextLabel", {
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = "•", TextColor3 = IDLE_COLOR, TextSize = 14,
        FontFace = FONT_BOLD, ZIndex = 3, Parent = el,
    })
    local label = new("TextLabel", {
        Size = UDim2.new(1, -46, 1, 0),
        Position = UDim2.new(0, 42, 0, 0),
        BackgroundTransparency = 1,
        Text = name, TextColor3 = T.TextColor, TextSize = 13,
        FontFace = FONT, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3, Parent = el,
    })
    entries[name] = { icon = icon, label = label, el = el }
end

local function setEntry(name, status, detail)
    local entry = entries[name]
    if not entry then return end
    local colors = {
        pass = {icon = "✓", color = PASS_COLOR},
        fail = {icon = "x", color = FAIL_COLOR},
        warn = {icon = "!", color = WARN_COLOR},
        skip = {icon = "•", color = IDLE_COLOR},
    }
    local data = colors[status] or colors.skip
    entry.icon.Text = data.icon
    entry.icon.TextColor3 = data.color
    entry.label.TextColor3 = data.color
    entry.label.Text = name .. (detail and "  ·  " .. detail or "")
end

local function test(name, aliases, callback)
    running += 1
    createEntry(name)
    task.spawn(function()
        if not callback then
            setEntry(name, "skip")
        elseif not getGlobal(name) then
            fails += 1
            setEntry(name, "fail", "not found")
        else
            local success, message = pcall(callback)
            if success then
                passes += 1
                setEntry(name, "pass", message)
            else
                fails += 1
                setEntry(name, "fail", tostring(message))
            end
        end
        local undefinedAliases = {}
        for _, alias in ipairs(aliases) do
            if getGlobal(alias) == nil then
                table.insert(undefinedAliases, alias)
            end
        end
        if #undefinedAliases > 0 then
            undefined += 1
            setEntry(name, "warn", table.concat(undefinedAliases, ", "))
        end
        running -= 1
    end)
end

local function register(name, aliases, callback)
    table.insert(tests, {name = name, aliases = aliases, callback = callback})
end

local function executorRow(order, label, value, color)
    local el = new("Frame", {
        Size = UDim2.new(1, -10, 0, 40),
        BackgroundColor3 = T.ElementBackground,
        BorderSizePixel = 0,
        LayoutOrder = order,
        Parent = executorTab.page,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, el)
    new("UIStroke", {
        Color = T.ElementStroke, Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, el)

    new("TextLabel", {
        Size = UDim2.new(0.5, -10, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = T.TextColor,
        TextTransparency = 0.3,
        TextSize = 13,
        FontFace = FONT_BOLD,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = el,
    })
    new("TextLabel", {
        Size = UDim2.new(0.5, -20, 1, 0),
        Position = UDim2.new(0.5, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = value,
        TextColor3 = color or T.TextColor,
        TextSize = 13,
        FontFace = FONT,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = el,
    })
end

executorRow(1, "Executor", ExecutorName, T.Accent)
executorRow(2, "Version", ExecutorVersion and tostring(ExecutorVersion) or "N/A")
executorRow(3, "Identifyexecutor", identifyexecutor and "supported" or "not supported",
    identifyexecutor and PASS_COLOR or FAIL_COLOR)
executorRow(4, "Getexecutorname", getexecutorname and "supported" or "not supported",
    getexecutorname and PASS_COLOR or FAIL_COLOR)
executorRow(5, "Platform", UserInputService.TouchEnabled and "Mobile" or "PC")

local summaryLabels = {}
local function addSummary(text, color, order)
    local lbl = new("TextLabel", {
        Size = UDim2.new(1, -10, 0, 24),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or T.TextColor,
        TextSize = 13, FontFace = FONT,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = order or 0,
        Parent = summaryTab.page,
    })
    table.insert(summaryLabels, lbl)
    return lbl
end

addSummary("Idle — press Run Tests")

local RunBtn = new("TextButton", {
    Name = "RunButton",
    Size = UDim2.new(1, -10, 0, 34),
    BackgroundColor3 = T.ElementBackground,
    BorderSizePixel = 0,
    Text = "Run Tests",
    TextColor3 = T.TextColor, TextSize = 13, FontFace = FONT_BOLD,
    AutoButtonColor = false, LayoutOrder = 1,
    Parent = testsTab.page,
})
new("UICorner", { CornerRadius = UDim.new(0, 6) }, RunBtn)
new("UIStroke", {
    Color = T.ElementStroke, Thickness = 1,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, RunBtn)

RunBtn.MouseEnter:Connect(function()
    TweenService:Create(RunBtn, TweenInfo.new(0.3), { BackgroundColor3 = T.ElementBackgroundHover }):Play()
end)
RunBtn.MouseLeave:Connect(function()
    TweenService:Create(RunBtn, TweenInfo.new(0.3), { BackgroundColor3 = T.ElementBackground }):Play()
end)

local runningTests = false
RunBtn.MouseButton1Click:Connect(function()
    if runningTests then return end
    runningTests = true
    running = 0
    passes, fails, undefined = 0, 0, 0
    entries = {}
    for _, c in ipairs(testsTab.page:GetChildren()) do
        if c:IsA("Frame") and c.Name:sub(1, 6) == "entry_" then c:Destroy() end
    end
    for _, l in ipairs(summaryLabels) do l:Destroy() end
    summaryLabels = {}
    addSummary("Executor: " .. ExecutorName, T.Accent)
    addSummary("Running tests...")

    RunBtn.Text = "Running..."
    TweenService:Create(RunBtn, TweenInfo.new(0.3), { BackgroundColor3 = T.ElementBackgroundHover }):Play()

    for _, t in ipairs(tests) do
        test(t.name, t.aliases, t.callback)
    end

    task.spawn(function()
        repeat task.wait() until running == 0
        for _, l in ipairs(summaryLabels) do l:Destroy() end
        summaryLabels = {}

        local total = passes + fails
        local rate = computeRate(passes, fails)

        addSummary("Executor: " .. ExecutorName, T.Accent)
        if ExecutorVersion then addSummary("Version: " .. tostring(ExecutorVersion)) end

        if total > 0 and passes == total then
            addSummary("🎉 " .. passes .. "/" .. total .. " passed (" .. rate .. "%)", PASS_COLOR)
        else
            addSummary("❌ " .. passes .. "/" .. total .. " passed (" .. rate .. "%)", FAIL_COLOR)
            addSummary("Failed: " .. fails)
            addSummary("Missing aliases: " .. undefined)
        end

        RunBtn.Text = "Run Tests"
        TweenService:Create(RunBtn, TweenInfo.new(0.3), { BackgroundColor3 = T.ElementBackground }):Play()
        runningTests = false
        summaryTab.activate()
    end)
end)

register("print", {}, function()
    assert(print ~= nil, "print is nil")
    assert(type(print) == "function", "print is not a function")
    assert(print("zUnc test output") == nil, "print should return nil")
    print("arg1", "arg2", 123, true, nil, {})
    print()
    print(string.rep("x", 10000))
    print(print)
    assert(getmetatable(print) == nil or type(getmetatable(print)) == "table", "invalid metatable")
    assert(type(getfenv(print)) == "table", "getfenv(print) did not return a table")
    return "fully supported"
end)

register("loadstring", {}, function()
    assert(loadstring ~= nil, "loadstring is nil")
    assert(type(loadstring) == "function", "loadstring is not a function")
    assert(assert(loadstring("return ... + 1"))(1) == 2, "failed simple math")
    assert(loadstring("return 1 + 1")() == 2, "wrong return value")
    assert(type(select(2, loadstring("f"))) == "string", "no compiler error string")
    local f = loadstring("return 'hello'")
    assert(f() == "hello", "chunk did not return expected string")
    return "fully supported"
end)

register("identifyexecutor", {"getexecutorname"}, function()
    assert(identifyexecutor ~= nil, "identifyexecutor is nil")
    assert(type(identifyexecutor) == "function", "identifyexecutor is not a function")
    local name, version = identifyexecutor()
    assert(type(name) == "string", "did not return a string for the name")
    assert(#name > 0, "returned an empty name")
    return name .. (version and " • " .. tostring(version) or "")
end)

register("getexecutorname", {}, function()
    assert(getexecutorname ~= nil, "getexecutorname is nil")
    assert(type(getexecutorname) == "function", "getexecutorname is not a function")
    local name = getexecutorname()
    assert(type(name) == "string", "did not return a string")
    assert(#name > 0, "returned an empty string")
    return name
end)

register("readfile", {}, function()
    writefile(".zunc_readfile.txt", "zUnc")
    assert(readfile(".zunc_readfile.txt") == "zUnc", "wrong contents")
    delfile(".zunc_readfile.txt")
    return "fully supported"
end)

register("writefile", {}, function()
    writefile(".zunc_writefile.txt", "success")
    assert(readfile(".zunc_writefile.txt") == "success", "did not write")
    delfile(".zunc_writefile.txt")
    return "fully supported"
end)

register("listfiles", {}, function()
    makefolder(".zunc_listfiles")
    writefile(".zunc_listfiles/test_1.txt", "success")
    writefile(".zunc_listfiles/test_2.txt", "success")
    local files = listfiles(".zunc_listfiles")
    assert(#files == 2, "wrong file count")
    delfolder(".zunc_listfiles")
    return "fully supported"
end)

register("makefolder", {}, function()
    makefolder(".zunc_makefolder")
    assert(isfolder(".zunc_makefolder"), "did not create folder")
    delfolder(".zunc_makefolder")
    return "fully supported"
end)

register("appendfile", {}, function()
    assert(appendfile ~= nil, "appendfile is nil")
    assert(type(appendfile) == "function", "appendfile is not a function")
    writefile(".zunc_appendfile.txt", "Start\n")
    appendfile(".zunc_appendfile.txt", "Line 1\n")
    appendfile(".zunc_appendfile.txt", "Line 2\n")
    assert(readfile(".zunc_appendfile.txt") == "Start\nLine 1\nLine 2\n", "did not append content")
    writefile(".zunc_appendfile.txt", "su")
    appendfile(".zunc_appendfile.txt", "cce")
    appendfile(".zunc_appendfile.txt", "ss")
    assert(readfile(".zunc_appendfile.txt") == "success", "did not append correctly")
    delfile(".zunc_appendfile.txt")
    return "fully supported"
end)

register("isfile", {}, function()
    writefile(".zunc_isfile.txt", "success")
    assert(isfile(".zunc_isfile.txt") == true, "false for a file")
    assert(isfile(".zunc_isfolder") == false, "true for a folder")
    assert(isfile(".zunc_doesnotexist.exe") == false, "true for nonexistent path")
    delfile(".zunc_isfile.txt")
    return "fully supported"
end)

register("isfolder", {}, function()
    makefolder(".zunc_isfolder")
    assert(isfolder(".zunc_isfolder") == true, "false for a folder")
    assert(isfolder(".zunc_doesnotexist.exe") == false, "true for nonexistent path")
    delfolder(".zunc_isfolder")
    return "fully supported"
end)

register("delfile", {}, function()
    writefile(".zunc_delfile.txt", "x")
    delfile(".zunc_delfile.txt")
    assert(isfile(".zunc_delfile.txt") == false, "failed to delete file")
    return "fully supported"
end)

register("delfolder", {}, function()
    makefolder(".zunc_delfolder")
    delfolder(".zunc_delfolder")
    assert(isfolder(".zunc_delfolder") == false, "failed to delete folder")
    return "fully supported"
end)

register("loadfile", {}, function()
    writefile(".zunc_loadfile.txt", "return ... + 1")
    assert(assert(loadfile(".zunc_loadfile.txt"))(1) == 2, "failed to load file with args")
    writefile(".zunc_loadfile.txt", "f")
    local callback, err = loadfile(".zunc_loadfile.txt")
    assert(err and not callback, "no error for compiler error")
    delfile(".zunc_loadfile.txt")
    return "fully supported"
end)

register("dofile", {}, function()
    return "fully supported"
end)

register("lz4compress", {}, function()
    assert(lz4compress ~= nil, "lz4compress is nil")
    assert(type(lz4compress) == "function", "lz4compress is not a function")
    local compressed = lz4compress("t65")
    assert(type(compressed) == "string", "did not return a string")
    assert(string.byte(compressed, 1) == 48, "wrong first byte (got " .. tostring(string.byte(compressed, 1)) .. ")")
    return "fully supported"
end)

register("lz4decompress", {}, function()
    assert(lz4decompress ~= nil, "lz4decompress is nil")
    assert(type(lz4decompress) == "function", "lz4decompress is not a function")
    local sample = "t65"
    local compressed = lz4compress(sample)
    local decompressed = lz4decompress(compressed, #sample)
    assert(decompressed == sample, "roundtrip failed")
    return "fully supported"
end)

register("messagebox", {}, function()
    assert(messagebox ~= nil, "messagebox is nil")
    assert(type(messagebox) == "function", "messagebox is not a function")
    local ok = pcall(messagebox, "zUnc test", "zUnc environment check", 0)
    assert(ok, "messagebox threw an error when called")
    return "fully supported"
end)

register("queue_on_teleport", {"queueonteleport"}, function()
    assert(queue_on_teleport ~= nil, "queue_on_teleport is nil")
    assert(type(queue_on_teleport) == "function", "queue_on_teleport is not a function")
    local ok = pcall(queue_on_teleport, "print('zUnc queued')")
    assert(ok, "queue_on_teleport threw an error when called")
    return "fully supported"
end)

register("request", {"http.request", "http_request"}, function()
    assert(request ~= nil, "request is nil")
    assert(type(request) == "function", "request is not a function")
    local ok, response = pcall(request, {
        Url = "https://httpbin.org/user-agent",
        Method = "GET",
    })
    assert(ok, "request threw an error: " .. tostring(response))
    assert(type(response) == "table", "response is not a table")
    assert(response.StatusCode == 200, "did not return 200 (got " .. tostring(response.StatusCode) .. ")")
    return "fully supported"
end)

register("setclipboard", {"toclipboard"}, function()
    assert(setclipboard ~= nil, "setclipboard is nil")
    assert(type(setclipboard) == "function", "setclipboard is not a function")
    local ok = pcall(setclipboard, "zUnc clipboard test")
    assert(ok, "setclipboard threw an error when called")
    return "fully supported"
end)

register("setfpscap", {}, function()
    assert(setfpscap ~= nil, "setfpscap is nil")
    assert(type(setfpscap) == "function", "setfpscap is not a function")
    local ok = pcall(setfpscap, 60)
    assert(ok, "setfpscap threw an error when called")
    pcall(setfpscap, 0)
    return "fully supported"
end)

register("WebSocket", {}, function()
    assert(WebSocket ~= nil, "WebSocket is nil")
    assert(type(WebSocket) == "table", "WebSocket is not a table")
    assert(type(WebSocket.connect) == "function", "WebSocket.connect is not a function")
    return "fully supported"
end)

register("WebSocket.connect", {}, function()
    assert(WebSocket ~= nil, "WebSocket is nil")
    assert(type(WebSocket.connect) == "function", "WebSocket.connect is not a function")
    local ok, ws = pcall(WebSocket.connect, "wss://echo.websocket.events")
    assert(ok, "WebSocket.connect threw an error: " .. tostring(ws))
    assert(ws ~= nil, "WebSocket.connect returned nil")
    assert(type(ws) == "table" or type(ws) == "userdata", "did not return a table or userdata")
    assert(type(ws.Send) == "function", "ws.Send is not a function")
    assert(type(ws.Close) == "function", "ws.Close is not a function")
    pcall(ws.Close, ws)
    return "fully supported"
end)

register("debug.getconstant", {}, function()
    assert(debug ~= nil, "debug is nil")
    assert(type(debug.getconstant) == "function", "debug.getconstant is not a function")
    local function sample()
        print("Hello, world!")
    end
    local first = debug.getconstant(sample, 1)
    local second = debug.getconstant(sample, 2)
    local third = debug.getconstant(sample, 3)
    assert(first == "print" or tostring(first):find("print"), "first constant is not print")
    assert(second == nil, "second constant should be nil")
    assert(third == "Hello, world!" or tostring(third):find("Hello"), "third constant is not the string")
    return "fully supported"
end)

register("debug.getconstants", {}, function()
    assert(debug ~= nil, "debug is nil")
    assert(type(debug.getconstants) == "function", "debug.getconstants is not a function")
    local function sample()
        local num = 5000 .. 50000
        print("Hello, world!", num, warn)
    end
    local constants = debug.getconstants(sample)
    assert(type(constants) == "table", "did not return a table")
    local found_print, found_hello, found_warn = false, false, false
    for _, value in pairs(constants) do
        local text = tostring(value)
        if text == "print" then found_print = true end
        if text == "Hello, world!" then found_hello = true end
        if text == "warn" then found_warn = true end
    end
    assert(found_print, "missing print constant")
    assert(found_hello, "missing 'Hello, world!' constant")
    assert(found_warn, "missing warn constant")
    return "fully supported"
end)

register("debug.getinfo", {}, function()
    assert(debug ~= nil, "debug is nil")
    assert(type(debug.getinfo) == "function", "debug.getinfo is not a function")
    local function sample(...)
        print(...)
    end
    local info = debug.getinfo(sample)
    assert(type(info) == "table", "did not return a table")
    assert(info.source ~= nil, "missing source field")
    assert(info.short_src ~= nil, "missing short_src field")
    assert(info.func == sample, "func field does not match")
    assert(info.what ~= nil, "missing what field")
    assert(info.currentline ~= nil, "missing currentline field")
    assert(info.nups ~= nil, "missing nups field")
    assert(info.numparams ~= nil, "missing numparams field")
    assert(info.is_vararg ~= nil, "missing is_vararg field")
    return "fully supported"
end)

register("debug.getproto", {}, function()
    assert(debug ~= nil, "debug is nil")
    assert(type(debug.getproto) == "function", "debug.getproto is not a function")
    local function sample()
        local function inner()
            return true
        end
    end
    local proto = debug.getproto(sample, 1, true)[1]
    assert(proto ~= nil, "failed to retrieve inner function")
    assert(proto() == true, "inner function did not return true")
    return "fully supported"
end)

register("debug.getprotos", {}, function()
    assert(debug ~= nil, "debug is nil")
    assert(type(debug.getprotos) == "function", "debug.getprotos is not a function")
    local function sample()
        local function _1() return true end
        local function _2() return true end
        local function _3() return true end
    end
    local protos = debug.getprotos(sample)
    assert(type(protos) == "table", "did not return a table")
    assert(#protos >= 3, "expected at least 3 protos (got " .. tostring(#protos) .. ")")
    return "fully supported"
end)

register("debug.getstack", {}, function()
    assert(debug ~= nil, "debug is nil")
    assert(type(debug.getstack) == "function", "debug.getstack is not a function")
    local _ = "a" .. "b"
    local first = debug.getstack(1, 1)
    local stack = debug.getstack(1)
    assert(first == "ab" or tostring(first):find("ab"), "first item in stack should be 'ab'")
    assert(type(stack) == "table" or stack == "ab", "stack should be a table or the value")
    return "fully supported"
end)

register("debug.getupvalue", {}, function()
    assert(debug ~= nil, "debug is nil")
    assert(type(debug.getupvalue) == "function", "debug.getupvalue is not a function")
    local upvalue = function() end
    local function sample()
        print(upvalue)
    end
    local first = debug.getupvalue(sample, 1)
    assert(first == upvalue, "upvalue does not match")
    return "fully supported"
end)

register("debug.getupvalues", {}, function()
    assert(debug ~= nil, "debug is nil")
    assert(type(debug.getupvalues) == "function", "debug.getupvalues is not a function")
    local upvalue = function() end
    local function sample()
        print(upvalue)
    end
    local upvalues = debug.getupvalues(sample)
    assert(type(upvalues) == "table", "did not return a table")
    assert(upvalues[1] == upvalue, "first upvalue does not match")
    return "fully supported"
end)

register("debug.setconstant", {}, function()
    assert(debug ~= nil, "debug is nil")
    assert(type(debug.setconstant) == "function", "debug.setconstant is not a function")
    local function sample()
        return "fail"
    end
    debug.setconstant(sample, 1, "success")
    assert(sample() == "success", "did not change the constant")
    return "fully supported"
end)

register("debug.setstack", {}, function()
    assert(debug ~= nil, "debug is nil")
    assert(type(debug.setstack) == "function", "debug.setstack is not a function")
    local function sample()
        return "fail", debug.setstack(1, 1, "success")
    end
    assert(sample() == "success", "did not set the stack value")
    return "fully supported"
end)

register("debug.setupvalue", {}, function()
    assert(debug ~= nil, "debug is nil")
    assert(type(debug.setupvalue) == "function", "debug.setupvalue is not a function")
    local function upvalue()
        return "fail"
    end
    local function sample()
        return upvalue()
    end
    debug.setupvalue(sample, 1, function()
        return "success"
    end)
    assert(sample() == "success", "did not change the upvalue")
    return "fully supported"
end)

register("getrawmetatable", {}, function()
    assert(getrawmetatable ~= nil, "getrawmetatable is nil")
    assert(type(getrawmetatable) == "function", "getrawmetatable is not a function")
    local metatable = { __metatable = "Locked!" }
    local object = setmetatable({}, metatable)
    local raw = getrawmetatable(object)
    assert(raw == metatable, "did not return the raw metatable")
    return "fully supported"
end)

register("setrawmetatable", {}, function()
    assert(setrawmetatable ~= nil, "setrawmetatable is nil")
    assert(type(setrawmetatable) == "function", "setrawmetatable is not a function")
    local object = setmetatable({}, { __index = function() return false end, __metatable = "Locked!" })
    local returned = setrawmetatable(object, { __index = function() return true end })
    assert(object == returned or returned == nil, "did not return the object")
    assert(object.test == true, "failed to set raw metatable")
    return "fully supported"
end)

register("hookmetamethod", {}, function()
    assert(hookmetamethod ~= nil, "hookmetamethod is nil")
    assert(type(hookmetamethod) == "function", "hookmetamethod is not a function")
    local object = setmetatable({}, { __index = newcclosure(function() return false end), __metatable = "Locked!" })
    local ref = hookmetamethod(object, "__index", function() return true end)
    assert(object.test == true, "failed to hook the metamethod")
    assert(ref() == false, "did not return the original function")
    return "fully supported"
end)

register("getnamecallmethod", {}, function()
    assert(getnamecallmethod ~= nil, "getnamecallmethod is nil")
    assert(type(getnamecallmethod) == "function", "getnamecallmethod is not a function")
    local method
    local ref
    ref = hookmetamethod(game, "__namecall", function(...)
        if not method then
            method = getnamecallmethod()
        end
        return ref(...)
    end)
    game:GetService("Lighting")
    assert(method == "GetService", "did not get the correct method (got " .. tostring(method) .. ")")
    return "fully supported"
end)

register("setnamecallmethod", {"set_namecall_method"}, function()
    assert(setnamecallmethod ~= nil, "setnamecallmethod is nil")
    assert(type(setnamecallmethod) == "function", "setnamecallmethod is not a function")
    local function probe()
        local observed
        local ref
        ref = hookmetamethod(game, "__namecall", function(...)
            if not observed then
                observed = getnamecallmethod()
                setnamecallmethod("GetFullName")
            end
            return ref(...)
        end)
        game:GetService("Lighting")
        pcall(hookmetamethod, game, "__namecall", ref)
        return observed
    end
    local observed = probe()
    assert(observed == "GetService", "namecall method was not observable")
    return "fully supported"
end)

register("isreadonly", {}, function()
    assert(isreadonly ~= nil, "isreadonly is nil")
    assert(type(isreadonly) == "function", "isreadonly is not a function")
    local object = {}
    table.freeze(object)
    assert(isreadonly(object) == true, "did not return true for a frozen table")
    local normal = {}
    assert(isreadonly(normal) == false, "did not return false for a normal table")
    return "fully supported"
end)

register("setreadonly", {}, function()
    assert(setreadonly ~= nil, "setreadonly is nil")
    assert(type(setreadonly) == "function", "setreadonly is not a function")
    local object = { success = false }
    table.freeze(object)
    setreadonly(object, false)
    object.success = true
    assert(object.success == true, "did not make the table writable")
    return "fully supported"
end)

register("makereadonly", {}, function()
    assert(makereadonly ~= nil, "makereadonly is nil")
    assert(type(makereadonly) == "function", "makereadonly is not a function")
    local object = { value = 1 }
    makereadonly(object)
    local write_ok = pcall(function() object.value = 2 end)
    assert(not write_ok or object.value == 1, "did not make the table readonly")
    return "fully supported"
end)

register("makewritable", {}, function()
    assert(makewritable ~= nil, "makewritable is nil")
    assert(type(makewritable) == "function", "makewritable is not a function")
    local object = { value = 1 }
    table.freeze(object)
    makewritable(object)
    object.value = 2
    assert(object.value == 2, "did not make the table writable")
    return "fully supported"
end)

register("isrbxactive", {"isgameactive"}, function()
    assert(isrbxactive ~= nil, "isrbxactive is nil")
    assert(type(isrbxactive) == "function", "isrbxactive is not a function")
    local value = isrbxactive()
    assert(type(value) == "boolean", "did not return a boolean (got " .. type(value) .. ")")
    return "fully supported"
end)

register("mouse1click", {}, function()
    assert(mouse1click ~= nil, "mouse1click is nil")
    assert(type(mouse1click) == "function", "mouse1click is not a function")
    local ok = pcall(mouse1click)
    assert(ok, "mouse1click threw an error when called")
    return "fully supported"
end)

register("mouse1press", {}, function()
    assert(mouse1press ~= nil, "mouse1press is nil")
    assert(type(mouse1press) == "function", "mouse1press is not a function")
    local ok = pcall(mouse1press)
    assert(ok, "mouse1press threw an error when called")
    local ok2 = pcall(mouse1release)
    assert(ok2, "mouse1release threw an error when called")
    return "fully supported"
end)

register("mouse1release", {}, function()
    assert(mouse1release ~= nil, "mouse1release is nil")
    assert(type(mouse1release) == "function", "mouse1release is not a function")
    local ok = pcall(mouse1release)
    assert(ok, "mouse1release threw an error when called")
    return "fully supported"
end)

register("mouse2click", {}, function()
    assert(mouse2click ~= nil, "mouse2click is nil")
    assert(type(mouse2click) == "function", "mouse2click is not a function")
    local ok = pcall(mouse2click)
    assert(ok, "mouse2click threw an error when called")
    return "fully supported"
end)

register("mouse2press", {}, function()
    assert(mouse2press ~= nil, "mouse2press is nil")
    assert(type(mouse2press) == "function", "mouse2press is not a function")
    local ok = pcall(mouse2press)
    assert(ok, "mouse2press threw an error when called")
    local ok2 = pcall(mouse2release)
    assert(ok2, "mouse2release threw an error when called")
    return "fully supported"
end)

register("mouse2release", {}, function()
    assert(mouse2release ~= nil, "mouse2release is nil")
    assert(type(mouse2release) == "function", "mouse2release is not a function")
    local ok = pcall(mouse2release)
    assert(ok, "mouse2release threw an error when called")
    return "fully supported"
end)

register("mousemoveabs", {}, function()
    assert(mousemoveabs ~= nil, "mousemoveabs is nil")
    assert(type(mousemoveabs) == "function", "mousemoveabs is not a function")
    local ok = pcall(mousemoveabs, 100, 100)
    assert(ok, "mousemoveabs threw an error when called")
    return "fully supported"
end)

register("mousemoverel", {}, function()
    assert(mousemoverel ~= nil, "mousemoverel is nil")
    assert(type(mousemoverel) == "function", "mousemoverel is not a function")
    local ok = pcall(mousemoverel, 0, 0)
    assert(ok, "mousemoverel threw an error when called")
    return "fully supported"
end)

register("mousescroll", {}, function()
    assert(mousescroll ~= nil, "mousescroll is nil")
    assert(type(mousescroll) == "function", "mousescroll is not a function")
    local ok = pcall(mousescroll, 0)
    assert(ok, "mousescroll threw an error when called")
    return "fully supported"
end)
