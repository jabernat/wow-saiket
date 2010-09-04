--[[****************************************************************************
  * _Latency by Saiket                                                         *
  * _Latency.lua - Adds a latency graph that updates using chat message pings. *
  ****************************************************************************]]


_LatencyOptions = {
	IsLocked = false;
};


local AddOnName, me = ...;
local L = me.L;
local LibGraph = LibStub( "LibGraph-2.0" );

me.Frame = CreateFrame( "Frame", nil, UIParent );
me.Resize = CreateFrame( "Button", nil, me.Frame );

-- Configuration
me.PingRate = 0.1; -- Minimum time between pings
me.UpdateRate = 0.5; -- Time between graph/label updates
me.PingDataAge = 5; -- Time to keep ping time data in the running average
me.MaxSimultaneousPings = 1; -- Max number of pings that can be sent at once


me.Prefix = "_L";

me.PingData = {};
me.PingCutoff = 0;
me.NumPings = 0; -- Number of pings en-route

me.TopColor = { r = 0.8, g = 0.8, b = 17 / 32 }; -- Gold
me.BottomColor = { r = 0.4; g = 0.4; b = 0.0; a = 0.4; }; -- Modified based on ping
me.Padding = 6;




--- Toggles the mod window.
-- @param Enable  True or false to show/hide the window, or nil to toggle.
function me.Toggle ( Enable )
	if ( Enable == nil ) then
		Enable = not me.Frame:IsShown();
	end

	if ( Enable ) then
		me.Frame:Show();
	else
		me.Frame:Hide();
	end
end
--- Toggles whether the frame is locked or not.
-- @param Enable  True or false to lock/unlock controls, or nil to toggle.
function me.ToggleLocked ( Locked )
	if ( Locked == nil ) then
		Locked = not _LatencyOptions.IsLocked;
	end
	_LatencyOptions.IsLocked = Locked;
	local Enable = not Locked;

	me.Frame:EnableMouse( Enable );
	me.Close:EnableMouse( Enable );
	SetDesaturation( me.Close:GetNormalTexture(), Locked );
	me.Resize:EnableMouse( Enable );
	if ( Enable ) then
		me.Close:Enable();
		me.Resize:Enable();
	else
		me.Close:Disable();
		me.Resize:Disable();
		me.Frame:StopMovingOrSizing();
	end
end


do
	local lshift = bit.lshift;
	local MaxFloatPart = 2 ^ 14 - 1;
	--- Decodes an encoded time string to a floating-point number.
	-- @param String  Encoded time string from _Latency.TimeEncode.
	-- @return Floating point time relative to GetTime().
	-- @see _Latency.TimeEncode
	function me.TimeDecode ( String )
		local FP1, FP2 = String:byte( 1, 2 );
		local FloatPart = ( lshift( FP1 - 0x80, 7 ) + ( FP2 - 0x80 ) ) / MaxFloatPart;

		local IntPart = 0;
		for Index = 3, #String do
			IntPart = IntPart + lshift( String:byte( Index ) - 0x80, 7 * ( Index - 3 ) );
		end

		return IntPart + FloatPart;
	end

	local floor = floor;
	local band = bit.band;
	local rshift = bit.rshift;
	local Bytes = {};
	--- Encodes the current time to a string.
	-- Format is "[fH][fL][iL][i2][i3]...[iH]" with (f)loat, (i)nt, (H)igh, (L)ow.
	-- @return Binary data string with no embedded nulls.
	function me.TimeEncode ()
		local Time = GetTime();
		local IntPart = floor( Time );
		local FloatPart = floor( ( Time - IntPart ) * MaxFloatPart + 0.5 );

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


--- Returns a running average of the player's ping.
function me.GetAveragePing ()
	local MinSendTime = GetTime() - me.PingDataAge;
	local Count, Total = 0, 0;
	for SendTime, Latency in pairs( me.PingData ) do
		if ( SendTime + Latency > MinSendTime ) then
			Count = Count + 1;
			Total = Total + Latency;
		else
			me.PingData[ SendTime ] = nil;
		end
	end
	if ( Count ~= 0 and Total ~= 0 ) then
		return Total / Count * 1000;
	end
end


--- Starts resizing the frame.
function me.Resize:OnMouseDown ()
	self:GetParent():StartSizing( "BOTTOMRIGHT" );
end
--- Stops resizing the frame.
function me.Resize:OnMouseUp ()
	self:GetParent():StopMovingOrSizing();
end


--- Saves position and size information before logging out.
function me.Frame:PLAYER_LOGOUT ()
	local Options, _ = _LatencyOptions;
	Options.Width, Options.Height = me.Frame:GetSize();
	Options.Point, _, _, Options.X, Options.Y = me.Frame:GetPoint();
end
--- Prevent pings from before zoning from being read after loading.
function me.Frame:PLAYER_ENTERING_WORLD ()
	me.PingCutoff = GetTime();
	me.NumPings = 0; -- Prevent issue with losing messages when entering/leaving BGs.
end
--- Reads round trip ping messages and times them.
function me.Frame:CHAT_MSG_ADDON ( _, Prefix, Message, Type, Author )
	if ( Prefix == me.Prefix and Type == "WHISPER" and Author == UnitName( "player" ) ) then
		if ( me.NumPings > 0 ) then
			me.NumPings = me.NumPings - 1;
		end

		local SendTime = me.TimeDecode( Message );
		if ( SendTime >= me.PingCutoff ) then
			me.PingData[ SendTime ] = GetTime() - SendTime;
		end
	end
