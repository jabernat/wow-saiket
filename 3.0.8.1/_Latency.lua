--[[****************************************************************************
  * _Latency by Saiket                                                         *
  * _Latency.lua - Adds a latency graph that updates using chat message pings. *
  ****************************************************************************]]


_LatencyOptions = {
	IsEnabled = true;
	IsLocked = false;
};


local L = _LatencyLocalization;
local LibGraph = LibStub( "LibGraph-2.0" );
local me = CreateFrame( "Frame", "_Latency", UIParent );

-- Configuration
me.PingRate = 0.1; -- Minimum time between pings
me.UpdateRate = 0.5; -- Time between graph/label updates
me.PingDataAge = 5; -- Time to keep ping time data in the running average
me.MaxSimultaneousPings = 1; -- Max number of pings that can be sent at once


me.Prefix = "_L";

local PingData = {};
me.PingData = PingData;
me.PingCutoff = 0;
me.NumPings = 0; -- Number of pings en-route

local TopColor = { r = 0.8, g = 0.8, b = 17 / 32 }; -- Gold
me.TopColor = TopColor;
local BottomColor = { r = 0.4; g = 0.4; b = 0.0; a = 0.4; }; -- Modified based on ping
me.BottomColor = BottomColor;
me.Padding = 6;




--[[****************************************************************************
  * Function: _Latency.Toggle                                                  *
  * Description: Toggles the mod enabled or disabled.                          *
  ****************************************************************************]]
function me.Toggle ( Enable )
	if ( Enable == nil ) then
		Enable = not _LatencyOptions.IsEnabled;
	end
	_LatencyOptions.IsEnabled = Enable;

	if ( Enable ) then
		me:Show();
	else
		me:Hide();
	end
end
--[[****************************************************************************
  * Function: _Latency.ToggleLocked                                            *
  * Description: Toggles whether the frame is locked or not.                   *
  ****************************************************************************]]
function me.ToggleLocked ( Locked )
	if ( Locked == nil ) then
		Locked = not _LatencyOptions.IsLocked;
	end
	_LatencyOptions.IsLocked = Locked;
	local Enable = not Locked;

	me:EnableMouse( Enable );
	me.Close:EnableMouse( Enable );
	SetDesaturation( me.Close:GetNormalTexture(), Locked );
	me.Resize:EnableMouse( Enable );
	if ( Enable ) then
		me.Close:Enable();
		me.Resize:Enable();
	else
		me.Close:Disable();
		me.Resize:Disable();
		me:StopMovingOrSizing();
	end
end


--[[****************************************************************************
  * Function: _Latency.TimeDecode                                              *
  * Description: Decodes an encoded time string to a floating-point number.    *
  ****************************************************************************]]
do
	local lshift = bit.lshift;
	function me.TimeDecode ( String )
		local FP1, FP2 = String:byte( 1, 2 );
		local FloatPart = ( lshift( FP1 - 0x80, 7 ) + ( FP2 - 0x80 ) ) / ( 2 ^ 14 - 1 );

		local IntPart = 0;
		for Index = 3, #String do
			IntPart = IntPart + lshift( String:byte( Index ) - 0x80, 7 * ( Index - 3 ) );
		end

		return IntPart + FloatPart;
	end
end
--[[****************************************************************************
  * Function: _Latency.TimeEncode                                              *
  * Description: Encodes the current time to a string.                         *
  *   "[fH][fL][iL][i2][i3]...[iH]" with (f)loat, (i)nt, (H)igh, (L)ow.        *
  ****************************************************************************]]
