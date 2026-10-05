--[[
    Dangerous Vampiric Urges v1.0
	Mod changes how 'give in to hunger' dialogue option is presented on screen. For example you can set it, to replace random dialogue option (like in prologue).
	Currently displaying is based on vanilla game hunger lvl. If some other hunger system(mod) is supposed to work with this, then it needs to change game's hunger lvl. Any other external systems won't change dialogue. 
	Doesn't (and shouldn't) affect any other game functionality.
	Should be compatible with everything that doesn't touch/replace variables in "VampireUrgeSpecialDialogueChoice".
--]]

------------------------------------------------------------
-- CONFIGURATION
------------------------------------------------------------
MOD_CONFIG = {
------------------------------------------------------------
-- CHANGING DIALOGUE OPTIONS DISPLAY
-- !!! DIALOGUE CHANGES ARE APPLIED BEFORE SHOWING DIALOGUE OPTIONS, IF YOUR HUNGER CHANGES AFTER DISPLAYING THEM ON SCREEN IT WON'T UPDATE (BUT WILL UPDATE IF YOU FOR EXAMPLE CHOOSE SOME DIALOGUE OPTION, BECAUSE IT REFRESHES DISPLAYED CHOICES); This is the case when you regenerate hp during dialogue
-- !!! ONLY VANILLA DIALOGUES WHICH HAVE OPTION "GIVE IN TO HUNGER" ARE AFFECTED. MOD DOESN'T ANY NEW CHOICES OR DRINKING CUTSCENES, IT ONLY CHANGES HOW CHOICE SHOULD BE PRESENTED
------------------------------------------------------------
    --enable/disable 'give in to hunger' dialogue option changes; false - vanilla behaviour; true - mod behaviour toggle; DIALOGUE MODIFICATION DOESN'T AFFECTS ANY OTHER FUNCTIONALITY, IT'S ONLY FOR SHOW
    isChangingDialogue = true,

    -- DIALOGUE RESPONSE DISPLAY OPTIONS - BASED ON CURRENT HUNGER
    -- HIGH hunger means that Coen forcefully eats NPC in dialogue (vanilla game behaviour). Such state is reached when your hp is less or equal 1 segment. On screen is shown red effect and audio(voices) starts playing
    -- I didn't specifically test which hp numbers/segments set MEDIUM and LOW hunger, but:
    -- MEDIUM hunger - normally when is reached on subtle voices and subtle red postprocess; Is reached around half hp
    -- LOW hunger - normally when is reached screen doesn't have any effects or additional audio. When around full hp
    
    --CUSTOMISE HOW 'GIVE IN' OPTION SHOULD BE PRESENTED
    --replacementMode; 0 - (default in game) vanilla, always visible when vampire; 1 - replaces only previous option but also changes back to normal dialogue option; 2 -- random replacement (all dialogue options)
    --dialogueOptionEffectIntensity; 0 - low; 1 - medium; 2 - high; how intense is effect on dialogue option (red color, shaking etc.) (default value in vanilla is based on hunger lvl)
    
    -- change dialogue options to this settings when on LOW hunger
    LOW_HUNGER_DIALOGUE = {
        replacementMode = 0,
        dialogueOptionEffectIntensity = 0
     },

    -- change dialogue options to this settings when on MEDIUM hunger 
    MEDIUM_HUNGER_DIALOGUE = {
        replacementMode = 2,
        dialogueOptionEffectIntensity = 1
     },

   -- change dialogue options to this settings when on HIGH hunger ======= kinda doesn't matter, because at this moment NPC will be your snack anyway
    HIGH_HUNGER_DIALOGUE = {
        replacementMode = 0,
        dialogueOptionEffectIntensity = 2
     },
------------------------------------------------------------
-- CUSTOM HUNGER THRESHOLD, BASED ON CURRENT HP %
------------------------------------------------------------
    -- enable/disable custom hunger level threshold, based on current hp %
    customHungerHPThreshold = false,





}


