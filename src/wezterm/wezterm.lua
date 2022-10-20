local wezterm = require 'wezterm';

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

local function get_tab_title(tab, tabs, panes, config, hover, max_width)
    local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
    local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle
    local SOLID_LEFT_MOST = wezterm.nerdfonts.ple_left_half_circle_thick
    local SOLID_RIGHT_MOST = wezterm.nerdfonts.ple_right_half_circle_thick
    
    local SSH_DOMAIN = wezterm.nerdfonts.mdi_collage
    local UNKNOWN_DOMAIN = wezterm.nerdfonts.mdi_close_box
    
    local SERVER_ICON = wezterm.nerdfonts.mdi_access_point
    local SHELL_ICON = wezterm.nerdfonts.mdi_console_line
    local WIN_ICON = wezterm.nerdfonts.mdi_windows
    local REMOTE_ICON = wezterm.nerdfonts.mdi_cloud
    local DASHBOARD_ICON = wezterm.nerdfonts.mdi_gauge
    local TEXT_EDITOR_ICON = wezterm.nerdfonts.mdi_pen
    local INSPECT_ICON = wezterm.nerdfonts.mdi_magnify
    local TRANSFER_ICON = wezterm.nerdfonts.mdi_flash
    
    local PYTHON_ICON = wezterm.nerdfonts.mdi_language_python
    local R_ICON = wezterm.nerdfonts.mdi_language_r
    
    local TASK_PENDING_ICON = wezterm.nerdfonts.mdi_run
    
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
        if in_array(tab.active_pane.domain_name, { "hanzg", "zafu", "zafud" }) then
            title_with_icon = SSH_DOMAIN .. " " .. tab.active_pane.domain_name
        else
            title_with_icon = UNKNOWN_DOMAIN .. " " .. tab.active_pane.domain_name
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
        elseif in_array(exec_name, { "top", "htop", "ntop" }) then
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
        elseif in_array(exec_name, { "curl", "wget", "aria2c" }) then
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
        { Attribute = { Intensity = "Bold" } },
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

local function set_right_status(window, pane)
    local batteries = ""
    
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
        
        batteries = batteries .. battery_icon .. string.format(" %.0f%%", battery.state_of_charge * 100) .. "  "
    end
    
    window:set_right_status(wezterm.format {
        { Attribute = { Intensity = "Bold" } },
        { Text = batteries .. wezterm.strftime("%H:%M ") },
    })
end

wezterm.on("format-tab-title", get_tab_title)

wezterm.on("update-right-status", set_right_status)

