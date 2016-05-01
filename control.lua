require "defines"

MAX_CONFIG_SIZE = 10
MAX_STORAGE_SIZE = 12

function glob_init()

    global["entity-recipes"] = global["entity-recipes"] or {}
    global["config"] = global["config"] or {}
    global["config-tmp"] = global["config-tmp"] or {}
    global["storage"] = global["storage"] or {}

end

function get_type(entity)

    if game.entity_prototypes[entity] then
        return game.entity_prototypes[entity].type
    end
    return ""

end

function count_keys(hashmap)

    local result = 0

    for _, __ in pairs(hashmap) do
        result = result + 1
    end

    return result

end

function get_config_item(player, index, type)

    if not global["config-tmp"][player.name]
            or index > #global["config-tmp"][player.name]
            or global["config-tmp"][player.name][index][type] == "" then

        return {"upgrade-planner-item-not-set"}

    end

    return game.item_prototypes[global["config-tmp"][player.name][index][type]].localised_name

end

function gui_init(player, after_research)

    if player.gui.top["replacer-config-button"] then
        player.gui.top["replacer-config-button"].destroy() 
    end

    if not player.gui.top["upgrade-planner-config-button"]
            and (player.force.technologies["automated-construction"].researched or after_research) then

        player.gui.top.add{
            type = "button",
            name = "upgrade-planner-config-button",
            caption = {"upgrade-planner-config-button-caption"}
        }

    end

end

function gui_open_frame(player)

    local frame = player.gui.left["upgrade-planner-config-frame"]
    local storage_frame = player.gui.left["upgrade-planner-storage-frame"]

    if frame then
        frame.destroy()
        if storage_frame then
            storage_frame.destroy()
        end
        global["config-tmp"][player.name] = nil
        return
    end

    -- If player config does not exist, we need to create it.

    global["config"][player.name] = global["config"][player.name] or {}

    -- Temporary config lives as long as the frame is open, so it has to be created
    -- every time the frame is opened.

    global["config-tmp"][player.name] = {}

    -- We need to copy all items from normal config to temporary config.

    local i = 0

    for i = 1, MAX_CONFIG_SIZE do

        if i > #global["config"][player.name] then
            global["config-tmp"][player.name][i] = { from = "", to = "" }
        else
            global["config-tmp"][player.name][i] = {
                from = global["config"][player.name][i].from, 
                to = global["config"][player.name][i].to
            }
        end
        
    end

    -- Now we can build the GUI.

    frame = player.gui.left.add{
        type = "frame",
        caption = {"upgrade-planner-config-frame-title"},
        name = "upgrade-planner-config-frame",
        direction = "vertical"
    }

    local error_label = frame.add{ 
        type = "label",
        caption = "---",
        name = "upgrade-planner-error-label"
    }

    error_label.style.minimal_width = 200

    local ruleset_grid = frame.add{
        type = "table",
        colspan = 3,
        name = "upgrade-planner-ruleset-grid"
    }

    ruleset_grid.add{
        type = "label",
        name = "upgrade-planner-grid-header-1",
        caption = {"upgrade-planner-config-header-1"}
    }
    ruleset_grid.add{
        type = "label",
        name = "upgrade-planner-grid-header-2",
        caption = {"upgrade-planner-config-header-2"}
    }
    ruleset_grid.add{
        type = "label",
        name = "upgrade-planner-grid-header-3",
        caption = ""
    }

    for i = 1, MAX_CONFIG_SIZE do
        ruleset_grid.add{ 
            type = "button",
            name = "upgrade-planner-from-" .. i,
            style = "upgrade-planner-small-button",
            caption = get_config_item(player, i, "from")
        }
        ruleset_grid.add{
            type = "button",
            name = "upgrade-planner-to-" .. i,
            style = "upgrade-planner-small-button",
            caption = get_config_item(player, i, "to")
        }
        ruleset_grid.add{
            type = "button",
            name = "upgrade-planner-clear-" .. i,
            style = "upgrade-planner-small-button",
            caption = {"upgrade-planner-config-button-clear"}
        }
    end

    local button_grid = frame.add{
        type = "table",
        colspan = 2,
        name = "upgrade-planner-button-grid"
    }

    button_grid.add{
        type = "button",
        name = "upgrade-planner-apply",
        caption = {"upgrade-planner-config-button-apply"}
    }
    button_grid.add{
        type = "button",
        name = "upgrade-planner-clear-all",
        caption = {"upgrade-planner-config-button-clear-all"}
    }

    storage_frame = player.gui.left.add{
        type = "frame",
        name = "upgrade-planner-storage-frame",
        caption = {"upgrade-planner-storage-frame-title"},
        direction = "vertical"
    }

    local storage_frame_error_label = storage_frame.add{
        type = "label",
        name = "upgrade-planner-storage-error-label",
        caption = "---"
    }

    storage_frame_error_label.style.minimal_width = 200

    local storage_frame_buttons = storage_frame.add{
        type = "table",
        colspan = 3,
        name = "upgrade-planner-storage-buttons"
    }

    storage_frame_buttons.add{
        type = "label",
        caption = {"upgrade-planner-storage-name-label"},
        name = "upgrade-planner-storage-name-label"
    }

    storage_frame_buttons.add{
        type = "textfield",
        text = "",
        name = "upgrade-planner-storage-name"
    }

    storage_frame_buttons.add{
        type = "button",
        caption = {"upgrade-planner-storage-store"},
        name = "upgrade-planner-storage-store",
        style = "upgrade-planner-small-button"
    }

    local storage_grid = storage_frame.add{
        type = "table",
        colspan = 3,
        name = "upgrade-planner-storage-grid"
    }

    if global["storage"][player.name] then

        i = 1
        for key, _ in pairs(global["storage"][player.name]) do
            storage_grid.add{
                type = "label",
                caption = key .. "        ",
                name = "upgrade-planner-storage-entry-" .. i
            }

            storage_grid.add{
                type = "button",
                caption = {"upgrade-planner-storage-restore"},
                name = "upgrade-planner-restore-" .. i,
                style = "upgrade-planner-small-button"
            }
            storage_grid.add{
                type = "button",
                caption = {"upgrade-planner-storage-remove"},
                name = "upgrade-planner-remove-" .. i,
                style = "upgrade-planner-small-button"
            }
            i = i + 1
        end

    end