do
	local floor = floor;
	local band = bit.band;
	local rshift = bit.rshift;
	local Bytes = {};
	function me.TimeEncode ()
		local Time = GetTime();
		local IntPart = floor( Time );
		local FloatPart = floor( ( Time - IntPart ) * ( 2 ^ 14 - 1 ) + 0.5 );

		-- Bit 8 of every byte always on to prevent embedded nulls in the string
		Bytes[ 1 ] = rshift( FloatPart, 7 ) + 0x80;
		Bytes[ 2 ] = band( FloatPart, 0x7F ) + 0x80;
		while ( IntPart > 0 ) do
			Bytes[ #Bytes + 1 ] = band( IntPart, 0x7F ) + 0x80;
			IntPart = rshift( IntPart, 7 );
		end

		Time = string.char( unpack( Bytes ) );
		wipe( Bytes );
		return Time;
	end
end


--[[****************************************************************************
  * Function: _Latency.GetAveragePing                                          *
  * Description: Returns a running average of the player's ping.               *
  ****************************************************************************]]
function me.GetAveragePing ()
	local MinSendTime = GetTime() - me.PingDataAge;
	local Count, Total = 0, 0;
	for SendTime, Latency in pairs( PingData ) do
		if ( SendTime + Latency > MinSendTime ) then
			Count = Count + 1;
			Total = Total + Latency;
		else
			PingData[ SendTime ] = nil;
		end
	end
	if ( Count ~= 0 and Total ~= 0 ) then
		return Total / Count * 1000;
	end
end


--[[****************************************************************************
  * Function: _Latency:OnUpdate                                                *
  * Description: Periodically sends ping messages.                             *
  ****************************************************************************]]
do
	local LastPing = me.PingRate;
	local LastUpdate = me.UpdateRate;
	local min, max = min, max;
	function me:OnUpdate ( Elapsed )
		LastPing = LastPing + Elapsed;
		if ( LastPing >= me.PingRate ) then
			LastPing = 0;
			if ( me.NumPings < me.MaxSimultaneousPings ) then
				SendAddonMessage( me.Prefix, me.TimeEncode(), "WHISPER", UnitName( "player" ) );
				me.NumPings = me.NumPings + 1;
			end
		end

		LastUpdate = LastUpdate + Elapsed;
		if ( LastUpdate >= me.UpdateRate ) then
			LastUpdate = 0;
			local Ping = me.GetAveragePing();
			if ( Ping ) then
				me.Graph:AddTimeData( Ping * me.UpdateRate );
				me.SubTitle:SetFormattedText( L.SUBTITLE_FORMAT, Ping );
			end
		end

		local Value = me.Graph:GetValue( me.Graph.XMax );
		BottomColor.r = min( Value / 400, 1.0 );
		BottomColor.g = min( max( 1 - Value / 150 * 0.4, 0 ), 0.4 );
		me.Graph:SetBarColors( BottomColor, TopColor );
	end
end
--[[****************************************************************************
  * Function: _Latency:PLAYER_ENTERING_WORLD                                   *
  ****************************************************************************]]
function me:PLAYER_ENTERING_WORLD ()
	-- Prevent pings from before zoning from being read after loading
	me.PingCutoff = GetTime();
end
--[[****************************************************************************
  * Function: _Latency:CHAT_MSG_ADDON                                          *
  ****************************************************************************]]
function me:CHAT_MSG_ADDON ( _, Prefix, Message, Type, Author )
	if ( Prefix == me.Prefix ) then
		if ( Type == "WHISPER" and Author == UnitName( "player" ) ) then
			if ( me.NumPings > 0 ) then
				me.NumPings = me.NumPings - 1;
			end

			local SendTime = me.TimeDecode( Message );
			if ( SendTime >= me.PingCutoff ) then
				PingData[ SendTime ] = GetTime() - SendTime;
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Latency:ADDON_LOADED                                            *
  ****************************************************************************]]
function me:ADDON_LOADED ( _, AddOn )
	if ( AddOn:lower() == "_latency" ) then
		me:UnregisterEvent( "ADDON_LOADED" );
		me.ADDON_LOADED = nil;

		me.Toggle( _LatencyOptions.IsEnabled );
		me.ToggleLocked( _LatencyOptions.IsLocked );
		me:SetScript( "OnHide", me.OnHide );
	end
end
--[[****************************************************************************
  * Function: _Latency:OnEvent                                                 *
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
  * Function: _Latency:OnSizeChanged                                           *
  * Description: Resizes the graph.                                            *
  ****************************************************************************]]
function me:OnSizeChanged ()
	self.Graph:SetWidth( self:GetWidth() - me.Padding * 2 );
	self.Graph:SetHeight( self:GetHeight() - me.Padding * 2 - 18 );
end
--[[****************************************************************************
  * Function: _Latency:OnHide                                                  *
  * Description: Prints a notice for how to reopen the window.                 *
  ****************************************************************************]]
