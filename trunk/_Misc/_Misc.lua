--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.lua - Common functions and global events/updates.                    *
  *                                                                            *
  * + The RaidWarning frame remembers 5 lines of text and shows the author of  *
  *   the messages similarly to /rs.                                           *
  * + The faction watch bar will automatically show the most recently active   *
  *   faction.                                                                 *
  * + Dismounts you automatically when the taxi map is opened.                 *
  * + Adds a status label to the middle of the screen indicating when the      *
  *   player goes AFK or DND.                                                  *
  * + Autoloots all quality fishing loot.                                      *
  ****************************************************************************]]


_MiscOptions = {};


local L = _MiscLocalization;
local me = CreateFrame( "Frame" );
_Misc = me;

local AddOnInitializers = {};
me.AddOnInitializers = AddOnInitializers;
local ProtectedFunctionQueue = {};
me.ProtectedFunctionQueue = ProtectedFunctionQueue;
me.InCombatLockdown = false;
local Time = {
	Hour = GetGameTime();
	Minute = select( 2, GetGameTime() );
	Second;
	LastSecond;
	StringCache;
};
me.Time = Time;

local AfkDndStatus = CreateFrame( "Frame", nil, UIParent );
me.AfkDndStatus = AfkDndStatus;
AfkDndStatus.Text = AfkDndStatus:CreateFontString( nil, "ARTWORK", "GameFontNormalHuge" );




--[[****************************************************************************
  * Function: _Misc.NilFunction                                                *
  * Description: Recycled generic function placeholder.                        *
  ****************************************************************************]]
me.NilFunction = _Dev and _Dev.NilFunction or function () end;
--[[****************************************************************************
  * Function: _Misc.Print                                                      *
  * Description: Write a string to the specified frame, or to the default chat *
  *   frame when unspecified. Output color defaults to yellow.                 *
  ****************************************************************************]]
me.Print = _Dev and _Dev.Print or function ( Message, ChatFrame, Color )
	if ( not Color ) then
		Color = NORMAL_FONT_COLOR;
	end
	( ChatFrame or DEFAULT_CHAT_FRAME ):AddMessage( tostring( Message ), Color.r, Color.g, Color.b, Color.id );
end;
--[[****************************************************************************
  * Function: _Misc.Exec                                                       *
  * Description: Works like RunScript, but returns the output.                 *
  ****************************************************************************]]
me.Exec = _Dev and _Dev.Exec or function ( Script, ... )
	local Function, ErrorMessage = loadstring( "return "..Script );
	if ( Function ) then
		return pcall( Function, ... );
	else -- Error parsing
		return false, ErrorMessage;
	end
end;


--[[****************************************************************************
  * Function: _Misc.InitializeAddOn                                            *
  * Description: Runs the initializer for an addon if one is present, and then *
  *   removes it from the initializer list.                                    *
  ****************************************************************************]]
