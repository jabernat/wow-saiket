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
	function NS:GetCorpseName ()
		if ( not UnitExists( "mouseover" ) and GetMouseFocus() == WorldFrame and GameTooltip:IsVisible()
			and GameTooltip:NumLines() <= 2 -- Must recognize tooltips already partially filled in by BuildTooltip
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
-- @param Connected  0 for offline, 1 for online.
-- @param Status  AFK or DND text label.
-- @see GetFriendInfo
function NS:BuildTooltip ( Hostile, Name, Level, Class, Location, Connected, Status )
	if ( Hostile == nil ) then
		return;
	end
	if ( Connected == nil ) then -- Returned from GetFriendInfo
		Connected = 0; -- Offline represented differently
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
	if ( Connected ) then -- Connected status is known
		local Text, Color;
		if ( Connected == 0 ) then
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
--- Builds a standard corpse tooltip for the given UnitID.
function NS:BuildTooltipByUnitID ( UnitID )
	local Hostile = UnitFactionGroup( UnitID ) ~= UnitFactionGroup( "player" );
	return self:BuildTooltip( Hostile, UnitName( UnitID ),
		UnitLevel( UnitID ), UnitClass( UnitID ), GetRealZoneText(), UnitIsConnected( UnitID ) and 1 or 0,
		( UnitIsAFK( UnitID ) and CHAT_FLAG_AFK ) or ( UnitIsDND( UnitID ) and CHAT_FLAG_DND ) );
end
--- Generic iterator for unit IDs of a given prefix counting from Index down to 1.
function NS.NextUnitID ( Prefix, Index )
	if ( Index >= 1 ) then
		return Index - 1, Prefix..Index;
	end
end
do
	local GHOST = GetSpellInfo( 8326 );
	--- @return True if the given unit can possibly have a corpse object.
	function NS:UnitHasCorpse ( UnitID )
		return not UnitIsConnected( UnitID ) -- Can't detect dead/ghost status of offline units
			or UnitDebuff( UnitID, GHOST ) ~= nil; -- UnitIsGhost is unreliable
	end
end
--- Activates a module to handle filling corpse tooltips under specific settings such as cross-realm BGs.
-- @param NewModule  Module table containing callbacks.
-- @return True if module was changed.
function NS:SetActiveModule ( NewModule )
	if ( self.ActiveModule ~= NewModule ) then
		local OldModule = self.ActiveModule;
		self.ActiveModule = NewModule;

		if ( OldModule and OldModule.OnDisable ) then
			OldModule:OnDisable();
		end
		if ( NewModule and NewModule.OnEnable ) then
			NewModule:OnEnable();
		end
		return true;
	end
end


do
	local WorldTypeModules = {
		party = "Party"; raid = "Raid";
		arena = "Battleground"; pvp = "Battleground";
	};
	--- Activates different modules when changing between instances/BGs/etc.
	function NS.Frame:PLAYER_ENTERING_WORLD ()
		local _, WorldType = IsInInstance();
		NS:SetActiveModule( NS[ WorldTypeModules[ WorldType ] or "Standard" ] );
	end
end
--- Deactivates modules when leaving game worlds.
function NS.Frame:PLAYER_LEAVING_WORLD ()
	NS:SetActiveModule( nil );
end
--- Global event handler.
function NS.Frame:OnEvent ( Event, ... )
	if ( self[ Event ] ) then
		return self[ Event ]( self, Event, ... );
	end
end
--- Matches corpse tooltips after the tooltip gets set.
GameTooltip:HookScript( "OnShow", function ()
	if ( not NS.ActiveModule ) then
		return;
	end
	local Name = NS:GetCorpseName();
	if ( not Name ) then
		return; -- Not a corpse tooltip
	end

	if ( Name == UnitName( "player" ) ) then
		NS:BuildTooltipByUnitID( "player" );
	elseif ( NS.ActiveModule.IterateUnitIDs ) then
		-- Match by module's unit IDs
		for _, UnitID in NS.ActiveModule:IterateUnitIDs() do
			if ( Name == UnitName( UnitID ) and NS:UnitHasCorpse( UnitID ) ) then -- Ignore non-ghost matches
				NS:BuildTooltipByUnitID( UnitID );
				break;
			end
		end
	else -- Let module aquire unit info and build tooltip
		NS.ActiveModule:Update( Name );
	end
end );




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
if ( IsPlayerInWorld() ) then -- Loaded on-demand
	NS.Frame:PLAYER_ENTERING_WORLD();
end