-- delay between ticks
tickMs = 1000
-- true - SPAM debug messeges everywhere
debug = true
------------------------------------------------------------
-- ACTUAL CODE STARTS FROM HERE
------------------------------------------------------------
UEHelpers = require("UEHelpers")

MOD_VARIABLES = {
    player = nil,
    inDialogue = false,
    isVampire = false,
    hungerSystem = nil,
    currentHungerLvl = 0
}

--caching this, otherwise game lags during hp regen xD
GA_hunger = nil

------------------------------------------------------------
-- HELPING FUNCTIONS
------------------------------------------------------------

local function PRINT_MSG(Msg)
    if debug == true then
        print("[Dangerous Vampiric Urges] " .. tostring(Msg) .. "\n")
    end
end

local function IS_VALID(obj)
    if obj == nil then return false end
    local ok, v = pcall(function() return obj:IsValid() end)
    return ok and v
end

local function IS_PLAYER_PAWN(Object)
    if Object == nil then return nil end
    local Success, Result = pcall(function() return Object:GetFullName() end)
    if Success and Result ~= nil then
         return string.find(Object:GetFullName(), "BP_PlayerCharacter_C_", 1, true) ~= nil 
    end
end

------------------------------------------------------------
-- FIND PLAYER
------------------------------------------------------------

local function FIND_PLAYER()

    local player = nil
    pcall(function()
        local controller = UEHelpers.GetPlayerController
        if IS_VALID(controller) then
           player = controller.GetPawn
        end
    end)
    --found player
    if IS_VALID(player) then return player end
    

    --2 attempt
    pcall(function()
        player = FindFirstOf("BP_PlayerCharacter_C")
    end)

    --found player
    if IS_VALID(player) then return player end


    --3 attempt
    local Candidates = nil
    pcall(function()
        Candidates = FindAllOf("BP_PlayerCharacter_C")
    end)
    if IS_VALID(Candidates) then
        for _, Candidate in ipairs(Candidates) do
            if IS_PLAYER_PAWN(Candidate) then
                local Controller = nil
                pcall(function()
                    Controller = Candidate:GetController()
                end)
                if IS_VALID(Controller) then
                    PRINT_MSG("Player found (FindAllOf recovery)")
                    return Candidate
                end
            end
        end
    end

    --player not found
    PRINT_MSG("PLAYER NOT FOUND!!!")
    return nil
end

------------------------------------------------------------
-- CHECK FOR MAIN MENU
------------------------------------------------------------
local function IS_MAIN_MENU_PRESENT()
    local mainMenu = nil
    pcall(function() mainMenu = FindFirstOf("BP_MainMenuPawn_C") end)
    if not IS_VALID(mainMenu) then
        -- no main menu
        return false
    end
    return true
end

------------------------------------------------------------
-- CHECK IF PLAYER IS VAMPIRE
------------------------------------------------------------
local function CHECK_VAMPIRE()
    if not IS_VALID(MOD_VARIABLES.player) then
        PRINT_MSG("Missing player")
        return false
    end

    pcall(function() MOD_VARIABLES.isVampire = MOD_VARIABLES.player:IsVampire() end)
    
    if MOD_VARIABLES.isVampire == true then
        PRINT_MSG("Player is vampire")
    end

end

------------------------------------------------------------
-- FIND HUNGER SYSTEM
------------------------------------------------------------
local function FIND_HUNGER_SYS()
    if IS_VALID(MOD_VARIABLES.hungerSystem) then return end
    pcall(function() 
        MOD_VARIABLES.hungerSystem = FindFirstOf("VampireHungerSubsystem")
    end)
    if not IS_VALID(MOD_VARIABLES.hungerSystem) then PRINT_MSG("Hunger system not found") return end
    PRINT_MSG("Hunger system found")
