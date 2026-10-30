customHunger = {}


helpers = require("helperFunc")
config = require("config")

local AssetRegistryHelpers = nil
local AssetRegistry = nil

-- /Game/Mods/DangerousVampiricUrges/WBP_BloodWidget
-- /Game/Mods/DangerousVampiricUrges/GA_ModVampireUrgesHelper
local modNameNoExtension = "DangerousVampiricUrges"

local hungerBarAsset = nil
local GAHelperAsset = nil

local drinkBloodTag = "DangerousVampiricUrges.DrinkBlood"

local looping = false
local drinkBlood = false

customHunger.hungerBarWidget = nil
customHunger.hungerGAListener = nil

customHunger.currentHungerAmount = 0
customHunger.maxHungerAmount = 0


------------------------------------------------------------
-- asset registry for WBP load
------------------------------------------------------------
local function CacheAssetRegistry()
    if AssetRegistryHelpers and AssetRegistry then return end

    AssetRegistryHelpers = StaticFindObject("/Script/AssetRegistry.Default__AssetRegistryHelpers")
    if not AssetRegistryHelpers:IsValid() then Log("AssetRegistryHelpers is not valid\n") end

    if AssetRegistryHelpers then
        AssetRegistry = AssetRegistryHelpers:GetAssetRegistry()
        if AssetRegistry:IsValid() then return end
    end

    AssetRegistry = StaticFindObject("/Script/AssetRegistry.Default__AssetRegistryImpl")
    if AssetRegistry:IsValid() then return end

    error("AssetRegistry is not valid\n")
end
------------------------------------------------------------
-- load .pak with WBP
------------------------------------------------------------
function customHunger.LOAD_HUNGER_BAR_ASSET()
    if helpers.IS_VALID(hungerBarAsset) then return end
    
    if not helpers.IS_VALID(AssetRegistry) or not helpers.IS_VALID(AssetRegistryHelpers) then
        CacheAssetRegistry()
    end

    local AssetData = {
        ["PackageName"] = UEHelpers.FindOrAddFName(string.format("/Game/Mods/%s/WBP_BloodWidget", modNameNoExtension)),
        ["AssetName"] = UEHelpers.FindOrAddFName("WBP_BloodWidget_C"),
    }

    hungerBarAsset = AssetRegistryHelpers:GetAsset(AssetData)

    if not helpers.IS_VALID(hungerBarAsset) then
        helpers.PRINT_MSG(string.format("hunger bar asset is not valid"))
        return
    end

    helpers.PRINT_MSG("Hunger widget loaded")
end
------------------------------------------------------------
-- Spawn widget and add to viewport
------------------------------------------------------------
function customHunger.SPAWN_HUNGER_BAR()
     if helpers.IS_VALID(customHunger.hungerBarWidget) then return end
    local WidgetBlueprintLibrary = StaticFindObject("/Script/UMG.WidgetBlueprintLibrary")
    if not helpers.IS_VALID(WidgetBlueprintLibrary) then helpers.PRINT_MSG("WidgetBPLibrary not valid") return end
    

    local controller = UEHelpers.GetPlayerController()
    local world
    pcall(function() world = controller:GetWorld() end)

    --create new widget only if it doesnt exist
    if not helpers.IS_VALID(customHunger.hungerBarWidget) then
        customHunger.hungerBarWidget = WidgetBlueprintLibrary:Create(world, hungerBarAsset, controller)
         helpers.PRINT_MSG("widget created")
    end

    if not helpers.IS_VALID(customHunger.hungerBarWidget) then helpers.PRINT_MSG("widget created but not valid?") end

ExecuteInGameThread(function() 
    customHunger.ON_HUD()
   end)

end

------------------------------------------------------------
-- Add widget to blood bar in hud
------------------------------------------------------------

