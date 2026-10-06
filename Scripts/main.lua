--[[
    Dangerous Vampiric Urges v0.6
	Mod changes how 'give in to hunger' dialogue option is presented on screen. For example you can set it, to replace random dialogue option (like in prologue).
	Currently displaying is based on hunger lvl. If some other hunger system(mod) is supposed to work with this, then it needs to change game's hunger lvl. Any other external systems won't change dialogue. 
	Doesn't (and shouldn't) affect any other game functionality.
	Should be compatible with everything that doesn't touch/replace variables in "VampireUrgeSpecialDialogueChoice" and VampireHungerSubsystem.
--]]

UEHelpers = require("UEHelpers")
helpers = require("helperFunc")
config = require("config")
dialogue = require("dialogueChange")
hungerHP = require("hungerSystemHP")


player = nil


------------------------------------------------------------
-- RUN THIS ONCE PER TICK
------------------------------------------------------------

local function RUN_ONCE_PER_TICK()
    --find player if not valid
        if not helpers.IS_VALID(player) then
            player = helpers.FIND_PLAYER()
            hungerHP.player = player
            if helpers.IS_VALID(player) then
                helpers.PRINT_MSG("Found player in tick")
                helpers.CHECK_VAMPIRE(player)

        else helpers.PRINT_MSG("PLAYER NOT FOUND...") return end
        end

end

------------------------------------------------------------
-- DEBUG BUTTONS
------------------------------------------------------------

local function DEBUG_BUTTONS()
    if not config.debug then return end

    pcall(function() 
    --% hp setter
    RegisterKeyBind(Key.B, function()

        ExecuteInGameThread(function() 
            if not helpers.IS_VALID(player) then return end

            if not helpers.IS_VALID(player.BloodBar) then return end

            TargetBloodPercent = 0.10   -- 1.0 = 100%

            local SetOK, SetErr = pcall(function()
                player.BloodBar:SetBloodPercent(TargetBloodPercent)
                hungerHP.ON_BLOOD_BAR_SETTING()
            end)

        end)

    end)
    
    end)

    pcall(function() 
    --set hunger to high
    RegisterKeyBind(Key.L, function()
        ExecuteInGameThread(function() 
            if not helpers.IS_VALID(player) then return end

            pcall(function()
                --helpers.PRINT_MSG("FORCE SETTING HUNGER TO HIGH")
                
                
                if not helpers.IS_VALID(player) then return end
               TargetBloodPercent = 0.50   -- 1.0 = 100%

            local SetOK, SetErr = pcall(function()
                player.BloodBar:SetBloodPercent(TargetBloodPercent)
                hungerHP.ON_BLOOD_BAR_SETTING()
            end)


            end)

        end)
    end)
        
    end)

    pcall(function() 
    --set hunger to low
    RegisterKeyBind(Key.P, function()
        ExecuteInGameThread(function() 
            if not helpers.IS_VALID(player) then return end
            
            pcall(function()
               TargetBloodPercent = 1.0   -- 1.0 = 100%

            local SetOK, SetErr = pcall(function()
                player.BloodBar:SetBloodPercent(TargetBloodPercent)
                hungerHP.ON_BLOOD_BAR_SETTING()
            end)
               

            end)

        end)
    end)
        
    end)
    

end

