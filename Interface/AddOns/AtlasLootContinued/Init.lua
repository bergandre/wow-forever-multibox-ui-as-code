-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)
local tonumber = _G.tonumber
local ipairs = _G.ipairs

-- ----------------------------------------------------------------------------
-- AddOn namespace.
-- ----------------------------------------------------------------------------
local addonname, ALPrivate = ...

-----------------------------------------------------------------------
-- AddOn version handling (fixed)
-----------------------------------------------------------------------

local GetAddOnMetadata = ALPrivate.Compat.GetAddOnMetadata
local addonVersion = GetAddOnMetadata(addonname, "Version")

-- The TOC placeholder is the literal "1". The build pipeline replaces it with the numeric build
-- number (e.g. "123456"), which also doubles as the sortable revision used for the version-sync
-- comm between players. Running straight from source, the placeholder is never replaced, so a
-- literal "1" is how we detect a dev build; a real build number is never "1".
local addonRevision = tonumber(addonVersion)

_G.AtlasLoot = {
	__addonrevision = addonRevision or 0,
	__addonversion  = addonVersion,

	Compat = ALPrivate.Compat,

	IsDevVersion  = addonVersion == "1",
	IsTestVersion = nil,
}

local AddonNameVersion = string.format("%s-%d", addonname, _G.AtlasLoot.__addonrevision)
local MainMT = {
	__tostring = function(self)
		return AddonNameVersion
	end,
}
setmetatable(_G.AtlasLoot, MainMT)

-- DB
AtlasLootDB                        = {}

-- Translations
_G.AtlasLoot.Locale                       = {}

-- Init functions
_G.AtlasLoot.Init                         = {}

-- Data table
_G.AtlasLoot.Data                         = {}

-- Version
local WOW_PROJECT_ID                      = _G.WOW_PROJECT_ID or 99
local WOW_PROJECT_MAINLINE                = _G.WOW_PROJECT_MAINLINE or 99
local WOW_PROJECT_CLASSIC                 = _G.WOW_PROJECT_CLASSIC or 1
local WOW_PROJECT_BURNING_CRUSADE_CLASSIC = _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 2
local WOW_PROJECT_WRATH_CLASSIC           = _G.WOW_PROJECT_WRATH_CLASSIC or 11
-- TODO: World of Warcraft: Forever - set the real WOW_PROJECT_* global (and/or its value) once known.
-- Left as nil on purpose: WOW_PROJECT_ID is always a real number in-game, so this comparison stays a safe no-op until filled in.
local WOW_PROJECT_FOREVER                 = _G.WOW_PROJECT_FOREVER or _G.WOW_PROJECT_CAMELOT

AtlasLoot.RETAIL_VERSION_NUM              = 99
AtlasLoot.CLASSIC_VERSION_NUM             = 1
AtlasLoot.BC_VERSION_NUM                  = 2
AtlasLoot.WRATH_VERSION_NUM               = 3
AtlasLoot.FOREVER_VERSION_NUM             = 4

AtlasLoot.GAME_VERSION_TEXTURES           = {
	[AtlasLoot.CLASSIC_VERSION_NUM] = (_G.C_Seasons and C_Seasons.GetActiveSeason() == 2) and 6366097 or 538639,
	[AtlasLoot.BC_VERSION_NUM] = 131194,
	[AtlasLoot.WRATH_VERSION_NUM] = 235509,
	-- Forever's own badge (Images/ForeverLogo.tga, drawn by tools/images/make_forever_logo.py). It used to reuse the
	-- Wrath logo, which confused players.
	[AtlasLoot.FOREVER_VERSION_NUM] = "Interface\\AddOns\\AtlasLootContinued\\Images\\ForeverLogo",
}

AtlasLoot.IS_CLASSIC                      = false
AtlasLoot.IS_BC                           = false
AtlasLoot.IS_WRATH                        = false
AtlasLoot.IS_RETAIL                       = false
AtlasLoot.IS_FOREVER                      = false

local CurrentGameVersion                  = AtlasLoot.RETAIL_VERSION_NUM
-- World of Warcraft: Forever has no WOW_PROJECT_* constant of its own and
-- reports WOW_PROJECT_ID == WOW_PROJECT_MAINLINE. This addon only ever
-- targets Forever, never real retail, so treat every Mainline-flavored
-- client as Forever (the WOW_PROJECT_FOREVER check stays first in case
-- Blizzard ever adds a real constant for it).
if WOW_PROJECT_ID == WOW_PROJECT_FOREVER or WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	CurrentGameVersion = AtlasLoot.FOREVER_VERSION_NUM
	AtlasLoot.IS_FOREVER = true
elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
	if LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_WRATH_OF_THE_LICH_KING then
		CurrentGameVersion = AtlasLoot.WRATH_VERSION_NUM
		AtlasLoot.IS_WRATH = true
	elseif LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_BURNING_CRUSADE then
		CurrentGameVersion = AtlasLoot.BC_VERSION_NUM
		AtlasLoot.IS_BC = true
	end
