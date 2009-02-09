--[[****************************************************************************
  * _Dev by Saiket                                                             *
  * _Dev.lua - Common functions.                                               *
  *                                                                            *
  * + math.round(float,precision) rounds float to precision decimal places.    *
  * + table.count(table) returns the number of table entries for indexed and   *
  *   associative arrays alike.                                                *
  * + Escape pipes inserted by the client for /script chat slash commands get  *
  *   removed to allow you to type escape sequences in-game.                   *
  * + The console key can only be used when control is held.                   *
  * + Shrinks the console font to 12 pt.                                       *
  * + Key bindings to reload the UI and to open chat with /script.             *
  * + Adds /togglemod <modname> to toggle on and off the given addon and       *
  *   reload the UI if necessary.                                              *
  * + Applies fix to all scrolling message frames to speed up printing many    *
  *   lines to them.  Idea courtesy of Drundia's Fix ScrollingMessageFrame Lag *
  *   addon.                                                                   *
  ****************************************************************************]]


local _DevOptionsOriginal = {
	PrintLuaErrors = true;

	Version = GetAddOnMetadata( "_Dev", "Version" ):match( "^([%d.]+)" );
};
_DevOptions = _DevOptionsOriginal;


local L = _DevLocalization;
local me = CreateFrame( "Frame" );
_Dev = me;

local ScrollingMessageFrames = {};
me.ScrollingMessageFrames = ScrollingMessageFrames;

me.Font = CreateFont( "_DevFont" );
me.ScriptSlashCommandBackup = SlashCmdList[ "SCRIPT" ];




--[[****************************************************************************
  * Function: _Dev.NilFunction                                                 *
  * Description: Recycled generic function placeholder.                        *
  ****************************************************************************]]
function me.NilFunction () end
--[[****************************************************************************
  * Function: _Dev.Print                                                       *
  * Description: Write a string to the specified frame, or to the default chat *
  *   frame when unspecified. Output color defaults to yellow.                 *
  ****************************************************************************]]
do
	local tostring = tostring;
	function me.Print ( Message, ChatFrame, Color )
		if ( not Color ) then
			Color = NORMAL_FONT_COLOR;
		end
		( ChatFrame or DEFAULT_CHAT_FRAME ):AddMessage( tostring( Message ), Color.r, Color.g, Color.b, Color.id );
	end
end
--[[****************************************************************************
  * Function: _Dev:AddMessage                                                  *
  * Description: Hook to speed up printing to scrolling message frames.  Idea  *
  *   courtesy of Drundia's Fix ScrollingMessageFrame Lag addon.               *
  ****************************************************************************]]
function me:AddMessage ()
	if ( not ( ScrollingMessageFrames[ self ] or self:IsProtected() ) ) then
		ScrollingMessageFrames[ self ] = true;
		self:SetHeight( self:GetHeight() );
	end
end
--[[****************************************************************************
  * Function: _Dev.Error                                                       *
  * Description: Displays an error message with the current error handler.     *
  ****************************************************************************]]
function me.Error ( Message, ForcePrint )
	if ( ForcePrint or _DevOptions.PrintLuaErrors ) then
		_Dev.Print( Message, nil, RED_FONT_COLOR );
	else
		geterrorhandler()( Message );
	end
end


--[[****************************************************************************
  * Function: _Dev.IsUIObject                                                  *
  * Description: Attempts to determine whether or not a table represents a     *
  *   frame by its contents.                                                   *
  ****************************************************************************]]
do
	local rawget = rawget;
	local type = type;
	function me.IsUIObject ( Value )
		return type( Value ) == "table"
			and type( rawget( Value, 0 ) ) == "userdata"
			and Value.IsObjectType
			and Value.GetName;
	end
end
--[[****************************************************************************
  * Function: _Dev.Round                                                       *
  * Description: Round a float to the nearest integer.                         *
  ****************************************************************************]]