end
------------------------------------------------------------
-- CHANGE EATING DIALOGUE OPTION
--eatingOption.bForceHungerLevel; needs to be true for working intensity change
--eatingOption.ReplacementMode; 0 - vanilla behaviour (always visible when vampire); 1 - replaces only previous option but also changes back to normal dialogue option; 2 - random replacement (all dialogue options)
--eatingOption.ForcedHungerLevel; 0 - low; 1 - medium 2 - high; how intense is anim on dialogue option (red color, shaking etc.)
------------------------------------------------------------

local function CHANGE_VAMPIRE_DIALOGUE_OPTION()
    if MOD_VARIABLES.isVampire == false then
        PRINT_MSG("Player is human = leave dialogue alone") 
        return false
    end

    FIND_HUNGER_SYS()

    -- 0 vanilla - always visible when vampire; 1 replaces only previous option but also changes back to normal dialogue option; 2 -- random replacement (all dialogue options)
    local replacementMode
     --0 low; 1 - medium 2 - high; how intense is anim on dialogue option (red color, shaking etc.)
    local dialogueOptionEffectIntensity

    PRINT_MSG(string.format("Current hunger lvl: %d", MOD_VARIABLES.hungerSystem.VampireHungerLevel))
    
    pcall(function() 
        if MOD_VARIABLES.hungerSystem.VampireHungerLevel == 0 then
            replacementMode = MOD_CONFIG.LOW_HUNGER_DIALOGUE.replacementMode
            dialogueOptionEffectIntensity = MOD_CONFIG.LOW_HUNGER_DIALOGUE.dialogueOptionEffectIntensity
        else
            if MOD_VARIABLES.hungerSystem.VampireHungerLevel == 1 then
                replacementMode = MOD_CONFIG.MEDIUM_HUNGER_DIALOGUE.replacementMode
                dialogueOptionEffectIntensity = MOD_CONFIG.MEDIUM_HUNGER_DIALOGUE.dialogueOptionEffectIntensity
            else
                replacementMode = MOD_CONFIG.HIGH_HUNGER_DIALOGUE.replacementMode
                dialogueOptionEffectIntensity = MOD_CONFIG.HIGH_HUNGER_DIALOGUE.dialogueOptionEffectIntensity
            end
        end
    end)


    local dialogueOptions
    pcall(function()
        dialogueOptions = FindAllOf("VampireUrgeSpecialDialogueChoice")
    end)
    
    if dialogueOptions == nil then
         PRINT_MSG("Couldn't find special vampire option in dialogue") 
         return false 
    end
    
    PRINT_MSG("EATING OPTION IS PRESENT")
   
    for _, eatingOption in ipairs(dialogueOptions) do
        pcall(function()
            eatingOption.bForceHungerLevel = true 
            eatingOption.ReplacementMode = replacementMode
            eatingOption.ForcedHungerLevel = dialogueOptionEffectIntensity 
        end)
        
    end

    PRINT_MSG("Succesfuly changed vampire eating dialogue option")
    return true
end

------------------------------------------------------------
-- DEAL WITH HUNGER VFX AND AUDIO
------------------------------------------------------------
local function DEAL_WITH_HUNGER_VISUALS(hungerA, hungerB)
    --replace hunger value which is sent to gameplay ability for vfx setting
    local status, err = pcall(function()
        PRINT_MSG("SETTING HUNGER VFX to: ")
        PRINT_MSG(MOD_VARIABLES.currentHungerLvl)
        hungerA:set(MOD_VARIABLES.currentHungerLvl) hungerB:set(MOD_VARIABLES.currentHungerLvl)
    end)
    PRINT_MSG(status)
    PRINT_MSG(err)
end

