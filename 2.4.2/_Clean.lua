--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.lua - Common functions.                                             *
  ****************************************************************************]]


_CleanOptions = {};


local me = CreateFrame( "Frame" );
_Clean = me;

local AddOnInitializers = {};
me.AddOnInitializers = AddOnInitializers;
local ProtectedMethodQueue = {};
me.ProtectedMethodQueue = ProtectedMethodQueue;
me.InCombatLockdown = false;
local PositionManagers = {};
me.PositionManagers = PositionManagers;
local LockedButtons = {};
me.LockedButtons = LockedButtons;

me.Colors = {
	Say      = { r = 1.0; g = 1.0; b = 1.0; };
	Yell     = { r = 1.0; g = 0.25; b = 0.25; };
	Emote1   = { r = 1.0; g = 0.4; b = 0.2; };
	Emote2   = { r = 0.8; g = 1/3; b = 0.125; }; -- Custom text emotes
	Guild1   = { r = 0.125; g = 0.9; b = 0.07; };
	Guild2   = { r = 0.6; g = 1.0; b = 0.4; }; -- Officer chat
	Whisper1 = { r = 0.7; g = 1/3; b = 0.7; };
	Whisper2 = { r = 1.0; g = 0.5; b = 1.0; }; -- Outbound

	Party = { r = 2/3; g = 2/3; b = 1.0; };
	Raid1 = { r = 1.0; g = 0.6; b = 0.0; };
	Raid2 = { r = 1.0; g = 2/3; b = 0.0; }; -- Raid leader
	Raid3 = { r = 1.0; g = 0.4; b = 0.0; }; -- CT_RaidAssist messages
	Battleground1 = { r = 0.0; g = 0.8; b = 1.0; };
	Battleground2 = { r = 0.4; g = 0.8; b = 1.0; }; -- Battleground leader

	Channel1 = { r = 1.0; g = 0.8; b = 0.8; };
	Channel2 = { r = 2/3; g = 0.5; b = 0.5; }; -- Dimmed

	Hostile1  = { r = 0.8; g = 0.5; b = 0.5; }; -- Brighter
	Hostile2  = { r = 0.8; g = 1/3; b = 1/3; };
	Friendly1 = { r = 0.4; g = 1.0; b = 0.4; }; -- Brighter
	Friendly2 = { r = 0.2; g = 0.6; b = 0.2; };
	Mana = { r = 0.2; g = 0.2; b = 1.0; };

	Miss = { r = 0.5; g = 0.5; b = 0.5; }; -- Miss, dodge, evade, etc.
	Fail = { r = 1/3; g = 1/3; b = 1/3; }; -- Couldn't cast

	Loot    = { r = 0.0; g = 0.4; b = 0.2; }; -- Money, loot, tradeskills
	System  = { r = 1.0; g = 1.0; b = 0.0; };
	Gain    = { r = 0.4; g = 2/3; b = 1.0; }; -- Rep., faction, XP, skills
	Warning = { r = 1.0; g = 0.07; b = 0.0; }; -- Raidwarning, localdefense
};

me.MonospaceFont = CreateFont( "_CleanMonospace" );
me.MonospaceNumberFont = CreateFont( "_CleanMonospaceNumber" );




--[[****************************************************************************
  * Function: _Clean.NilFunction                                               *
  * Description: Recycled generic function placeholder.                        *
  ****************************************************************************]]
me.NilFunction = _Dev and _Dev.NilFunction or function () end;
--[[****************************************************************************
  * Function: _Clean.Print                                                     *
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
  * Function: _Clean.InitializeAddOn                                           *
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
  * Function: _Clean.RegisterAddOnInitializer                                  *
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
  * Function: _Clean:RunProtectedMethod                                        *
  * Description: Runs an arbitrary method if possible, or after combat ends.   *
  ****************************************************************************]]
do
	local tinsert = tinsert;
	function me:RunProtectedMethod ( Method, ... )
		if ( me.InCombatLockdown and self:IsProtected() ) then -- Store for later
			tinsert( ProtectedMethodQueue, { Method, self, ... } );
		else
			self[ Method ]( self, ... );
		end
	end
end
--[[****************************************************************************
  * Function: _Clean:SetPoint                                                  *
  * Description: RunProtectedMethod shortcut for SetPoint.                     *
  ****************************************************************************]]
do
	local RunProtectedMethod = me.RunProtectedMethod;
	function me:SetPoint ( ... )
		RunProtectedMethod( self, "SetPoint", ... );
	end
end
--[[****************************************************************************
  * Function: _Clean:SetAllPoints                                              *
  * Description: RunProtectedMethod shortcut for SetAllPoints.                 *
  ****************************************************************************]]
do
	local RunProtectedMethod = me.RunProtectedMethod;
	function me:SetAllPoints ( Frame )
		RunProtectedMethod( self, "SetAllPoints", Frame );
	end
