local bosses = {}
local addon = CreateFrame("Frame")
local ssWhenOOC = nil
local db = {}

addon:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
addon:RegisterEvent("PLAYER_LEVEL_UP")
addon:RegisterEvent("ACHIEVEMENT_EARNED")
addon:RegisterEvent("PLAYER_TARGET_CHANGED")
addon:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
addon:RegisterEvent("PLAYER_REGEN_ENABLED")
addon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
addon:RegisterEvent("ADDON_LOADED")

function addon:ADDON_LOADED(mod)
	if mod ~= "PaparazziGnome" then return end
	self:UnregisterEvent("ADDON_LOADED")
	PaparazziGnomeDB = PaparazziGnomeDB or {}
	local pName = UnitName("player")
	PaparazziGnomeDB[pName] = PaparazziGnomeDB[pName] or {}
	db = PaparazziGnomeDB[pName]
	for k in pairs(db) do
		if type(k) == "string" then
			local numericId = tonumber(k:sub(7, 10), 16)
			db[numericId] = true
			db[k] = nil
		end
	end
end


local total = 0
local lastAutoSS = 0
local function snapthatshit(self, elapsed)
	total = total + elapsed
	if total > 1.25 then
		local t = GetTime()
		if t > (lastAutoSS + 120) then
			Screenshot()
			lastAutoSS = t
		end
		total = 0
		self:SetScript("OnUpdate", nil)
	end
end

local function targetCheck(unit)
	local c = UnitClassification(unit)
	if c ~= "worldboss" then return end
	local id = UnitGUID(unit)
	if not id then return end
	bosses[id] = true
end
function addon:UPDATE_MOUSEOVER_UNIT() targetCheck("mouseover") end
function addon:PLAYER_TARGET_CHANGED() targetCheck("target") end
function addon:PLAYER_LEVEL_UP() self:SetScript("OnUpdate", snapthatshit) end
function addon:ACHIEVEMENT_EARNED() self:SetScript("OnUpdate", snapthatshit) end

function addon:COMBAT_LOG_EVENT_UNFILTERED(_, event, _, _, _, _, _, dGuid)
	if event ~= "UNIT_DIED" or UnitIsDeadOrGhost("player") or not bosses[dGuid] then return end
	local type, _, _, _, _, cid = strsplit("-", dguid or "")
	local numericId = type and (type == "Creature" or type == "Vehicle" or type == "Pet") and tonumber(cid) or 0
	-- Because of this, we no longer screenshot on new boss kills if the player is dead,
	-- but I can't be arsed to add a "is raid in combat" scan right now.
	if db[numericId] then return end
	db[numericId] = true
	if InCombatLockdown() then
		ssWhenOOC = true
	else
		self:SetScript("OnUpdate", snapthatshit)
	end
end

function addon:PLAYER_REGEN_ENABLED()
	if ssWhenOOC then
		self:SetScript("OnUpdate", snapthatshit)
		ssWhenOOC = nil
	end
end