function customHunger.ON_HUD() 
    helpers.PRINT_MSG("ON_HUD CALLED")
    
    if not helpers.IS_VALID(customHunger.hungerBarWidget) then
        helpers.PRINT_MSG("ON HUD _ widget not valid?")
        return
    end
    if helpers.IS_VALID(customHunger.hungerBarWidget:GetParent()) then  helpers.PRINT_MSG("ON HUD _ widget has parent") return end -- widget added already


    helpers.PRINT_MSG("ON_HUD CALLED after returns")
    local hud = FindFirstOf("WBP_GameHUD_C")
    if not helpers.IS_VALID(hud) then helpers.PRINT_MSG("hud not valid") return end


    
    helpers.PRINT_MSG(string.format("found: %s", hud:GetFullName()))

  
    local root = hud.VampireStats.WidgetTree.RootWidget
    
    helpers.PRINT_MSG(string.format("found: %s", root:GetFullName()))
    helpers.PRINT_MSG("WIDGET DOESNT HAVE PARENT")

    --Set size of widget
    --customHunger.hungerBarWidget:ChangeScale(32,120)

    pcall(function() root:AddChild(customHunger.hungerBarWidget) end)

    helpers.PRINT_MSG("WIDGET ADDED")

    --debug
    if helpers.IS_VALID(customHunger.hungerBarWidget:GetParent()) then
        helpers.PRINT_MSG("WIDGET HAS PARENT - no adding")
    end

end
------------------------------------------------------------
-- LOAD ASSET custom helper GA 
------------------------------------------------------------
local function LOAD_GA_HELPER_ASSET()
    if not helpers.IS_VALID(AssetRegistry) or not helpers.IS_VALID(AssetRegistryHelpers) then
        CacheAssetRegistry()
    end

    -- load asset
    local AssetData = {
        ["PackageName"] = UEHelpers.FindOrAddFName(string.format("/Game/Mods/%s/GA_ModVampireUrgesHelper", modNameNoExtension)),
        ["AssetName"] = UEHelpers.FindOrAddFName("GA_ModVampireUrgesHelper_C"),
    }

    GAHelperAsset = AssetRegistryHelpers:GetAsset(AssetData)

    if not helpers.IS_VALID(GAHelperAsset) then
        helpers.PRINT_MSG(string.format("hunger listener asset not valid"))
        return
    end

end

------------------------------------------------------------
-- Give custom helper GA
------------------------------------------------------------
function customHunger.ADD_HELPER_GA(player)
    if not helpers.IS_VALID(player) then return end
    if helpers.IS_VALID(customHunger.hungerGAListener) then return end --stop if exists

    LOAD_GA_HELPER_ASSET()

    local ASCClass = StaticFindObject("/Script/Dawnwalker.DawnwalkerAbilitySystemComponent")
    if not ASCClass:IsValid() then 
        helpers.PRINT_MSG("ASC Class not found")
        return
    end

    local abilitySystemComponent = player:GetComponentByClass(ASCClass)
    if not helpers.IS_VALID(abilitySystemComponent) then
        helpers.PRINT_MSG("ASC not valid")
        return 
    end

    --give ability
   pcall(function()
        local AbilityClass = StaticFindObject("/Game/Mods/DangerousVampiricUrges/GA_ModVampireUrgesHelper.GA_ModVampireUrgesHelper_C")
        if not AbilityClass:IsValid() then 
            helpers.PRINT_MSG("Ability Class not found")
            return
        end
        local SpecHandle = abilitySystemComponent:K2_GiveAbility(AbilityClass, 1, -1)
        if SpecHandle and SpecHandle ~= -1 then
            helpers.PRINT_MSG("added my ability")
            local activated = abilitySystemComponent:TryActivateAbility(SpecHandle, true)
            if not activated then
                helpers.PRINT_MSG("ability not activated")
            else
                helpers.PRINT_MSG("ability activated")
            end
        end
        customHunger.hungerGAListener = FindFirstOf("GA_ModVampireUrgesHelper_C")
    end)


    if helpers.IS_VALID(customHunger.hungerGAListener) then
        helpers.PRINT_MSG("ability is valid")
    end


end

------------------------------------------------------------
-- Init hunger bar with values
------------------------------------------------------------

