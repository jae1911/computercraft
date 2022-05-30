-- DN0's Mining Program --
-- Yes, we know, this one looks like Python but using Lua.

--
-- THEORY
--
--   0123
--   xxxx0
--   xxxx1
--   xxxx2
--   xxxx3
--
-- Turtle starts at 0,0 -> 0,1 -> 0,2 -> 0,3 -> 1,3 -> 1,2 -> 1,1 -> 1,0 ect..


-- Setup important vars
task = {}
task.EX = 0 -- Excavate
task.UL = 1 -- Unload
task.RE = 2 -- Refuel
task.FI = 3 -- Finish

local depth = 100
local start_depth = 0
local current_task = task.EX
local mining = false
local task_depth = 0
local min_fuel = 100
-- position
local x = 0
local z = 0
local return_base = false
local prev_x = 0
local prev_y = 0
local direction = 0
-- mining params
local quary_size = 4 -- 4x4 = 1c

function reset_term()
    -- Clear the terminal
    term.clear()
    term.setCursorPos(1,1)
end

function motd()
    -- Shit function to print the MOTD
    reset_term()
    print("DN0's Efficient Mining Program")
end

function save_state()
    -- Saves the state of the program in case of chunk unload or some fail in
    -- general
    local state_file = fs.open("state_miner", "w")
    state_file.writeLine(depth)
    state_file.writeLine(start_depth)
    state_file.writeLine(current_task)
    state_file.writeLine(task_depth)
    state_file.writeLine(x)
    state_file.writeLine(z)
    state_file.close()
end

function restore_state()
    -- Restores a state from a previously saved file
    local state_file = fs.open("state_miner", "r")

    if state_file == nil then
        print("No snapshot detected, skipping")
        return 0
    end

    depth = tonumber(state_file.readLine())
    start_depth = tonumber(state_file.readLine())
    current_task = tonumber(state_file.readLine())
    task_depth = tonumber(state_file.readLine())
    x = tonumber(state_file.readLine())
    z = tonumber(state_file.readLine())

    state_file.close()

    return 1
end

function ivFull()
  for i = 1,16 do
    if turtle.getItemSpace(i) > 0 then
      return false
    end
  end
  return true
end

function checkfuel()
    fuel_level = turtle.getFuelLevel()
    local refuled = false

    if turtle.getFuelLevel() > min_fuel then
            refuled = true
    end

    while refuled == false do
        print("-- REFUELING --")

        task_depth = depth -- save task depth in case we want to go refuel

        current_task = task.RE

        -- Scan turtle inventory for fuel
        for i = 1, 16 do
            local item = turtle.getItemDetail(i)
            if item then
                local name = item.name
                local j = string.find(name, ":")
                if "coal" == string.sub(name, j + 1, j + 1 + string.len("coal")) then
                    turtle.select(i)
                    local max_fuel = tonumber(turtle.getFuelLimit())
                    local is_refueling = true
                    while is_refueling == true do
                        item = turtle.getItemDetail(i)
                        if (not item) or (turtle.getFuelLevel() > max_fuel - 200) then
                            is_refueling = false
                        else
                            turtle.refuel(1)
                        end
                    end
                end
            end
        end

        -- TODO: go back to base layer (0,0,0) and get fuel from there

        if turtle.getFuelLevel() > min_fuel then
            refuled = true
        end
    end

    current_task = task.EX
end

function checkinv()
    if ivFull() then
        current_task = task.UL

        -- Save stuff before going to 0,0,0
        prev_x = x
        prev_y = y
        task_depth = depth

        -- Go to 0,0,0
        if x == 0 and z == 0 and depth ~= 0 then
            for i = 1, depth do
                turtle.up()

                depth = depth + 1
            end
        elseif direction == -2 then
            turtle.turnLeft()

            to_go_z = quary_size - z - 1
            to_go_x = quary_size - x - 1
            for i = 0, to_go_z do
                turtle.forward()
            end
        end
 
        current_task = task.EX
    end
end

function mine()
    -- main mining function
    mining = true
    total_times = 0 -- debug
    while mining do
        checkfuel()
        -- checkinv()

        -- mine stuff

        if return_base == false then
            if (depth == start_depth) or (x == 0 and z == 0) then -- Base layer
                turtle.digDown()

                turtle.down()
                depth = depth - 1
                task_depth = depth

                direction = 0
            end

            -- Regular mining routine
            if x ~= quary_size - 1 then -- Going from down to up
                for i = 1, quary_size - 1 do
                    turtle.dig()

                    turtle.forward()
                    x = x + 1
                end
            elseif x == quary_size - 1 then -- Going from up to down
                for i = 1, quary_size - 1 do
                    turtle.dig()

                    turtle.forward()

                    x = x - 1
                end
            end

            if x == quary_size - 1 and z ~= quary_size - 1 then
                turtle.turnLeft()
                direction = direction - 1
                turtle.dig()
                turtle.forward()
                z = z + 1
                turtle.turnLeft()
                direction = direction - 1
            elseif x == 0 and z ~= quary_size - 1 then
                turtle.turnRight()
                direction = direction + 1
                turtle.dig()
                turtle.forward()
                z = z + 1
                turtle.turnRight()
                direction = direction + 1
            elseif z == quary_size - 1 then -- Reset when at max
                return_base = true
            end
        else
            turtle.turnLeft()
            direction = direction - 1
            turtle.dig()
            local left_to_base = quary_size - 1
            if z ~= quary_size - 1 then
                left_to_base = left_to_base - z
            end
            for i = 1, left_to_base do
                turtle.forward()
                z = z - 1
            end
            turtle.turnLeft()
            direction = direction - 1

            return_base = false
        end

        print("-- DEBUG --")
        print(x)
        print(z)
        print(depth)
        print(direction)

        -- Debug
        total_times = total_times + 1
        if total_times == quary_size * 5 then
            break
        end
    end
end

function check_chest()
    turtle.turnRight()
    direction = direction + 1
    local success, meta = turtle.inspect()

    if success then
        print(meta.name)
        if meta.name ~= "minecraft:chest" then
            success = false
        end
    end

    turtle.turnLeft()
    direction = direction - 1

    return success
end

-- MAIN FUNCTION : --

-- Check for chest
if not check_chest() then
    print("Please put a chest/double chest at the right of the turtle.")
    return
end

-- Try to restore to autostart
local state = restore_state()

if state == 1 then
    -- Resume --
    mine()
else -- If no state saved
    motd()
    mine()
end
