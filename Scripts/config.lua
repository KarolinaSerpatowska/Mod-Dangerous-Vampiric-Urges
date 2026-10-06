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

-- change dialogue options to this settings when on HIGH hunger ======= kinda doesn't matter, because at this moment NPC will be your snack anyway
config.HIGH_HUNGER_DIALOGUE = {
    replacementMode = 0,
    dialogueOptionEffectIntensity = 2
}
------------------------------------------------------------
-- CUSTOM HUNGER THRESHOLD, BASED ON CURRENT HP %
------------------------------------------------------------
-- enable/disable custom hunger level threshold, based on current hp %
config.customHungerHPThreshold = true







-- delay between ticks
config.tickMs = 1000
-- true - SPAM debug messeges everywhere
config.debug = true






return config