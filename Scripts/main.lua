--[[
    Dangerous Vampiric Urges v1.0
	Mod changes how 'give in to hunger' dialogue option is presented on screen. For example you can set it, to replace random dialogue option (like in prologue).
	Currently displaying is based on vanilla game hunger lvl. If some other hunger system(mod) is supposed to work with this, then it needs to change game's hunger lvl. Any other external systems won't change dialogue. 
	Doesn't (and shouldn't) affect any other game functionality.
	Should be compatible with everything that doesn't touch/replace variables in "VampireUrgeSpecialDialogueChoice".
--]]

UEHelpers = require("UEHelpers")
helpers = require("helperFunc")
config = require("config")
dialogue = require("dialogueChange")

MOD_VARIABLES = {
    player = nil,
    currentHungerLvl = 0
}

--caching this, otherwise game lags during hp regen xD and should do it anyway
GA_hunger = nil

isHungerInit = false

TargetBloodPercent = 0.10   -- 1.0 = 100%

------------------------------------------------------------
-- DEAL WITH HUNGER VFX AND AUDIO
------------------------------------------------------------
local function DEAL_WITH_HUNGER_VISUALS(hungerA, hungerB)
    --replace hunger value which is sent to gameplay ability for vfx setting
    local status, err = pcall(function()
        helpers.PRINT_MSG("SETTING HUNGER VFX to: ")
        helpers.PRINT_MSG(MOD_VARIABLES.currentHungerLvl)
        hungerA:set(MOD_VARIABLES.currentHungerLvl) hungerB:set(MOD_VARIABLES.currentHungerLvl)
    end)
    helpers.PRINT_MSG(status)
    helpers.PRINT_MSG(err)
end

