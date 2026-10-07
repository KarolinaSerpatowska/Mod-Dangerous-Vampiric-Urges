--[[
    Dangerous Vampiric Urges v0.6
	Mod changes how 'give in to hunger' dialogue option is presented on screen. For example you can set it, to replace random dialogue option (like in prologue).
	Currently displaying is based on hunger lvl. If some other hunger system(mod) is supposed to work with this, then it needs to change game's hunger lvl. Any other external systems won't change dialogue. 
	Doesn't (and shouldn't) affect any other game functionality.
	Should be compatible with everything that doesn't touch/replace variables in VampireUrgeSpecialDialogueChoice and VampireHungerSubsystem.
--]]
------------------------------------------------------------
-- CONFIGURATION
------------------------------------------------------------
config = {} --don't touch this
------------------------------------------------------------
-- CHANGING DIALOGUE OPTIONS DISPLAY
-- !!! DIALOGUE CHANGES ARE APPLIED BEFORE SHOWING DIALOGUE OPTIONS, IF YOUR HUNGER CHANGES AFTER DISPLAYING THEM ON SCREEN IT WON'T UPDATE (BUT WILL UPDATE IF YOU FOR EXAMPLE CHOOSE SOME DIALOGUE OPTION, BECAUSE IT REFRESHES DISPLAYED CHOICES); This is the case when you regenerate hp during dialogue
-- !!! ONLY VANILLA DIALOGUES WHICH HAVE OPTION "GIVE IN TO HUNGER" ARE AFFECTED. MOD DOESN'T ANY NEW CHOICES OR DRINKING CUTSCENES, IT ONLY CHANGES HOW CHOICE SHOULD BE PRESENTED
------------------------------------------------------------
--enable/disable 'give in to hunger' dialogue option changes; false - vanilla behaviour; true - mod behaviour toggle; DIALOGUE MODIFICATION DOESN'T AFFECTS ANY OTHER FUNCTIONALITY, IT'S ONLY FOR SHOW
config.isChangingDialogue = true

-- DIALOGUE RESPONSE DISPLAY OPTIONS - BASED ON CURRENT HUNGER
-- HIGH hunger means that Coen forcefully eats NPC in dialogue (vanilla game behaviour). Such state is reached when your hp is less or equal 1 segment. On screen is shown red effect and audio(voices) starts playing
-- I didn't specifically test which hp numbers/segments set MEDIUM and LOW hunger, but:
-- MEDIUM hunger - normally when is reached on subtle voices and subtle red postprocess; Is reached around half hp
-- LOW hunger - normally when is reached screen doesn't have any effects or additional audio. When around full hp
    
--CUSTOMISE HOW 'GIVE IN' OPTION SHOULD BE PRESENTED
--replacementMode; 0 - (default in game) vanilla, always visible when vampire; 1 - replaces only previous option but also changes back to normal dialogue option; 2 -- random replacement (all dialogue options)
--dialogueOptionEffectIntensity; 0 - low; 1 - medium; 2 - high; how intense is effect on dialogue option (red color, shaking etc.) (default value in vanilla is based on hunger lvl)
    
-- change dialogue options to this settings when on LOW hunger
config.LOW_HUNGER_DIALOGUE = {
    replacementMode = 0,
    dialogueOptionEffectIntensity = 2
}

-- change dialogue options to this settings when on MEDIUM hunger 
config.MEDIUM_HUNGER_DIALOGUE = {
    replacementMode = 2,
    dialogueOptionEffectIntensity = 2
}

-- change dialogue options to this settings when on HIGH hunger
config.HIGH_HUNGER_DIALOGUE = {
    replacementMode = 0,
    dialogueOptionEffectIntensity = 2
}

-- true - disables automatic feeding in dialogues when hunger is high - you can still click on option, and it will work normally; false - vanilla = when hunger is high then eat NPC
-- NEEDS isChangingDialogue = true !!!!!!
config.disableForcefulEating = false

------------------------------------------------------------
-- CUSTOM HUNGER THRESHOLD, BASED ON CURRENT HP %
------------------------------------------------------------
-- true - enable custom hunger level threshold, based on current hp %; false - vanilla, mod doesn't change hunger
config.customHungerHPThreshold = false

-- true - use always the same percent thresholds and ignore number of hp segments, WILL USE THRESHOLDS FOR 2 SEGMENTS; false - use different thresholds, based on current number of hp segments
config.oneThresholdForEverySegment = false

-- HP PERCENT THRESHOLDS:
-- this is used if oneThresholdForEverySegment = true; 
-- thresholds when hp has 2 segments
config.TWO_SEGMENTS_PERCENTS = {
-- this means that:
-- low hunger if hp is from 80% - 100% (80 % included)
-- medium hunger if hp is from 40% - 80% (40% included)
-- high hunger if hp is from 0% - 40%
    low = 80.0,
    high = 40.0
}

config.THREE_SEGMENTS_PERCENTS = {
    low = 80.0,
    high = 40.0
}

config.FOUR_SEGMENTS_PERCENTS = {
    low = 80.0,
    high = 40.0
}

config.FIVE_SEGMENTS_PERCENTS = {
    low = 80.0,
    high = 40.0
}

------------------------------------------------------------
-- CUSTOM HUNGER SYSTEM WITH BAR
------------------------------------------------------------
config.customHungerSystem = true





------------------------------------------------------------
-- DEBUG AND STUFF
------------------------------------------------------------
-- delay between ticks
config.tickMs = 1000
-- true - SPAM debug messeges everywhere
config.debug = true


return config