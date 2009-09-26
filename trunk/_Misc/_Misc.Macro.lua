--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.Macro.lua - Changes to make macros easier to manage.                 *
  *                                                                            *
  * + Adds /print for executing LUA by command line. It executes its argument  *
  *   and displays the returned value in a chat window formatted with          *
  *   tostring(). The argument should be an RValue.                            *
  *   + Pipes typed into the command will be unescaped to allow manual         *
  *     construction of color and link tags.                                   *
  * + /alert will display your message like /print, but in the center of the   *
  *   screen with a warning sound.                                             *
  *   + Pipes typed into the command will be unescaped to allow manual         *
  *     construction of color and link tags.                                   *
  *   + The function alert(message, [color], [duration]) works like the slash  *
  *     command and can optionally specify the color and duration to use.      *
  ****************************************************************************]]


local _Misc = _Misc;
local me = {};
_Misc.Macro = me;




--[[****************************************************************************
  * Function: _Misc.Macro.UnitInGroup                                          *
  * Description: Returns true if the specified unit is in the party.           *
  ****************************************************************************]]
function me.UnitInGroup ( Unit )
	return UnitPlayerOrPetInRaid( Unit )
		or UnitPlayerOrPetInParty( Unit )
		or UnitIsUnit( Unit, "player" )
		or UnitIsUnit( Unit, "pet" );
end
--[[****************************************************************************
  * Function: _Misc.Macro.UnitIsCastable                                       *
  * Description: Returns true if the specified unit can be cast upon.          *
  ****************************************************************************]]
function me.UnitIsCastable ( Unit )
	return UnitIsFriend( "player", Unit )
		and not UnitIsDeadOrGhost( Unit )
		and UnitIsConnected( Unit )
		and UnitIsVisible( Unit )
		and UnitInRange( Unit );
end
--[[****************************************************************************
  * Function: _Misc.Macro.ItemUsable                                           *
  * Description: Returns true if an item is usable.                            *
  ****************************************************************************]]
do
	local GetItemInfo = GetItemInfo;
	local GetItemCount = GetItemCount;
	local IsUsableItem = IsUsableItem;
	local GetItemCooldown = GetItemCooldown;
	local ItemHasRange = ItemHasRange;
	local IsItemInRange = IsItemInRange;
	function me.ItemUsable ( Item, Unit )
		if ( type( Item ) == "number" ) then
			Item = "item:"..Item;
		end

		return GetItemInfo( Item )
			and GetItemCount( Item ) > 0
			and IsUsableItem( Item )
			and GetItemCooldown( Item ) == 0
			and ( not ItemHasRange( Item ) or IsItemInRange( Item, Unit or "target" ) == 1 );
	end
end
--[[****************************************************************************
  * Function: _Misc.Macro.GarbleGsub                                           *
  * Description: Gsub replace function used by Garble.                         *
  ****************************************************************************]]
function me.GarbleGsub ( Character )
	return "\31"..Character;
end
--[[****************************************************************************
  * Function: _Misc.Macro.Garble                                               *
  * Description: Garbles the text in a string.                                 *
  ****************************************************************************]]
function me.Garble ( Text )
	return Text:gsub( "[\33-\128]", me.GarbleGsub );
end
--[[****************************************************************************
  * Function: _Misc.Macro.Truncate                                             *
  * Description: Shortens a string to a given length and adds an ellipsis.     *
  ****************************************************************************]]
