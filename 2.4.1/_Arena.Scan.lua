--[[****************************************************************************
  * _Arena by Saiket                                                           *
  * _Arena.Scan.lua - Scans unit tooltips to find group composition.           *
  ****************************************************************************]]


local _Arena = _Arena;
local L = _ArenaLocalization;
local me = CreateFrame( "GameTooltip", "_ArenaScan" );
_Arena.Scan = me;


-- Table of known found classes, reset per arena match
me.Results = {
	DRUID   = { Count = 0; Specs = { BALANCE       = false; FERAL        = false; RESTORATION = false; }; Wells = 0; Players = {}; Pets = {}; };
	HUNTER  = { Count = 0; Specs = { BEASTMASTERY  = false; MARKSMANSHIP = false; SURVIVAL    = false; }; Wells = 0; Players = {}; Pets = {}; };
	MAGE    = { Count = 0; Specs = { ARCANE        = false; FIRE         = false; FROST       = false; }; Wells = 0; Players = {}; Pets = {}; };
	PALADIN = { Count = 0; Specs = { HOLY          = false; PROTECTION   = false; RETRIBUTION = false; }; Wells = 0; Players = {}; Pets = {}; };
	PRIEST  = { Count = 0; Specs = { SHADOW        = false; DISCIPLINE   = false; HOLY        = false; }; Wells = 0; Players = {}; Pets = {}; };
	ROGUE   = { Count = 0; Specs = { ASSASSINATION = false; COMBAT       = false; SUBTLETY    = false; }; Wells = 0; Players = {}; Pets = {}; };
	SHAMAN  = { Count = 0; Specs = { ELEMENTAL     = false; ENHANCEMENT  = false; RESTORATION = false; }; Wells = 0; Players = {}; Pets = {}; };
	WARLOCK = { Count = 0; Specs = { AFFLICTION    = false; DEMONOLOGY   = false; DESTRUCTION = false; }; Wells = 0; Players = {}; Pets = {}; };
	WARRIOR = { Count = 0; Specs = { ARMS          = false; FURY         = false; PROTECTION  = false; }; Wells = 0; Players = {}; Pets = {}; };
};

-- Temporary table of found buffs
local BuffResults = {
	DRUID   = { Count = 0; Specs = { BALANCE       = false; FERAL        = false; RESTORATION = false; }; Groups = {}; };
	HUNTER  = { Count = 0; Specs = { BEASTMASTERY  = false; MARKSMANSHIP = false; SURVIVAL    = false; }; Groups = {}; };
	MAGE    = { Count = 0; Specs = { ARCANE        = false; FIRE         = false; FROST       = false; }; Groups = {}; };
	PALADIN = { Count = 0; Specs = { HOLY          = false; PROTECTION   = false; RETRIBUTION = false; }; Groups = {}; };
	PRIEST  = { Count = 0; Specs = { SHADOW        = false; DISCIPLINE   = false; HOLY        = false; }; Groups = {}; };
	ROGUE   = { Count = 0; Specs = { ASSASSINATION = false; COMBAT       = false; SUBTLETY    = false; }; Groups = {}; };
	SHAMAN  = { Count = 0; Specs = { ELEMENTAL     = false; ENHANCEMENT  = false; RESTORATION = false; }; Groups = {}; };
	WARLOCK = { Count = 0; Specs = { AFFLICTION    = false; DEMONOLOGY   = false; DESTRUCTION = false; }; Groups = {}; };
	WARRIOR = { Count = 0; Specs = { ARMS          = false; FURY         = false; PROTECTION  = false; }; Groups = {}; };
};
me.BuffResults = BuffResults;

