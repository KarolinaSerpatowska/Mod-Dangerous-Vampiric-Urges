customHunger = {}


helpers = require("helperFunc")
config = require("config")

local AssetRegistryHelpers = nil
local AssetRegistry = nil

-- /Game/Mods/DangerousVampiricUrges/WBP_BloodWidget
local modNameNoExtension = "DangerousVampiricUrges"

local hungerBarAsset = nil

customHunger.hungerBarWidget = nil

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


    
    helpers.PRINT_MSG(string.format("znaleziono: %s", hud:GetFullName()))

  
  --VerticalBox /Engine/Transient.GameEngine_2147482572:BP_GameInstance_C_2147482521.WBP_UIFrontend_C_2147479937.WidgetTree_2147479936.WBP_GameHUD_C_2147446531.WidgetTree_2147446530.VampireStats.WidgetTree_2147446455.VerticalBox_20
    -- local path = "/Game/_Dawnwalker/UI/_Unified/HUD/PlayerStatPanel/WBP_HUD_VampireStats.WBP_HUD_VampireStats_C:WidgetTree.Overlay_0"
    --/Engine/Transient.GameEngine_2147482572:BP_GameInstance_C_2147482521.WBP_UIFrontend_C_2147479937.WidgetTree_2147479936.WBP_GameHUD_C_2147446539.WidgetTree_2147446538.VampireStats.WidgetTree_2147446463.WBP_HUD_VampireStats_BloodSegment_C_2147445961.WidgetTree_2147445960.HeightConstrainer
    --WBP_HUD_VampireStats_C /Game/_Dawnwalker/UI/_Unified/HUD/WBP_GameHUD.WBP_GameHUD_C:WidgetTree.VampireStats
    --Overlay /Game/_Dawnwalker/UI/_Unified/HUD/PlayerStatPanel/WBP_HUD_VampireStats.WBP_HUD_VampireStats_C:WidgetTree.Overlay_0
    --Overlay /Game/_Dawnwalker/UI/_Unified/HUD/PlayerStatPanel/WBP_HUD_VampireStats_BloodSegment.WBP_HUD_VampireStats_BloodSegment_C:WidgetTree.Overlay_42

  
    local root = hud.VampireStats.WidgetTree.RootWidget
    
    helpers.PRINT_MSG(string.format("znaleziono: %s", root:GetFullName()))
    helpers.PRINT_MSG("WIDGET DOESNT HAVE PARENT")

    local a,b = pcall(function() root:AddChild(customHunger.hungerBarWidget) end)
        
    helpers.PRINT_MSG(a)
    helpers.PRINT_MSG(b)
    helpers.PRINT_MSG("WIDGET ADDED")

    --debug
    if helpers.IS_VALID(customHunger.hungerBarWidget:GetParent()) then
        helpers.PRINT_MSG("WIDGET HAS PARENT - no adding")
    end

end

function customHunger.INIT_HUNGER_BAR(player)
    if not helpers.IS_VALID(player) then helpers.PRINT_MSG("INIT BAR: no player") return end
    if not helpers.IS_VALID(player.BloodBar) then helpers.PRINT_MSG("INIT BAR: no blood bar") return end
    if not helpers.IS_VALID(customHunger.hungerBarWidget) then helpers.PRINT_MSG("INIT BAR: widget not valid") return end

    
    local maxHungerAmount = player.BloodBar:GetBloodBarLength()

    if maxHungerAmount == 0 then
        helpers.PRINT_MSG("INIT BAR: blood bar is zero")
        return
    end

    local currentHungerAmount = maxHungerAmount / 2

    pcall(function() 
        customHunger.hungerBarWidget:SetCurrentBarValue(currentHungerAmount, maxHungerAmount)
    end)
    
    

end

function customHunger.REMOVE_FROM_VIEWPORT()
    if not helpers.IS_VALID(customHunger.hungerBarWidget) then return end
    if not helpers.IS_VALID(customHunger.hungerBarWidget:GetParent()) then
        helpers.PRINT_MSG("WIDGET DOESNT HAVE PARENT - removing")
        customHunger.hungerBarWidget:RemoveFromParent()
        helpers.PRINT_MSG("widget removed")
    end

end

-- Function /Game/Mods/DangerousVampiricUrges/WBP_BloodWidget.WBP_BloodWidget_C:ChangeScale
--Function /Game/Mods/DangerousVampiricUrges/WBP_BloodWidget.WBP_BloodWidget_C:SetCurrentBarValue
--HUDManagerSubsystem /Game/Map_Blockout_Valley/Blockout_Valley.Blockout_Valley:HUDManagerSubsystem_2147401949

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



return customHunger


--VampireStats
--Function /Script/DogwoodUI.HUDManagerSubsystem:IsHUDVisible
--Function /Script/DogwoodUI.HUDManagerSubsystem:SetHUDVisible
--Function /Game/_Dawnwalker/UI/_Unified/HUD/PlayerStatPanel/WBP_HUD_VampireStats_BloodSegment.WBP_HUD_VampireStats_BloodSegment_C:CalculateAndShowCostPercentage
--WidgetBlueprintGeneratedClass /Game/_Dawnwalker/UI/_Unified/HUD/WBP_GameHUD.WBP_GameHUD_C