do
	local floor = floor;
	function me.Round ( Float, Precision )
		if ( Precision ) then
			local Multiplier = 10 ^ Precision;
			return floor( Float * Multiplier + 0.5 ) / Multiplier;
		else
			return floor( Float + 0.5 );
		end
	end
end
--[[****************************************************************************
  * Function: _Dev.Count                                                       *
  * Description: Count the number of items in an array, including those with   *
	*   non-numeric indexes.                                                     *
  ****************************************************************************]]
function me.Count ( Table )
	local TableSize = 0;

	for _ in pairs( Table ) do
		TableSize = TableSize + 1;
	end

	return TableSize;
end


--[[****************************************************************************
  * Function: _Dev.Exec                                                        *
  * Description: Works like RunScript, but returns the output.                 *
  ****************************************************************************]]
function me.Exec ( Script, ... )
	local Function, ErrorMessage = loadstring( "return "..Script );
	if ( Function ) then
		return pcall( Function, ... );
	else -- Error parsing
		return false, ErrorMessage;
	end
end


--[[****************************************************************************
  * Function: _Dev.ScriptSlashCommand                                          *
  * Description: Allows the use of text formatting when scripting through      *
  *   in-game text fields.                                                     *
  ****************************************************************************]]
function me.ScriptSlashCommand ( Input )
	me.ScriptSlashCommandBackup( Input and Input:gsub( "||", "|" ) or nil );
end
--[[****************************************************************************
  * Function: _Dev.OpenChatScriptBinding                                       *
  * Description: Key binding to open chat prefixed with the shortest localized *
  *   /script equivalent slash command.                                        *
  ****************************************************************************]]