-- Database of blessing name to class mappings
-- [ L[ "Buff Name" ] ] = { Class, Spec, BuffGroupName, SearchText };
local BuffData = {
	-- Druid
	[ L[ "Thorns" ] ] = { "DRUID" };
	[ L[ "Mark of the Wild" ] ] = { "DRUID" };
	[ L[ "Gift of the Wild" ] ] = { "DRUID" };
	[ L[ "Leader of the Pack" ] ] = { "DRUID", "FERAL", "AURA" };
	[ L[ "Moonkin Aura" ] ] = { "DRUID", "BALANCE", "AURA" };
	[ L[ "Tree of Life" ] ] = { "DRUID", "RESTORATION", "AURA", L[ "^Increases healing received by 25%% of the Tree of Life's total spirit%.$" ] };

	-- Hunter
	[ L[ "Trueshot Aura" ] ] = { "HUNTER", "MARKSMANSHIP", "AURA" };
	[ L[ "Aspect of the Pack" ] ] = { "HUNTER", nil, "AURA" };
	[ L[ "Aspect of Nature" ] ] = { "HUNTER", nil, "AURA" };
	[ L[ "Ferocious Inspiration" ] ] = { "HUNTER", "BEASTMASTERY" };
	-- Personal
	[ L[ "Bestial Wrath" ] ] = { "HUNTER", "BEASTMASTERY" };
	[ L[ "Ferocious Inspiration" ] ] = { "HUNTER", "BEASTMASTERY" };
	[ L[ "Master Tactician" ] ] = { "HUNTER", "SURVIVAL" };

	-- Mage
	[ L[ "Arcane Intellect" ] ] = { "MAGE" };
	[ L[ "Arcane Brilliance" ] ] = { "MAGE" };
	[ L[ "Dampen Magic" ] ] = { "MAGE" };
	[ L[ "Amplify Magic" ] ] = { "MAGE" };
	-- Personal
	[ L[ "Ice Barrier" ] ]  = { "MAGE", "FROST" };
	[ L[ "Combustion" ] ]   = { "MAGE", "FIRE" };
	[ L[ "Arcane Power" ] ] = { "MAGE", "ARCANE" };

	-- Paladin auras
	[ L[ "Devotion Aura" ] ] = { "PALADIN", nil, "AURA" };
	[ L[ "Concentration Aura" ] ] = { "PALADIN", nil, "AURA" };
	[ L[ "Crusader Aura" ] ] = { "PALADIN", nil, "AURA" };
	[ L[ "Fire Resistance Aura" ] ] = { "PALADIN", nil, "AURA" };
	[ L[ "Frost Resistance Aura" ] ] = { "PALADIN", nil, "AURA" };
	[ L[ "Shadow Resistance Aura" ] ] = { "PALADIN", nil, "AURA" };
	[ L[ "Retribution Aura" ] ] = { "PALADIN", nil, "AURA" };
	[ L[ "Sanctity Aura" ] ] = { "PALADIN", "RETRIBUTION", "AURA" };
	-- Paladin blessings
	[ L[ "Blessing of Wisdom" ] ] = { "PALADIN", nil, "BLESSING" };
	[ L[ "Blessing of Might" ] ] = { "PALADIN", nil, "BLESSING" };
	[ L[ "Blessing of Light" ] ] = { "PALADIN", nil, "BLESSING" };
	[ L[ "Blessing of Kings" ] ] = { "PALADIN", nil, "BLESSING" };
	[ L[ "Blessing of Salvation" ] ] = { "PALADIN", nil, "BLESSING" };
	[ L[ "Blessing of Sanctuary" ] ] = { "PALADIN", "PROTECTION", "BLESSING" };
	[ L[ "Greater Blessing of Wisdom" ] ] = { "PALADIN", nil, "BLESSING" };
	[ L[ "Greater Blessing of Might" ] ] = { "PALADIN", nil, "BLESSING" };
	[ L[ "Greater Blessing of Light" ] ] = { "PALADIN", nil, "BLESSING" };
	[ L[ "Greater Blessing of Kings" ] ] = { "PALADIN", nil, "BLESSING" };
	[ L[ "Greater Blessing of Salvation" ] ] = { "PALADIN", nil, "BLESSING" };
	[ L[ "Greater Blessing of Sanctuary" ] ] = { "PALADIN", "PROTECTION", "BLESSING" };
	-- Personal
	[ L[ "Seal of Command" ] ] = { "PALADIN", "RETRIBUTION" };
	[ L[ "Holy Shield" ] ] = { "PALADIN", "PROTECTION" };
	[ L[ "Divine Illumination" ] ] = { "PALADIN", "HOLY" };
	[ L[ "Divine Favor" ] ] = { "PALADIN", "HOLY" };

	-- Priest
	[ L[ "Power Word: Fortitude" ] ] = { "PRIEST" };
	[ L[ "Prayer of Fortitude" ] ] = { "PRIEST" };
	[ L[ "Shadow Protection" ] ] = { "PRIEST" };
	[ L[ "Prayer of Shadow Protection" ] ] = { "PRIEST" };
	[ L[ "Divine Spirit" ] ] = { "PRIEST", "DISCIPLINE" };
	[ L[ "Prayer of Spirit" ] ] = { "PRIEST", "DISCIPLINE" };
	-- Personal
	[ L[ "Shadowform" ] ] = { "PRIEST", "SHADOW" };
	[ L[ "Blessed Resilience" ] ] = { "PRIEST", "HOLY" };
	[ L[ "Clearcasting" ] ] = { "PRIEST", "HOLY", nil, L[ "^Your next Flash Heal, Binding Heal, or Greater Heal spell has its mana cost reduced by 100%%%.$" ] };
	[ L[ "Surge of Light" ] ] = { "PRIEST", "HOLY" };
	[ L[ "Pain Suppression" ] ] = { "PRIEST", "DISCIPLINE" };
	[ L[ "Power Infusion" ] ] = { "PRIEST", "DISCIPLINE" };
	[ L[ "Focused Will" ] ] = { "PRIEST", "DISCIPLINE" };

	-- Rogue
	[ L[ "Find Weakness" ] ] = { "ROGUE", "ASSASSINATION" };
	[ L[ "Adrenaline Rush" ] ] = { "ROGUE", "COMBAT" };
	[ L[ "Shadowstep" ] ] = { "ROGUE", "SUBTLETY" };

	-- Shaman
	[ L[ "Heroism" ] ] = { "SHAMAN" };
	[ L[ "Water Breathing" ] ] = { "SHAMAN" };
	[ L[ "Water Walking" ] ] = { "SHAMAN" };
	[ L[ "Ancestral Healing" ] ] = { "SHAMAN", "RESTORATION" };
	[ L[ "Earth Shield" ] ] = { "SHAMAN", "RESTORATION" };
	-- Shaman totems
	[ L[ "Stoneskin Totem" ] ] = { "SHAMAN" };
	[ L[ "Strength of Earth Totem" ] ] = { "SHAMAN" };
	[ L[ "Tremor Totem" ] ] = { "SHAMAN" };
	[ L[ "Healing Stream Totem" ] ] = { "SHAMAN" };
	[ L[ "Frost Resistance Totem" ] ] = { "SHAMAN" };
	[ L[ "Mana Spring Totem" ] ] = { "SHAMAN" };
	[ L[ "Fire Resistance Totem" ] ] = { "SHAMAN" };
	[ L[ "Nature Resistance Totem" ] ] = { "SHAMAN" };
	[ L[ "Windwall Totem" ] ] = { "SHAMAN" };
	[ L[ "Frost Resistance Totem" ] ] = { "SHAMAN" };
	[ L[ "Grace of Air Totem" ] ] = { "SHAMAN" };
	[ L[ "Tranquil Air Totem" ] ] = { "SHAMAN" };
	[ L[ "Wrath of Air Totem" ] ] = { "SHAMAN" };
	[ L[ "Mana Tide Totem" ] ] = { "SHAMAN", "RESTORATION" };
	[ L[ "Totem of Wrath" ] ] = { "SHAMAN", "ELEMENTAL" };
	-- Personal
	[ L[ "Shamanistic Rage" ] ] = { "SHAMAN", "ENHANCEMENT" };
	[ L[ "Unleashed Rage" ] ] = { "SHAMAN", "ENHANCEMENT" };
	[ L[ "Stormstrike" ] ] = { "SHAMAN", "ENHANCEMENT" };

	-- Warlocks
	[ L[ "Detect Invisibility" ] ] = { "WARLOCK" };
	[ L[ "Detect Lesser Invisibility" ] ] = { "WARLOCK" };
	[ L[ "Underwater Breathing" ] ] = { "WARLOCK" };
	[ L[ "Master Demonologist" ] ] = { "WARLOCK", "DEMONOLOGY" };
	[ L[ "Soul Link" ] ] = { "WARLOCK", "DEMONOLOGY" };
	[ L[ "Demonic Knowledge" ] ] = { "WARLOCK", "DEMONOLOGY" };
	[ L[ "Blood Pact" ] ] = { "WARLOCK", nil, "PET" };
	[ L[ "Paranoia" ] ] = { "WARLOCK", nil, "PET" };
	-- Personal
	[ L[ "Backlash" ] ] = { "WARLOCK", "DESTRUCTION" };

	-- Warrior
	[ L[ "Commanding Shout" ] ] = { "WARRIOR", nil, "SHOUT" };
	[ L[ "Battle Shout" ] ] = { "WARRIOR", nil, "SHOUT" };
	-- Personal
	[ L[ "Second Wind" ] ] = { "WARRIOR", "ARMS", nil, L[ "^Generates %d+ rage and heals %d+%% of your total health every 2 sec%.$" ] };
	[ L[ "Rampage" ] ] = { "WARRIOR", "FURY", nil, L[ "^Increases attack power by %d+%.$" ] };
	[ L[ "Bloodthirst" ] ] = { "WARRIOR", "ARMS", nil, L[ "^Successful melee attacks restore %d+ to %d+ health%.$" ] };
};
me.BuffData = BuffData;