------------------------------------------------------------
-- OVERRIDE HUNGER LEVEL IN GAME (DOESN'T TOUCH DIALOGUE)
------------------------------------------------------------
local function CHANGE_HUNGER_LVL()
    
    FIND_HUNGER_SYS()

    local prevHunger
    pcall(function()

        if IS_VALID(MOD_VARIABLES.hungerSystem) then
            prevHunger = MOD_VARIABLES.hungerSystem.VampireHungerLevel
            PRINT_MSG("KEKE")
            PRINT_MSG(MOD_VARIABLES.hungerSystem.VampireHungerLevel)

            if prevHunger ~= MOD_VARIABLES.currentHungerLvl then -- only change hunger lvl when is different then current
                MOD_VARIABLES.hungerSystem.VampireHungerLevel = MOD_VARIABLES.currentHungerLvl
                
                PRINT_MSG("Hunger lvl ->" .. tostring(MOD_VARIABLES.currentHungerLvl))
                -- vfx stuff
                pcall(function() 
                        if not IS_VALID(GA_hunger) then
                            GA_hunger = FindFirstOf("GA_VampireHunger_C")
                        end
                        if IS_VALID(GA_hunger) then
                            local hungerLVLChanged = GA_hunger["On Hunger Level Changed"]
                            hungerLVLChanged(GA_hunger, MOD_VARIABLES.currentHungerLvl)
                        end
                    end)
            else
                PRINT_MSG("Hunger is the same do nothing")
            end

        end

    end)
end

------------------------------------------------------------
-- FIRES WHEN DIALOGUE STARTS
------------------------------------------------------------

local function DIALOGUE_STARTED()
    if MOD_VARIABLES.isVampire == false then return end --player is human
    
    PRINT_MSG("On dialogue start")
    MOD_VARIABLES.inDialogue = true

    --testing forcefull eating AAAAAND it doesn't work xD
    --MOD_CONFIG.currentHungerLvl = 2
    --CHANGE_HUNGER_LVL()

    if MOD_CONFIG.isChangingDialogue == true then
        CHANGE_VAMPIRE_DIALOGUE_OPTION()
    end

end

------------------------------------------------------------
-- FIRES WHEN DIALOGUE ENDS
------------------------------------------------------------

local function DIALOGUE_ENDED()
    if MOD_VARIABLES.isVampire == false then return end --player is human

    PRINT_MSG("On dialogue end")
    MOD_VARIABLES.inDialogue = false

end

------------------------------------------------------------
-- RESET AT RELOAD
------------------------------------------------------------

tickHandle = nil
pcall(function()
    RegisterHook("/Script/Engine.PlayerController:ClientRestart", function()
        --reset mod
        PRINT_MSG("RESETING MOD")
        MOD_VARIABLES.player = nil
        MOD_VARIABLES.isVampire = false
        MOD_VARIABLES.inDialogue = false
        MOD_VARIABLES.hungerSystem = nil
        MOD_VARIABLES.currentHungerLvl = 0
        GA_hunger = nil

        --main menu is back
        if IS_MAIN_MENU_PRESENT() and tickHandle ~= nil then    
            --stop ticking
            PRINT_MSG("CANCELING TICK")
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
                    if IS_VALID(controller) and IS_VALID(controller.Pawn) and IS_PLAYER_PAWN(controller.Pawn) then
                        isGameReady = true
                        PRINT_MSG("Game ready")
                        -- one-time setup here
                        MOD_VARIABLES.player = controller.Pawn
                        FIND_HUNGER_SYS()
                        CHECK_VAMPIRE()
                        -- start mod/tick 
                        tickHandle = MakeActionHandle()
                        ExecuteInGameThreadWithDelay(tickHandle, 3000, TICK)
                    elseif failsafe > 60 then
                        PRINT_MSG("timeout, waiting for leaving main menu")
                        if not IS_MAIN_MENU_PRESENT() then
                            isGameReady = true
                            -- one-time setup here
                            --start mod/tick on timeout and leaving main menu
                            tickHandle = MakeActionHandle()
                            ExecuteInGameThreadWithDelay(tickHandle, 3000, TICK)
                            PRINT_MSG("Game ready - timeout, waited for leaving main menu")
                        end
                    end
                end)
                return false
            end)

        end

    end)
end)

------------------------------------------------------------
-- RUN THIS ONCE PER TICK
------------------------------------------------------------