------------------------------------------------------------
-- SETUP
------------------------------------------------------------
local function SETUP()

    --debug
    DEBUG_BUTTONS()

    --hooks for needed functionality
    pcall(function()
        RegisterHook("/Game/_Dawnwalker/Player/BP_PlayerCharacter.BP_PlayerCharacter_C:On Night Started", function() helpers.PRINT_MSG("ON NIGHT STARTED") 
            helpers.CHECK_VAMPIRE(player)
            
         end)
    end)

    pcall(function()
        RegisterHook("/Game/_Dawnwalker/Player/BP_PlayerCharacter.BP_PlayerCharacter_C:On Day Started", function() helpers.PRINT_MSG("ON DAY STARTED")
            helpers.CHECK_VAMPIRE(player)
            --if changing hunger then disable hunger vfx
            if config.customHungerHPThreshold then
                pcall(function() 
                        if not helpers.IS_VALID(hungerHP.GA_hunger) then
                            hungerHP.GA_hunger = FindFirstOf("GA_VampireHunger_C")
                        end
                        if helpers.IS_VALID(hungerHP.GA_hunger) then
                            helpers.PRINT_MSG("Day started: disable hunger vfx")
                            local hungerLVLChanged = hungerHP.GA_hunger["On Hunger Level Changed"]
                            hungerLVLChanged(hungerHP.GA_hunger, 0)
                        end
                end)
            end

        end)
    end)

    --dialogue changing
    if config.isChangingDialogue then
        helpers.PRINT_MSG("CHANGING DIALOGUES ENABLED")
        pcall(function()
            RegisterHook("/Script/Dawnwalker.DawnwalkerPlayerCharacter:CallOnCinematicModeStarted", function() helpers.PRINT_MSG("DIALOGUE STARTED") dialogue.DIALOGUE_STARTED() end)
        end)
        
        pcall(function()
            RegisterHook("/Script/Dawnwalker.DawnwalkerPlayerCharacter:CallOnCinematicModeEnded", function() helpers.PRINT_MSG("DIALOGUE ENDED") dialogue.DIALOGUE_ENDED() end)
        end)
    end

    -- only when custom hp % threshold for hunger
    if config.customHungerHPThreshold then
        helpers.PRINT_MSG("CUSTOM HUNGER LVL:HP ENABLED")
        -- this fires AFTER setting bloodbar
        --this is called by /Script/DogwoodVampireHunger.VampireHungerSubsystem:OnBloodValueChanged
        pcall(function()
            RegisterHook("/Script/Dawnwalker.DawnwalkerPlayerCharacter:OnVampireHungerLevelChanged", function(self, hung) helpers.PRINT_MSG("DawnwalkerPlayerCharacter:OnVampireHungerLevelChanged pre")
                helpers.PRINT_MSG(hung:get())
                if not helpers.isVampire then return end --player is human
                hung:set(hungerHP.currentHungerLvl) --replace games hunger with current, but kind doesn't do anything?
            end, 
            function()
                helpers.PRINT_MSG("DawnwalkerPlayerCharacter:OnVampireHungerLevelChanged post")
            end)
        end)

        pcall(function()
            RegisterHook("/Script/DogwoodVampireHunger.VampireHungerSubsystem:OnBloodValueChanged", function() helpers.PRINT_MSG("ON BLOOD PRE") end, function() helpers.PRINT_MSG("ON BLOOD POST") hungerHP.ON_BLOOD_BAR_SETTING() end)
        end)
        
        --this sets hunger vfx and audio to hunger lvl
        pcall(function()
            RegisterHook("/Game/_Dawnwalker/Player/VampireHunger/GA_VampireHunger.GA_VampireHunger_C:Calculate Valid Hunger Effects", 
            function(context, hungA, hungB) 
                helpers.PRINT_MSG("GA_hunger: pre vfx calculate")
                hungerHP.DEAL_WITH_HUNGER_VISUALS(hungA, hungB)
            end,
            function() return end)
        end)
    end


    --NEVER AGAIN STUPID BP'S
    local debugBP = false
    if debugBP then
        --WHY??????????..................
        pcall(function() RegisterHook("/Game/_Dawnwalker/Player/VampireHunger/GA_VampireHunger.GA_VampireHunger_C:ExecuteUbergraph_GA_VampireHunger", function(self, EntryPoint)
        -- This fires for EVERY event inside this blueprint.
        print("Ubergraph triggered at ID: " .. tostring(EntryPoint:get()))
        --3137
        --3707 mine?
        --2481
        --2354 from game high?
        if EntryPoint:get() == 2354 then
            helpers.PRINT_MSG("GA_hunger 2354 caught via Ubergraph")
        end

        if EntryPoint:get() == 3707 then
            helpers.PRINT_MSG("GA_hunger 3707 caught via Ubergraph")
        end
        end, function() return end) end)
    end

end

------------------------------------------------------------
-- TICK
------------------------------------------------------------

function TICK()
    local Success, ErrorMessage = pcall(RUN_ONCE_PER_TICK)
    if not Success then
        helpers.PRINT_MSG("TICK ERROR | " .. tostring(ErrorMessage))
    end
    tickHandle = MakeActionHandle()
    ExecuteInGameThreadWithDelay(tickHandle, config.tickMs, TICK)
end

