--[[
    Dangerous Vampiric Urges v0.6.2
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
customHungerSystem = require("customHungerWithBar")


player = nil
isInCombat = false

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
            --safety sometime this is needed
            
            if config.customHungerSystem then
                customHungerSystem.LOAD_HUNGER_BAR_ASSET()
                customHungerSystem.SPAWN_HUNGER_BAR()
                customHungerSystem.ON_HUD()
                customHungerSystem.INIT_HUNGER_BAR(player)
            end

        else helpers.PRINT_MSG("PLAYER NOT FOUND...") return end
    end 
    
    


    if config.customHungerSystem and helpers.IS_VALID(player) then
        customHungerSystem.INIT_HUNGER_BAR(player)
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
               

                helpers.PRINT_MSG("BUTTON?")
                
                    player.BloodBar:SetBloodPercent(TargetBloodPercent)
                    hungerHP.ON_BLOOD_BAR_SETTING()

            end)

            helpers.PRINT_MSG(SetOK)
            helpers.PRINT_MSG(SetErr)
               

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
            
            
            --init hunger bar
            if config.customHungerSystem then
                customHungerSystem.INIT_HUNGER_BAR(player)

            end
            
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
        --pcall(function()
        --    RegisterHook("/Script/Dawnwalker.DawnwalkerPlayerCharacter:CallOnCinematicModeStarted", function() helpers.PRINT_MSG("DIALOGUE STARTED") dialogue.DIALOGUE_STARTED() end)
        --end)
        
        pcall(function()
            RegisterHook("/Script/Dawnwalker.DawnwalkerPlayerCharacter:CallOnCinematicModeEnded", function() helpers.PRINT_MSG("DIALOGUE ENDED") dialogue.DIALOGUE_ENDED() end)
        end)

        pcall(function()
            RegisterHook("/Script/DogwoodUI.CinematicDialogueChoiceLineWidget:SetupChoice", function() helpers.PRINT_MSG("DIALOGUE CHOICE SAFETY") dialogue.DIALOGUE_STARTED() end)
        end)

        pcall(function()
            RegisterHook("/Script/DogwoodUI.CinematicDialogueChoiceWidget:ShowChoices", function() helpers.PRINT_MSG("DIALOGUE CHOICE COUNTER RESET") dialogue.ON_RESET() end)
        end)
--Function /Script/DogwoodUI.CinematicDialogueChoiceWidget:ShowChoices here reset counter
    end

    -- only when custom hp % threshold for hunger OR custom hunger
    if config.customHungerHPThreshold or config.customHungerSystem then
        helpers.PRINT_MSG("CUSTOM HUNGER LVL:HP OR CUSTOM HUNGER ENABLED")
        -- this fires AFTER setting bloodbar
        --this is called by /Script/DogwoodVampireHunger.VampireHungerSubsystem:OnBloodValueChanged
        pcall(function()
            RegisterHook("/Script/Dawnwalker.DawnwalkerPlayerCharacter:OnVampireHungerLevelChanged", function(self, hung) helpers.PRINT_MSG("DawnwalkerPlayerCharacter:OnVampireHungerLevelChanged pre")
                
                helpers.PRINT_MSG(hung:get())
                if not helpers.isVampire then return end --player is human
                
                --hunger custom HP
                if config.customHungerHPThreshold then
                    hung:set(hungerHP.currentHungerLvl) --replace games hunger with current, but kind doesn't do anything?
                end
            
            end, 
            function()
                helpers.PRINT_MSG("DawnwalkerPlayerCharacter:OnVampireHungerLevelChanged post")


 


            end)
        end)

        
       
        pcall(function()
            RegisterHook("/Script/DogwoodVampireHunger.VampireHungerSubsystem:OnBloodValueChanged", function() return end, function() helpers.PRINT_MSG("ON BLOOD POST") 
                
                if config.customHungerHPThreshold then
                    hungerHP.ON_BLOOD_BAR_SETTING() 
                end


                --init hunger bar
                if config.customHungerSystem then
                    
                    --init if hunger was set
                    customHungerSystem.INIT_HUNGER_BAR(player)




                end


            end)
        end)
        
        --this sets hunger vfx and audio to hunger lvl
        pcall(function()
            RegisterHook("/Game/_Dawnwalker/Player/VampireHunger/GA_VampireHunger.GA_VampireHunger_C:Calculate Valid Hunger Effects", 
            function(context, hungA, hungB) 

                if config.customHungerHPThreshold then
                    helpers.PRINT_MSG("GA_hunger: pre vfx calculate")
                    hungerHP.DEAL_WITH_HUNGER_VISUALS(hungA, hungB)
                end

            end,
            function() return end)
        end)


        if config.customHungerSystem then
        --all things replenishing blood
        pcall(function() --this fires when drinking outside combat(with holding button)
            RegisterHook("/Script/Dawnwalker.DrinkBloodFocusAbility:TickDrinking", function() return end, function() helpers.PRINT_MSG("BLOOD TICK") 
                
                customHunger.TICK_BLOOD()

            end)
        end)


        pcall(function() --drinking overall returns victim
            RegisterHook("/Script/Dawnwalker.DrinkBloodSubsystem:NotifyBloodDrinkingStarted", function() return end, function() helpers.PRINT_MSG("BLOOD DRINK STARTED") 
                
                --if in combat then drinking = voracius bite
                if isInCombat then
                    helpers.PRINT_MSG("COMBAT DRINKING")
                    --just start some tick loop until it ends 
                else
                    helpers.PRINT_MSG("OUTSIDE COMBAT DRINKING") 
                end


            end)
        end)

        pcall(function() --drinking overall returns victim
            RegisterHook("/Script/Dawnwalker.DrinkBloodSubsystem:NotifyBloodDrinkingStopped", function() return end, function() helpers.PRINT_MSG("BLOOD DRINK ENDED") 
                
                --if loop drink active then stop

            end)
        end)

        pcall(function() --combat start
            RegisterHook("/Script/DogwoodCombat.PlayerCombatComponent:OnCombatStarted", function() return end, function() helpers.PRINT_MSG("COMBAT STARTED") 
                isInCombat = true

            end)
        end)

        pcall(function() --combat end
            RegisterHook("/Script/DogwoodCombat.PlayerCombatComponent:OnCombatEnded", function() return end, function() helpers.PRINT_MSG("COMBAT ENDED") 
                isInCombat = false

            end)
        end)

        pcall(function() --drinking in dialogue ended (only works for [give in to the hunger])
            RegisterHook("/Script/Dawnwalker.QuestBlockSystemImpl:OnBloodDrinkingStopped", function() return end, function() helpers.PRINT_MSG("DIALOGUE DRINKING ENDED") 
                

            end)
        end)

        pcall(function() --drinking in dialogue started - this doesnt work
            RegisterHook("/Script/Dawnwalker.QuestBlockSystemImpl:OnBloodDrinkingStarted", function() return end, function() helpers.PRINT_MSG("DIALOGUE DRINKING STARTED") 
                

            end)
        end)



        end


--Function /Script/Dawnwalker.DrinkBloodSubsystem:OnDrinkingInProgress
--Function /Script/Dawnwalker.DrinkBloodSubsystem:NotifyBloodDrinkingStopped

--Function /Script/DogwoodStats.BloodBarComponent:RestoreAmount
--Function /Script/DogwoodStats.BloodBarComponent:RestorePercentage
--Function /Script/DogwoodCombat.CombatFocusComponent:GetOverallPlannedHealthOrBloodCost

--Function /Script/DogwoodCombat.CombatFocusComponent:GetOverallPlannedHealthOrBloodCost
--Function /Script/Dawnwalker.QuestBlockSystemImpl:OnBloodDrinkingStopped
--Function /Script/Dawnwalker.QuestConditionHostileActionType_Controller:OnBloodDrinking
    end

end
--Function /Script/Dawnwalker.QuestBlockSystemImpl:OnBloodDrinkingStarted this no idea?
--Function /Script/Dawnwalker.QuestBlockSystemImpl:OnBloodDrinkingStopped this works for dialogue
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
        dialogue.ON_RESET()
        helpers.hungerSystem = nil
        hungerHP.currentHungerLvl = 0
        hungerHP.GA_hunger = nil
        hungerHP.player = nil
        isInCombat = false

        if config.customHungerSystem then
            customHungerSystem.REMOVE_FROM_VIEWPORT()
            customHunger.currentHungerAmount = 0
            customHunger.maxHungerAmount = 0
        end

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



--hunger bar add to UI
if config.customHungerSystem then
        --hunger bar UI
        NotifyOnNewObject("/Game/_Dawnwalker/UI/_Unified/HUD/WBP_GameHUD.WBP_GameHUD_C", function(hud)
        ExecuteInGameThread(function()
            helpers.PRINT_MSG("Init hunger widget starting")
            --init widget stuff
            customHungerSystem.LOAD_HUNGER_BAR_ASSET()
            customHungerSystem.SPAWN_HUNGER_BAR()
            customHungerSystem.ON_HUD()

             if helpers.IS_VALID(player) then
                customHungerSystem.INIT_HUNGER_BAR(player)
            end
            
        end)
        end)


end


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
