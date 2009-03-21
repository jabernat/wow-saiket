--[[****************************************************************************
  * oUF_SpellRange by Saiket                                                   *
  * oUF_SpellRange.lua - Improved range element for oUF.                       *
  *                                                                            *
  * Elements handled: .SpellRange                                              *
  * Settings:                                                                  *
  *   - inRangeAlpha - Frame alpha value for units in range. (Required)        *
  *   - outsideRangeAlpha - Frame alpha for units out of range. (Required)     *
  * Note that SpellRange will automatically disable Range elements of frames.  *
  ****************************************************************************]]


local UpdateRate = 0.1;

local UpdateFrame;
local Objects = {};

-- Class-specific spell info
local HelpID, HelpName;
local HarmID, HarmName;




--[[****************************************************************************
  * Function: local IsInRange                                                  *
  ****************************************************************************]]
local IsInRange;
do
	local UnitIsConnected = UnitIsConnected;
	local UnitCanAssist = UnitCanAssist;
	local UnitCanAttack = UnitCanAttack;
	local UnitIsUnit = UnitIsUnit;
	local UnitPlayerOrPetInRaid = UnitPlayerOrPetInRaid;
	local UnitIsDead = UnitIsDead;
	local UnitOnTaxi = UnitOnTaxi;
	local UnitInRange = UnitInRange;
	local IsSpellInRange = IsSpellInRange;
	local CheckInteractDistance = CheckInteractDistance;
	function IsInRange ( UnitID )
		if ( UnitIsConnected( UnitID ) ) then
			if ( UnitCanAssist( "player", UnitID ) ) then
				if ( HelpName and not UnitIsDead( UnitID ) ) then
					return IsSpellInRange( HelpName, UnitID ) == 1;
				elseif ( not UnitOnTaxi( "player" ) -- UnitInRange always returns nil while on flightpaths
					and ( UnitIsUnit( UnitID, "player" ) or UnitIsUnit( UnitID, "pet" )
						or UnitPlayerOrPetInParty( UnitID ) or UnitPlayerOrPetInRaid( UnitID ) )
				) then
					return UnitInRange( UnitID ); -- Fast checking for self and party members (38 yd range)
				end
			elseif ( HarmName and not UnitIsDead( UnitID ) and UnitCanAttack( "player", UnitID ) ) then
				return IsSpellInRange( HarmName, UnitID ) == 1;
			end

			-- Fallback when spell not found or class uses none
			return CheckInteractDistance( UnitID, 4 ); -- Follow distance (28 yd range)
		end
	end
end
--[[****************************************************************************
  * Function: local UpdateRange                                                *
  ****************************************************************************]]
local function UpdateRange ( self )
	self:SetAlpha( self[ IsInRange( self.unit ) and "inRangeAlpha" or "outsideRangeAlpha" ] );
end
--[[****************************************************************************
  * Function: local UpdateSpells                                               *
  ****************************************************************************]]
local function UpdateSpells ()
	if ( HelpID ) then
		HelpName = GetSpellInfo( HelpID );
	end
	if ( HarmID ) then
		HarmName = GetSpellInfo( HarmID );
	end
end


--[[****************************************************************************
  * Function: local OnUpdate                                                   *
  ****************************************************************************]]
local OnUpdate;
do
	local NextUpdate = 0;
	function OnUpdate ( self, Elapsed )
		NextUpdate = NextUpdate - Elapsed;
		if ( NextUpdate <= 0 ) then
			NextUpdate = UpdateRate;

			UpdateSpells();
			for Object in pairs( Objects ) do
				if ( Object:IsVisible() ) then
					UpdateRange( Object );
				end
			end
		end
	end
end


--[[****************************************************************************
  * Function: local Enable                                                     *
  ****************************************************************************]]
local function Enable ( self, UnitID )
	if ( self.SpellRange ) then
		if ( self.Range ) then -- Disable default range checking
			self:DisableElement( "Range" );
			self.Range = nil;
		end

		if ( not UpdateFrame ) then
			UpdateFrame = CreateFrame( "Frame" );
			UpdateFrame:SetScript( "OnUpdate", OnUpdate );
		else
			UpdateFrame:Show();
		end
	end
	Objects[ self ] = true;
	return true;
end
--[[****************************************************************************
  * Function: local Disable                                                    *
  ****************************************************************************]]
local function Disable ( self )
	Objects[ self ] = nil;
	if ( not next( Objects ) ) then
		UpdateFrame:Hide();
	end
end
--[[****************************************************************************
  * Function: local Update                                                     *
  ****************************************************************************]]
local function Update ( self, Event, UnitID )
	if ( Event ~= "OnTargetUpdate" ) then -- Caused by a real event
		UpdateSpells();
		UpdateRange( self ); -- Update range immediately
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	local Class = select( 2, UnitClass( "player" ) );
	-- Optional low level baseline skills with greater than 28 yard range
	HelpID = ( {
		DEATHKNIGHT = 61999; -- Raise Ally
		DRUID = 5185; -- Healing Touch
		MAGE = 1459; -- Arcane Intellect
		PALADIN = 635; -- Holy Light
		PRIEST = 585; -- Smite
		SHAMAN = 331; -- Healing Wave
		WARLOCK = 5697; -- Unending Breath
	} )[ Class ];
	HarmID = ( {
		DEATHKNIGHT = 52375; -- Death Coil
		DRUID = 5176; -- Wrath
		HUNTER = 75; -- Auto Shot
		MAGE = 133; -- Fireball
		PALADIN = 62124; -- Hand of Reckoning
		PRIEST = 2050; -- Lesser Heal
		SHAMAN = 403; -- Lightning Bolt
		WARLOCK = 686; -- Shadow Bolt
		WARRIOR = 355; -- Taunt
	} )[ Class ];

	oUF:AddElement( "SpellRange", Update, Enable, Disable );
end