end

function gui_save_changes(player)

    -- Saving changes consists in:
    --   1. copying config-tmp to config
    --   2. removing config-tmp
    --   3. closing the frame

    if global["config-tmp"][player.name] then

        local i = 0
        global["config"][player.name] = {}

        for i = 1, #global["config-tmp"][player.name] do

            -- Rule can be saved only if both "from" and "to" fields are set.

            if global["config-tmp"][player.name][i].from == ""
                    or global["config-tmp"][player.name][i].to == "" then

                global["config"][player.name][i] = { from = "", to = "" }

            else
                global["config"][player.name][i] = {
                    from = global["config-tmp"][player.name][i].from,
                    to = global["config-tmp"][player.name][i].to
                }
            end
            
        end

        global["config-tmp"][player.name] = nil

    end

    local frame = player.gui.left["upgrade-planner-config-frame"]
    local storage_frame = player.gui.left["upgrade-planner-storage-frame"]

    if frame then
        frame.destroy()
        if storage_frame then
            storage_frame.destroy()
        end
    end

end

function gui_clear_all(player)

    local i = 0
    local frame = player.gui.left["upgrade-planner-config-frame"]

    if not frame then return end

    local ruleset_grid = frame["upgrade-planner-ruleset-grid"]

    for i = 1, MAX_CONFIG_SIZE do

        global["config-tmp"][player.name][i] = { from = "", to = "" }
        ruleset_grid["upgrade-planner-from-" .. i].caption = {"upgrade-planner-item-not-set"}
        ruleset_grid["upgrade-planner-to-" .. i].caption = {"upgrade-planner-item-not-set"}
        
    end

end

function gui_display_message(frame, storage, message)

    local label_name = "upgrade-planner-"
    if storage then label_name = label_name .. "storage-" end
    label_name = label_name .. "error-label"

    local error_label = frame[label_name]
    if not error_label then return end

    if message ~= "---" then
        message = {message}
    end

    error_label.caption = message

end

function gui_set_rule(player, type, index)

    local frame = player.gui.left["upgrade-planner-config-frame"]
    if not frame or not global["config-tmp"][player.name] then return end

    local stack = player.cursor_stack

    if not stack.valid_for_read then
        gui_display_message(frame, false, "upgrade-planner-item-empty")
        return
    end

    if stack.name ~= "deconstruction-planner" or type ~= "to" then

        local opposite = "from"
        local i = 0

        if type == "from" then

            opposite = "to"

            for i = 1, #global["config-tmp"][player.name] do
                if index ~= i and global["config-tmp"][player.name][i].from == stack.name then
                    gui_display_message(frame, false, "upgrade-planner-item-already-set")
                    return
                end
            end

        end

        local related = global["config-tmp"][player.name][index][opposite]

        if related ~= "" then

            if related == stack.name then
                gui_display_message(frame, false, "upgrade-planner-item-is-same")
                return
            end

            if get_type(stack.name) ~= get_type(related) then
                gui_display_message(frame, false, "upgrade-planner-item-not-same-type")
                return
            end

        end

    end

    global["config-tmp"][player.name][index][type] = stack.name

    local ruleset_grid = frame["upgrade-planner-ruleset-grid"]
    ruleset_grid["upgrade-planner-" .. type .. "-" .. index].caption = game.item_prototypes[stack.name].localised_name

