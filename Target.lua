local addonName = ...

local LibEvent = LibStub:GetLibrary("LibEvent.7000")

local YOU = YOU
local NONE = NONE
local EMPTY = EMPTY
local TARGET = TARGET
local TOOLTIP_UPDATE_TIME = TOOLTIP_UPDATE_TIME or 0.2

local addon = TinyTooltip

local function GetTargetString(unit)
    if (not UnitExists(unit)) then return end
    local name = UnitName(unit)
    local icon = addon:GetRaidIcon(unit) or ""
    local scrubbedUnitIsUnit = scrubsecretvalues(UnitIsUnit(unit, "player"))
    --if UnitIsUnit(unit, "player") then
    if scrubbedUnitIsUnit then
        return format("|cffff3333>>%s<<|r", strupper(YOU))
    elseif UnitIsPlayer(unit) then
        local class = select(2, UnitClass(unit))
        local colorCode = C_ClassColor.GetClassColor(class):GenerateHexColor()
        --local colorCode = select(4, GetClassColor(class))
        return format("%s|c%s%s|r", icon, colorCode, name)
    elseif UnitIsOtherPlayersPet(unit) then
        return format("%s|cff%s<%s>|r", icon, addon:GetHexColor(GameTooltip_UnitColor(unit)), name)
    else
        return format("%s|cff%s[%s]|r", icon, addon:GetHexColor(GameTooltip_UnitColor(unit)), name)
    end
end

-- I hate doing this, but it's the only way I can avoid secret issues
-- Blizzard doesn't want us scanning the tooltip, but won't provide a 'safe' section of the tooltip for us to use
----[[
local combatTargetTooltip = CreateFrame("GameTooltip", addonName.."CombatTargetTooltip", GameTooltip, "GameTooltipTemplate")
combatTargetTooltip:SetOwner(GameTooltip, "ANCHOR_BOTTOM", 0, -50)
combatTargetTooltip:ClearLines()
if addon.db.general.bodyFontSize == "default" then
	local fontInfo = GetFontInfo(GameTooltipText)
	_G[combatTargetTooltip:GetName().."TextLeft1"]:SetFont(fontInfo.fontObject:GetFont(), fontInfo.height, "")
else
    combatTargetTooltip:SetFontHeight(addon.db.general.bodyFontSize)
end
GameTooltip:HookScript("OnHide", function() combatTargetTooltip:Hide() end)
GameTooltip:HookScript("OnTooltipCleared", function() combatTargetTooltip:Hide() end)
--]]

GameTooltip:HookScript("OnUpdate", function(self, elapsed)
    self.updateElapsed = (self.updateElapsed or 0) + elapsed
    if (self.updateElapsed >= TOOLTIP_UPDATE_TIME) then
        self.updateElapsed = 0
        if (not UnitExists("mouseover")) then return end
        if (addon.db.unit.player.showTarget and UnitIsPlayer("mouseover"))
            or (addon.db.unit.npc.showTarget and not UnitIsPlayer("mouseover")) then
            local line = addon:FindLine(self, "^"..TARGET..":")
            local text = GetTargetString("mouseovertarget")
            local isSecretTime = not canaccessvalue(_G[self:GetName().."TextLeft1"]:GetText())
            if isSecretTime then
				-- When the tooltip is secret, we use a custom target tooltip
				combatTargetTooltip:Show()
                if text then
					combatTargetTooltip:SetOwner(GameTooltip, "ANCHOR_BOTTOM", 0, -3)
					combatTargetTooltip:ClearLines()
					combatTargetTooltip:AddLine(format("%s: %s", TARGET, text))
					combatTargetTooltip:Show()
				else
					combatTargetTooltip:Hide()
                end
            elseif (line and not text) then
                addon:HideLine(self, "^"..TARGET..":")
                self:Show()
            elseif (not line and text) then
                self:AddLine(format("%s: %s", TARGET, text))
                self:Show()
            elseif (line) then
                line:SetFormattedText("%s: %s", TARGET, text)
            end
        end
    end
end)

-- Targeted By

local function GetTargetByString(mouseover, num, tip)
    local count, prefix = 0, IsInRaid() and "raid" or "party"
    local roleIcon, colorCode, name
    local first = true
    local isPlayer = UnitIsPlayer(mouseover)
    for i = 1, num do
        if UnitIsUnit(mouseover, prefix..i.."target") and not UnitIsUnit(prefix..i, "player") then
            count = count + 1
            if (isPlayer or prefix == "party") then
                if (first) then
                    tip:AddLine(format("%s:", addon.L and addon.L.TargetBy or "Targeted By"))
                    first = false
                end
                roleIcon  = addon:GetRoleIcon(prefix..i) or ""
                colorCode = select(4,GetClassColor(select(2,UnitClass(prefix..i))))
                name      = UnitName(prefix..i)
                tip:AddLine("   " .. roleIcon .. " |c" .. colorCode .. name .. "|r")
            end
        end
    end
    if (count > 0 and not isPlayer and prefix ~= "party") then
        return format("|cff33ffff%s|r", count)
    end
end

LibEvent:attachTrigger("tooltip:unit", function(self, tip, unit)
    if (tip:IsUnit("mouseover")) then
        local num = GetNumGroupMembers()
        if (num >= 1) and
          ((addon.db.unit.player.showTargetBy and UnitIsPlayer("mouseover"))
          or (addon.db.unit.npc.showTargetBy and not UnitIsPlayer("mouseover"))) then
            local text = GetTargetByString("mouseover", num, tip)
            if (text) then
                tip:AddLine(format("%s: %s", addon.L and addon.L.TargetBy or "Targeted By", text), nil, nil, nil, true)
            end
        end
    end
end)
