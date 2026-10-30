--[[
    Dangerous Vampiric Urges
--]]

UEHelpers = require("UEHelpers")
helpers = require("helperFunc")
config = require("config")
dialogue = require("dialogueChange")
hungerHP = require("hungerSystemHP")
customHungerSystem = require("customHungerWithBar")


player = nil
isInCombat = false

-- if bored can do bools for every function hook and unhook when hook not needed
--hooks (for setting change = no double hooks)
hookForHUDCreation = false
buttonsDone = false
noRequirementsHooks = false
dialogueHooks = false
hungerLVLChangeHooks = false
drinkingBloodHooks = false

------------------------------------------------------------
-- RUN THIS ONCE PER TICK REMOVE?
------------------------------------------------------------

local function RUN_ONCE_PER_TICK()
   

end
------------------------------------------------------------
-- this is initial setup that requires game to be fully loaded
------------------------------------------------------------
local function WAIT_FOR_INIT_SETUP()
    local failsafe = 0
    local initCustomHunger = false
    local initPlayer = helpers.IS_VALID(player)
    LoopAsync(1000, function()
        if initPlayer and initCustomHunger then return true end -- stop this loop
        if failsafe > 1000 then
            print("[Dangerous Vampiric Urges] Init took too long and failed")
            return true
        end --stop loop if goes too long

        ExecuteInGameThread(function()

            if initPlayer and initCustomHunger then helpers.PRINT_MSG("INIT LOOP DONE") return end -- if done then stop
            failsafe = failsafe + 1


            --player is missing
            if not initPlayer then
                player = helpers.FIND_PLAYER()
                if helpers.IS_VALID(player) then
                    hungerHP.player = player
                    initPlayer = true
                end
            end


            -- init custom hunger system
            if not initCustomHunger and helpers.IS_VALID(player) and config.customHungerSystem  then
                initCustomHunger = customHunger.INIT_SETUP(player)
            end
    

            if failsafe > 1000 then return end --stop loop if goes too long and failed
    
    
    end)

        return false
    end)
end

------------------------------------------------------------
-- DEBUG BUTTONS
------------------------------------------------------------

local function DEBUG_BUTTONS()
    if not config.debug then return end
    if buttonsDone then return end

    pcall(function() 
    --% hp setter
    RegisterKeyBind(Key.B, function()

        ExecuteInGameThread(function() 
            if not helpers.IS_VALID(player) then return end

            if not helpers.IS_VALID(player.BloodBar) then return end

            TargetBloodPercent = 0.30   -- 1.0 = 100%

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
               
                --find some normal size for widget
                    customHunger.hungerBarWidget:ChangeScale(32,120)

                   -- player.BloodBar:SetBloodPercent(TargetBloodPercent)
                   -- hungerHP.ON_BLOOD_BAR_SETTING()

            end)

            helpers.PRINT_MSG(SetOK)
            helpers.PRINT_MSG(SetErr)
               

            end)

        end)
    end)
        
    end)



    buttonsDone = true
end

------------------------------------------------------------
-- SETUP HERE ARE HOOKS AND BUTTONS
------------------------------------------------------------
local function SETUP()

    --debug
    DEBUG_BUTTONS()
    