end

function gui_clear_rule(player, index)

    local frame = player.gui.left["upgrade-planner-config-frame"]
    if not frame or not global["config-tmp"][player.name] then return end

    gui_display_message(frame, false, "---")

    local ruleset_grid = frame["upgrade-planner-ruleset-grid"]

    global["config-tmp"][player.name][index] = { from = "", to = "" }
    ruleset_grid["upgrade-planner-from-" .. index].caption = {"upgrade-planner-item-not-set"}
    ruleset_grid["upgrade-planner-to-" .. index].caption = {"upgrade-planner-item-not-set"}

end

function gui_store(player)

    global["storage"][player.name] = global["storage"][player.name] or {}

    local storage_frame = player.gui.left["upgrade-planner-storage-frame"]
    if not storage_frame then return end

    local textfield = storage_frame["upgrade-planner-storage-buttons"]["upgrade-planner-storage-name"]
    local name = textfield.text
    name = string.match(name, "^%s*(.-)%s*$")

    if not name or name == "" then
        gui_display_message(storage_frame, true, "upgrade-planner-storage-name-not-set")
        return
    end

    if global["storage"][player.name][name] then
        gui_display_message(storage_frame, true, "upgrade-planner-storage-name-in-use")
        return
    end

    global["storage"][player.name][name] = {}
    local i = 0

    for i = 1, #global["config-tmp"][player.name] do
        global["storage"][player.name][name][i] = {
            from = global["config-tmp"][player.name][i].from,
            to = global["config-tmp"][player.name][i].to
        }
    end

    local storage_grid = storage_frame["upgrade-planner-storage-grid"]
    local index = count_keys(global["storage"][player.name]) + 1

    if index > MAX_STORAGE_SIZE + 1 then
        gui_display_message(storage_frame, true, "upgrade-planner-storage-too-long")
        return
    end

    storage_grid.add{
        type = "label",
        caption = name .. "        ",
        name = "upgrade-planner-storage-entry-" .. index
    }

    storage_grid.add{
        type = "button",
        caption = {"upgrade-planner-storage-restore"},
        name = "upgrade-planner-restore-" .. index,
        style = "upgrade-planner-small-button"
    }

    storage_grid.add{
        type = "button",
        caption = {"upgrade-planner-storage-remove"},
        name = "upgrade-planner-remove-" .. index,
        style = "upgrade-planner-small-button"
    }

    gui_display_message(storage_frame, true, "---")
    textfield.text = ""

end

function gui_restore(player, index)

    local frame = player.gui.left["upgrade-planner-config-frame"]
    local storage_frame = player.gui.left["upgrade-planner-storage-frame"]
    if not frame or not storage_frame then return end

    local storage_grid = storage_frame["upgrade-planner-storage-grid"]
    local storage_entry = storage_grid["upgrade-planner-storage-entry-" .. index]
    if not storage_entry then return end

    local name = string.match(storage_entry.caption, "^%s*(.-)%s*$")
    if not global["storage"][player.name] or not global["storage"][player.name][name] then return end

    global["config-tmp"][player.name] = {}

    local i = 0
    local ruleset_grid = frame["upgrade-planner-ruleset-grid"]

    for i = 1, MAX_CONFIG_SIZE do
        if i > #global["storage"][player.name][name] then
            global["config-tmp"][player.name][i] = { from = "", to = "" }
        else
            global["config-tmp"][player.name][i] = {
                from = global["storage"][player.name][name][i].from,
                to = global["storage"][player.name][name][i].to
            }
        end
        ruleset_grid["upgrade-planner-from-" .. i].caption = get_config_item(player, i, "from")
        ruleset_grid["upgrade-planner-to-" .. i].caption = get_config_item(player, i, "to")
    end

    gui_display_message(storage_frame, true, "---")

end

