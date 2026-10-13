customHunger = {}


helpers = require("helperFunc")
config = require("config")

local AssetRegistryHelpers = nil
local AssetRegistry = nil

-- /Game/Mods/DangerousVampiricUrges/WBP_BloodWidget
local modNameNoExtension = "DangerousVampiricUrges"

local hungerBarAsset = nil

local looping = false
local drinkBlood = false

customHunger.hungerBarWidget = nil
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

    local a,b = pcall(function() root:AddChild(customHunger.hungerBarWidget) end)
        
    helpers.PRINT_MSG(a)
    helpers.PRINT_MSG(b)
    helpers.PRINT_MSG("WIDGET ADDED")

    --set to fill
    --local slot = customHunger.hungerBarWidget.Slot
        --slot:SetHorizontalAlignment(0)
        --slot:SetVerticalAlignment(0)


    --debug
    if helpers.IS_VALID(customHunger.hungerBarWidget:GetParent()) then
        helpers.PRINT_MSG("WIDGET HAS PARENT - no adding")
    end

end

------------------------------------------------------------
-- Init hunger bar with values
------------------------------------------------------------

function customHunger.INIT_HUNGER_BAR(player)
    if not helpers.IS_VALID(player) then helpers.PRINT_MSG("INIT BAR: no player") return end
    if not helpers.IS_VALID(player.BloodBar) then helpers.PRINT_MSG("INIT BAR: no blood bar") return end
    if not helpers.IS_VALID(customHunger.hungerBarWidget) then helpers.PRINT_MSG("INIT BAR: widget not valid") return end


    --don't init if already was inited
    if customHunger.maxHungerAmount ~= 0 then return end

    customHunger.maxHungerAmount = player.BloodBar:GetBloodBarLength()

     if customHunger.maxHungerAmount == 0 then
        helpers.PRINT_MSG("INIT BAR: blood bar is zero")
        return
    end

    customHunger.currentHungerAmount = customHunger.maxHungerAmount / 2

    pcall(function() 
        customHunger.hungerBarWidget:SetCurrentBarValue(customHunger.currentHungerAmount, customHunger.maxHungerAmount)
    end)
    
    

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
    if helpers.IS_VALID(customHunger.hungerBarWidget) then return end

    customHunger.hungerBarWidget = FindFirstOf("WBP_BloodWidget_C")
    if helpers.IS_VALID(customHunger.hungerBarWidget) then helpers.PRINT_MSG("FOUND WIDGET") return end

end

local function CHANGE_POSITION()
    if not helpers.IS_VALID(customHunger.hungerBarWidget) then helpers.PRINT_MSG("NOT VALID WIDGET WTF") return end
    
        customHunger.hungerBarWidget:SetVisibility(0)
        customHunger.hungerBarWidget:InvalidateLayoutAndVolatility()
        customHunger.hungerBarWidget:ForceLayoutPrepass()

      local NewPadding = {
           Left = 150,
            Top = 100.0
        }

        local WTF = customHunger.hungerBarWidget.Slot
        WTF:SetSize(NewPadding)
        WTF.Size.SizeRule = 1
        WTF:SetHorizontalAlignment(0)
        WTF:SetVerticalAlignment(0)

        helpers.PRINT_MSG("POSITIONING")



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

--Function /Script/DogwoodCombat.CombatFocusComponent:GetOverallPlannedHealthOrBloodCost
--Function /Script/DogwoodCombat.CombatFocusVampireAbility:GetBloodDrinkValueToHeal
--Function /Script/DogwoodStats.BloodBarComponent:UnlockBlood
--Function /Script/Dawnwalker.DrinkBloodSubsystem:ReplenishBlood

--Function /Script/Dawnwalker.DrinkBloodSubsystem:TriggerBloodDrinkingInteraction
--Function /Script/Dawnwalker.DawnwalkerPlayerCharacter:OnDrinkBloodSubsystemBloodDrinkingStopped
--Function /Script/Dawnwalker.DawnwalkerPlayerCharacter:OnDrinkBloodSubsystemBloodDrinkingStarted
--Function /Game/_Dawnwalker/UI/_Unified/HUD/PlayerStatPanel/WBP_HUD_VampireStats_BloodSegment.WBP_HUD_VampireStats_BloodSegment_C:CalculateAndShowCostPercentage
--VampireStats

--Function /Script/DogwoodUI.HUDManagerSubsystem:IsHUDVisible
--Function /Script/DogwoodUI.HUDManagerSubsystem:SetHUDVisible



-- GE for healing
--GE_ShadowBiteHeal_C /Game/_Dawnwalker/Combat/Focus/Vampire/ShadowstepBite/GE_ShadowBiteHeal.Default__GE_ShadowBiteHeal_C