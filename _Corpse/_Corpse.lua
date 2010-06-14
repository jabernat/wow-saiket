--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * _Corpse.lua - Shows information about moused-over corpses.                 *
  ****************************************************************************]]


local L = _CorpseLocalization;
local me = CreateFrame( "Frame", "_Corpse" );

me.ActiveModule = nil;

local GameTooltip = GetClickFrame( "GameTooltip" ); -- Gets the original frame named "GameTooltip", in case the global is overriden




--[[****************************************************************************
  * Function: _Corpse.GetCorpseName                                            *
  * Description: Gets the name from a corpse's tooltip, or nil of no corpse.   *
  ****************************************************************************]]
do
	local UnitExists = UnitExists;
	local GetMouseFocus = GetMouseFocus;
	function me.GetCorpseName ()
		if ( not UnitExists( "mouseover" ) and GetMouseFocus() == WorldFrame and GameTooltip:IsVisible() and GameTooltip:NumLines() <= 2 ) then
			local Text = GameTooltipTextLeft1:GetText();
			if ( Text ) then
				Text = Text:match( L.CORPSE_PATTERN );
				if ( Text ) then
					return ( "-" ):split( Text );
				end
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Corpse.BuildCorpseTooltip                                       *
  * Description: Adds info from friends list to the current corpse tooltip.    *
  *   Adds info to fontstrings directly; avoids using ClearLines to keep other *
  *   tooltip addons from thinking the tooltip is being reset.                 *
  ****************************************************************************]]
function me.BuildCorpseTooltip ( Hostile, Name, Level, Class, Location, ConnectedStatus, Status )
	if ( Hostile == nil ) then
		return;
	end
	if ( ConnectedStatus == nil ) then -- Returned from GetFriendInfo
		ConnectedStatus = 0; -- Offline represented differently
	end

	-- Build first line
	local Text = L.CORPSE_FORMAT:format( Name );
	local Color = FACTION_BAR_COLORS[ Hostile and 2 or 6 ];
	GameTooltipTextLeft1:SetTextColor( Color.r, Color.g, Color.b );
	local Right = GameTooltipTextRight1;
	if ( Status and #Status > 0 ) then -- AFK or DND
		Color = NORMAL_FONT_COLOR;
		Right:SetText( Status );
		Right:SetTextColor( Color.r, Color.g, Color.b );
		Right:Show()
	else
		Right:Hide();
	end

	-- Add second status line
	if ( ConnectedStatus ) then -- Connected status is known
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




--[[****************************************************************************
  * Function: _Corpse:PLAYER_ENTERING_WORLD                                    *
  ****************************************************************************]]
function me:PLAYER_ENTERING_WORLD ()
	local Type = select( 2, IsInInstance() );
	local Module;

	if ( Type == "pvp" ) then -- In battleground
		Module = me.Battlegrounds;
	elseif ( Type == "party" ) then -- In a 5-man dungeon
		Module = me.Dungeons;
	elseif ( Type ~= "arena" ) then
		Module = me.Standard;
	end -- Else disable in arenas

	me.SetActiveModule( Module );
end
--[[****************************************************************************
  * Function: _Corpse:PLAYER_LEAVING_WORLD                                     *
  ****************************************************************************]]
function me:PLAYER_LEAVING_WORLD ()
	me.SetActiveModule( nil );
end
--[[****************************************************************************
  * Function: _Corpse:OnEvent                                                  *
  * Description: Global event handler.                                         *
  ****************************************************************************]]
do
	local type = type;
	function me:OnEvent ( Event, ... )
		if ( type( self[ Event ] ) == "function" ) then
			self[ Event ]( self, Event, ... );
		end
	end
end




--[[****************************************************************************
  * Function: _Corpse:GameTooltipOnShow                                        *
  * Description: Hook called when GameTooltip updates.                         *
  ****************************************************************************]]
function me:GameTooltipOnShow ()
	-- Tooltip contents updated
	if ( me.ActiveModule ) then
		local Name, Server = me.GetCorpseName();
		if ( Name ) then -- Found corpse tooltip
			me.ActiveModule:Update( Name, Server ); -- Add data to tooltip using module's info
		end
	end
end
--[[****************************************************************************
  * Function: _Corpse.SetActiveModule                                          *
  ****************************************************************************]]
function me.SetActiveModule ( NewModule )
	if ( NewModule ~= me.ActiveModule ) then
		local OldModule = me.ActiveModule;
		me.ActiveModule = NewModule;

		if ( OldModule and OldModule.Disable ) then
			OldModule:Disable();
		end
		if ( NewModule and NewModule.Enable ) then
			NewModule:Enable();
		end

		return true;
	end
end
--[[****************************************************************************
  * Function: _Corpse.IsModuleActive                                           *
  ****************************************************************************]]
function me.IsModuleActive ( Module )
	return Module == me.ActiveModule;
end




me:SetScript( "OnEvent", me.OnEvent );
me:RegisterEvent( "PLAYER_ENTERING_WORLD" );
if ( IsLoggedIn() ) then -- Loaded on-demand
	me:PLAYER_ENTERING_WORLD();
end

GameTooltip:HookScript( "OnShow", me.GameTooltipOnShow );