local PetLookup = {};
me.PetLookup = PetLookup;


local _G = getfenv( 0 );




--[[****************************************************************************
  * Function: _Arena.Scan.ResetResults                                         *
  * Description: Resets the scan results.                                      *
  ****************************************************************************]]
function me.ResetResults ()
	me.Results = {
		DRUID   = { Count = 0; Specs = { BALANCE       = false; FERAL        = false; RESTORATION = false; }; Wells = 0; Players = {}; Pets = {}; };
		HUNTER  = { Count = 0; Specs = { BEASTMASTERY  = false; MARKSMANSHIP = false; SURVIVAL    = false; }; Wells = 0; Players = {}; Pets = {}; };
		MAGE    = { Count = 0; Specs = { ARCANE        = false; FIRE         = false; FROST       = false; }; Wells = 0; Players = {}; Pets = {}; };
		PALADIN = { Count = 0; Specs = { HOLY          = false; PROTECTION   = false; RETRIBUTION = false; }; Wells = 0; Players = {}; Pets = {}; };
		PRIEST  = { Count = 0; Specs = { SHADOW        = false; DISCIPLINE   = false; HOLY        = false; }; Wells = 0; Players = {}; Pets = {}; };
		ROGUE   = { Count = 0; Specs = { ASSASSINATION = false; COMBAT       = false; SUBTLETY    = false; }; Wells = 0; Players = {}; Pets = {}; };
		SHAMAN  = { Count = 0; Specs = { ELEMENTAL     = false; ENHANCEMENT  = false; RESTORATION = false; }; Wells = 0; Players = {}; Pets = {}; };
		WARLOCK = { Count = 0; Specs = { AFFLICTION    = false; DEMONOLOGY   = false; DESTRUCTION = false; }; Wells = 0; Players = {}; Pets = {}; };
		WARRIOR = { Count = 0; Specs = { ARMS          = false; FURY         = false; PROTECTION  = false; }; Wells = 0; Players = {}; Pets = {}; };
	};
