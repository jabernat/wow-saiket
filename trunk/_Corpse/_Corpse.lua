--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * _Corpse.lua - Shows information about moused-over corpses.                 *
  ****************************************************************************]]


local AddOnName, NS = ...;
_Corpse = NS;
local L = NS.L;
NS.Frame = CreateFrame( "Frame" );




do
	local UnitExists = UnitExists;
	local GetMouseFocus = GetMouseFocus;
	--- Gets the name from a visible corpse tooltip.
	-- @return Corpse owner's name, or nil if the tooltip isn't for a corpse.
	function NS.GetCorpseName ()
		if ( not UnitExists( "mouseover" ) and GetMouseFocus() == WorldFrame and GameTooltip:IsVisible()
			and GameTooltip:NumLines() <= 2 -- Must recognize tooltips already partially filled in by BuildCorpseTooltip
		) then
			local Text = GameTooltipTextLeft1:GetText();
			if ( Text ) then
				local Pattern, Name = L.CORPSE_PATTERN;
				if ( type( Pattern ) == "function" ) then -- Function to handle multiple cases, such as in French
					Name = Pattern( Text );
				else
					Name = Text:match( Pattern );
				end

				return Name;
			end
		end
	end
end
--- Adds detailed unit info to a corpse tooltip.
-- Adds info to fontstrings directly; avoids using ClearLines to keep other
-- tooltip addons from thinking the tooltip is being reset.
-- @param Hostile  Boolean, true if hostile to the player.
-- @param ConnectedStatus  0 for offline, 1 for online.
-- @param Status  AFK or DND text label.
-- @see GetFriendInfo
function NS.BuildCorpseTooltip ( Hostile, Name, Level, Class, Location, ConnectedStatus, Status )
	if ( Hostile == nil ) then
		return;
	end
	if ( ConnectedStatus == nil ) then -- Returned from GetFriendInfo
		ConnectedStatus = 0; -- Offline represented differently
	end

	-- Build first line
	local Color = FACTION_BAR_COLORS[ Hostile and 2 or 6 ];
	GameTooltipTextLeft1:SetTextColor( Color.r, Color.g, Color.b );
	local Right = GameTooltipTextRight1;
	if ( Status and #Status > 0 ) then -- AFK or DND
		local Color = NORMAL_FONT_COLOR;
		Right:SetText( Status );
		Right:SetTextColor( Color.r, Color.g, Color.b );
		Right:Show()
	else
		Right:Hide();
	end

	-- Add second status line
	if ( ConnectedStatus ) then -- Connected status is known
		local Text, Color;
		if ( ConnectedStatus == 0 ) then
			Text = L.OFFLINE;
			Color = GRAY_FONT_COLOR;
		else -- Online
			if ( Class ) then -- Show details
				if ( Level ) then
					Text = L.LEVEL_CLASS_PATTERN:format( Level, Class );
				else
					Text = Class;
				end
			else -- Plain online
				Text = L.ONLINE;
			end
			Color = HIGHLIGHT_FONT_COLOR;
		end
		if ( GameTooltip:NumLines() < 2 ) then
			GameTooltip:AddLine( Text, Color.r, Color.g, Color.g );
		else -- Line already shown
			local Left = GameTooltipTextLeft2;
			Left:SetText( Text );
			Left:SetTextColor( Color.r, Color.g, Color.g );
			Left:Show();
			GameTooltipTextRight2:Hide();
		end
	end

	-- Hack to effectively resize the tooltip without breaking FadeOut() like Show() does
	GameTooltip:AppendText( "" );
end




--- Activates different modules when changing between instances/BGs/etc.
function NS.Frame:PLAYER_ENTERING_WORLD ()
	local Type = select( 2, IsInInstance() );
	local Module;

	if ( Type == "pvp" ) then -- In battleground
		Module = NS.Battlegrounds;
	elseif ( Type == "party" ) then -- In a 5-man dungeon
		Module = NS.Dungeons;
	elseif ( Type ~= "arena" ) then
		Module = NS.Standard;
	end -- Else disable in arenas

	NS.SetActiveModule( Module );
end
--- Deactivates modules when leaving game worlds.
function NS.Frame:PLAYER_LEAVING_WORLD ()
	NS.SetActiveModule( nil );
end
--- Global event handler.
function NS.Frame:OnEvent ( Event, ... )
	if ( self[ Event ] ) then
		return self[ Event ]( self, Event, ... );
	end
end




do
	local ActiveModule;
	local PlayerName = UnitName( "player" );
	--- Hook called when GameTooltip updates.
	function NS:GameTooltipOnShow ()
		-- Tooltip contents updated
		if ( ActiveModule ) then
			local Name = NS.GetCorpseName();
			if ( Name ) then -- Found corpse tooltip
				if ( Name == PlayerName ) then
					-- Create a common tooltip for the player's corpse
					NS.BuildCorpseTooltip( false, Name,
						UnitLevel( "player" ), UnitClass( "player" ), GetRealZoneText(), 1,
						( UnitIsAFK( "player" ) and CHAT_FLAG_AFK ) or ( UnitIsDND( "player" ) and CHAT_FLAG_DND ) );
				else -- Add data to tooltip using module's info
					ActiveModule:Update( Name );
				end
			end
		end
	end
	--- Activates a module to handle filling corpse tooltips under specific settings such as cross-realm BGs.
	-- @param NewModule  Module table containing callbacks.
	-- @return True if module was changed.
	function NS.SetActiveModule ( NewModule )
		if ( NewModule ~= ActiveModule ) then
			local OldModule = ActiveModule;
			ActiveModule = NewModule;

			if ( OldModule and OldModule.Disable ) then
				OldModule:Disable();
			end
			if ( NewModule and NewModule.Enable ) then
				NewModule:Enable();
			end

			return true;
		end
	end
	--- Returns true if a given module is the active one.
	function NS.IsModuleActive ( Module )
		return Module == ActiveModule;
	end
end




do
	local Constants = {
		"CORPSE_TOOLTIP",
		"ERR_BAD_PLAYER_NAME_S",
		"ERR_FRIEND_ADDED_S",
		"ERR_FRIEND_REMOVED_S",
	};
	--- Script to extract localization data from a client.
	function NS.LocaleExtract ()
		local Data = {
			Locale = GetCVar( "locale" );
			VersionCorpse = GetAddOnMetadata( AddOnName, "Version" );
			VersionWoW = ( "%s (%d)" ):format( GetBuildInfo() );

			Constants = {};
			Taint = {};
		};
		for _, Constant in ipairs( Constants ) do
			Data.Constants[ Constant ] = _G[ Constant ];
			local _, AddOn = issecurevariable( Constant );
			if ( AddOn ) then
				Data.Taint[ Constant ] = AddOn;
			end
		end
		_CorpseLocale = Data;
		ReloadUI();
	end
end




NS.Frame:SetScript( "OnEvent", NS.Frame.OnEvent );
NS.Frame:RegisterEvent( "PLAYER_ENTERING_WORLD" );
if ( IsLoggedIn() ) then -- Loaded on-demand
	NS.Frame:PLAYER_ENTERING_WORLD();
end

GameTooltip:HookScript( "OnShow", NS.GameTooltipOnShow );