local function RUN_ONCE_PER_TICK()
    --find player if not valid
        if not IS_VALID(MOD_VARIABLES.player) then
            MOD_VARIABLES.player = FIND_PLAYER()
            CHECK_VAMPIRE()
            if IS_VALID(MOD_VARIABLES.player) then
                PRINT_MSG("Found player")
        else PRINT_MSG("PLAYER NOT FOUND...") return end
        end

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
    if not IS_VALID(MOD_VARIABLES.player.BloodBar) then 
        PRINT_MSG("Blood bar missing when calculating hp percent")
        return HPpercent
    end

    pcall(function()
        PRINT_MSG(string.format("Current hp: %f", MOD_VARIABLES.player.BloodBar:GetBlood()))
        current = 100 * tonumber(MOD_VARIABLES.player.BloodBar:GetBlood())
        PRINT_MSG(string.format("Max hp: %f", MOD_VARIABLES.player.BloodBar:GetBloodBarLength()))
        HPpercent = current / tonumber(MOD_VARIABLES.player.BloodBar:GetBloodBarLength())
    end)

    PRINT_MSG(string.format("HP percent: %f", HPpercent))
    return HPpercent
end

------------------------------------------------------------
-- DETERMINE HUNGER BASED ON HP
------------------------------------------------------------
local function CALC_HUNGER_FROM_HP()
    local HpPercent = GET_CURRENT_HP_PERCENT()
    PRINT_MSG(HpPercent)
    -- hp % is invalid
    if HpPercent == -1 then
        PRINT_MSG("INVALID HP PERCENT")
        FIND_HUNGER_SYS()
        -- return current hunger lvl
        PRINT_MSG("RETURN CURRENT HUNGER: ")
        PRINT_MSG(MOD_VARIABLES.hungerSystem.VampireHungerLevel)
        MOD_VARIABLES.currentHungerLvl = MOD_VARIABLES.hungerSystem.VampireHungerLevel
    end

    --low hunger
    if HpPercent <= 100.0 and HpPercent >= 80.0 then
        PRINT_MSG("CALC RESULT HUNGER = 0")
        MOD_VARIABLES.currentHungerLvl = 0
    end

    --medium
    if HpPercent < 80.0 and HpPercent >= 40.0 then
        PRINT_MSG("CALC RESULT HUNGER = 1")
        MOD_VARIABLES.currentHungerLvl =  1
    end

    --high
    if HpPercent >= 0.0 and HpPercent < 40.0 then
        PRINT_MSG("CALC RESULT HUNGER = 2")
        MOD_VARIABLES.currentHungerLvl = 2
    end

end

------------------------------------------------------------
-- ON HP CHANGE
------------------------------------------------------------

local function ON_BLOOD_BAR_SETTING()
    if not IS_VALID(MOD_VARIABLES.player) then return end
    if customHungerHPThreshold == false then return end --if vanilla hunger then do nothing

    --here start changes to the hunger lvl
    FIND_HUNGER_SYS()
    CALC_HUNGER_FROM_HP()
   
    pcall(function() ON_HUNGER_CHANGED(MOD_VARIABLES.currentHungerLvl)
    end)

end

------------------------------------------------------------
-- DEBUG BUTTONS
------------------------------------------------------------

