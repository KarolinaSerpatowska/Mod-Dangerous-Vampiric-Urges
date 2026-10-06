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
         return string.find(Object:GetFullName(), "BP_PlayerCharacter_C_", 1, true) ~= nil 
    end
end

------------------------------------------------------------
-- FIND PLAYER
------------------------------------------------------------

function helpers.FIND_PLAYER()

    local player = nil
    pcall(function()
        local controller = UEHelpers.GetPlayerController
        if helpers.IS_VALID(controller) then
           player = controller.GetPawn
        end
    end)
    --found player
    if helpers.IS_VALID(player) then
        return player
    end
    

    --2 attempt
    pcall(function()
        player = FindFirstOf("BP_PlayerCharacter_C")
    end)

    --found player
    if helpers.IS_VALID(player) then   
        return player
    end


    --3 attempt
    local Candidates = nil
    pcall(function()
        Candidates = FindAllOf("BP_PlayerCharacter_C")
    end)
    if helpers.IS_VALID(Candidates) then
        for _, Candidate in ipairs(Candidates) do
            if helpers.IS_PLAYER_PAWN(Candidate) then
                local Controller = nil
                pcall(function()
                    Controller = Candidate:GetController()
                end)
                if helpers.IS_VALID(Controller) then
                    helpers.PRINT_MSG("Player found (FindAllOf recovery)")
                    return Candidate
                end
            end
        end
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
    
    if helpers.isVampire then
        helpers.PRINT_MSG("Player is vampire")
    end

end
------------------------------------------------------------
-- FIND HUNGER SYSTEM
------------------------------------------------------------
function helpers.FIND_HUNGER_SYS()
    if helpers.IS_VALID(helpers.hungerSystem) then return end
    pcall(function() 
        helpers.hungerSystem = FindFirstOf("VampireHungerSubsystem")
    end)
    if not helpers.IS_VALID(helpers.hungerSystem) then helpers.PRINT_MSG("Hunger system not found") return end
    helpers.PRINT_MSG("Hunger system found")
end



return helpers