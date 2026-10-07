customHunger = {}


helpers = require("helperFunc")
config = require("config")

local AssetRegistryHelpers = nil
local AssetRegistry = nil

-- /Game/Mods/test/WBP_BloodWidget
local modNameNoExtension = "test"

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
    --this works
    --if not hungerBarAsset:IsValid() then
       -- helpers.PRINT_MSG(string.format("hunger bar asset is not valid"))
      --  return
    --end
    
    --this i don't know
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
    local WidgetBlueprintLibrary = StaticFindObject("/Script/UMG.WidgetBlueprintLibrary")
    if not helpers.IS_VALID(WidgetBlueprintLibrary) then helpers.PRINT_MSG("WidgetBPLibrary not valid") return end
    

    local controller = UEHelpers.GetPlayerController()
    local world
    pcall(function() world = controller:GetWorld() end)

    --create new widget only if it doesnt exist
    if not helpers.IS_VALID(customHunger.hungerBarWidget) then
        customHunger.hungerBarWidget = WidgetBlueprintLibrary:Create(world, hungerBarAsset, controller)
    end
    

    --add to viewport
    if helpers.IS_VALID(customHunger.hungerBarWidget) then
         customHunger.hungerBarWidget:AddToViewport(0)
    end

end








return customHunger