function me.InitializeAddOn ( Name )
	Name = Name:upper(); -- For case insensitive file systems (Windows')
	if ( AddOnInitializers[ Name ] and IsAddOnLoaded( Name ) ) then
		AddOnInitializers[ Name ]();
		AddOnInitializers[ Name ] = nil;
		return true;
	end
end
--[[****************************************************************************
  * Function: _Misc.RegisterAddOnInitializer                                   *
  * Description: Adds an addon's initializer function to the initializer list. *
  ****************************************************************************]]
function me.RegisterAddOnInitializer ( Name, Initializer )
	if ( IsAddOnLoaded( Name ) ) then
		Initializer();
		return true;
	else
		AddOnInitializers[ Name:upper() ] = Initializer;
	end
end


--[[****************************************************************************
  * Function: _Misc:RunProtectedFunction                                       *
  * Description: Runs an function, or stores it until after combat ends if it  *
  *   calls protected functions.                                               *
  ****************************************************************************]]
do
	local tinsert = tinsert;
	function me:RunProtectedFunction ( Function, Protected )
		if ( self.InCombatLockdown and Protected ) then -- Store for later
			tinsert( self.ProtectedFunctionQueue, Function );
		else
			Function();
		end
	end
end
--[[****************************************************************************
  * Function: _Misc:HookScript                                                 *
  * Description: Hooks event handlers even when an original isn't present.     *
  ****************************************************************************]]
function me:HookScript ( Script, Handler )
	if ( self:GetScript( Script ) ) then
		self:HookScript( Script, Handler );
	else
		self:SetScript( Script, Handler );
	end
end


--[[****************************************************************************
  * Function: _Misc:RaidWarningFrameOnEvent                                    *
  * Description: Adds the author to raid warning messages.                     *
  ****************************************************************************]]
function me:RaidWarningFrameOnEvent ( Event, Message, Author, ... )
	if ( Author ) then
		Message = L.RAIDWARNING_FORMAT:format( Author, Message );
	end
	return RaidWarningFrame_OnEvent( self, Event, Message, Author, ... );
end
--[[****************************************************************************
  * Function: _Misc.SetItemRef                                                 *
  * Description: Allows the UI to recognize "|Hurl:" as a hyperlink.           *
  ****************************************************************************]]
do
	local Backup = SetItemRef;
	function me.SetItemRef ( Link, Text, Button, ... )
		if ( Link:sub( 1, 3 ) == "url" ) then
			Link = Link:sub( 5 );
			local EditBox = DEFAULT_CHAT_FRAME.editBox;
			if ( IsModifiedClick( "CHATLINK" ) and EditBox:IsVisible() ) then
				EditBox:Insert( EditBox:GetText() );
			end
		else
			return Backup( Link, Text, Button, ... );
		end
	end
end


--[[****************************************************************************
  * Function: _Misc:LOOT_OPENED                                                *
  * Description: Autoloots all items in fishing loot despite BoP status.       *
  ****************************************************************************]]
function me:LOOT_OPENED ()
	if ( IsFishingLoot() ) then
		for Index = 1, GetNumLootItems() do
			LootSlot( Index );
			ConfirmLootSlot( Index );
		end
	end
end
--[[****************************************************************************
  * Function: _Misc:COMBAT_TEXT_UPDATE                                         *
  ****************************************************************************]]
do
	local GetWatchedFactionInfo = GetWatchedFactionInfo;
	function me:COMBAT_TEXT_UPDATE ( Event, Type, Faction, Value )
		if ( Type == "FACTION" and Faction ~= GetWatchedFactionInfo() ) then
			for Index = 1, GetNumFactions() do
				if ( Faction == GetFactionInfo( Index ) ) then
					SetWatchedFactionIndex( Index );
					break;
				end
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Misc:TAXIMAP_OPENED                                             *
  ****************************************************************************]]
function me:TAXIMAP_OPENED ()
	Dismount();
end
--[[****************************************************************************
  * Function: _Misc:ADDON_LOADED                                               *
  ****************************************************************************]]
function me:ADDON_LOADED ( Event, AddOn )
	self.InitializeAddOn( AddOn );
end
--[[****************************************************************************
  * Function: _Misc:PLAYER_LOGIN                                               *
  ****************************************************************************]]
function me:PLAYER_LOGIN ()
	me.FCF.UpdateStickyType();
end
--[[****************************************************************************
  * Function: _Clean:PLAYER_REGEN_DISABLED                                     *
  ****************************************************************************]]
function me:PLAYER_REGEN_DISABLED ()
	me.InCombatLockdown = true;
end
--[[****************************************************************************
  * Function: _Misc:PLAYER_REGEN_ENABLED                                       *
  ****************************************************************************]]
function me:PLAYER_REGEN_ENABLED ()
	me.InCombatLockdown = false;

	-- Combat lockdown over; run all stored functions
	for Index = 1, #ProtectedFunctionQueue do
		ProtectedFunctionQueue[ Index ]();
		ProtectedFunctionQueue[ Index ] = nil;
	end
end