function me.Truncate ( Text, MaxLength )
	if ( #Text > MaxLength ) then
		if ( MaxLength >= 3 ) then
			return Text:sub( 1, MaxLength - 3 ).."\226\128\166";
		else -- Not enough room for ellipsis
			return Text:sub( 1, MaxLength );
		end
	else
		return Text;
	end
end




--[[****************************************************************************
  * Function: _Misc.Macro.Alert                                                *
  * Description: Show a message in the middle of the screen and play a sound.  *
  ****************************************************************************]]
function me.Alert ( Message, Color )
	if ( not Color ) then
		Color = NORMAL_FONT_COLOR;
	end
	RaidNotice_AddMessage( RaidWarningFrame, "|TInterface\\DialogFrame\\DialogAlertIcon:48|t"..tostring( Message ), Color );
	PlaySound( "RaidWarning" );
end
--[[****************************************************************************
  * Function: _Misc.Macro.PrintSlashCommand                                    *
  * Description: Slash command chat handler for the _Misc.Print function.      *
  ****************************************************************************]]
function me.PrintSlashCommand ( Input )
	if ( Input and not Input:find( "^%s*$" ) ) then
		local Success, Output = _Misc.Exec( Input:gsub( "||", "|" ) );
		if ( Success ) then
			_Misc.Print( Output );
		else
			geterrorhandler()( Output );
		end
	end
end
--[[****************************************************************************
  * Function: _Misc.Macro.AlertSlashCommand                                    *
  * Description: Slash command chat handler for _Misc.Macro.Alert.             *
  ****************************************************************************]]
function me.AlertSlashCommand ( Input )
	if ( Input and not Input:find( "^%s*$" ) ) then
		local Success, Output = _Misc.Exec( Input:gsub( "||", "|" ) );
		if ( Success ) then
			me.Alert( Output );
		else
			geterrorhandler()( Output );
		end
	end
end


--[[****************************************************************************
  * Function: _Misc.Macro.EnableErrors                                         *
  * Description: Toggles error messages and error speech.                      *
  ****************************************************************************]]
do
	local Backups = {}; -- Backup filter settings
	local SetCVar = SetCVar;
	local ipairs = ipairs;
	local next = next;
	function me.EnableErrors ( Enabled )
		SetCVar( "Sound_EnableSFX", Enabled and 1 or 0 );
		SetCVar( "Sound_EnableErrorSpeech", Enabled and 1 or 0 );
		UIErrorsFrame[ Enabled and "RegisterEvent" or "UnregisterEvent" ]( UIErrorsFrame, "UI_ERROR_MESSAGE" );

		if ( IsAddOnLoaded( "Blizzard_CombatLog" ) ) then
			Blizzard_CombatLog_RefreshGlobalLinks();

			if ( Enabled ) then
				-- Restore old filters
				Blizzard_CombatLog_ApplyFilters( Blizzard_CombatLog_CurrentSettings );

			else
				-- Temporarily hide these messages
				local EventList;
				for Index, Filter in ipairs( Blizzard_CombatLog_CurrentSettings.filters ) do
					EventList = Filter.eventList;
					if ( Filter.sourceFlags and Filter.sourceFlags[ COMBATLOG_FILTER_MINE ] and EventList[ "SPELL_CAST_FAILED" ] ) then
						Backups[ Index ] = EventList[ "SPELL_CAST_FAILED" ];
						EventList[ "SPELL_CAST_FAILED" ] = false;
					end
				end

				if ( next( Backups ) ) then -- Needs update
					Blizzard_CombatLog_ApplyFilters( Blizzard_CombatLog_CurrentSettings );
					-- Restore old filter
					for Index, Backup in pairs( Backups ) do
						Blizzard_CombatLog_CurrentSettings.filters[ Index ].eventList[ "SPELL_CAST_FAILED" ] = Backup;
						Backups[ Index ] = nil;
					end
				end
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Misc.Macro.EnableErrorsSlashCommand                             *
  * Description: Slash command chat handler for _Misc.Macro.EnableErrors.      *
  ****************************************************************************]]
function me.EnableErrorsSlashCommand ( Input )
	me.EnableErrors( Input and Input:trim() == "1" );
end


--[[****************************************************************************
  * Function: _Misc.Macro.Mount                                                *
  * Description: Uses the mount with the given name depending on location.     *
  ****************************************************************************]]
