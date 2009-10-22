--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.Macro.lua - Custom slash commands and shortcuts.                     *
  ****************************************************************************]]


local _Misc = _Misc;
local me = {};
_Misc.Macro = me;




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
			local SpellID = tonumber( Name, 16 );
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
	me.Mount( ( "," ):split( SecureCmdOptionParse( Input ) or "" ) );
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
	alert = me.Alert;
	SlashCmdList[ "ALERT" ] = me.AlertSlashCommand;

	err = me.EnableErrors;
	SlashCmdList[ "ERR" ] = me.EnableErrorsSlashCommand;

	SlashCmdList[ "MOUNT" ] = me.MountSlashCommand;

	SlashCmdList[ "PALLYPOWERLOAD" ] = me.PallyPowerLoadSlashCommand;
end
