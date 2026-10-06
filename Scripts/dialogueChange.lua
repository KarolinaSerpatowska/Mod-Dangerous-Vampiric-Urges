dialogue = {}

dialogue.inDialogue = false

helpers = require("helperFunc")
config = require("config")
------------------------------------------------------------
-- CHANGE EATING DIALOGUE OPTION
--eatingOption.bForceHungerLevel; needs to be true for working intensity change
--eatingOption.ReplacementMode; 0 - vanilla behaviour (always visible when vampire); 1 - replaces only previous option but also changes back to normal dialogue option; 2 - random replacement (all dialogue options)
--eatingOption.ForcedHungerLevel; 0 - low; 1 - medium 2 - high; how intense is anim on dialogue option (red color, shaking etc.)
------------------------------------------------------------

function dialogue.CHANGE_VAMPIRE_DIALOGUE_OPTION()
    if not helpers.isVampire then
        helpers.PRINT_MSG("Player is human = leave dialogue alone") 
        return false
    end

    helpers.FIND_HUNGER_SYS()

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
         return false 
    end
    
    helpers.PRINT_MSG("EATING OPTION IS PRESENT")
   
    for _, eatingOption in ipairs(dialogueOptions) do
        pcall(function()
            eatingOption.bForceHungerLevel = true 
            eatingOption.ReplacementMode = replacementMode
            eatingOption.ForcedHungerLevel = dialogueOptionEffectIntensity 
        end)
        
    end

    helpers.PRINT_MSG("Succesfuly changed vampire eating dialogue option")
    return true
end

------------------------------------------------------------
-- FIRES WHEN DIALOGUE STARTS
------------------------------------------------------------

function dialogue.DIALOGUE_STARTED()
    if not helpers.isVampire then return end --player is human
    
    helpers.PRINT_MSG("On dialogue start")
    dialogue.inDialogue = true

    --testing forcefull eating AAAAAND it doesn't work xD
    --MOD_CONFIG.currentHungerLvl = 2
    --CHANGE_HUNGER_LVL()

    if config.isChangingDialogue then
        dialogue.CHANGE_VAMPIRE_DIALOGUE_OPTION()
    end

end

------------------------------------------------------------
-- FIRES WHEN DIALOGUE ENDS
------------------------------------------------------------

function dialogue.DIALOGUE_ENDED()
    if not helpers.isVampire then return end --player is human

    helpers.PRINT_MSG("On dialogue end")
    dialogue.inDialogue = false

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