do
	local WintergraspName;
	local GetCompanionInfo = GetCompanionInfo;
	function me.Mount ( NameGround, NameFlying )
		if ( IsMounted() ) then
			Dismount();
		elseif ( CanExitVehicle() ) then
			if ( IsControlKeyDown() ) then
				VehicleExit();
			end
		elseif ( NameGround and IsOutdoors() ) then -- Can probably mount up
			-- Find and use mount
			local Flyable = IsFlyableArea() and not ( GetRealZoneText() == WintergraspName and not GetWintergraspWaitTime() ); -- Excludes Wintergrasp while battles are active
			local Name = ( Flyable and NameFlying or NameGround ):trim():lower();
			local SpellID = tonumber( Name );
			for Index = 1, GetNumCompanions( "MOUNT" ) do
				local _, MountName, MountSpellID = GetCompanionInfo( "MOUNT", Index );
				if ( SpellID and SpellID == MountSpellID
					or Name == MountName:lower()
				) then
					CallCompanion( "MOUNT", Index );
					return true;
				end
			end
		end
	end

	-- Find Wintergrasp's localized name
	local NorthrendID = 4;
	local Zones = { GetMapZones( NorthrendID ) };
	for ZoneIndex, ZoneName in ipairs( Zones ) do
		SetMapZoom( NorthrendID, ZoneIndex );
		if ( GetMapInfo() == "LakeWintergrasp" ) then
			WintergraspName = ZoneName;
			break;
		end
	end
end
--[[****************************************************************************
  * Function: _Misc.Macro.MountSlashCommand                                    *
  * Description: Slash command chat handler for _Misc.Macro.Mount.             *
  ****************************************************************************]]
function me.MountSlashCommand ( Input )
	me.Mount( ( "," ):split( SecureCmdOptionParse( Input ) ) );
end
--[[****************************************************************************
  * Function: _Misc.Macro.PallyPowerLoadSlashCommand                           *
  * Description: Slash command chat handler to update PallyPower.              *
  ****************************************************************************]]
if ( select( 2, UnitClass( "player" ) ) == "PALADIN" ) then
	function me.PallyPowerLoadSlashCommand ( Input )
		local Preset, Seal, Aura, RighteousFury = ( "," ):split( ( SecureCmdOptionParse( Input ) or "" ):trim() );

		if ( Preset ~= "" ) then
			-- Note: See PallyPowerValues.lua for these IDs
			Seal, Aura = tonumber( Seal ), tonumber( Aura );
			RighteousFury = RighteousFury and RighteousFury ~= "";

			local Success, Reason = LoadAddOn( "PallyPower" );
			if ( not Success ) then
				error( _G[ "ADDON_"..Reason ] );
			end


			-- Assignments
			PallyPower:LoadPreset( Preset );
			if ( Seal ) then
				PallyPower:SealAssign( Seal );
			end
			if ( Aura ) then
				local Name = UnitName( "player" );
				PallyPower_AuraAssignments[ Name ] = Aura;
				PallyPower:SendMessage( "AASSIGN "..Name.." "..Aura );
			end
			PallyPower.opt.rf = RighteousFury;
			PallyPower:RFAssign();

			PallyPower:ButtonsUpdate();
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	UnitInGroup = me.UnitInGroup;
	UnitIsCastable = me.UnitIsCastable;
	garble = me.Garble;
	usable = me.ItemUsable;
	trunc = me.Truncate;

	SlashCmdList[ "PRINT" ] = me.PrintSlashCommand;
	alert = me.Alert;
	SlashCmdList[ "ALERT" ] = me.AlertSlashCommand;

	err = me.EnableErrors;
	SlashCmdList[ "ERR" ] = me.EnableErrorsSlashCommand;

	SlashCmdList[ "MOUNT" ] = me.MountSlashCommand;

	SlashCmdList[ "PALLYPOWERLOAD" ] = me.PallyPowerLoadSlashCommand;
end