end
--[[****************************************************************************
  * Function: _Arena.Scan.ResetBuffResults                                     *
  * Description: Resets the buff scan results.                                 *
  ****************************************************************************]]
do
	local pairs = pairs;
	function me.ResetBuffResults ()
		for _, ClassData in pairs( BuffResults ) do
			ClassData.Count = 0;
			for Group in pairs( ClassData.Groups ) do
				ClassData.Groups[ Group ] = nil;
			end
			for Spec in pairs( ClassData.Specs ) do
				ClassData.Specs[ Spec ] = false;
			end
		end
	end
end




--[[****************************************************************************
  * Function: _Arena.Scan.UnitIsHostile                                        *
  * Description: Returns true if a unit should be considered hostile.  Note    *
  *   that it assumes only two factions exist: friendly team and hostile team. *
  ****************************************************************************]]
do
	local UnitCanAttack = UnitCanAttack;
	local UnitIsCharmed = UnitIsCharmed;
	function me.UnitIsHostile ( UnitID )
		return not not UnitCanAttack( "player", UnitID ) == ( UnitIsCharmed( UnitID ) == UnitIsCharmed( "player" ) );
	end
end
--[[****************************************************************************
  * Function: _Arena.Scan.ScanUnit                                             *
  * Description: Scans a unit, and returns true if anything new is found.      *
  ****************************************************************************]]