function me.OpenChatScriptBinding ()
	local SlashIndex = 0;
	local SlashTextShortest, SlashText;

	while ( true ) do
		SlashIndex = SlashIndex + 1;
		SlashText = _G[ "SLASH_SCRIPT"..SlashIndex ];
		if ( not SlashText ) then
			break;
		elseif ( not SlashTextShortest or #SlashText < #SlashTextShortest ) then
			SlashTextShortest = SlashText;
		end
	end

	ChatFrame_OpenChat( SlashTextShortest.." " );
end
--[[****************************************************************************
  * Function: _Dev.ReloadUIBinding                                             *
  * Description: Key binding to reload the UI.                                 *
  ****************************************************************************]]
me.ReloadUIBinding = function () ReloadUI(); end; -- Allow late binding
--[[****************************************************************************
  * Function: _Dev.ToggleAddOn                                                 *
  * Description: Toggles the given addon and reloads the UI immediately.  If   *
  *   the addon is load on demand, it will be loaded without a reload UI and   *
  *   its enabled or disabled status will not be modified. Returns an error    *
  *    string on failure.                                                      *
  ****************************************************************************]]
function me.ToggleAddOn ( AddOnName )
	local Loaded, ErrorReason;
	ErrorReason = select( 6, GetAddOnInfo( AddOnName ) );

	if ( not ErrorReason or ErrorReason == "DISABLED" ) then
		if ( IsAddOnLoaded( AddOnName ) ) then
			DisableAddOn( AddOnName );
			ReloadUI();
			return;
		elseif ( IsAddOnLoadOnDemand( AddOnName ) ) then
			Loaded, ErrorReason = LoadAddOn( AddOnName );
			if ( Loaded ) then
				return;
			end
		else
			EnableAddOn( AddOnName );
			ReloadUI();
			return;
		end
	end

	return _G[ "ADDON_"..ErrorReason ];
end
--[[****************************************************************************
  * Function: _Dev.ToggleAddOnSlashCommand                                     *
  * Description: Slash command chat handler for the _Dev.ToggleAddOn function. *
  ****************************************************************************]]
function me.ToggleAddOnSlashCommand ( Input )
	if ( Input and not Input:find( "^%s*$" ) ) then
		-- Call will reload UI unless it fails
		local ErrorString = me.ToggleAddOn( Input );
		if ( ErrorString ) then -- Error
			me.Error( L.TOGGLEADDON_ERROR_FORMAT:format( Input, ErrorString ), true );
		end
	end
end


--[[****************************************************************************
  * Function: _Dev:MODIFIER_STATE_CHANGED                                      *
  ****************************************************************************]]
function me:MODIFIER_STATE_CHANGED ( _, Modifier, State )
	Modifier = Modifier:sub( 2 );
	if ( GetModifiedClick( "_DEV_ENABLECONSOLE" ):find( Modifier, 1, true ) ) then
		SetConsoleKey( State == 1 and "`" or nil );
	end
	if ( GetModifiedClick( "_DEV_FRAMES_INTERACTIVE" ):find( Modifier, 1, true ) ) then
		me.Frames.SetInteractive( State == 1 );
	end
end
--[[****************************************************************************
  * Function: _Dev:ADDON_LOADED                                                *
  ****************************************************************************]]
function me:ADDON_LOADED ( _, AddOn )
	if ( AddOn:lower() == "_dev" ) then
		me:UnregisterEvent( "ADDON_LOADED" );
		me.ADDON_LOADED = nil;

		if ( _DevOptions.Version ~= _DevOptionsOriginal.Version ) then
			-- Reset settings
			_DevOptions = _DevOptionsOriginal;
		end
		me.Outline:OnLoad();
		me.Stats:OnLoad();
		me.Options:OnLoad();
	end
end
--[[****************************************************************************
  * Function: _Dev:OnEvent                                                     *
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
  * Function: _Dev:OnUpdate                                                    *
  * Description: Simulates the MODIFIER_STATE_CHANGED event, but continues to  *
  *   work even when an editbox has keyboard focus.                            *
  ****************************************************************************]]
do
	local IsShiftKeyDown = IsShiftKeyDown;
	local IsControlKeyDown = IsControlKeyDown;
	local IsAltKeyDown = IsAltKeyDown;

	local LastShift, LastCtrl, LastAlt; -- Last states of modifiers
	local Shift, Ctrl, Alt;
	local Color = ChatTypeInfo[ "SYSTEM" ]; -- ID 1
	function me:OnUpdate ()
		Shift, Ctrl, Alt = IsShiftKeyDown(), IsControlKeyDown(), IsAltKeyDown();
		if ( Shift ~= LastShift ) then
			LastShift = Shift;
			me:OnEvent( "MODIFIER_STATE_CHANGED", "*SHIFT", Shift or 0 );
		end
		if ( Ctrl ~= LastCtrl ) then
			LastCtrl = Ctrl;
			me:OnEvent( "MODIFIER_STATE_CHANGED", "*CTRL", Ctrl or 0 );
		end
		if ( Alt ~= LastAlt ) then
			LastAlt = Alt;
			me:OnEvent( "MODIFIER_STATE_CHANGED", "*ALT", Alt or 0 );
		end

		-- Refresh any updated message frames
		for MessageFrame in pairs( ScrollingMessageFrames ) do
			ScrollingMessageFrames[ MessageFrame ] = nil;
			if ( MessageFrame:IsVisible() ) then
				MessageFrame:UpdateColorByID( Color.id, Color.r, Color.g, Color.b ); -- Redraws text
			end
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	ConsoleExec( "fontsize 12" ); -- The console's font size
	me.Font:SetFontObject( NumberFontNormalSmall );

	-- Events
	me:SetScript( "OnEvent", me.OnEvent );
	me:SetScript( "OnUpdate", me.OnUpdate );
	me:RegisterEvent( "ADDON_LOADED" );

	-- Hooks
	math.round = me.Round;
	table.count = me.Count;

	SlashCmdList[ "SCRIPT" ] = me.ScriptSlashCommand;
	SlashCmdList[ "_DEV_TOGGLEADDON" ] = me.ToggleAddOnSlashCommand;

	-- Fix to speed up printing many lines to scrolling message frames, by Drundia
	hooksecurefunc( getmetatable( ChatFrame1 ).__index, "AddMessage", me.AddMessage );
end
