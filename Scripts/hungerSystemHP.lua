hungerHP = {}

config = require("config")
helpers = require("helperFunc")

--caching this, otherwise game lags during hp regen xD and should do it anyway
hungerHP.GA_hunger = nil

hungerHP.player = nil
hungerHP.currentHungerLvl = 0
------------------------------------------------------------
-- DEAL WITH HUNGER VFX AND AUDIO
------------------------------------------------------------
function hungerHP.DEAL_WITH_HUNGER_VISUALS(hungerA, hungerB)
    --should check if human and set it to no hunger when human?

    --replace hunger value which is sent to gameplay ability for vfx setting
    local status, err = pcall(function()
        helpers.PRINT_MSG("SETTING HUNGER VFX to: ")
        helpers.PRINT_MSG(hungerHP.currentHungerLvl)
        --if human set to 0
        if not helpers.isVampire then
            hungerA:set(hungerHP.currentHungerLvl) hungerB:set(hungerHP.currentHungerLvl)
        else
            hungerA:set(hungerHP.currentHungerLvl) hungerB:set(hungerHP.currentHungerLvl)
        end
    end)
    helpers.PRINT_MSG(status)
    helpers.PRINT_MSG(err)
end

------------------------------------------------------------
-- OVERRIDE HUNGER LEVEL IN GAME (DOESN'T TOUCH DIALOGUE)
------------------------------------------------------------
function hungerHP.CHANGE_HUNGER_LVL()
    
    helpers.FIND_HUNGER_SYS()

    local prevHunger
    pcall(function()

        if helpers.IS_VALID(helpers.hungerSystem) then
            prevHunger = helpers.hungerSystem.VampireHungerLevel
            helpers.PRINT_MSG(string.format("GAME HUNGER %d", helpers.hungerSystem.VampireHungerLevel))
            
            if prevHunger ~= hungerHP.currentHungerLvl then -- only change hunger lvl when is different then current
                helpers.hungerSystem.VampireHungerLevel = hungerHP.currentHungerLvl
                
                helpers.PRINT_MSG("Hunger lvl ->" .. tostring(hungerHP.currentHungerLvl))
                -- vfx stuff
                pcall(function() 
                        if not helpers.IS_VALID(hungerHP.GA_hunger) then
                            hungerHP.GA_hunger = FindFirstOf("GA_VampireHunger_C")
                        end
                        if helpers.IS_VALID(hungerHP.GA_hunger) then
                            local hungerLVLChanged = hungerHP.GA_hunger["On Hunger Level Changed"]
                            hungerLVLChanged(hungerHP.GA_hunger, hungerHP.currentHungerLvl)
                        end
                    end)
            else
                helpers.PRINT_MSG("Hunger is the same do nothing - checking vfx")

                --check if vfx is set correctly
                pcall(function() 
                    if not helpers.IS_VALID(hungerHP.GA_hunger) then
                        hungerHP.GA_hunger = FindFirstOf("GA_VampireHunger_C")
                    end

                    local hungerGALvl = hungerHP.GA_hunger["Current Intensity"] --intensity = 1 when high hunger, goes to 0 when low
                    helpers.PRINT_MSG(string.format("VFX HUNGER %f", hungerGALvl))

                    if hungerGALvl == 1.0 and hungerHP.currentHungerLvl ~= 2 then
                        helpers.PRINT_MSG(string.format("MY HUNGER %d", hungerHP.currentHungerLvl))
                        helpers.PRINT_MSG("HUNGER VFX WRONG - CHANGING")
                        local hungerLVLChanged = hungerHP.GA_hunger["On Hunger Level Changed"]
                        hungerLVLChanged(hungerHP.GA_hunger, hungerHP.currentHungerLvl)
                    else
                        if hungerGALvl == 0.0 and hungerHP.currentHungerLvl ~= 0 then
                            helpers.PRINT_MSG(string.format("MY HUNGER %d", hungerHP.currentHungerLvl))
                            helpers.PRINT_MSG("HUNGER VFX WRONG - CHANGING")
                            local hungerLVLChanged = hungerHP.GA_hunger["On Hunger Level Changed"]
                            hungerLVLChanged(hungerHP.GA_hunger, hungerHP.currentHungerLvl)
                        end
                    end


    end)



            end

        end

    end)
end

------------------------------------------------------------
--Blood/Vampire HP = tonumber(BloodBar:GetBlood())
--BarLength	= tonumber(BloodBar:GetBloodBarLength())
--BarsScaled = tonumber(BloodBar:GetCurrentBloodBarsScaled())
------------------------------------------------------------
-- CALC CURRENT HP %
------------------------------------------------------------

function hungerHP.GET_CURRENT_HP_PERCENT()
    local HPpercent = -1
    if not helpers.IS_VALID(hungerHP.player.BloodBar) or hungerHP.player.BloodBar:GetBlood() == 0 then 
        helpers.PRINT_MSG("Blood bar missing when calculating hp percent")
        return HPpercent
    end

    pcall(function()
        helpers.PRINT_MSG(string.format("Current hp: %f", hungerHP.player.BloodBar:GetBlood()))
        current = 100 * tonumber(hungerHP.player.BloodBar:GetBlood())
        helpers.PRINT_MSG(string.format("Max hp: %f", hungerHP.player.BloodBar:GetBloodBarLength()))
        HPpercent = current / tonumber(hungerHP.player.BloodBar:GetBloodBarLength())
    end)

    helpers.PRINT_MSG(string.format("HP percent: %f", HPpercent))
    return HPpercent
end

------------------------------------------------------------
-- DETERMINE HUNGER BASED ON HP
------------------------------------------------------------
function hungerHP.CALC_HUNGER_FROM_HP()
    local HpPercent = hungerHP.GET_CURRENT_HP_PERCENT()
    helpers.PRINT_MSG(HpPercent)
    -- hp % is invalid
    if HpPercent == -1 then
        helpers.PRINT_MSG("INVALID HP PERCENT")
        helpers.FIND_HUNGER_SYS()
        -- return current hunger lvl
        helpers.PRINT_MSG("RETURN CURRENT HUNGER: ")
        helpers.PRINT_MSG(helpers.hungerSystem.VampireHungerLevel)
        hungerHP.currentHungerLvl = helpers.hungerSystem.VampireHungerLevel
        return -1
    end


    local low_threshold = config.TWO_SEGMENTS_PERCENTS.low
    local high_threshold = config.TWO_SEGMENTS_PERCENTS.high

    --change thresholds
    if not config.oneThresholdForEverySegment then 
        local currentBloodSegments = hungerHP.player.BloodBar:GetSegmentCount()
        --default is set to two, no need to check 2
        if currentBloodSegments == 3 then
            helpers.PRINT_MSG("3 seg")
            low_threshold = config.THREE_SEGMENTS_PERCENTS.low
            high_threshold = config.THREE_SEGMENTS_PERCENTS.high
        end
        if currentBloodSegments == 4 then
            helpers.PRINT_MSG("4 seg")
            low_threshold = config.FOUR_SEGMENTS_PERCENTS.low
            high_threshold = config.FOUR_SEGMENTS_PERCENTS.high
        end
        if currentBloodSegments == 5 then
            helpers.PRINT_MSG("5 seg")
            low_threshold = config.FIVE_SEGMENTS_PERCENTS.low
            high_threshold = config.FIVE_SEGMENTS_PERCENTS.high
        end
    end

    --low hunger
    if HpPercent <= 100.0 and HpPercent >= low_threshold then
        helpers.PRINT_MSG("CALC RESULT HUNGER = 0")
        hungerHP.currentHungerLvl = 0
    end

    --medium
    if HpPercent < low_threshold and HpPercent >= high_threshold then
        helpers.PRINT_MSG("CALC RESULT HUNGER = 1")
        hungerHP.currentHungerLvl =  1
    end

    --high
    if HpPercent >= 0.0 and HpPercent < high_threshold then
        helpers.PRINT_MSG("CALC RESULT HUNGER = 2")
        hungerHP.currentHungerLvl = 2
    end

end

------------------------------------------------------------
-- ON HP CHANGE
------------------------------------------------------------

function hungerHP.ON_BLOOD_BAR_SETTING()
    if not helpers.IS_VALID(hungerHP.player) then return end
    if not helpers.isVampire then return end --player is human
    if not config.customHungerHPThreshold then return end --if vanilla hunger then do nothing

    helpers.PRINT_MSG("ON BLOOD BAR SETTING")

    --here start changes to the hunger lvl
    helpers.FIND_HUNGER_SYS()
    hungerHP.CALC_HUNGER_FROM_HP()
   
    helpers.PRINT_MSG(string.format("CURRENT HUNGER %d", hungerHP.currentHungerLvl))

    pcall(function() hungerHP.CHANGE_HUNGER_LVL()
    end)

end

return hungerHP


------------------------------------------------------------
-- MY TRASH NOTES
------------------------------------------------------------
--BloodBarComponent /Game/Map_Blockout_Valley/Blockout_Valley.Blockout_Valley:PersistentLevel.BP_PlayerState_C_2147479961.Blood Bar
--Function /Script/DogwoodStats.BloodBarComponent:GetBlood
--Function /Script/DogwoodStats.BloodBarComponent:GetSegmentCount
--Function /Script/DogwoodStats.BloodBarComponent:GetSingleSegmentBloodAmount (int index)