do
	local UnitExists = UnitExists;
	local UnitName = UnitName;
	local UnitIsHostile = me.UnitIsHostile;
	local UnitIsPlayer = UnitIsPlayer;
	function me.ScanUnit ( UnitID )
		if ( UnitExists( UnitID ) and UnitName( UnitID ) ~= L.UNKNOWNOBJECT
			and UnitIsHostile( UnitID )
		) then -- Valid enemy unit
			local Modified = false;
			if ( me.IsShamanTotem( UnitID ) ) then
				Modified = me.AddShamanTotem( UnitID ) or Modified;
			else
				if ( UnitIsPlayer( UnitID ) ) then
					Modified = me.AddPlayer( UnitID ) or Modified;
				elseif ( me.IsWarlockPet( UnitID ) ) then
					Modified = me.AddWarlockPet( UnitID ) or Modified;
				elseif ( me.IsHunterPet( UnitID ) ) then
					Modified = me.AddHunterPet( UnitID ) or Modified;
				end
	
				Modified = me.AddUnitBuffs( UnitID ) or Modified;
			end
	
			return Modified;
		end
	end
end




--[[****************************************************************************
  * Function: _Arena.Scan.AddPlayer                                            *
  * Description: Adds a unit known to be a player.                             *
  ****************************************************************************]]
do
	local UnitClass = UnitClass;
	local UnitName = UnitName;
	local select = select;
	local pairs = pairs;
	function me.AddPlayer ( UnitID )
		local ClassResults = me.Results[ select( 2, UnitClass( UnitID ) ) ];
	
		-- Add player name to cache and count total known players
		local Players = ClassResults.Players;
		local Count = 0;
		Players[ UnitName( UnitID ) ] = true;
		for Name in pairs( Players ) do
			Count = Count + 1;
		end
	
		if ( Count > ClassResults.Count ) then
			ClassResults.Count = Count;
			return true;
		end
	end
end
--[[****************************************************************************
  * Function: _Arena.Scan.AddPet                                               *
  * Description: Adds a unit known to be a pet of a given class, and returns   *
  *   true if the pet has been seen before.  In that case, the current results *
  *   will be replaced with saved results.                                     *
  ****************************************************************************]]
