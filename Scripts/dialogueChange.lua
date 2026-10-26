dialogue = {}

dialogue.inDialogue = false

helpers = require("helperFunc")
config = require("config")

local choicesCount = 0
------------------------------------------------------------
-- CHANGE EATING DIALOGUE OPTION
--eatingOption.bForceHungerLevel; needs to be true for working intensity change
--eatingOption.ReplacementMode; 0 - vanilla behaviour (always visible when vampire); 1 - replaces only previous option but also changes back to normal dialogue option; 2 - random replacement (all dialogue options)
--eatingOption.ForcedHungerLevel; 0 - low; 1 - medium 2 - high; how intense is anim on dialogue option (red color, shaking etc.)
------------------------------------------------------------

function dialogue.CHANGE_VAMPIRE_DIALOGUE_OPTION()
    if not helpers.isVampire then
        helpers.PRINT_MSG("Player is human = leave dialogue alone") 
        return
    end

    helpers.PRINT_MSG("Changing dialogue function start")

    helpers.FIND_HUNGER_SYS()

    helpers.PRINT_MSG("Changing dialogue after find hunger sys")

    -- 0 vanilla - always visible when vampire; 1 replaces only previous option but also changes back to normal dialogue option; 2 -- random replacement (all dialogue options)
    local replacementMode
     --0 low; 1 - medium 2 - high; how intense is anim on dialogue option (red color, shaking etc.)
    local dialogueOptionEffectIntensity

    helpers.PRINT_MSG(string.format("Current hunger lvl: %d", helpers.hungerSystem.VampireHungerLevel))
    
    pcall(function() 
        if helpers.hungerSystem.VampireHungerLevel == 0 then
            replacementMode = config.LOW_HUNGER_DIALOGUE.replacementMode
            dialogueOptionEffectIntensity = config.LOW_HUNGER_DIALOGUE.dialogueOptionEffectIntensity
        else
            if helpers.hungerSystem.VampireHungerLevel == 1 then
                replacementMode = config.MEDIUM_HUNGER_DIALOGUE.replacementMode
                dialogueOptionEffectIntensity = config.MEDIUM_HUNGER_DIALOGUE.dialogueOptionEffectIntensity
            else
                replacementMode = config.HIGH_HUNGER_DIALOGUE.replacementMode
                dialogueOptionEffectIntensity = config.HIGH_HUNGER_DIALOGUE.dialogueOptionEffectIntensity
            end
        end
    end)

    local dialogueOptions
    pcall(function()
        dialogueOptions = FindAllOf("VampireUrgeSpecialDialogueChoice")
    end)
    
    if dialogueOptions == nil then
         helpers.PRINT_MSG("Couldn't find special vampire option in dialogue") 
         return 
    end
    
    helpers.PRINT_MSG("EATING OPTION IS PRESENT")
   
    for _, eatingOption in ipairs(dialogueOptions) do
        pcall(function()
            --if more then 1, then change dialogue replacement (random etc.)
            if choicesCount > 2 then
                eatingOption.ReplacementMode = replacementMode
            else 
                helpers.PRINT_MSG("1 option is present, replacement mode = vanilla")
                eatingOption.ReplacementMode = 0
            end

            eatingOption.bForceHungerLevel = true
            eatingOption.ForcedHungerLevel = dialogueOptionEffectIntensity
            
            if config.disableForcefulEating then --if disable forcefull eating
                eatingOption.DisplayMode = 1
            end

        end)
        
    end

    helpers.PRINT_MSG("Succesfuly changed vampire eating dialogue option")
    return
end

------------------------------------------------------------
-- FIRES WHEN DIALOGUE STARTS
------------------------------------------------------------

function dialogue.DIALOGUE_STARTED()
    if not config.isChangingDialogue then return end
    if not helpers.isVampire then  helpers.PRINT_MSG("Dialogue player is human" ) return end --player is human


    --count how many dialogue options you have
    --choicesCount = choicesCount + 1
    if choicesCount == 0 then
        local choiceWidgets
        local choiceMap
        pcall(function()
            choiceWidgets = FindAllOf("CinematicDialogueChoiceWidget")
        end)

    for _, choiceWidget in ipairs(choiceWidgets) do
    if helpers.IS_VALID(choiceWidget) then
        helpers.PRINT_MSG(string.format("found: %s", choiceWidget:GetFullName()))
        displayedChoiceObj = choiceWidget.DisplayedChoice --DisplayedChoice --Choices
        if helpers.IS_VALID(displayedChoiceObj) then
            helpers.PRINT_MSG(string.format("found: %s", displayedChoiceObj:GetFullName()))
            choiceMap = displayedChoiceObj.Choices
            if choiceMap and #choiceMap ~= 0 then
                helpers.PRINT_MSG(string.format("found in map: %d", #choiceMap))
                choicesCount = #choiceMap
            end
        end
    end 

    end

    end

    helpers.PRINT_MSG(string.format("choices count: %d", choicesCount))




    helpers.PRINT_MSG("On dialogue choice")
    dialogue.inDialogue = true
    
    dialogue.CHANGE_VAMPIRE_DIALOGUE_OPTION()

end

------------------------------------------------------------
-- FIRES WHEN DIALOGUE ENDS
------------------------------------------------------------

function dialogue.DIALOGUE_ENDED()
    if not config.isChangingDialogue then return end
    if not helpers.isVampire then return end --player is human

    helpers.PRINT_MSG("On dialogue end")
    dialogue.inDialogue = false

    --reset dialogue choices count
    choicesCount = 0
end

function dialogue.ON_RESET()
    if not config.isChangingDialogue then return end
    helpers.PRINT_MSG("On dialogue reset")

    choicesCount = 0
end


return dialogue
------------------------------------------------------------
-- MY TRASH NOTES
------------------------------------------------------------
--it would be nice to find something to refresh dialogue options then it would be posssible to have hunger consequence when hunger changed during dialogue
--Function /Script/DialogueSystem.CinematicCharacter:ResponseStartedHandler
--Function /Script/DogwoodUI.CinematicDialogueChoiceLineWidget:InitializeChoice
--Function /Script/DogwoodUI.CinematicDialogueChoiceWidget:ShowChoices
--Function /Script/DogwoodUI.CinematicDialogueChoiceWidget:GetChoiceLines

-- /Game/_Dawnwalker/Player/BP_PlayerCharacter.BP_PlayerCharacter_C:On Dialogue Started = replacement for dialogue? didn't test

---Function /Script/Dawnwalker.DawnwalkerPlayerCharacter:OnVampireUrgeForced

--this resets dialogue options to white default options; how to refresh this easily without saving?
--pcall(function()
--dialogueOptions = FindAllOf("CinematicDialogueChoiceLineWidget")
--for _, eatingOption in ipairs(dialogueOptions) do
--eatingOption:InitializeChoice()        
--end  
--end)
        
--prologue soldiers dialogue
--VampireUrgeSpecialDialogueChoice /Game/_Dawnwalker/Quest/q001_vs/Dialog/Scenes/q001_09_brencis_soldiers_before_combat_ns_FG.q001_09_brencis_soldiers_before_combat_ns_FG:CinematicNode_Choice_0.VampireUrgeSpecialDialogueChoice_1

--prologue vlad dialogue
--VampireUrgeSpecialDialogueChoice /Game/_Dawnwalker/Quest/q001_vs/Dialog/Scenes/q001_10_vlad_hideout_ns_FG.q001_10_vlad_hideout_ns_FG:CinematicNode_Choice_2.VampireUrgeSpecialDialogueChoice_1