end
--[[****************************************************************************
  * Function: _Clean:ClearAllPoints                                            *
  * Description: RunProtectedMethod shortcut for ClearAllPoints.               *
  ****************************************************************************]]
do
	local RunProtectedMethod = me.RunProtectedMethod;
	function me:ClearAllPoints ()
		RunProtectedMethod( self, "ClearAllPoints" );
	end
end
--[[****************************************************************************
  * Function: _Clean:HookScript                                                *
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
  * Function: _Clean.ManagePositions                                           *
  * Description: Calls all frame position manager overrides.                   *
  ****************************************************************************]]
function me.ManagePositions ()
	for _, Manager in ipairs( PositionManagers ) do
		Manager();
	end
end
--[[****************************************************************************
  * Function: _Clean.AddPositionManager                                        *
  * Description: Adds a position manager override.                             *
  ****************************************************************************]]
function me.AddPositionManager ( Manager )
	tinsert( PositionManagers, Manager );
end


--[[****************************************************************************
  * Function: _Clean.AddLockedButton                                           *
  * Description: Registers a button to only accept mouse clicks when the       *
  *   control modifier is held.                                                *
  ****************************************************************************]]
function me.AddLockedButton ( Button )
	LockedButtons[ Button ] = true;
	me.RunProtectedMethod( Button, "EnableMouse", IsControlKeyDown() == 1 );
end
--[[****************************************************************************
  * Function: _Clean.RemoveLockedButton                                        *
  * Description: Unlocks a button.                                             *
  ****************************************************************************]]
function me.RemoveLockedButton ( Button )
	LockedButtons[ Button ] = nil;
	me.RunProtectedMethod( Button, "EnableMouse", true );
end


--[[****************************************************************************
  * Function: _Clean:RemoveButtonIconBorder                                    *
  * Description: Hides the border graphic from an action button-like icon.     *
  ****************************************************************************]]
function me:RemoveButtonIconBorder ()
	self:SetTexCoord( 0.08, 0.92, 0.08, 0.92 );
end


--[[****************************************************************************
  * Function: _Clean:MODIFIER_STATE_CHANGED                                    *
  ****************************************************************************]]
do
	local RunProtectedMethod = me.RunProtectedMethod;
	local pairs = pairs;
	function me:MODIFIER_STATE_CHANGED ( _, Modifier, State )
		if ( Modifier:sub( 2 ) == "CTRL" ) then
			local Enable = State == 1;
			for Button in pairs( LockedButtons ) do
				RunProtectedMethod( Button, "EnableMouse", Enable );
				if ( not Enable ) then
					-- Don't let it get locked on the cursor
					RunProtectedMethod( Button, "StopMovingOrSizing" );
				end
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Clean:PLAYER_REGEN_DISABLED                                     *
  ****************************************************************************]]
function me:PLAYER_REGEN_DISABLED ()
	me.InCombatLockdown = true;
end
--[[****************************************************************************
  * Function: _Clean:PLAYER_REGEN_ENABLED                                      *
  ****************************************************************************]]
function me:PLAYER_REGEN_ENABLED ()
	me.InCombatLockdown = false;

	-- Combat lockdown over; set all stored points
	for Index = 1, #ProtectedMethodQueue do
		local Args = ProtectedMethodQueue[ Index ];

		Args[ 2 ][ Args[ 1 ] ]( select( 2, unpack( Args ) ) );
		ProtectedMethodQueue[ Index ] = nil;
	end
end
--[[****************************************************************************
  * Function: _Clean:ADDON_LOADED                                              *
  ****************************************************************************]]
function me:ADDON_LOADED ( _, AddOn )
	me.InitializeAddOn( AddOn );
end

--[[****************************************************************************
  * Function: _Clean:OnEvent                                                   *
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




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", me.OnEvent );
	me:RegisterEvent( "ADDON_LOADED" );
	me:RegisterEvent( "PLAYER_REGEN_ENABLED" );
	me:RegisterEvent( "PLAYER_REGEN_DISABLED" );
	me:RegisterEvent( "MODIFIER_STATE_CHANGED" );

	hooksecurefunc( "UIParent_ManageFramePositions", me.ManagePositions );


	-- Set up font replacement
	me.MonospaceFont:SetFont(
		"Interface\\AddOns\\_Clean\\Skin\\DejaVuSansMono.ttf", 10, "" );
	me.MonospaceNumberFont:SetFont(
		"Interface\\AddOns\\_Clean\\Skin\\DejaVuSansMono.ttf", 8, "OUTLINE" );
	me.RegisterAddOnInitializer( "Blizzard_MacroUI",
		function () MacroFrameText:SetFontObject( me.MonospaceFont ); end );
	me.RegisterAddOnInitializer( "_Dev",
		function () _Dev.Font:SetFontObject( me.MonospaceNumberFont ); end );
end