function customHunger.INIT_HUNGER_BAR(player)
    if not helpers.IS_VALID(player) then helpers.PRINT_MSG("INIT BAR: no player") return false end
    if not helpers.IS_VALID(player.BloodBar) then helpers.PRINT_MSG("INIT BAR: no blood bar") return false end
    if not helpers.IS_VALID(customHunger.hungerBarWidget) then helpers.PRINT_MSG("INIT BAR: widget not valid") return false end


    --don't init if already was inited
    if customHunger.maxHungerAmount ~= 0 then return true end

    customHunger.maxHungerAmount = player.BloodBar:GetBloodBarLength()

     if customHunger.maxHungerAmount == 0 then
        helpers.PRINT_MSG("INIT BAR: blood bar is zero")
        return false
    end

    customHunger.currentHungerAmount = customHunger.maxHungerAmount / 2

    pcall(function() 
        customHunger.hungerBarWidget:SetCurrentBarValue(customHunger.currentHungerAmount, customHunger.maxHungerAmount)
    end)
    
    
    return true
end

------------------------------------------------------------
-- Remove widget
------------------------------------------------------------

function customHunger.REMOVE_FROM_VIEWPORT()
    if not helpers.IS_VALID(customHunger.hungerBarWidget) then return end
    if not helpers.IS_VALID(customHunger.hungerBarWidget:GetParent()) then
        helpers.PRINT_MSG("WIDGET DOESNT HAVE PARENT - removing")
        customHunger.hungerBarWidget:RemoveFromParent()
        helpers.PRINT_MSG("widget removed")
    end

end
------------------------------------------------------------
-- If widget is missing then try to recover it from the hud (happens when mod is reloaded during gameplay)
------------------------------------------------------------

function customHunger.TRY_FIND_WIDGET()
    if helpers.IS_VALID(customHunger.hungerBarWidget) then return true end

    customHunger.hungerBarWidget = FindFirstOf("WBP_BloodWidget_C")
    if helpers.IS_VALID(customHunger.hungerBarWidget) then helpers.PRINT_MSG("FOUND WIDGET") return true end

    return false
end

------------------------------------------------------------
-- Init Setup
------------------------------------------------------------
function customHunger.INIT_SETUP(player)
    if not helpers.IS_VALID(player) then return false end
    helpers.PRINT_MSG("Do init setup in game")
    --give helper
    customHunger.ADD_HELPER_GA(player)
    local giveAbility = helpers.IS_VALID(customHunger.hungerGAListener)

    local findWidget = customHunger.TRY_FIND_WIDGET()
    --if hunger bar exists then find it --this should find widget when mod restarts during gameplay
    if not findWidget then --hunger bar is not created
        customHungerSystem.LOAD_HUNGER_BAR_ASSET()
        customHungerSystem.SPAWN_HUNGER_BAR()
        customHungerSystem.ON_HUD()
        findWidget = helpers.IS_VALID(customHunger.hungerBarWidget)
    end

    local initBar = customHungerSystem.INIT_HUNGER_BAR(player)
    local hungerBarOnHUD = helpers.IS_VALID(customHunger.hungerBarWidget:GetParent())



    if initBar and giveAbility and findWidget and hungerBarOnHUD then
        helpers.PRINT_MSG("Init done")
        return true
    end

    --stupid debug
    if not initBar then 
        helpers.PRINT_MSG("Init bar false")
    end

    if not giveAbility then 
        helpers.PRINT_MSG("give ability false")
    end

    if not findWidget then 
        helpers.PRINT_MSG("findWidget false")
    end

    if not hungerBarOnHUD then 
        helpers.PRINT_MSG("bar on hud false")
    end


    return false
end

------------------------------------------------------------
-- For ticking drinking, adds blood
------------------------------------------------------------