--hunger bar add to UI (IF MOD CHANGED SETTINGS)
    if config.customHungerSystem and not hookForHUDCreation then
        hookForHUDCreation = true
        --hunger bar UI
            NotifyOnNewObject("/Game/_Dawnwalker/UI/_Unified/HUD/WBP_GameHUD.WBP_GameHUD_C", function(hud)
                if not config.customHungerSystem then return end

            ExecuteInGameThread(function()
                helpers.PRINT_MSG("Init hunger widget starting")
                if customHunger.TRY_FIND_WIDGET() == true then  --found widget already
                    if helpers.IS_VALID(player) then
                        customHungerSystem.INIT_HUNGER_BAR(player)
                    end
                    return
                end

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



    if not noRequirementsHooks then
        helpers.PRINT_MSG("BASIC FUNCIONALITY HOOKING")
    --hooks for basic functionality
    pcall(function()
        RegisterHook("/Script/Dawnwalker.AudioCharacterEnvironmentComponent:OnPlayerFormChanged", function(obj, newForm) helpers.PRINT_MSG("ON PLAYER FORM CHANGED")
            --form 0 = human, 1 = vampire    
            helpers.CHECK_VAMPIRE(player)


                --changed into vampire
                if newForm:get() == 1 then




                    --init hunger bar with custom value, when night starts
                    if config.customHungerSystem then
                        customHunger.HUNGER_BAR_ON_NIGHT_START(player)
                    end



                else 
                --changed into human

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


                end

                

            end)
        end)


        noRequirementsHooks = true

    end


    --dialogue changing
    if config.isChangingDialogue and not dialogueHooks then
        helpers.PRINT_MSG("CHANGING DIALOGUES ENABLED")
        
        pcall(function()
            RegisterHook("/Script/Dawnwalker.DawnwalkerPlayerCharacter:CallOnCinematicModeEnded", function() helpers.PRINT_MSG("DIALOGUE ENDED") dialogue.DIALOGUE_ENDED()
            end)
        end)

        pcall(function()
            RegisterHook("/Script/DogwoodUI.CinematicDialogueChoiceLineWidget:SetupChoice", function() helpers.PRINT_MSG("DIALOGUE CHOICES START") dialogue.DIALOGUE_STARTED()
                     end)
        end)

        pcall(function()
            RegisterHook("/Script/DogwoodUI.CinematicDialogueChoiceWidget:ShowChoices", function() helpers.PRINT_MSG("DIALOGUE CHOICE COUNTER RESET") dialogue.ON_RESET()
                 end)
        end)


        dialogueHooks = true

    end

    -- only when custom hp % threshold for hunger OR custom hunger
    if config.customHungerHPThreshold or config.customHungerSystem then
        if not hungerLVLChangeHooks then

        helpers.PRINT_MSG("CUSTOM HUNGER LVL:HP OR CUSTOM HUNGER ENABLED")
        -- this fires AFTER setting bloodbar
        --this is called by /Script/DogwoodVampireHunger.VampireHungerSubsystem:OnBloodValueChanged
        pcall(function()
            RegisterHook("/Script/Dawnwalker.DawnwalkerPlayerCharacter:OnVampireHungerLevelChanged", function(self, hung) helpers.PRINT_MSG("DawnwalkerPlayerCharacter:OnVampireHungerLevelChanged pre")
                if not config.customHungerHPThreshold and not config.customHungerSystem then return end

                helpers.PRINT_MSG(hung:get())
                if not helpers.isVampire then return end --player is human
                
                --hunger custom HP
                if config.customHungerHPThreshold then
                    hung:set(hungerHP.currentHungerLvl) --replace games hunger with current, but kind doesn't do anything? = doing it for safety
                end
            
            end, 
            function() helpers.PRINT_MSG("TO REMOVE NO WORRIES: DawnwalkerPlayerCharacter:OnVampireHungerLevelChanged post") end)
        end)

        
       --basicaly fires when vampire hp changed
        pcall(function()
            RegisterHook("/Script/DogwoodVampireHunger.VampireHungerSubsystem:OnBloodValueChanged", function() return end, function() 
                if not config.customHungerHPThreshold and not config.customHungerSystem then return end
                --helpers.PRINT_MSG("ON BLOOD POST") 
                
                if config.customHungerHPThreshold then
                    hungerHP.ON_BLOOD_BAR_SETTING() 
                end


                --init hunger bar
                if config.customHungerSystem then
                    
                    --init if hunger was set
                    --customHungerSystem.INIT_HUNGER_BAR(player)




                end


            end)
        end)
        
        --this sets hunger vfx and audio to hunger lvl
        pcall(function()
            RegisterHook("/Game/_Dawnwalker/Player/VampireHunger/GA_VampireHunger.GA_VampireHunger_C:Calculate Valid Hunger Effects", 
            function(context, hungA, hungB) 
                if not config.customHungerHPThreshold and not config.customHungerSystem then return end
                if config.customHungerHPThreshold then
                    helpers.PRINT_MSG("GA_hunger: pre vfx calculate")
                    hungerHP.DEAL_WITH_HUNGER_VISUALS(hungA, hungB)
                end

            end,
            function() return end)
        end)

        hungerLVLChangeHooks = true

    end

        if config.customHungerSystem and not drinkingBloodHooks then
             helpers.PRINT_MSG("CUSTOM HUNGER SYSTEM ENABLED")

        --all things with blood drinking
            pcall(function() --this fires when drinking outside combat(with holding button)
                RegisterHook("/Script/Dawnwalker.DrinkBloodFocusAbility:TickDrinking", function() return end, function() helpers.PRINT_MSG("BLOOD TICK") 
                    if not config.customHungerSystem then return end
                    customHunger.TICK_BLOOD()

                end)
            end)
--Function /Script/Dawnwalker.DrinkBloodFocusAbility:StartDrinking
--Function /Script/Dawnwalker.DrinkBloodFocusAbility:FinishDrinking

--GA_DrinkBlood?

            --if not using then remove, but usseless probably
            pcall(function() --drinking returns victim (doesn't fire when holding button drinking?)
                RegisterHook("/Script/Dawnwalker.DrinkBloodSubsystem:NotifyBloodDrinkingStarted", function() return end, function() helpers.PRINT_MSG("BLOOD DRINK STARTED") 
                    if not config.customHungerSystem then return end
                    --if in combat then drinking = voracius bite
                    if isInCombat then
                        helpers.PRINT_MSG("COMBAT DRINKING")
                        --just start some tick loop until it ends
                        --customHunger.START_STOP_LOOP_BLOOD(true)
                    else -- this never happens?
                        helpers.PRINT_MSG("OUTSIDE COMBAT DRINKING")
                        --customHunger.START_STOP_LOOP_BLOOD(true) 
                    end


                end)
            end)

            pcall(function() --drinking returns victim
                RegisterHook("/Script/Dawnwalker.DawnwalkerPlayerCharacter:OnDrinkBloodSubsystemBloodDrinkingStopped", function() 
                    --if loop drink active then stop
                    if not config.customHungerSystem then return end
                    customHunger.START_STOP_LOOP_BLOOD(false)
                    return 
                end,
                function() helpers.PRINT_MSG("BLOOD DRINK ENDED") 
                
                    


                end)
            end)

            --this is not needed
            pcall(function() --combat start
                RegisterHook("/Script/DogwoodCombat.PlayerCombatComponent:OnCombatStarted", function() return end, function() 
                    if not config.customHungerSystem then return end
                    helpers.PRINT_MSG("COMBAT STARTED") 
                    isInCombat = true

                end)
            end)
            --this is not needed
            pcall(function() --combat end
                RegisterHook("/Script/DogwoodCombat.PlayerCombatComponent:OnCombatEnded", function() return end, function()
                    if not config.customHungerSystem then return end
                    helpers.PRINT_MSG("COMBAT ENDED") 
                    isInCombat = false

                end)
            end)

            pcall(function() --drinking in dialogue ended (only works for [give in to the hunger], and outside combat too?)
                RegisterHook("/Script/Dawnwalker.QuestBlockSystemImpl:OnBloodDrinkingStopped", function() return end, function()
                    if not config.customHungerSystem then return end
                     helpers.PRINT_MSG("DIALOGUE DRINKING ENDED") 
                        --add some blood to bar(no tick), if no drinking with holding 
                        customHunger.APPLY_INSTANT_BLOOD()
                end)
            end)

            --GA_ShadowstepBite_C = voracius bite - this is hidden in BP...
            pcall(function()
                RegisterHook("/Game/_Dawnwalker/Combat/Focus/Vampire/ShadowstepBite/GA_ShadowstepBite.GA_ShadowstepBite_C:ExecuteUbergraph_GA_ShadowstepBite", function(self, EntryPoint)
                    if not config.customHungerSystem then return end
                    local ID = EntryPoint:get()
                    if ID == 1584 then --/Game/_Dawnwalker/Combat/Focus/Vampire/ShadowstepBite/GA_ShadowstepBite.GA_ShadowstepBite_C:OnBloodDrinkingStarted
                        helpers.PRINT_MSG("VORACIOUS BITE: BLOOD START")
                        customHunger.START_STOP_LOOP_BLOOD(true)
                    end

                    if ID == 1248 then --/Game/_Dawnwalker/Combat/Focus/Vampire/ShadowstepBite/GA_ShadowstepBite.GA_ShadowstepBite_C:OnBloodDrinkingEnded
                        helpers.PRINT_MSG("VORACIOUS BITE: BLOOD END")
                         customHunger.START_STOP_LOOP_BLOOD(false)
                    end
                    
                end)
            end)


            drinkingBloodHooks = true

        end

--GA_FocusDrinkBlood
--GE_BloodDrinking
--GE_BloodDrinkOpenWorldRegen
--GE_BloodDrinkOpenWorldRegen_WithDuration

--Function /Script/DogwoodCombat.CombatFocusVampireAbility:GetBloodDrinkValueToHeal
--Function /Script/DogwoodFocus.FocusAbilityBase:GetHealthCost
--Function /Script/DogwoodFocus.FocusAbilityBase:GetHealthPercentageCost
--Function /Script/DogwoodCombat.CombatComponentBase:UnlockHealth



--still need to find for when dialogue is drinking (ambrus?)
-- another thing items

--Function /Script/Dawnwalker.DrinkBloodSubsystem:TriggerBloodDrinkingInteraction

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
-- TICK REMOVE?
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

config.applyConfig()

-- This receives saved changes for settings
--values.setting this is current value for setting
--changes.setting.old this is old value for changed setting
-- if bored can do bools for every function hook and unhook when hook not needed
local API = require("dmm_api")
local ok, unsubscribe = pcall(API.subscribe, "DangerousVampiricUrges", function(values, changes)
    config.applyConfig()

    helpers.PRINT_MSG("CONFIG CHANGED")

    --only setup when hooking is needed
    if (changes.CustomHungerHPThreshold and changes.CustomHungerHPThreshold.old ~= values.CustomHungerHPThreshold)
    or (changes.ChangingDialogue and changes.ChangingDialogue.old ~= values.ChangingDialogue) then
         SETUP()
    end


    --don't setup if changes are in main menu
    if not helpers.IS_MAIN_MENU_PRESENT() then
        -- custom hunger hp setting changed
        if (changes.CustomHungerHPThreshold and changes.CustomHungerHPThreshold.old ~= values.CustomHungerHPThreshold)
        or (changes.oneThreshold and changes.oneThreshold.old ~= values.oneThreshold)
        or (changes.twoSegLow and changes.twoSegLow.old ~= values.twoSegLow)
        or (changes.twoSegHigh and changes.twoSegHigh.old ~= values.twoSegHigh)
        or (changes.threeSegLow and changes.threeSegLow.old ~= values.threeSegLow)
        or (changes.threeSegHigh and changes.threeSegHigh.old ~= values.threeSegHigh)
        or (changes.fourSegLow and changes.fourSegLow.old ~= values.fourSegLow)
        or (changes.fourSegHigh and changes.fourSegHigh.old ~= values.fourSegHigh)
        or (changes.fiveSegLow and changes.fiveSegLow.old ~= values.fiveSegLow)
        or (changes.fiveSegHigh and changes.fiveSegHigh.old ~= values.fiveSegHigh) then

            if helpers.IS_VALID(helpers.hungerSystem) then
            --reset hunger lvl
                helpers.PRINT_MSG("RESET HUNGER LVL")
                pcall(function() helpers.hungerSystem:OnBloodValueChanged() end)
            end
        end
    end

end)
if not ok then
    print("[Dangerous Vampiric Urges] Settings callback unavailable: " .. tostring(unsubscribe) .. "\n")
end

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
            customHunger.START_STOP_LOOP_BLOOD(false) 
            customHunger.currentHungerAmount = 0
            customHunger.maxHungerAmount = 0
            customHunger.hungerGAListener = nil
        end

        -- no main menu = reload, game -> game
        if not helpers.IS_MAIN_MENU_PRESENT() then
            WAIT_FOR_INIT_SETUP()
            return
        end

        --main menu is back = reload, game -> main menu
        if helpers.IS_MAIN_MENU_PRESENT() and tickHandle ~= nil then    
            --tick to remove in future if not needed
            --stop ticking
            helpers.PRINT_MSG("CANCELING TICK")
            local success = CancelDelayedAction(tickHandle)
            tickHandle = nil
            --if canceled tick then wait for going back to game
            local isGameReady = false
            local failsafe = 0

            LoopAsync(1000, function()
                if isGameReady then return true end -- stop this loop             
                ExecuteInGameThread(function()
                    if isGameReady then return end
                    failsafe = failsafe + 1
                    local controller = UEHelpers.GetPlayerController()
                    if helpers.IS_VALID(controller) and helpers.IS_VALID(controller.Pawn) and helpers.IS_PLAYER_PAWN(controller.Pawn) then
                        isGameReady = true
                        helpers.PRINT_MSG("Game ready")
                        -- one-time setup here
                        player = controller.Pawn
                        helpers.PRINT_MSG("Game ready player:")
                        helpers.PRINT_MSG(player:GetFullName())
                        hungerHP.player = player
                        SETUP()
                        WAIT_FOR_INIT_SETUP()
                        -- start mod/tick 
                        tickHandle = MakeActionHandle()
                        ExecuteInGameThreadWithDelay(tickHandle, 3000, TICK)
                    elseif failsafe > 60 then
                        helpers.PRINT_MSG("timeout, waiting for leaving main menu")
                        if not helpers.IS_MAIN_MENU_PRESENT() then
                            isGameReady = true
                            SETUP()
                            WAIT_FOR_INIT_SETUP()
                            --in this situation player is found in tick
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
if config.customHungerSystem and not hookForHUDCreation then
    hookForHUDCreation = true
    --hunger bar UI
        NotifyOnNewObject("/Game/_Dawnwalker/UI/_Unified/HUD/WBP_GameHUD.WBP_GameHUD_C", function(hud)
        ExecuteInGameThread(function()
            helpers.PRINT_MSG("Init hunger widget starting")
            if customHunger.TRY_FIND_WIDGET() then  --found widget already
                    if helpers.IS_VALID(player) then
                        customHungerSystem.INIT_HUNGER_BAR(player)
                    end
                    return
            end
            
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
    if isGameReady then return true end -- stop this loop               
    ExecuteInGameThread(function()
        if isGameReady then return end
        failsafe = failsafe + 1
        local controller = UEHelpers.GetPlayerController()
        if helpers.IS_VALID(controller) and helpers.IS_VALID(controller.Pawn) and helpers.IS_PLAYER_PAWN(controller.Pawn) then
            isGameReady = true
            helpers.PRINT_MSG("Game ready")
            -- one-time setup here
            player = controller.Pawn
            helpers.PRINT_MSG("Game ready player:")
            helpers.PRINT_MSG(player:GetFullName())
            hungerHP.player = player
            SETUP()
            WAIT_FOR_INIT_SETUP()
            -- start mod/tick 
            tickHandle = MakeActionHandle()
            ExecuteInGameThreadWithDelay(tickHandle, 3000, TICK)
        elseif failsafe > 60 then
            helpers.PRINT_MSG("timeout, waiting for leaving main menu")
            if not helpers.IS_MAIN_MENU_PRESENT() then
                isGameReady = true
                SETUP()
                WAIT_FOR_INIT_SETUP()
                -- one-time setup here
                --player is found in tick
                --start mod/tick on timeout and leaving main menu
                tickHandle = MakeActionHandle()
                ExecuteInGameThreadWithDelay(tickHandle, 3000, TICK)
                helpers.PRINT_MSG("Game ready - timeout, waited for leaving main menu")
            end
        end
    end)
    return false
end)