--[[****************************************************************************
  * Function: _Misc:OnEvent                                                    *
  * Description: Global event handler.                                         *
  ****************************************************************************]]
do
	local type = type;
	function me:OnEvent ( Event, ... )
		if ( type( me[ Event ] ) == "function" ) then
			me[ Event ]( self, Event, ... );
		end
	end
end
--[[****************************************************************************
  * Function: _Misc:OnUpdate                                                   *
  * Description: Global update handler.                                        *
  ****************************************************************************]]
function me:OnUpdate ( Elapsed )
	Time.OnUpdate( self, Elapsed );
end




--------------------------------------------------------------------------------
-- _Misc.Time
-------------

--[[****************************************************************************
  * Function: _Misc.Time.IsKnown                                               *
  * Description: Returns true if the hour and minute server times are loaded.  *
  ****************************************************************************]]
function Time.IsKnown ()
	return Time.Hour ~= -1;
end
--[[****************************************************************************
  * Function: _Misc.Time.GetGameTimeParts                                      *
  * Description: Gets time parts used in formating time strings.               *
  ****************************************************************************]]
function Time.GetGameTimeParts ()
	return Time.Hour, Time.Minute,
		Time.Second and L.TIME_VALUE_FORMAT:format( Time.Second ) or L.TIME_VALUE_UNKNOWN;
end
--[[****************************************************************************
  * Function: _Misc.Time.FormatString                                          *
  * Description: Formats the time into a string.                               *
  ****************************************************************************]]
function Time.FormatString ()
	return L.TIME_FORMAT:format( Time.GetGameTimeParts() );
end
--[[****************************************************************************
  * Function: _Misc.Time.GetGameTimeString                                     *
  * Description: Gets the server time, including an estimate of seconds.       *
  ****************************************************************************]]
function Time.GetGameTimeString ()
	return Time.StringCache or Time.FormatString();
end

--[[****************************************************************************
  * Function: _Misc.Time:OnUpdate                                              *
  * Description: Keeps accurate track of seconds relative to the server time.  *
  ****************************************************************************]]
do
	local floor = floor;
	function Time:OnUpdate ( Elapsed )
		if ( Time.Second ) then
			Time.Second = Time.Second + Elapsed;
		end
	
		local Hour, Minute = GetGameTime();
		if ( Minute ~= Time.Minute or Hour ~= Time.Hour ) then -- Server time changed
			if ( Time.Minute ) then -- At least one minute is already synched
				Time.Second = 0; -- Start second count from synced minute
			end
			Time.Hour   = Hour;
			Time.Minute = Minute;
		end
	
		local NewSecond = Time.Second and Time.LastSecond ~= floor( Time.Second );
		if ( NewSecond ) then
			Time.LastSecond = floor( Time.Second );
		end
		if ( NewSecond or not Time.LastSecond ) then
			Time.StringCache = Time.FormatString();
			Time.Text:SetFormattedText( L.TIMETEXT_FORMAT, Time.StringCache );
		end
	end
end




--------------------------------------------------------------------------------
-- _Misc.AfkDndStatus
---------------------

--[[****************************************************************************
  * Function: _Misc.AfkDndStatus:Update                                        *
  * Description: Updates the display based on the Status flag.                 *
  ****************************************************************************]]
function AfkDndStatus:Update ()
	local Status = ( UnitIsAFK( "player" ) and CHAT_FLAG_AFK )
		or ( UnitIsDND( "player" ) and CHAT_FLAG_DND )
		or nil;

	if ( Status ) then
		self.Text:SetText( Status );
		self:Show();
	else
		self:Hide();
	end
end
--[[****************************************************************************
  * Function: _Misc.AfkDndStatus:PLAYER_FLAGS_CHANGED                          *
  ****************************************************************************]]
function AfkDndStatus:PLAYER_FLAGS_CHANGED ( Event, UnitID )
	if ( UnitID == "player" ) then
		self:Update();
	end
end
--[[****************************************************************************
  * Function: _Misc.AfkDndStatus:PLAYER_ENTERING_WORLD                         *
  ****************************************************************************]]