function me:OnHide ()
	-- Only print message when directly hidden (i.e. not hidding the interface)
	if ( not self:IsShown() ) then
		print( L.ONCLOSE_NOTICE );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Set up window
	me:SetWidth( 300 );
	me:SetHeight( 80 );
	me:SetScale( 0.8 );
	me:SetPoint( "CENTER" );
	me:SetFrameStrata( "MEDIUM" );
	me:EnableMouse( true );
	me:SetToplevel( true );
	me:SetBackdrop( {
		bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground";
		edgeFile = "Interface\\TutorialFrame\\TutorialFrameBorder";
		tile = true; tileSize = 32; edgeSize = 32;
		insets = { left = 7; right = 5; top = 3; bottom = 6; };
	} );
	-- Make dragable
	me:SetMovable( true );
	me:SetResizable( true );
	me:SetUserPlaced( true );
	me:SetClampedToScreen( true );
	me:SetClampRectInsets( me.Padding + 2, -me.Padding, -me.Padding - 18, me.Padding );
	me:CreateTitleRegion():SetAllPoints();
	-- Close button
	me.Close = CreateFrame( "Button", nil, me, "UIPanelCloseButton" );
	me.Close:SetPoint( "TOPRIGHT", 4, 4 );
	me.Close:SetScript( "OnClick", function () me.Toggle(); end );
	-- Title
	me.Title = me:CreateFontString( nil, "ARTWORK", "GameFontHighlight" );
	me.Title:SetText( L.TITLE );
	me.Title:SetPoint( "TOPLEFT", me, 11, -6 );
	-- SubTitle
	me.SubTitle = me:CreateFontString( nil, "ARTWORK", "GameFontNormal" );
	me.SubTitle:SetPoint( "LEFT", me.Title, "RIGHT", 4, 0 );
	me.SubTitle:SetPoint( "RIGHT", me.Close, "LEFT", -4, 0 );
	me.SubTitle:SetJustifyH( "RIGHT" );

	-- Graph
	local Graph = LibGraph:CreateGraphRealtime( "_LatencyGraph", me, "BOTTOMLEFT", "BOTTOMLEFT", me.Padding + 2, me.Padding, me:GetWidth() - me.Padding * 2, me:GetHeight() - me.Padding * 2 - 18 );
	me.Graph = Graph;
	Graph:SetGridSpacing( 1.0, 100 );
	Graph:SetYMax( 2.0 );
	Graph:SetXAxis( -11, -1 );
	Graph:SetFilterRadius( 1 );
	Graph:SetAutoScale( 1 );
	Graph:SetYLabels( true, true );

	Graph:SetMode( "EXPFAST" );
	Graph:SetDecay( 0.5 );
	Graph:SetFilterRadius( 2 );


	-- Resize grip
	local Resize = CreateFrame( "Button", nil, me );
	me.Resize = Resize;
	Resize:SetWidth( 30 );
	Resize:SetHeight( 30 );
	Resize:SetPoint( "BOTTOMRIGHT", 6, -4 );
	Resize:SetFrameLevel( Graph:GetFrameLevel() + 2 );
	Resize:SetNormalTexture( "Interface\\AddOns\\_Latency\\Skin\\ResizeGrip" );
	Resize:SetHighlightTexture( "Interface\\AddOns\\_Latency\\Skin\\ResizeGrip" );
	Resize:SetScript( "OnMouseDown", function ()
		me:StartSizing( "BOTTOMRIGHT" );
	end );
	Resize:SetScript( "OnMouseUp", function ()
		me:StopMovingOrSizing();
	end );
	me:SetMinResize( 44 + me.Title:GetWidth(), 60 );


	me:SetScript( "OnUpdate", me.OnUpdate );
	me:SetScript( "OnEvent", me.OnEvent );
	me:SetScript( "OnSizeChanged", me.OnSizeChanged );
	me:RegisterEvent( "CHAT_MSG_ADDON" );
	me:RegisterEvent( "PLAYER_ENTERING_WORLD" );
	me:RegisterEvent( "ADDON_LOADED" );


	SlashCmdList[ "_LATENCY_TOGGLE" ] = function ( Input )
		if ( Input and Input:trim():lower() == L.LOCK ) then
			me.ToggleLocked();
		else
			me.Toggle();
		end
	end;
end
