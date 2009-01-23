--{{{ Libraries

local RL = AceLibrary("Roster-2.1")
local Aura = AceLibrary("SpecialEvents-Aura-2.0")
local L = AceLibrary("AceLocale-2.2"):new("GridStatusHealthFade")

--}}}

--{{{ Libraries

L:RegisterTranslations("enUS", function()
	return {
		["Health Fade"] = true,
		["HP fade threshold"] = true,
		["Set the HP % for the HP fade."] = true,
		["Color 2"] = true,
		["Color 2 for HP Fade"] = true,
	}
end)

--}}}

GridStatusHealthFade = GridStatus:NewModule("GridStatusHealthFade")
GridStatusHealthFade.menuName = L["Health Fade"]
GridStatusHealthFade.options = false

--{{{ AceDB defaults

GridStatusHealthFade.defaultDB = {
	debug = false,
	alert_healthFade = {
		text = L["Health Fade"],
		enable = true,
		color = { r = 0.2, g = 0, b = 0, a = 1 },
		color2 = { r = 1, g = 0, b = 0, a = 1 },
		priority = 99,
		threshold = 80,
		range = true,
	},
}

--}}}

--{{{ AceOptions table

local alert_healthFadeOptions = {
	["threshold"] = {
		type = "range",
		name = L["HP fade threshold"],
		desc = L["Set the HP % for the HP fade."],
		max = 1,
		min = 0,
		step = 0.01,
		isPercent = true,
		get = function ()
			return GridStatusHealthFade.db.profile.alert_healthFade.threshold
		end,
		set = function (v)
			GridStatusHealthFade.db.profile.alert_healthFade.threshold = v
			GridStatusHealthFade:UpdateAllUnits()
		end,
	},
	["color2"] = {
		type = "color",
		name = L["Color 2"],
		desc = L["Color 2 for HP Fade"],
		hasAlpha = true,
		get = function ()
			local color = GridStatusHealthFade.db.profile.alert_healthFade.color2
			return color.r, color.g, color.b, color.a
		end,
		set = function (r, g, b, a)
			local color = GridStatusHealthFade.db.profile.alert_healthFade.color2
			color.r = r
			color.g = g
			color.b = b
			color.a = a or 1
		end,
	},
}

function GridStatusHealthFade:OnInitialize()
	self.super.OnInitialize(self)
	self:RegisterStatus("alert_healthFade", L["Health Fade"], alert_healthFadeOptions, true)
end

function GridStatusHealthFade:OnEnable()
	self:RegisterEvent("Grid_UnitJoined")
	self:RegisterEvent("Grid_UnitChanged")
	self:RegisterBucketEvent("UNIT_HEALTH", 0.2)
end

function GridStatusHealthFade:Reset()
	self.super.Reset(self)
	self:UpdateAllUnits()
end

function GridStatusHealthFade:UpdateAllUnits()
	local name, status, statusTbl

	for name, status, statusTbl in self.core:CachedStatusIterator("alert_healthFade") do
		self:Grid_UnitJoined(name)
	end
end

function GridStatusHealthFade:UNIT_HEALTH(units)
	local unitid

	for unitid in pairs(units) do
		self:UpdateUnit(unitid)
	end
end

function GridStatusHealthFade:Grid_UnitJoined(name, unitid)
	if unitid then
		self:UpdateUnit(unitid, true)
		self:UpdateUnit(unitid)
	end

end

function GridStatusHealthFade:Grid_UnitChanged(name, unitid)
	self:UpdateUnit(unitid)
end

function GridStatusHealthFade:UpdateUnit(unitid, ignoreRange)
	local cur, max = UnitHealth(unitid), UnitHealthMax(unitid)
	local threshold = cur / max
	local name = UnitName(unitid)
	local settings = self.db.profile.alert_healthFade

	if not name then return end

	if threshold <= settings.threshold and
		not UnitIsDeadOrGhost(unitid) then
		local color = {}
		color.r = (settings.color.r * threshold) + (settings.color2.r * (1 - threshold))
		color.g = (settings.color.g * threshold) + (settings.color2.g * (1 - threshold))
		color.b = (settings.color.b * threshold) + (settings.color2.b * (1 - threshold))
		color.a = (settings.color.a * threshold) + (settings.color2.a * (1 - threshold))

		self.core:SendStatusGained(name, "alert_healthFade",
			settings.priority,
			(settings.range and 40),
			color,
			math.ceil((threshold / settings.threshold) * 100).."%",
			threshold ,
			settings.threshold,
			settings.icon)
	else
		self.core:SendStatusLost(name, "alert_healthFade")
	end
end