function AfkDndStatus:PLAYER_ENTERING_WORLD ()
	self:Update();
end
--[[****************************************************************************
  * Function: _Misc.AfkDndStatus:OnEvent                                       *
  * Description: Shows and hides the status text when AFK or DND.              *
  ****************************************************************************]]
function AfkDndStatus:OnEvent ( Event, ... )
	if ( type( self[ Event ] ) == "function" ) then
		self[ Event ]( self, Event, ... );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", me.OnEvent );
	me:SetScript( "OnUpdate", me.OnUpdate );

	me:RegisterEvent( "COMBAT_TEXT_UPDATE" );
	me:RegisterEvent( "TAXIMAP_OPENED" );
	me:RegisterEvent( "ADDON_LOADED" );
	me:RegisterEvent( "PLAYER_LOGIN" );
	me:RegisterEvent( "LOOT_OPENED" );
	me:RegisterEvent( "PLAYER_REGEN_ENABLED" );
	me:RegisterEvent( "PLAYER_REGEN_DISABLED" );

	AfkDndStatus:Hide();
	AfkDndStatus:SetFrameStrata( "BACKGROUND" );
	AfkDndStatus:SetScript( "OnEvent", AfkDndStatus.OnEvent );
	AfkDndStatus:RegisterEvent( "PLAYER_FLAGS_CHANGED" );
	AfkDndStatus:RegisterEvent( "PLAYER_ENTERING_WORLD" );
	AfkDndStatus.Text:SetPoint( "BOTTOM", AutoFollowStatusText, "TOP" );

	-- Create the time display
	local TimeText = UIParent:CreateFontString( nil, "OVERLAY" );
	TimeText:SetPoint( "TOPLEFT", UIParent );
	if ( IsAddOnLoaded( "_Dev" ) ) then
		_Dev.Stats:SetPoint( "TOPLEFT", TimeText, "TOPRIGHT" );
	end
	if ( IsAddOnLoaded( "_Clean" ) ) then
		TimeText:SetFontObject( _Clean.MonospaceNumberFont );
	else
		TimeText:SetFontObject( NumberFontNormalSmall );
	end
	TimeText:SetAlpha( 0.5 );
	Time.Text = TimeText;

	-- Add undress button to dressupframe
	local Button = CreateFrame( "Button", nil, DressUpFrame, "UIPanelButtonTemplate" );
	Button:SetWidth( 80 );
	Button:SetHeight( 22 );
	Button:SetPoint( "RIGHT", Button:GetParent():GetName().."ResetButton", "LEFT" );
	Button:SetText( L.UNDRESS_LABEL );
	Button:SetScript( "OnClick",
		function () 
			DressUpModel:Undress();
			PlaySound( "gsTitleOptionOK" );
		end );


	-- Allow ctrl-left click to focus units
	local Button = CreateFrame( "Button", "_MiscFocusMouseoverButton", nil, "SecureActionButtonTemplate" );
	Button:SetAttribute( "type", "macro" );
	Button:SetAttribute( "macrotext", "/focus mouseover" ); -- Allow clearing focus when no mouseover
	Button:SetScript( "OnEvent", function ( self )
		if ( not InCombatLockdown() ) then
			self:UnregisterEvent( "UPDATE_BINDINGS" );
			SetBindingClick( "CTRL-BUTTON1", "_MiscFocusMouseoverButton" );
			SetOverrideBinding( self, true, "CTRL-SHIFT-BUTTON1", "CAMERAORSELECTORMOVE" );
			SetOverrideBinding( self, true, "ALT-CTRL-BUTTON1", "CAMERAORSELECTORMOVE" );
			self:RegisterEvent( "UPDATE_BINDINGS" );
		end
	end );
	Button:RegisterEvent( "UPDATE_BINDINGS" );


	-- Hooks
	SetItemRef = me.SetItemRef;
	RaidWarningFrame:SetScript( "OnEvent", me.RaidWarningFrameOnEvent );
end