do
	local UnitName = UnitName;
	function me.AddPet ( UnitID, ClassResults )
		local PetName = UnitName( UnitID );
		if ( PetLookup[ PetName ] ) then
			me.Results = PetLookup[ PetName ];
			return true;
		else
			PetLookup[ PetName ] = me.Results;
			ClassResults.Pets[ PetName ] = true;
		end
	end
end


--[[****************************************************************************
  * Function: _Arena.Scan.IsShamanTotem                                        *
  * Description: Determine if a unit is a shaman totem.                        *
  ****************************************************************************]]
do
	local UnitName = UnitName;
	local UnitIsPlayer = UnitIsPlayer;
	function me.IsShamanTotem ( UnitID )
		local Name = UnitName( UnitID );
		return not UnitIsPlayer( UnitID )
			and ( Name:find( L.SCAN_TOTEM_PATTERN1 )
			or Name:find( L.SCAN_TOTEM_PATTERN2 ) );
	end
end
--[[****************************************************************************
  * Function: _Arena.Scan.AddShamanTotem                                       *
  * Description: Adds a unit known to be a shaman totem.                       *
  ****************************************************************************]]
function me.AddShamanTotem ( UnitID )
	local Modified = false;
	local ShamanResults = me.Results.SHAMAN;
	local Name = UnitName( UnitID );

	if ( Name == L[ "Totem of Wrath" ]
		and not ShamanResults.Specs.ELEMENTAL
	 ) then
		ShamanResults.Specs.ELEMENTAL = true;
		Modified = true;
	elseif ( Name == L[ "Mana Tide Totem" ]
		and not ShamanResults.Specs.RESTORATION
	 ) then
		ShamanResults.Specs.RESTORATION = true;
		Modified = true;
	end
	if ( ShamanResults.Count == 0 ) then
		ShamanResults.Count = 1;
		Modified = true;
	end

	return Modified;
end

--[[****************************************************************************
  * Function: _Arena.Scan.IsWarlockPet                                         *
  * Description: Determine if a unit is a warlock's demon pet.                 *
  ****************************************************************************]]
do
	local UnitIsPlayer = UnitIsPlayer;
	local UnitCreatureType = UnitCreatureType;
	function me.IsWarlockPet ( UnitID )
		return not UnitIsPlayer( UnitID )
			and UnitCreatureType( UnitID ) == L.SCAN_CREATURETYPE_DEMON;
	end
end
--[[****************************************************************************
  * Function: _Arena.Scan.AddWarlockPet                                        *
  * Description: Adds a unit known to be a warlock's demon pet.                *
  ****************************************************************************]]
function me.AddWarlockPet ( UnitID )
	local Modified = false;
	local WarlockResults = me.Results.WARLOCK;

	if ( UnitCreatureFamily( UnitID ) == L.SCAN_CREATUREFAMILY_FELGUARD
		and not WarlockResults.Specs.DEMONOLOGY
	) then
		WarlockResults.Specs.DEMONOLOGY = true;
		Modified = true;
	end

	-- Add pet name to cache
	if ( me.AddPet( UnitID, WarlockResults ) ) then -- Recognized
		return true;
	end

	if ( WarlockResults.Count == 0 ) then
		WarlockResults.Count = 1;
		Modified = true;
	end

	return Modified;
end

--[[****************************************************************************
  * Function: _Arena.Scan.IsHunterPet                                          *
  * Description: Determine if a unit is a hunter's beast pet.                  *
  ****************************************************************************]]
do
	local UnitIsPlayer = UnitIsPlayer;
	local UnitCreatureType = UnitCreatureType;
	function me.IsHunterPet ( UnitID )
		return not UnitIsPlayer( UnitID )
			and UnitCreatureType( UnitID ) == L.SCAN_CREATURETYPE_BEAST;
	end
end
--[[****************************************************************************
  * Function: _Arena.Scan.AddHunterPet                                         *
  * Description: Adds a unit known to be a hunter's beast pet.                 *
  ****************************************************************************]]