------------------------------------------------------------
-- MAIN = mod starting
------------------------------------------------------------
print("[Dangerous Vampiric Urges] Mod loaded")

helpers.PRINT_MSG(string.format(
    "Tick=%dms | Debug=%s",
    config.tickMs,
    tostring(config.debug)
))
------------------------------------------------------------
-- RESET AT RELOAD
------------------------------------------------------------
tickHandle = nil
pcall(function()
    RegisterHook("/Script/Engine.PlayerController:ClientRestart", function()
        --reset mod
        helpers.PRINT_MSG("RESETING MOD")
        player = nil
        helpers.isVampire = false
        dialogue.inDialogue = false
        helpers.hungerSystem = nil
        hungerHP.currentHungerLvl = 0
        hungerHP.GA_hunger = nil
        hungerHP.player = nil

        --main menu is back
        if helpers.IS_MAIN_MENU_PRESENT() and tickHandle ~= nil then    
            --stop ticking
            helpers.PRINT_MSG("CANCELING TICK")
            local success = CancelDelayedAction(tickHandle)
            tickHandle = nil
            --if canceled tick then wait for going back to game
            local isGameReady = false
            local failsafe = 0

            LoopAsync(1000, function()                
                ExecuteInGameThread(function()
                    if isGameReady then return end
                    failsafe = failsafe + 1
                    local controller = UEHelpers.GetPlayerController()
                    if helpers.IS_VALID(controller) and helpers.IS_VALID(controller.Pawn) and helpers.IS_PLAYER_PAWN(controller.Pawn) then
                        isGameReady = true
                        helpers.PRINT_MSG("Game ready")
                        -- one-time setup here
                        player = controller.Pawn
                        hungerHP.player = player
                        helpers.CHECK_VAMPIRE(player)
                        -- start mod/tick 
                        tickHandle = MakeActionHandle()
                        ExecuteInGameThreadWithDelay(tickHandle, 3000, TICK)
                    elseif failsafe > 60 then
                        helpers.PRINT_MSG("timeout, waiting for leaving main menu")
                        if not helpers.IS_MAIN_MENU_PRESENT() then
                            isGameReady = true
                            -- one-time setup here
                            --start mod/tick on timeout and leaving main menu
                            tickHandle = MakeActionHandle()
                            ExecuteInGameThreadWithDelay(tickHandle, 3000, TICK)
                            helpers.PRINT_MSG("Game ready - timeout, waited for leaving main menu")
                        end
                    end
                end)
                return false
            end)

        end

    end)
end)


--wait for game to be ready = loaded etc.
local isGameReady = false
local failsafe = 0

LoopAsync(1000, function()                
    ExecuteInGameThread(function()
        if isGameReady then return end
        failsafe = failsafe + 1
        local controller = UEHelpers.GetPlayerController()
        if helpers.IS_VALID(controller) and helpers.IS_VALID(controller.Pawn) and helpers.IS_PLAYER_PAWN(controller.Pawn) then
            isGameReady = true
            helpers.PRINT_MSG("Game ready")
            -- one-time setup here
            player = controller.Pawn
            hungerHP.player = player
            helpers.CHECK_VAMPIRE(player)
            SETUP()
            -- start mod/tick 
            tickHandle = MakeActionHandle()
            ExecuteInGameThreadWithDelay(tickHandle, 3000, TICK)
        elseif failsafe > 60 then
            helpers.PRINT_MSG("timeout, waiting for leaving main menu")
            if not helpers.IS_MAIN_MENU_PRESENT() then
                isGameReady = true
                SETUP()
                -- one-time setup here
                --start mod/tick on timeout and leaving main menu
                tickHandle = MakeActionHandle()
                ExecuteInGameThreadWithDelay(tickHandle, 3000, TICK)
                helpers.PRINT_MSG("Game ready - timeout, waited for leaving main menu")
            end
        end
    end)
    return false
end)


------------------------------------------------------------
-- MY TRASH NOTES
------------------------------------------------------------
--Function /Script/Dawnwalker.DrinkBloodSubsystem:TriggerBloodDrinkingInteraction
--Function /Script/Dawnwalker.DawnwalkerPlayerCharacter:OnDrinkBloodSubsystemBloodDrinkingStopped
--Function /Script/Dawnwalker.DawnwalkerPlayerCharacter:OnDrinkBloodSubsystemBloodDrinkingStarted