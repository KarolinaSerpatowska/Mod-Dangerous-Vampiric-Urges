helpers = {}

helpers.isVampire = false
helpers.hungerSystem = nil

config = require("config")
UEHelpers = require("UEHelpers")
------------------------------------------------------------
-- HELPING FUNCTIONS
------------------------------------------------------------

function helpers.PRINT_MSG(Msg)
    if config.debug then
        print("[Dangerous Vampiric Urges] " .. tostring(Msg) .. "\n")
    end
end

function helpers.IS_VALID(obj)
    if obj == nil then return false end
    local ok, v = pcall(function() return obj:IsValid() end)
    return ok and v
end

function helpers.IS_PLAYER_PAWN(Object)
    if Object == nil then return nil end
    local Success, Result = pcall(function() return Object:GetFullName() end)
    if Success and Result ~= nil then
        helpers.PRINT_MSG(Object:GetFullName()) 
        return string.find(Object:GetFullName(), "BP_PlayerCharacter_C_", 1, true) ~= nil 
    end
end

------------------------------------------------------------
-- FIND PLAYER
------------------------------------------------------------

function helpers.FIND_PLAYER()

    local player = nil

    local controller = UEHelpers.GetPlayerController()

    if helpers.IS_VALID(controller) and helpers.IS_VALID(controller.Pawn) and helpers.IS_PLAYER_PAWN(controller.Pawn) then
        player = controller.Pawn
        helpers.PRINT_MSG(player:GetFullName())
        helpers.CHECK_VAMPIRE(player)
        return player
    end
    
    --player not found
    helpers.PRINT_MSG("PLAYER NOT FOUND!!!")
    return nil
end

------------------------------------------------------------
-- CHECK FOR MAIN MENU
------------------------------------------------------------
function helpers.IS_MAIN_MENU_PRESENT()
    local mainMenu = nil
    pcall(function() mainMenu = FindFirstOf("BP_MainMenuPawn_C") end)
    if not helpers.IS_VALID(mainMenu) then
        -- no main menu
        return false
    end

    return true
end

------------------------------------------------------------
-- CHECK IF PLAYER IS VAMPIRE
------------------------------------------------------------
function helpers.CHECK_VAMPIRE(player)
    if not helpers.IS_VALID(player) then
        helpers.PRINT_MSG("Missing player")
        return false
    end

    pcall(function() helpers.isVampire = player:IsVampire() end)
    
    if not helpers.isVampire then
        helpers.PRINT_MSG("Player: Human")
    end

    if helpers.isVampire then
        helpers.PRINT_MSG("Player: Vampire")
    end

end
------------------------------------------------------------
-- FIND HUNGER SYSTEM
------------------------------------------------------------
function helpers.FIND_HUNGER_SYS()
    if helpers.IS_VALID(helpers.hungerSystem) then  helpers.PRINT_MSG("Hunger sys valid no need for looking") return end
    pcall(function() 
        helpers.hungerSystem = FindFirstOf("VampireHungerSubsystem")
    end)
    if not helpers.IS_VALID(helpers.hungerSystem) then helpers.PRINT_MSG("Hunger system not found") return end
    helpers.PRINT_MSG("Hunger system found")
end



return helpers