function me.AddHunterPet ( UnitID )
	local HunterResults = me.Results.HUNTER;

	-- Add pet name to cache
	if ( me.AddPet( UnitID, HunterResults ) ) then -- Recognized
		return true;
	end

	if ( HunterResults.Count == 0 ) then
		HunterResults.Count = 1;
		return true; -- Modified
	end
end




--[[****************************************************************************
  * Function: _Arena.Scan.SearchBuffTooltip                                    *
  * Description: Searches all but the first strings in a buff tooltip for a    *
  *   given search pattern.                                                    *
  ****************************************************************************]]
function me.SearchBuffTooltip ( UnitID, BuffIndex, Pattern )
	me:ClearLines();
	me:SetUnitBuff( UnitID, BuffIndex );

	local Prefix = me:GetName().."Text";
	local Left, Right;
	for Line = 2, me:NumLines() do
		Left = _G[ Prefix.."Left"..Line ]:GetText();
		Right = _G[ Prefix.."Right"..Line ];
		Right = Right:IsShown() and Right:GetText();

		if ( ( Left and Left:find( Pattern ) )
			or ( Right and Right:find( Pattern ) )
		) then
			return true;
		end
	end
end
--[[****************************************************************************
  * Function: _Arena.Scan.AddUnitBuffs                                         *
  * Description: Scans a unit's buffs, and returns true if any new classes     *
  *   are detected.                                                            *
  ****************************************************************************]]
do
	local SearchBuffTooltip = me.SearchBuffTooltip;
	local UnitBuff = UnitBuff;
	local pairs = pairs;
	local max = max;
	function me.AddUnitBuffs ( UnitID )
		local BuffIndex = 1;
		local Name = UnitBuff( UnitID, BuffIndex );
		me.ResetBuffResults();
	
		while ( Name ) do
			local Data = BuffData[ Name ];
	
			if ( Data -- Recognized buff
				and ( not Data[ 4 ] or SearchBuffTooltip( UnitID, BuffIndex, Data[ 4 ] ) ) -- Tooltip contents match
			) then
				local ClassData = BuffResults[ Data[ 1 ] ];

				-- Flag spec
				if ( Data[ 2 ] ) then -- Buff is spec-specific
					ClassData.Specs[ Data[ 2 ] ] = true;
				end

				-- Add to buff counts
				if ( Data[ 3 ] ) then -- Part of a group of buffs
					ClassData.Groups[ Data[ 3 ] ]
						= ( ClassData.Groups[ Data[ 3 ] ] or 0 ) + 1;
				else
					ClassData.Count = 1; -- Don't count non-unique buffs more than once
				end
			end

			BuffIndex = BuffIndex + 1;
			Name = UnitBuff( UnitID, BuffIndex );
		end


		-- Save found classes
		local Modified = false;
		for Class, ClassData in pairs( BuffResults ) do
			-- Find max number of class
			for Group, Count in pairs( ClassData.Groups ) do
				if ( Count > ClassData.Count ) then
					ClassData.Count = Count;
					Modified = true;
				end
			end
			-- Merge with running results
			local ClassResults = me.Results[ Class ];
			ClassResults.Count = max( ClassResults.Count, ClassData.Count );
			for Spec, Found in pairs( ClassResults.Specs ) do
				if ( not Found and ClassData.Specs[ Spec ] ) then
					ClassResults.Specs[ Spec ] = true;
					Modified = true;
				end
			end
		end
		return Modified;
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetOwner( WorldFrame, "ANCHOR_NONE" );

	-- Allow blank template to dynamically add new lines based on these
	me:AddFontStrings(
		me:CreateFontString( "$parentTextLeft1", nil, "GameTooltipText" ),
		me:CreateFontString( "$parentTextRight1", nil, "GameTooltipText" ) );
end