------------------------------------------------------------
-- OVERRIDE HUNGER LEVEL IN GAME (DOESN'T TOUCH DIALOGUE)
------------------------------------------------------------
local function CHANGE_HUNGER_LVL()
    
    helpers.FIND_HUNGER_SYS()

    local prevHunger
    pcall(function()

        if helpers.IS_VALID(helpers.hungerSystem) then
            prevHunger = helpers.hungerSystem.VampireHungerLevel
            helpers.PRINT_MSG(string.format("GAME HUNGER %d", helpers.hungerSystem.VampireHungerLevel))
            --helpers.PRINT_MSG(helpers.hungerSystem.VampireHungerLevel)

            if prevHunger ~= MOD_VARIABLES.currentHungerLvl then -- only change hunger lvl when is different then current
                helpers.hungerSystem.VampireHungerLevel = MOD_VARIABLES.currentHungerLvl
                
                helpers.PRINT_MSG("Hunger lvl ->" .. tostring(MOD_VARIABLES.currentHungerLvl))
                -- vfx stuff
                pcall(function() 
                        if not helpers.IS_VALID(GA_hunger) then
                            GA_hunger = FindFirstOf("GA_VampireHunger_C")
                        end
                        if helpers.IS_VALID(GA_hunger) then
                            local hungerLVLChanged = GA_hunger["On Hunger Level Changed"]
                            hungerLVLChanged(GA_hunger, MOD_VARIABLES.currentHungerLvl)
                        end
                    end)
            else
                helpers.PRINT_MSG("Hunger is the same do nothing - checking vfx")

                --check if vfx is set correctly
                pcall(function() 
                    if not helpers.IS_VALID(GA_hunger) then
                        GA_hunger = FindFirstOf("GA_VampireHunger_C")
                    end
            
                    local hungerGALvl = GA_hunger["Active Hunger Effects"]
                    helpers.PRINT_MSG(string.format("VFX HUNGER %d", hungerGALvl))
                    --helpers.PRINT_MSG(hungerGALvl)
                    if hungerGALvl ~= MOD_VARIABLES.currentHungerLvl then
                        helpers.PRINT_MSG(string.format("MY HUNGER %d", MOD_VARIABLES.currentHungerLvl))
                        --helpers.PRINT_MSG(MOD_VARIABLES.currentHungerLvl)
                        helpers.PRINT_MSG("HUNGER VFX WRONG - CHANGING")
                        local hungerLVLChanged = GA_hunger["On Hunger Level Changed"]
                        hungerLVLChanged(GA_hunger, MOD_VARIABLES.currentHungerLvl)
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
local function GET_CURRENT_HP_PERCENT()
    local HPpercent = -1
    if not helpers.IS_VALID(MOD_VARIABLES.player.BloodBar) or MOD_VARIABLES.player.BloodBar:GetBlood() == 0 then 
        helpers.PRINT_MSG("Blood bar missing when calculating hp percent")
        return HPpercent
    end

    pcall(function()
        helpers.PRINT_MSG(string.format("Current hp: %f", MOD_VARIABLES.player.BloodBar:GetBlood()))
        current = 100 * tonumber(MOD_VARIABLES.player.BloodBar:GetBlood())
        helpers.PRINT_MSG(string.format("Max hp: %f", MOD_VARIABLES.player.BloodBar:GetBloodBarLength()))
        HPpercent = current / tonumber(MOD_VARIABLES.player.BloodBar:GetBloodBarLength())
    end)

    helpers.PRINT_MSG(string.format("HP percent: %f", HPpercent))
    return HPpercent
end

------------------------------------------------------------
-- DETERMINE HUNGER BASED ON HP
------------------------------------------------------------
local function CALC_HUNGER_FROM_HP()
    local HpPercent = GET_CURRENT_HP_PERCENT()
    helpers.PRINT_MSG(HpPercent)
    -- hp % is invalid
    if HpPercent == -1 then
        helpers.PRINT_MSG("INVALID HP PERCENT")
        helpers.FIND_HUNGER_SYS()
        -- return current hunger lvl
        helpers.PRINT_MSG("RETURN CURRENT HUNGER: ")
        helpers.PRINT_MSG(helpers.hungerSystem.VampireHungerLevel)
        MOD_VARIABLES.currentHungerLvl = helpers.hungerSystem.VampireHungerLevel
        return -1
    end

    --low hunger
    if HpPercent <= 100.0 and HpPercent >= 80.0 then
        helpers.PRINT_MSG("CALC RESULT HUNGER = 0")
        MOD_VARIABLES.currentHungerLvl = 0
    end

    --medium
    if HpPercent < 80.0 and HpPercent >= 40.0 then
        helpers.PRINT_MSG("CALC RESULT HUNGER = 1")
        MOD_VARIABLES.currentHungerLvl =  1
    end

    --high
    if HpPercent >= 0.0 and HpPercent < 40.0 then
        helpers.PRINT_MSG("CALC RESULT HUNGER = 2")
        MOD_VARIABLES.currentHungerLvl = 2
    end

end

------------------------------------------------------------
-- ON HP CHANGE
------------------------------------------------------------

local function ON_BLOOD_BAR_SETTING()
    if not helpers.IS_VALID(MOD_VARIABLES.player) then return end
    if not helpers.isVampire then return end --player is human
    if not config.customHungerHPThreshold then return end --if vanilla hunger then do nothing

    helpers.PRINT_MSG("ON BLOOD BAR SETTING")

    --here start changes to the hunger lvl
    helpers.FIND_HUNGER_SYS()
    CALC_HUNGER_FROM_HP()
   
    helpers.PRINT_MSG(string.format("CURRENT HUNGER %d", MOD_VARIABLES.currentHungerLvl))

    pcall(function() CHANGE_HUNGER_LVL()
    end)

end

local function INIT_HUNGER()
    helpers.PRINT_MSG("INIT HUNGER")
    helpers.FIND_HUNGER_SYS()

    if not helpers.IS_VALID(MOD_VARIABLES.player) then helpers:FIND_PLAYER() end

     if not helpers.IS_VALID(MOD_VARIABLES.player.BloodBar) then 
        helpers.PRINT_MSG("Blood bar missing when calculating hp percent")
        return HPpercent
    end

    local ready = false
   -- local a, b = pcall(function()
        --if(MOD_VARIABLES.player.BloodBar:GetBlood() == 0) then 

        --    LoopAsync(1000, function()
        --        if ready then PRINT_MSG("WTF return") return true end
         --       PRINT_MSG("Blood bar still not set - waiting")                
          --      ExecuteInGameThread(function()
         --           if MOD_VARIABLES.player.BloodBar:GetBlood() ~= 0 then
          --              ready = true
         --               PRINT_MSG("Blood bar set - do init")
         --           end
           --         PRINT_MSG("WTF")
         --       end) 
        --       return false
       --     end)

        --end
      --   PRINT_MSG("EXIT?")
  --  end)

    --LoopAsync(1000, function()

        --PRINT_MSG("LOOOOOP")       

        --ExecuteInGameThread(function()
        --    PRINT_MSG("WTF")
        --    if ready then return end
        --    if IS_VALID(MOD_VARIABLES.player.BloodBar) and MOD_VARIABLES.player.BloodBar:GetBlood() ~= 0 then
       --         ready = true
        --        PRINT_MSG("Blood bar set - do init")
       --     end
        --    PRINT_MSG("END THIS SHIT")
       -- end)

      --  return ready
        
  --  end)

    --PRINT_MSG(a)
    --PRINT_MSG(b)

    helpers.PRINT_MSG("HELLO?")

    ON_BLOOD_BAR_SETTING()

    helpers.PRINT_MSG(string.format("CURRENT HUNGER %d", MOD_VARIABLES.currentHungerLvl))

    --check if vfx is set correctly
    pcall(function() 
        if not helpers.IS_VALID(GA_hunger) then
            GA_hunger = FindFirstOf("GA_VampireHunger_C")
        end
            
        local hungerGALvl = GA_hunger["Active Hunger Effects"]
        helpers.PRINT_MSG(hungerGALvl)
        if hungerGALvl ~= MOD_VARIABLES.currentHungerLvl then
            helpers.PRINT_MSG(MOD_VARIABLES.currentHungerLvl)
            helpers.PRINT_MSG("HUNGER VFX WRONG - SET CORRECTLY")
            local hungerLVLChanged = GA_hunger["On Hunger Level Changed"]
            hungerLVLChanged(GA_hunger, MOD_VARIABLES.currentHungerLvl)
        end
    end)

    --isHungerInit = true


end

------------------------------------------------------------
-- RUN THIS ONCE PER TICK
------------------------------------------------------------

local function RUN_ONCE_PER_TICK()
    --find player if not valid
        if not helpers.IS_VALID(MOD_VARIABLES.player) then
            MOD_VARIABLES.player = helpers.FIND_PLAYER()
            if helpers.IS_VALID(MOD_VARIABLES.player) then
                helpers.PRINT_MSG("Found player in tick")
                helpers.CHECK_VAMPIRE(MOD_VARIABLES.player)

                --INIT_HUNGER()
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
            if not helpers.IS_VALID(MOD_VARIABLES.player) then return end

            if not helpers.IS_VALID(MOD_VARIABLES.player.BloodBar) then return end

            TargetBloodPercent = 0.10   -- 1.0 = 100%

            local SetOK, SetErr = pcall(function()
                MOD_VARIABLES.player.BloodBar:SetBloodPercent(TargetBloodPercent)
            end)

        end)

    end)
    
    end)

    pcall(function() 
    --set hunger to high
    RegisterKeyBind(Key.L, function()
        ExecuteInGameThread(function() 
            if not helpers.IS_VALID(MOD_VARIABLES.player) then return end

            pcall(function()
                --helpers.PRINT_MSG("FORCE SETTING HUNGER TO HIGH")
                
                
                if not helpers.IS_VALID(MOD_VARIABLES.player) then return end
                --ON_HUNGER_CHANGED(2)
               TargetBloodPercent = 0.50   -- 1.0 = 100%

            local SetOK, SetErr = pcall(function()
                MOD_VARIABLES.player.BloodBar:SetBloodPercent(TargetBloodPercent)
            end)


            end)

        end)
    end)
        
    end)

    pcall(function() 
    --set hunger to low
    RegisterKeyBind(Key.P, function()
        ExecuteInGameThread(function() 
            if not helpers.IS_VALID(MOD_VARIABLES.player) then return end
            
            pcall(function()
               TargetBloodPercent = 1.0   -- 1.0 = 100%

            local SetOK, SetErr = pcall(function()
                MOD_VARIABLES.player.BloodBar:SetBloodPercent(TargetBloodPercent)
            end)
                
                
                --ON_HUNGER_CHANGED(0)
               

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
        RegisterHook("/Game/_Dawnwalker/Player/BP_PlayerCharacter.BP_PlayerCharacter_C:On Night Started", function() helpers.PRINT_MSG("ON NIGHT STARTED") helpers.CHECK_VAMPIRE(MOD_VARIABLES.player) end)
    end)

    pcall(function()
        RegisterHook("/Game/_Dawnwalker/Player/BP_PlayerCharacter.BP_PlayerCharacter_C:On Day Started", function() helpers.PRINT_MSG("ON DAY STARTED") helpers.CHECK_VAMPIRE(MOD_VARIABLES.player) end)
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
                hung:set(MOD_VARIABLES.currentHungerLvl) --replace games hunger with current, but kind doesn't do anything?
            end, 
            function()
                helpers.PRINT_MSG("DawnwalkerPlayerCharacter:OnVampireHungerLevelChanged post")
            end)
        end)

        --for init hunger
        --pcall(function()
            --RegisterHook("/Script/DogwoodStats.BloodBarComponent:SetBloodPercent", function() PRINT_MSG("BloodBarComponent:SetBloodPercent pre") end, function() PRINT_MSG("BloodBarComponent:SetBloodPercent post") if not isHungerInit then INIT_HUNGER() end end)
        --end)

        --for init hunger
        --pcall(function()
            --RegisterHook("/Script/DogwoodStats.BloodBarComponent:OnOwningStatePawnSet", function() PRINT_MSG("BloodBarComponent:on pawn set pre") end, function() PRINT_MSG("BloodBarComponent:on pawn set ppost") INIT_HUNGER() end)
        --end)

        pcall(function()
            RegisterHook("/Script/DogwoodVampireHunger.VampireHungerSubsystem:OnBloodValueChanged", function() helpers.PRINT_MSG("ON BLOOD PRE") end, function() helpers.PRINT_MSG("ON BLOOD POST") ON_BLOOD_BAR_SETTING() end)
        end)
        
        --this sets hunger vfx and audio to hunger lvl
        pcall(function()
            RegisterHook("/Game/_Dawnwalker/Player/VampireHunger/GA_VampireHunger.GA_VampireHunger_C:Calculate Valid Hunger Effects", 
            function(context, hungA, hungB) 
                --should check if human and set it to no hunger when human?
                helpers.PRINT_MSG("GA_hunger: pre vfx calculate")
                DEAL_WITH_HUNGER_VISUALS(hungA, hungB)
            end,
            function() return end)
        end)
    end

    --NEVER AGAIN STUPID BP'S
    if not config.debug then
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
        MOD_VARIABLES.player = nil
        helpers.isVampire = false
        dialogue.inDialogue = false
        helpers.hungerSystem = nil
        MOD_VARIABLES.currentHungerLvl = 0
        GA_hunger = nil
        isHungerInit = false

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
                        MOD_VARIABLES.player = controller.Pawn
                        helpers.CHECK_VAMPIRE(MOD_VARIABLES.player)
                        --INIT_HUNGER()
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
            MOD_VARIABLES.player = controller.Pawn
            helpers.CHECK_VAMPIRE(MOD_VARIABLES.player)
            SETUP()
            --INIT_HUNGER()
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
--MulticastInlineDelegateProperty /Script/Dawnwalker.DawnwalkerPlayerCharacter:OnBloodChanged
--Function /Script/Dawnwalker.DawnwalkerPlayerCharacter:OnVampireHungerLevelChanged
--DelegateFunction /Script/DogwoodVampireHunger.OnVampireHungerLevelChanged__DelegateSignature
--Function /Script/DogwoodVampireHunger.VampireHungerSubsystem:GetVampireHungerLevel
--Function /Script/Dawnwalker.DawnwalkerPlayerCharacter:OnDrinkBloodSubsystemBloodDrinkingStopped
--Function /Script/Dawnwalker.DawnwalkerPlayerCharacter:OnDrinkBloodSubsystemBloodDrinkingStarted
--DogwoodVampireHungerSettings /Script/DogwoodVampireHunger.Default__DogwoodVampireHungerSettings
--VampireHungerChoiceCondition /Script/Dawnwalker.Default__VampireHungerChoiceCondition
--ScriptStruct /Script/DogwoodVampireHunger.BloodBarVampireHungerSegments

--Function /Script/DogwoodVampireHunger.VampireHungerSubsystem:OnBloodValueChanged


--VampireHungerChoiceCondition /Script/Dawnwalker.Default__VampireHungerChoiceCondition
-- Function /Script/Dawnwalker.DawnwalkerPlayerCharacter:OnVampireHungerLevelChanged
-- Function /Script/Dawnwalker.DawnwalkerPlayerCharacter:IsVampire

--Class /Script/DogwoodVampireHunger.DogwoodVampireHungerSettings
--ObjectProperty /Script/DogwoodVampireHunger.VampireHungerSubsystem:LoadedVampireHungerTable
--/Script/Engine.DataTable'/Game/_Dawnwalker/Player/VampireHunger/VampireHungerDefinitions.VampireHungerDefinitions'


--BloodBarComponent /Game/Map_Blockout_Valley/Blockout_Valley.Blockout_Valley:PersistentLevel.BP_PlayerState_C_2147479961.Blood Bar
--Function /Script/DogwoodStats.BloodBarComponent:GetBlood
--Function /Script/DogwoodStats.BloodBarComponent:GetSegmentCount
--Function /Script/DogwoodStats.BloodBarComponent:GetSingleSegmentBloodAmount (int index)

-- /Game/_Dawnwalker/Player/BP_PlayerCharacter.BP_PlayerCharacter_C:On Dialogue Started = replacement for dialogue? didn't test

---Function /Script/Dawnwalker.DawnwalkerPlayerCharacter:OnVampireUrgeForced