function gui_remove(player, index)

    if not global["storage"][player.name] then return end

    local storage_frame = player.gui.left["upgrade-planner-storage-frame"]
    if not storage_frame then return end

    local storage_grid = storage_frame["upgrade-planner-storage-grid"]
    local label = storage_grid["upgrade-planner-storage-entry-" .. index]
    local btn1 = storage_grid["upgrade-planner-restore-" .. index]
    local btn2 = storage_grid["upgrade-planner-remove-" .. index]

    if not label or not btn1 or not btn2 then return end

    local name = string.match(label.caption, "^%s*(.-)%s*$")

    label.destroy()
    btn1.destroy()
    btn2.destroy()

    global["storage"][player.name][name] = nil

    gui_display_message(storage_frame, true, "---")

end

script.on_event(defines.events.on_marked_for_deconstruction, function(event)

    local entity = event.entity
    local deconstruction = false
    local upgrade = false
    local player = nil
    local stack = nil
    local i = 0

    -- Determine which player used upgrade planner.
    -- If more than one player has upgrade planner in their hand or one
    -- player has a upgrade planner and other has deconstruction planner,
    -- we can't determine it, so we have to discard deconstruction order.

    for i = 1, #game.players do

        stack = game.players[i].cursor_stack

        if stack.valid_for_read then
            if stack.name == "upgrade-planner" then
                if upgrade or deconstruction then
                    entity.cancel_deconstruction(entity.force)
                    return
                end
                player = game.players[i]
                upgrade = true
            elseif stack.type == "deconstruction-item" then
                if upgrade then
                    entity.cancel_deconstruction(entity.force)
                    return
                end
                deconstruction = true
            end
        end

    end

    if not player then return end

    -- Get player config.

    if not global["config"][player.name] then

        -- Config for this player does not exist yet, so we have nothing to do.
        -- We can create it now for later usage.

        global["config"][player.name] = {}
        entity.cancel_deconstruction(entity.force)
        return
        
    end

    local config = global["config"][player.name]

    -- Check if entity is valid and stored in config as a source.

    local index = 0

    for i = 1, #config do

        if config[i].from == entity.name then
            index = i
            break
        end

    end

    if index == 0 then
        entity.cancel_deconstruction(entity.force)
        return
    end

    local type = get_type(entity.name) 
    if type == "" then
        entity.cancel_deconstruction(entity.force)
        return
    end

    -- If entity is a deconstruction planner, we are only marking entities for deconstruction, without replacing them

    if config[index].to ~= "deconstruction-planner" then

        local new_entity = {
            name = "entity-ghost",
            inner_name = config[index].to,
            position = entity.position,
            direction = entity.direction,
            force = entity.force
        }

        -- If entity is an assembling machine, we need to preserve its recipe.

        if type == "assembling-machine" then
            global["entity-recipes"][entity.position.x .. ":" .. entity.position.y] = entity.recipe
        end

        -- If entity is a transport belt to ground, we need to preserve it type (input or output)

        if type == "transport-belt-to-ground" then
            new_entity.type = entity.belt_to_ground_type
        end

        game.get_surface(1).create_entity(new_entity)

    end

end)

script.on_event(defines.events.on_robot_built_entity, function(event)

    local entity = event.created_entity

    -- Restore recipe of any assembling machine placed by the robot.

    if get_type(entity.name) == "assembling-machine" then

        local tag = entity.position.x .. ":" .. entity.position.y
        if global["entity-recipes"][tag] then
            entity.recipe = global["entity-recipes"][tag]
            global["entity-recipes"][tag] = nil
        end

    end

end)

script.on_event(defines.events.on_gui_click, function(event) 

    local element = event.element
    local player = game.get_player(event.player_index)

    if element.name == "upgrade-planner-config-button" then
        gui_open_frame(player)
    elseif element.name == "upgrade-planner-apply" then
        gui_save_changes(player)
    elseif element.name == "upgrade-planner-clear-all" then
        gui_clear_all(player)
    elseif element.name  == "upgrade-planner-storage-store" then
        gui_store(player)
    else

        local type, index = string.match(element.name, "upgrade%-planner%-(%a+)%-(%d+)")
        if type and index then
            if type == "from" or type == "to" then
                gui_set_rule(player, type, tonumber(index))
            elseif type == "restore" then
                gui_restore(player, tonumber(index))
            elseif type == "remove" then
                gui_remove(player, tonumber(index))
            elseif type == "clear" then
                gui_clear_rule(player, tonumber(index))
            end
        end

    end

end)

script.on_event(defines.events.on_research_finished, function(event)

    if event.research.name == 'automated-construction' then
        for _, player in pairs(game.players) do
            gui_init(player, true)
        end
    end

end)

script.on_init(function()

    glob_init()

    for _, player in pairs(game.players) do
        gui_init(player, false)
    end


end)