return {
    set_environment_variables = {
        PATH = wezterm.executable_dir .. ":" .. os.getenv("PATH"),
    },
    
    -- # [ ? age ] base64=YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBqSjVGalZCK2ZVb0tteEdSejlYWEp6M2tLcEtDVU5wejBEY2VzUlZWencwCmpiZWptOWRNTWdKa0h2cDJDTWQwZmk2VktnNVA2SXc2QjdQTEhaYkZya1kKLS0tIEVEbG1hQTVHalEyREp4Rko1RSt4NFZ4Z2dxSTR1aTJycU9NVUx3dHRKckUKe+B0jFv1n5UW8xj2mUHkY121lf7KTcIpAIDTzDC8xtUmnx7nRsZ9zomCBjzk7cJ3nH82edvi49TRmaTOOaIVTvWTfp8jClpwJLb3RmSLJ/2fC9knbfAgvSLkNOVDsO4ZNopU/ufYxaxIvKu3onxxWac4DDxLAD4wMI9SgqjHNv9cs9Rk79rrQCIVCybhm6T+IvWsijyNvJtslHhDkSxf/D+N379GXCU5ujuaN0686c3QJQrtdKeQT61/Gsk52a5TAqV1dTn28rOiAqceVlS9fLFXzjfgaSmCoNb47IhsAk0V4LMc1Ze8FWiX04VJfgZAd3duCIX4bK1M2oN9S3SE6H5YySK5TJmauE69aUbqBLwEdAK0nsd5uTXEOl9KbcCTkRL4PX7nniAZb9jEUCe65f6WvJGaWFqcbfb6At8T2vt+8X9MP1tz9Ag7nJlRxgSQfoENCWJnppcgMHpW12Su0Dm5liYHOnc6WdqHSKS6ZCYDI9CKqZUt1y5tyLkGVB4xNFdpkgrtvd9zxHMlhGrW0PkV+N/qjNd74HghVIV5uEBTjxyZEWuc6yUDd+HTWzcv3iPJomQlw67sZ6XvOcyjTPjoCi9oMuZ4CYo3+UmyGSPvt11MSa1MA2a1a89Go24+YpJqnJ/EF2bI0ZuhE0G6+H8fGSD/k3c6R1/ldH91msLfrF7xS0UV9QvScblnGmhAwW13cHrjc1FnhbCNePRA6UuqwMLiH3FHmM7TuiwGkANkwN2Osp5Kcr/vUHZfcMbqfph6GcoULWQ9GBy2sXPvaBxlrZdILqY8wyWR+yADRXJEggkgU51EiEw4MmyRyyo0DFwH0IBBrPja/G8XAud9nGqdRlZ9gNtQ1Z/KzgqF6IT5MybhP5jIS1CDdtstP1OhQnK9f4xF6u/yftSkBIgD1Ca+tuUyQ59p/qfJ0rExTeuTDX2P0Ta16zlSKdEtvjmT
    
    font_rules = {
        { font = get_font_config { "Bold", "DemiBold" } },
        { italic = true, font = get_font_config({ "Bold", "DemiBold" }, true) },
        { intensity = "Half", font = get_font_config { "Regular", "Regular" } },
        { intensity = "Half", italic = true, font = get_font_config({ "Regular", "Regular" }, true) },
        { intensity = "Bold", font = get_font_config { "ExtraBold", "Bold" } },
        { intensity = "Bold", italic = true, font = get_font_config({ "ExtraBold", "Bold" }, true) },
    },
    font_size = 14,
    
    keys = {
        {
            key = "`",
            mods = "",
            action = wezterm.action.ActivateKeyTable { name = "default", one_shot = false, timeout_milliseconds = 1000 },
        },
        {
            key = "s",
            mods = "SUPER",
            action = wezterm.action.QuickSelect,
        },
        {
            key = "S",
            mods = "SUPER",
            action = wezterm.action.QuickSelect,
        },
    },
    key_tables = {
        default = {
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
                key = "r",
                mods = "",
                action = wezterm.action.RotatePanes("Clockwise"),
            },
            {
                key = "R",
                mods = "",
                action = wezterm.action.RotatePanes("Clockwise"),
            },
            {
                key = "r",
                mods = "SUPER",
                action = wezterm.action.RotatePanes("CounterClockwise"),
            },
            {
                key = "R",
                mods = "SUPER",
                action = wezterm.action.RotatePanes("CounterClockwise"),
            },
            {
                key = "Backspace",
                mods = "",
                action = wezterm.action.CloseCurrentPane { confirm = false },
            },
            {
                key = "q",
                mods = "",
                action = wezterm.action.ActivateTabRelative(-1),
            },
            {
                key = "Q",
                mods = "",
                action = wezterm.action.ActivateTabRelative(-1),
            },
            {
                key = "e",
                mods = "",
                action = wezterm.action.ActivateTabRelative(1),
            },
            {
                key = "E",
                mods = "",
                action = wezterm.action.ActivateTabRelative(1),
            },
            {
                key = "1",
                mods = "",
                action = wezterm.action.MoveTabRelative(-1),
            },
            {
                key = "3",
                mods = "",
                action = wezterm.action.MoveTabRelative(1),
            },
            {
                key = "t",
                mods = "",
                action = wezterm.action.SpawnTab("CurrentPaneDomain"),
            },
            {
                key = "T",
                mods = "",
                action = wezterm.action.SpawnTab("CurrentPaneDomain"),
            },
            {
                key = "w",
                mods = "",
                action = wezterm.action.CloseCurrentTab { confirm = false },
            },
            {
                key = "W",
                mods = "",
                action = wezterm.action.CloseCurrentTab { confirm = false },
            },
            {
                key = "h",
                mods = "",
                action = wezterm.action.ActivatePaneDirection("Left"),
            },
            {
                key = "H",
                mods = "",
                action = wezterm.action.ActivatePaneDirection("Left"),
            },
            {
                key = "j",
                mods = "",
                action = wezterm.action.ActivatePaneDirection("Down"),
            },
            {
                key = "J",
                mods = "",
                action = wezterm.action.ActivatePaneDirection("Down"),
            },
            {
                key = "k",
                mods = "",
                action = wezterm.action.ActivatePaneDirection("Up"),
            },
            {
                key = "K",
                mods = "",
                action = wezterm.action.ActivatePaneDirection("Up"),
            },
            {
                key = "l",
                mods = "",
                action = wezterm.action.ActivatePaneDirection("Right"),
            },
            {
                key = "L",
                mods = "",
                action = wezterm.action.ActivatePaneDirection("Right"),
            },
            {
                key = "n",
                mods = "",
                action = wezterm.action.SpawnWindow,
            },
            {
                key = "N",
                mods = "",
                action = wezterm.action.SpawnWindow,
            },
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
                mods = "SUPER",
                action = wezterm.action.Multiple(get_repeated_array(wezterm.action.SendKey { key = "UpArrow" }, 20)),
            },
            {
                key = "DownArrow",
                mods = "SUPER",
                action = wezterm.action.Multiple(get_repeated_array(wezterm.action.SendKey { key = "DownArrow" }, 20)),
            },
            {
                key = "Space",
                mods = "",
                action = wezterm.action.ShowLauncher,
            },
            {
                key = "Enter",
                mods = "",
                action = wezterm.action.ToggleFullScreen,
            },
        },
    },
    
    colors = {
        tab_bar = {
            background = "black",
            new_tab = { bg_color = "black", fg_color = "bisque", intensity = "Bold" },
            new_tab_hover = { bg_color = "black", fg_color = "gold", intensity = "Bold" },
        },
    },
    
    check_for_updates_interval_seconds = 60 * 60 * 24 * 7,
    show_update_window = true,
    
    native_macos_fullscreen_mode = true,
    window_background_opacity = 0.8,
    window_decorations = "RESIZE",
    
    enable_scroll_bar = false,
    scrollback_lines = 10000,
    
    hide_tab_bar_if_only_one_tab = false,
    switch_to_last_active_tab_when_closing_tab = true,
    tab_max_width = 20,
    use_fancy_tab_bar = false,
    
    pane_focus_follows_mouse = true,
    
    visual_bell = {
        fade_in_duration_ms = 200,
        fade_out_duration_ms = 100,
        target = "CursorColor",
    },
}