local function DEBUG_BUTTONS()
    if debug == false then return end

    pcall(function() 
    --% hp setter
    RegisterKeyBind(Key.B, function()

        ExecuteInGameThread(function() 
            if not IS_VALID(MOD_VARIABLES.player) then return end

            if not IS_VALID(MOD_VARIABLES.player.BloodBar) then return end
	
            local BeforeBlood = nil
            pcall(function()
                BeforeBlood = tonumber(MOD_VARIABLES.player.BloodBar:GetBlood())
            end)

            TargetBloodPercent = 0.05   -- 1.0 = 100%

            local SetOK, SetErr = pcall(function()
                MOD_VARIABLES.player.BloodBar:SetBloodPercent(TargetBloodPercent)
            end)

            local AfterBlood = nil
            pcall(function()
                AfterBlood = tonumber(MOD_VARIABLES.player.BloodBar:GetBlood())
            end)

        end)

    end)
    
    end)

    pcall(function() 
    --set hunger to high
    RegisterKeyBind(Key.L, function()
        ExecuteInGameThread(function() 
            if not IS_VALID(MOD_VARIABLES.player) then return end

            pcall(function()
                PRINT_MSG("FORCE SETTING HUNGER TO HIGH")
                
                
                if not IS_VALID(MOD_VARIABLES.player) then return end
                ON_HUNGER_CHANGED(2)
               


            end)

        end)
    end)
        
    end)

    pcall(function() 
    --set hunger to low
    RegisterKeyBind(Key.P, function()
        ExecuteInGameThread(function() 
            if not IS_VALID(MOD_VARIABLES.player) then return end
            
            pcall(function()
                PRINT_MSG("SETTING HUNGER TO LOW")
                
                
                ON_HUNGER_CHANGED(0)
               

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
        RegisterHook("/Game/_Dawnwalker/Player/BP_PlayerCharacter.BP_PlayerCharacter_C:On Night Started", function() PRINT_MSG("ON NIGHT STARTED") CHECK_VAMPIRE() end)
    end)

    pcall(function()
        RegisterHook("/Game/_Dawnwalker/Player/BP_PlayerCharacter.BP_PlayerCharacter_C:On Day Started", function() PRINT_MSG("ON DAY STARTED") CHECK_VAMPIRE() end)
    end)

    if MOD_CONFIG.isChangingDialogue == true then
        -- hook to dialogue only when settings enable it
        PRINT_MSG("CHANGING DIALOGUES ENABLED - hooking")
        pcall(function()
            RegisterHook("/Script/Dawnwalker.DawnwalkerPlayerCharacter:CallOnCinematicModeStarted", function() DIALOGUE_STARTED() end)
        end)
        
        pcall(function()
            RegisterHook("/Script/Dawnwalker.DawnwalkerPlayerCharacter:CallOnCinematicModeEnded", function() DIALOGUE_ENDED() end)
        end)
    end

    -- only when custom hp % threshold for hunger
    if MOD_CONFIG.customHungerHPThreshold == true then
        PRINT_MSG("CUSTOM HUNGER LVL:HP ENABLED - hooking")
        -- this fires AFTER setting bloodbar
        --this is called by /Script/DogwoodVampireHunger.VampireHungerSubsystem:OnBloodValueChanged
        pcall(function()
            RegisterHook("/Script/Dawnwalker.DawnwalkerPlayerCharacter:OnVampireHungerLevelChanged", function(self, hung) PRINT_MSG("DawnwalkerPlayerCharacter:OnVampireHungerLevelChanged pre")
                --PRINT_MSG(hung:get())
                hung:set(MOD_VARIABLES.currentHungerLvl) --replace games hunger with current
            end)
        end)

        --not needed right now
        --pcall(function()
            --RegisterHook("/Script/DogwoodStats.BloodBarComponent:SetBloodPercent", function() PRINT_MSG("BloodBarComponent:SetBloodPercent pre") end, function() PRINT_MSG("BloodBarComponent:SetBloodPercent post") ON_BLOOD_BAR_SETTING() end)
        --end)

        pcall(function()
            RegisterHook("/Script/DogwoodVampireHunger.VampireHungerSubsystem:OnBloodValueChanged", function() PRINT_MSG("ON BLOOD PRE") ON_BLOOD_BAR_SETTING() end, function() PRINT_MSG("ON BLOOD POST") ON_BLOOD_BAR_SETTING() end)
        end)
        
        --this sets hunger vfx and audio to hunger lvl
        pcall(function()
            RegisterHook("/Game/_Dawnwalker/Player/VampireHunger/GA_VampireHunger.GA_VampireHunger_C:Calculate Valid Hunger Effects", 
            function(context, hungA, hungB) 
                PRINT_MSG("GA_hunger: pre vfx calculate")
                DEAL_WITH_HUNGER_VISUALS(hungA, hungB)
            end,
            function() return end)
        end)
    end

    --NEVER AGAIN
    if debug == true then
        --WHY??????????..................
        pcall(function() RegisterHook("/Game/_Dawnwalker/Player/VampireHunger/GA_VampireHunger.GA_VampireHunger_C:ExecuteUbergraph_GA_VampireHunger", function(self, EntryPoint)
        -- This fires for EVERY event inside this blueprint.
        print("Ubergraph triggered at ID: " .. tostring(EntryPoint:get()))
        --3137
        --3707 mine?
        --2481
        --2354 from game high?
        if EntryPoint:get() == 2354 then
            PRINT_MSG("GA_hunger 2354 caught via Ubergraph")
        end

        if EntryPoint:get() == 3707 then
            PRINT_MSG("GA_hunger 3707 caught via Ubergraph")
        end
        end, function() return end) end)
    end

end

------------------------------------------------------------
-- TICK (REPLACE THIS WITH loopAsync?)
------------------------------------------------------------

function TICK()
    local Success, ErrorMessage = pcall(RUN_ONCE_PER_TICK)
    if not Success then
        PRINT_MSG("TICK ERROR | " .. tostring(ErrorMessage))
    end
    tickHandle = MakeActionHandle()
    ExecuteInGameThreadWithDelay(tickHandle, tickMs, TICK)
end

------------------------------------------------------------
-- MAIN = mod starting
------------------------------------------------------------

print("[Dangerous Vampiric Urges] Mod loaded")

PRINT_MSG(string.format(
    "Tick=%dms | Debug=%s",
    tickMs,
    tostring(debug)
))

--wait for game to be ready = loaded etc.
local isGameReady = false
local failsafe = 0

LoopAsync(1000, function()                
    ExecuteInGameThread(function()
        if isGameReady then return end
        failsafe = failsafe + 1
        local controller = UEHelpers.GetPlayerController()
        if IS_VALID(controller) and IS_VALID(controller.Pawn) and IS_PLAYER_PAWN(controller.Pawn) then
            isGameReady = true
            PRINT_MSG("Game ready")
            -- one-time setup here
            MOD_VARIABLES.player = controller.Pawn
            CHECK_VAMPIRE()
            FIND_HUNGER_SYS()
            SETUP()
            -- start mod/tick 
            tickHandle = MakeActionHandle()
            ExecuteInGameThreadWithDelay(tickHandle, 3000, TICK)
        elseif failsafe > 60 then
            PRINT_MSG("timeout, waiting for leaving main menu")
            if not IS_MAIN_MENU_PRESENT() then
                isGameReady = true
                SETUP()
                -- one-time setup here
                --start mod/tick on timeout and leaving main menu
                tickHandle = MakeActionHandle()
                ExecuteInGameThreadWithDelay(tickHandle, 3000, TICK)
                PRINT_MSG("Game ready - timeout, waited for leaving main menu")
            end
        end
    end)
    return false
end)




------------------------------------------------------------
-- MY TRASH NOTES
------------------------------------------------------------
--Function /Script/Dawnwalker.DrinkBloodSubsystem:TriggerBloodDrinkingInteraction
--Function /Script/Dawnwalker.DawnwalkerPlayerCharacter:ResetBloodSegmentsOnNightStartBp
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

--it would be nice to find something to refresh dialogue options then it would be posssible to have hunger consequence when hunger changed during dialogue
--Function /Script/DialogueSystem.CinematicCharacter:ResponseStartedHandler
--Function /Script/DogwoodUI.CinematicDialogueChoiceLineWidget:InitializeChoice
--Function /Script/DogwoodUI.CinematicDialogueChoiceWidget:ShowChoices
--Function /Script/DogwoodUI.CinematicDialogueChoiceWidget:GetChoiceLines

--this resets dialogue options to white default options; how to refresh this easily without saving?
--pcall(function()
--dialogueOptions = FindAllOf("CinematicDialogueChoiceLineWidget")
--for _, eatingOption in ipairs(dialogueOptions) do
--eatingOption:InitializeChoice()        
--end  
--end)
        