end
--- Applies settings when loaded.
function me.Frame:ADDON_LOADED ( Event, AddOn )
	if ( AddOn == AddOnName ) then
		self:UnregisterEvent( Event );
		self[ Event ] = nil;

		local Options = _LatencyOptions;
		self:ClearAllPoints();
		self:SetPoint( Options.Point or "CENTER", nil, Options.Point or "CENTER", Options.X or 0, Options.Y or 0 );
		self:SetSize( Options.Width or 300, Options.Height or 80 );
		me.ToggleLocked( Options.IsLocked );
	end
end
--- Global event handler.
function me.Frame:OnEvent ( Event, ... )
	if ( self[ Event ] ) then
		return self[ Event ]( self, Event, ... );
	end
end


do
	local LastPing = me.PingRate;
	local LastUpdate = me.UpdateRate;
	local min, max = min, max;
	--- Periodically sends ping messages and updates the graph display.
	function me.Frame:OnUpdate ( Elapsed )
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
				me.Label:SetFormattedText( L.LABEL_FORMAT, Ping );
			end

			local Value = me.Graph:GetValue( me.Graph.XMax );
			me.BottomColor.r = min( Value / 400, 1 );
			me.BottomColor.g = min( max( 1 - Value / 150 * 0.4, 0 ), 0.4 );
			me.Graph:SetBarColors( me.BottomColor, me.TopColor );
		end
	end
end


--- Resizes the graph to match the window size.
function me.Frame:OnSizeChanged ()
	-- Note: LibGraph-2.0 doesn't hook SetSize, so use SetWidth/Height.
	me.Graph:SetWidth( self:GetWidth() - me.Padding * 2 );
	me.Graph:SetHeight( self:GetHeight() - me.Padding * 2 - 18 );
end
--- Prints a notice for how to reopen the window.
function me.Frame:OnHide ()
	if ( not self:IsShown() ) then -- Was directly hidden (i.e. didn't hide interface)
		self:SetScript( "OnHide", nil ); -- Only print once
		self.OnHide = nil;
		print( L.ONCLOSE_NOTICE );
	end
end


--- Slash command handler to toggle the window or lock it.
function me.SlashCommand ( Input )
	if ( Input and Input:trim():lower() == L.LOCK ) then
		me.ToggleLocked();
	else
		me.Toggle();
	end
end




-- Set up window
local Frame = me.Frame;
Frame:Hide();
Frame:SetScale( 0.8 );
Frame:SetFrameStrata( "MEDIUM" );
Frame:SetToplevel( true );
Frame:SetBackdrop( {
	bgFile = [[Interface\TutorialFrame\TutorialFrameBackground]];
	edgeFile = [[Interface\TutorialFrame\TutorialFrameBorder]];
	tile = true; tileSize = 32; edgeSize = 32;
	insets = { left = 7; right = 5; top = 3; bottom = 6; };
} );
-- Make dragable
Frame:EnableMouse( true );
Frame:SetResizable( true );
Frame:SetClampedToScreen( true );
Frame:SetClampRectInsets( me.Padding + 2, -me.Padding, -me.Padding - 18, me.Padding );
Frame:CreateTitleRegion():SetAllPoints();
-- Close button
me.Close = CreateFrame( "Button", nil, Frame, "UIPanelCloseButton" );
me.Close:SetPoint( "TOPRIGHT", 4, 4 );
-- Title
local Title = Frame:CreateFontString( nil, "ARTWORK", "GameFontHighlight" );
Title:SetText( L.TITLE );
Title:SetPoint( "TOPLEFT", Frame, 11, -6 );
-- Ping label
me.Label = Frame:CreateFontString( nil, "ARTWORK", "GameFontNormal" );
me.Label:SetPoint( "LEFT", Title, "RIGHT", 4, 0 );
me.Label:SetPoint( "RIGHT", me.Close, "LEFT", -4, 0 );
me.Label:SetJustifyH( "RIGHT" );

-- Graph
local Graph = LibGraph:CreateGraphRealtime( "_LatencyGraph", Frame, "BOTTOMLEFT", "BOTTOMLEFT",
	me.Padding + 2, me.Padding, Frame:GetWidth() - me.Padding * 2, Frame:GetHeight() - me.Padding * 2 - 18 );
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
local Resize = me.Resize;
Resize:SetSize( 30, 30 );
Resize:SetPoint( "BOTTOMRIGHT", 6, -4 );
Resize:SetFrameLevel( Graph:GetFrameLevel() + 2 );
Resize:SetNormalTexture( [[Interface\AddOns\]]..AddOnName..[[\Skin\ResizeGrip]] );
Resize:SetHighlightTexture( [[Interface\AddOns\]]..AddOnName..[[\Skin\ResizeGrip]] );
Resize:SetScript( "OnMouseDown", Resize.OnMouseDown );
Resize:SetScript( "OnMouseUp", Resize.OnMouseUp );
Frame:SetMinResize( 44 + Title:GetWidth(), 60 );


Frame:SetScript( "OnEvent", Frame.OnEvent );
Frame:SetScript( "OnUpdate", Frame.OnUpdate );
Frame:SetScript( "OnSizeChanged", Frame.OnSizeChanged );
Frame:SetScript( "OnHide", Frame.OnHide );
Frame:RegisterEvent( "CHAT_MSG_ADDON" );
Frame:RegisterEvent( "PLAYER_ENTERING_WORLD" );
Frame:RegisterEvent( "ADDON_LOADED" );
Frame:RegisterEvent( "PLAYER_LOGOUT" );


SlashCmdList[ "_LATENCY_TOGGLE" ] = me.SlashCommand;
-- Un-cache stub slash commands created by AddonLoader
for Command in GetAddOnMetadata( AddOnName, "X-LoadOn-Slash" ):gmatch( "/[^%s,]+" ) do
	Command = Command:upper();
	hash_SlashCmdList[ Command ] = nil;
	_G[ "SLASH_"..Command:sub( 2 ).."1" ] = nil;
end