function customHunger.TICK_BLOOD()
    if not helpers.IS_VALID(customHunger.hungerBarWidget) then helpers.PRINT_MSG("NOT VALID WIDGET") return end

    drinkBlood = true

    customHunger.currentHungerAmount = customHunger.currentHungerAmount + 1


    pcall(function() 
        customHunger.hungerBarWidget:SetCurrentBarValue(customHunger.currentHungerAmount, customHunger.maxHungerAmount)
    end)

end

function customHunger.START_STOP_LOOP_BLOOD(isLoop)
    looping = isLoop
    if looping then
        ExecuteInGameThread(customHunger.LOOP_BLOOD)
    end

end

function customHunger.LOOP_BLOOD()
    --helpers.PRINT_MSG("LOOPING BLOOD")
    
    customHunger.TICK_BLOOD()

    if looping then
        ExecuteInGameThread(customHunger.LOOP_BLOOD)
    end
end

function customHunger.APPLY_INSTANT_BLOOD()
    if drinkBlood then helpers.PRINT_MSG("NOT APPLYING INSTA BLOOD - IT WAS TICK DRINKING") return end

    customHunger.currentHungerAmount = customHunger.currentHungerAmount + 50

    pcall(function() 
        customHunger.hungerBarWidget:SetCurrentBarValue(customHunger.currentHungerAmount, customHunger.maxHungerAmount)
    end)

end

function customHunger.HUNGER_BAR_ON_NIGHT_START(player)
    if not helpers.IS_VALID(player) then helpers.PRINT_MSG("INIT BAR: no player") return end
    if not helpers.IS_VALID(player.BloodBar) then helpers.PRINT_MSG("INIT BAR: no blood bar") return end
    if not helpers.IS_VALID(customHunger.hungerBarWidget) then helpers.PRINT_MSG("INIT BAR: widget not valid") return end

    customHunger.maxHungerAmount = player.BloodBar:GetBloodBarLength()

     if customHunger.maxHungerAmount == 0 then
        helpers.PRINT_MSG("INIT BAR: blood bar is zero")
        return
    end

    --set this to some percent
    customHunger.currentHungerAmount = customHunger.maxHungerAmount / 2

    pcall(function() 
        customHunger.hungerBarWidget:SetCurrentBarValue(customHunger.currentHungerAmount, customHunger.maxHungerAmount)
    end)
end

return customHunger
------------------------------------------------------------
-- MY TRASH NOTES
------------------------------------------------------------
--MY WIDGET
--Function /Game/Mods/DangerousVampiricUrges/WBP_BloodWidget.WBP_BloodWidget_C:ChangeScale
--Function /Game/Mods/DangerousVampiricUrges/WBP_BloodWidget.WBP_BloodWidget_C:SetCurrentBarValue

--GA helper
--GA_ModVampireUrgesHelper_C
--Function /Game/Mods/DangerousVampiricUrges/GA_ModVampireUrgesHelper.GA_ModVampireUrgesHelper_C:OnGameplayTagAdded



--Function /Script/DogwoodCombat.CombatFocusComponent:GetOverallPlannedHealthOrBloodCost
--Function /Script/DogwoodCombat.CombatFocusVampireAbility:GetBloodDrinkValueToHeal
--Function /Script/DogwoodStats.BloodBarComponent:UnlockBlood
--Function /Script/Dawnwalker.DrinkBloodSubsystem:ReplenishBlood

--Function /Script/Dawnwalker.DrinkBloodSubsystem:TriggerBloodDrinkingInteraction
--Function /Script/Dawnwalker.DawnwalkerPlayerCharacter:OnDrinkBloodSubsystemBloodDrinkingStopped
--Function /Script/Dawnwalker.DawnwalkerPlayerCharacter:OnDrinkBloodSubsystemBloodDrinkingStarted
--Function /Game/_Dawnwalker/UI/_Unified/HUD/PlayerStatPanel/WBP_HUD_VampireStats_BloodSegment.WBP_HUD_VampireStats_BloodSegment_C:CalculateAndShowCostPercentage

--Function /Script/DogwoodUI.HUDManagerSubsystem:IsHUDVisible
--Function /Script/DogwoodUI.HUDManagerSubsystem:SetHUDVisible