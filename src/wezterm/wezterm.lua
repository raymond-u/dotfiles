local wezterm = require "wezterm"

local function get_font_config(weights, italic)
    return wezterm.font_with_fallback {
        { family = "JetBrains Mono", weight = weights[1], style = italic and "Italic" or "Normal" },
        { family = "Sarasa Mono SC", weight = weights[2], style = italic and "Italic" or "Normal" },
    }
end

local function get_deco_array(length, sub_characters)
    local deco_array = {}

    for i = 1, length do
        local deco_string = ""

        for j = 1, #tostring(i) do
            deco_string = deco_string .. sub_characters[tonumber(tostring(i):sub(j, j)) + 1]
        end

        deco_array[i] = deco_string
    end

    return deco_array
end

local function in_array(value, array)
    for _, val in ipairs(array) do
        if val == value then
            return true
        end
    end

    return false
end

local function get_repeated_array(obj, times)
    local array = {}

    for i = 1, times do
        array[i] = obj
    end

    return array
end

local function capitalize(str)
    return (str:gsub("^%l", string.upper))
end

local function get_process_name(str)
    return str:gsub("^.*[/\\]", ""):gsub("%.exe$", "")
end

wezterm.on(
    "format-tab-title",
    function(tab, tabs, panes, config, hover, max_width)
        local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
        local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle
        local SOLID_LEFT_MOST = wezterm.nerdfonts.ple_left_half_circle_thick
        local SOLID_RIGHT_MOST = wezterm.nerdfonts.ple_right_half_circle_thick

        local SSH_DOMAIN = wezterm.nerdfonts.md_collage

        local SERVER_ICON = wezterm.nerdfonts.md_access_point
        local SHELL_ICON = wezterm.nerdfonts.md_console_line
        local WIN_ICON = wezterm.nerdfonts.md_windows
        local REMOTE_ICON = wezterm.nerdfonts.md_cloud
        local DASHBOARD_ICON = wezterm.nerdfonts.md_gauge
        local TEXT_EDITOR_ICON = wezterm.nerdfonts.md_pen
        local INSPECT_ICON = wezterm.nerdfonts.md_magnify
        local TRANSFER_ICON = wezterm.nerdfonts.md_flash

        local PYTHON_ICON = wezterm.nerdfonts.md_language_python
        local R_ICON = wezterm.nerdfonts.md_language_r

        local TASK_PENDING_ICON = wezterm.nerdfonts.md_run

        local SUBSCRIPTS = get_deco_array(100, { "₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉" })
        local SUPERSCRIPTS = get_deco_array(100, { "⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹" })

        local has_unseen_output = false

        for _, pane in ipairs(tab.panes) do
            if pane.has_unseen_output then
                has_unseen_output = true

                break
            end
        end

        local background = tab.is_active and "gold" or hover and "chocolate" or has_unseen_output and "lightsteelblue" or "dimgray"
        local edge_background = "black"
        local foreground = "black"
        local edge_foreground = background

        local exec_name = ""
        local title_with_icon = ""
        local title = ""

        if tab.active_pane.foreground_process_name == "" then
            if tab.active_pane.domain_name == "local" then
                title_with_icon = TASK_PENDING_ICON .. " unknown"
            else
                title_with_icon = SSH_DOMAIN .. " " .. tab.active_pane.domain_name
            end
        else
            exec_name = get_process_name(tab.active_pane.foreground_process_name)

            if exec_name == "wezterm-gui" then
                title_with_icon = SERVER_ICON .. " WezTerm"
            elseif in_array(exec_name, { "sh", "bash", "zsh" }) then
                title_with_icon = SHELL_ICON .. " " .. capitalize(exec_name)
            elseif exec_name == "cmd" then
                title_with_icon = WIN_ICON .. " CMD"
            elseif in_array(exec_name, { "wsl", "wslhost" }) then
                title_with_icon = WIN_ICON .. " WSL"
            elseif in_array(exec_name, { "ssh", "sftp" }) then
                title_with_icon = REMOTE_ICON .. " " .. exec_name:upper()
            elseif in_array(exec_name, { "btm", "top", "htop", "ntop" }) then
                title_with_icon = DASHBOARD_ICON .. " " .. exec_name
            elseif exec_name == "nano" then
                title_with_icon = TEXT_EDITOR_ICON .. " nano"
            elseif exec_name == "vim" then
                title_with_icon = TEXT_EDITOR_ICON .. " Vim"
            elseif exec_name == "nvim" then
                title_with_icon = TEXT_EDITOR_ICON .. " Neovim"
            elseif in_array(exec_name, { "bat", "less", "moar" }) then
                title_with_icon = INSPECT_ICON .. " " .. exec_name
            elseif in_array(exec_name, { "fzf", "peco" }) then
                title_with_icon = INSPECT_ICON .. " " .. exec_name
            elseif exec_name == "man" then
                title_with_icon = INSPECT_ICON .. " Manual"
            elseif in_array(exec_name, { "aria2c", "curl", "wget", "yt-dlp" }) then
                title_with_icon = TRANSFER_ICON .. " " .. exec_name
            elseif in_array(exec_name, { "python", "Python" }) then
                title_with_icon = PYTHON_ICON .. " Python"
            elseif exec_name == "R" then
                title_with_icon = R_ICON .. " R"
            else
                title_with_icon = TASK_PENDING_ICON .. " " .. exec_name
            end
        end

        if wezterm.truncate_right(title_with_icon, max_width - 6) ~= title_with_icon then
            title = " " .. wezterm.truncate_right(title_with_icon, max_width - 8) .. " .."
        else
            title = " " .. title_with_icon .. " "
        end

        local tab_id = SUBSCRIPTS[tab.tab_index + 1]
        local pane_id = SUPERSCRIPTS[tab.active_pane.pane_index + 1]

        return {
            { Background = { Color = edge_background } },
            { Foreground = { Color = edge_foreground } },
            { Text = tab.tab_index == 0 and SOLID_LEFT_MOST or SOLID_LEFT_ARROW },
            { Background = { Color = background } },
            { Foreground = { Color = foreground } },
            { Text = tab_id },
            { Text = title },
            { Text = pane_id },
            { Background = { Color = edge_background } },
            { Foreground = { Color = edge_foreground } },
            { Text = tab.tab_index == #tabs - 1 and SOLID_RIGHT_MOST or SOLID_RIGHT_ARROW },
        }
    end
)

wezterm.on(
    "update-status",
    function(window, pane)
        local batteries = ""
        wezterm.GLOBAL.hourglass = wezterm.GLOBAL.hourglass or 0

        for _, battery in ipairs(wezterm.battery_info()) do
            local battery_icon = wezterm.nerdfonts.fa_battery_full

            if battery.state_of_charge < 0.1 then
                battery_icon = wezterm.nerdfonts.fa_battery_empty
            elseif battery.state_of_charge < 0.25 then
                battery_icon = wezterm.nerdfonts.fa_battery_quarter
            elseif battery.state_of_charge < 0.5 then
                battery_icon = wezterm.nerdfonts.fa_battery_half
            elseif battery.state_of_charge < 0.75 then
                battery_icon = wezterm.nerdfonts.fa_battery_three_quarters
            end

            batteries = battery_icon .. string.format(" %.0f%%", battery.state_of_charge * 100) .. "  "
        end

        local meta = pane:get_metadata() or {}

        if meta.is_tardy then
            local seconds = meta.since_last_response_ms / 1000.0

            if seconds > 5 then
                local tardy_icon = wezterm.nerdfonts.fa_hourglass_start

                if wezterm.GLOBAL.hourglass == 1 then
                    tardy_icon = wezterm.nerdfonts.fa_hourglass_half
                elseif wezterm.GLOBAL.hourglass == 2 then
                    tardy_icon = wezterm.nerdfonts.fa_hourglass_end
                end

                wezterm.GLOBAL.hourglass = wezterm.GLOBAL.hourglass + 1
                local tardy = tardy_icon .. string.format(" %.1fs", seconds) .. "  "

                window:set_right_status(wezterm.format {
                    { Attribute = { Intensity = "Bold" } },
                    { Text = tardy .. batteries .. wezterm.strftime("%H:%M ") },
                })

                return
            end
        end

        wezterm.GLOBAL.hourglass = 0

        window:set_right_status(wezterm.format {
            { Text = batteries .. wezterm.strftime("%H:%M ") },
        })
    end
)

local config = wezterm.config_builder()
config:set_strict_mode(true)

config.set_environment_variables = {
    PATH = wezterm.executable_dir .. ":" .. os.getenv("PATH"),
}

config.colors = {
    tab_bar = {
        background = "black",
        inactive_tab_hover = { bg_color = "black", fg_color = "black", italic = false },
        new_tab = { bg_color = "black", fg_color = "bisque", intensity = "Bold" },
        new_tab_hover = { bg_color = "black", fg_color = "gold", intensity = "Bold" },
    },
}

config.font_rules = {
    { intensity = "Normal", italic = false, font = get_font_config { "Bold", "DemiBold" } },
    { intensity = "Bold", italic = false, font = get_font_config { "Bold", "DemiBold" } },
    { intensity = "Half", italic = false, font = get_font_config { "Regular", "Regular" } },
    { intensity = "Normal", italic = true, font = get_font_config({ "Bold", "DemiBold" }, true) },
    { intensity = "Bold", italic = true, font = get_font_config({ "Bold", "DemiBold" }, true) },
    { intensity = "Half", italic = true, font = get_font_config({ "Regular", "Regular" }, true) },
}
config.font_size = 14

config.keys = {
    {
        key = "`",
        mods = "",
        action = wezterm.action.ActivateKeyTable { name = "default", one_shot = false, timeout_milliseconds = 1000 },
    },
    {
        key = "UpArrow",
        mods = "SHIFT",
        action = wezterm.action.ScrollToPrompt(-1),
    },
    {
        key = "DownArrow",
        mods = "SHIFT",
        action = wezterm.action.ScrollToPrompt(1),
    },
    {
        key = "Space",
        mods = "CTRL",
        action = wezterm.action.ShowLauncher,
    },
}
config.key_tables = {
    default = {
        -- Window control
        {
            key = "n",
            mods = "",
            action = wezterm.action.SpawnWindow,
        },
        -- Domain control
        {
            key = "Backspace",
            mods = "SHIFT",
            action = wezterm.action.DetachDomain("CurrentPaneDomain"),
        },
        -- Tab control
        {
            key = "t",
            mods = "",
            action = wezterm.action.SpawnTab("CurrentPaneDomain"),
        },
        {
            key = "t",
            mods = "SHIFT",
            action = wezterm.action.SpawnTab("DefaultDomain"),
        },
        {
            key = "w",
            mods = "",
            action = wezterm.action.CloseCurrentTab { confirm = false },
        },
        {
            key = "q",
            mods = "",
            action = wezterm.action.ActivateTabRelative(-1),
        },
        {
            key = "e",
            mods = "",
            action = wezterm.action.ActivateTabRelative(1),
        },
        {
            key = "a",
            mods = "",
            action = wezterm.action.MoveTabRelative(-1),
        },
        {
            key = "d",
            mods = "",
            action = wezterm.action.MoveTabRelative(1),
        },
        -- Pane control
        {
            key = "-",
            mods = "",
            action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" },
        },
        {
            key = "\\",
            mods = "",
            action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" },
        },
        {
            key = "Backspace",
            mods = "",
            action = wezterm.action.CloseCurrentPane { confirm = false },
        },
        {
            key = "z",
            mods = "",
            action = wezterm.action.TogglePaneZoomState,
        },
        {
            key = "r",
            mods = "",
            action = wezterm.action.RotatePanes("Clockwise"),
        },
        {
            key = "r",
            mods = "SHIFT",
            action = wezterm.action.RotatePanes("CounterClockwise"),
        },
        {
            key = "h",
            mods = "",
            action = wezterm.action.ActivatePaneDirection("Left"),
        },
        {
            key = "j",
            mods = "",
            action = wezterm.action.ActivatePaneDirection("Down"),
        },
        {
            key = "k",
            mods = "",
            action = wezterm.action.ActivatePaneDirection("Up"),
        },
        {
            key = "l",
            mods = "",
            action = wezterm.action.ActivatePaneDirection("Right"),
        },
        -- Scrolling
        {
            key = "UpArrow",
            mods = "",
            action = wezterm.action.ScrollToTop,
        },
        {
            key = "DownArrow",
            mods = "",
            action = wezterm.action.ScrollToBottom,
        },
        {
            key = "UpArrow",
            mods = "SHIFT",
            action = wezterm.action.Multiple(get_repeated_array(wezterm.action.SendKey { key = "UpArrow" }, 20)),
        },
        {
            key = "DownArrow",
            mods = "SHIFT",
            action = wezterm.action.Multiple(get_repeated_array(wezterm.action.SendKey { key = "DownArrow" }, 20)),
        },
        -- Misc
        {
            key = "Escape",
            mods = "",
            action = wezterm.action.PopKeyTable,
        },
        {
            key = "`",
            mods = "",
            action = wezterm.action.SendKey { key = "`" },
        },
        {
            key = "Tab",
            mods = "",
            action = wezterm.action.ResetTerminal,
        },
        {
            key = "u",
            mods = "",
            action = wezterm.action.CharSelect { copy_on_select = false },
        },
        {
            key = "c",
            mods = "",
            action = wezterm.action.QuickSelect,
        },
        {
            key = "v",
            mods = "",
            action = wezterm.action.ActivateCopyMode,
        },
        {
            key = "Enter",
            mods = "",
            action = wezterm.action.ToggleFullScreen,
        },
    },
}

config.mouse_bindings = {
    {
        event = { Down = { streak = 4, button = "Left" } },
        mods = "",
        action = wezterm.action.Multiple { wezterm.action.SelectTextAtMouseCursor("SemanticZone"), wezterm.action.CopyTo("PrimarySelection") },
    },
    {
        event = { Down = { streak = 1, button = "Right" } },
        mods = "",
        action = wezterm.action.PasteFrom("Clipboard"),
    },
}

config.visual_bell = {
    fade_in_duration_ms = 200,
    fade_out_duration_ms = 100,
    target = "CursorColor",
}

config.check_for_updates = false
config.pane_focus_follows_mouse = true
config.scrollback_lines = 10000

config.native_macos_fullscreen_mode = true
config.use_resize_increments = true
config.window_background_opacity = 0.8
config.window_decorations = "RESIZE"

config.switch_to_last_active_tab_when_closing_tab = true
config.tab_max_width = 20
config.use_fancy_tab_bar = false
config.show_tab_index_in_tab_bar = false

return config