elseif WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
	CurrentGameVersion = AtlasLoot.WRATH_VERSION_NUM
	AtlasLoot.IS_WRATH = true
elseif WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
	CurrentGameVersion = AtlasLoot.CLASSIC_VERSION_NUM
	AtlasLoot.IS_CLASSIC = true
end

AtlasLoot.CURRENT_VERSION_NUM = CurrentGameVersion

function AtlasLoot:GetGameVersion()
	return CurrentGameVersion
end

-- Which content each client has. The version numbers say which client this is, not which content comes after which:
-- Forever is built on Classic and has no TBC or Wrath content, so "TBC or later" has to be false there although
-- 4 > 2. GameVersion_GE/GT/LE/LT therefore ask whether the current client has the content of a version instead of
-- comparing numbers. A client that is not listed (an unknown one) falls back to comparing the numbers.
local CLIENT_CONTENT = {
	[AtlasLoot.CLASSIC_VERSION_NUM] = { [AtlasLoot.CLASSIC_VERSION_NUM] = true },
	[AtlasLoot.BC_VERSION_NUM]      = { [AtlasLoot.CLASSIC_VERSION_NUM] = true, [AtlasLoot.BC_VERSION_NUM] = true },
	[AtlasLoot.WRATH_VERSION_NUM]   = { [AtlasLoot.CLASSIC_VERSION_NUM] = true, [AtlasLoot.BC_VERSION_NUM] = true, [AtlasLoot.WRATH_VERSION_NUM] = true },
	[AtlasLoot.FOREVER_VERSION_NUM] = { [AtlasLoot.CLASSIC_VERSION_NUM] = true, [AtlasLoot.FOREVER_VERSION_NUM] = true },
}

local function ClientHasContent(gameVersion)
	local content = CLIENT_CONTENT[CurrentGameVersion]
	if content then
		return content[gameVersion] == true
	end
	return CurrentGameVersion >= gameVersion
end

-- equal
function AtlasLoot:GameVersion_EQ(gameVersion, ret, retFalse)
	if CurrentGameVersion == gameVersion then
		return ret or true
	else
		return retFalse
	end
end

-- not equal
function AtlasLoot:GameVersion_NE(gameVersion, ret, retFalse)
	if CurrentGameVersion ~= gameVersion then
		return ret or true
	else
		return retFalse
	end
end

-- has more content than gameVersion (its content, and more)
function AtlasLoot:GameVersion_GT(gameVersion, ret, retFalse)
	if CurrentGameVersion ~= gameVersion and ClientHasContent(gameVersion) then
		return ret or true
	else
		return retFalse
	end
end

-- does not have the content of gameVersion
function AtlasLoot:GameVersion_LT(gameVersion, ret, retFalse)
	if not ClientHasContent(gameVersion) then
		return ret or true
	else
		return retFalse
	end
end

-- has the content of gameVersion
function AtlasLoot:GameVersion_GE(gameVersion, ret, retFalse)
	if ClientHasContent(gameVersion) then
		return ret or true
	else
		return retFalse
	end
end

-- does not have more content than gameVersion
function AtlasLoot:GameVersion_LE(gameVersion, ret, retFalse)
	if CurrentGameVersion == gameVersion or not ClientHasContent(gameVersion) then
		return ret or true
	else
		return retFalse
	end
end

-- The client has the systems that arrived with Wrath: achievements, companion tracking, the newer model viewer. That is
-- about the client, not the content: Forever is a modern client that has them although it has no Wrath content, so it
-- cannot be asked with GameVersion_GE(WRATH_VERSION_NUM), which is about content.
function AtlasLoot:ClientHasWrathSystems(ret, retFalse)
	if self:GameVersion_GE(self.WRATH_VERSION_NUM) or self:GameVersion_EQ(self.FOREVER_VERSION_NUM) then
		return ret or true
	else
		return retFalse
	end
end

-- Forever's client drops the legacy GetFactionInfoByID global in favor of
-- C_Reputation.GetFactionDataByID. Polyfill the old multi-return shape so
-- every existing call site (Button/Faction_type.lua, ItemDB/ItemDB.lua,
-- and the Collections data files) keeps working unchanged.
if not _G.GetFactionInfoByID and _G.C_Reputation and _G.C_Reputation.GetFactionDataByID then
	_G.GetFactionInfoByID = function(factionID)
		local factionData = C_Reputation.GetFactionDataByID(factionID)
		if not factionData then return end
		return factionData.name, factionData.description, factionData.reaction,
			factionData.currentReactionThreshold, factionData.nextReactionThreshold,
			factionData.currentStanding, factionData.atWarWith, factionData.canToggleAtWar
	end
end
