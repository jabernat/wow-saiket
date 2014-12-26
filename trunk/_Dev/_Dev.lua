--[[****************************************************************************
  * _Dev by Saiket                                                             *
  * _Dev.lua - Special tools useful for debugging the UI.                      *
  ****************************************************************************]]


local AddOnName = ...;
local _DevOptionsOriginal = {
	PrintLuaErrors = true;

	Version = GetAddOnMetadata( AddOnName, "Version" ):match( "^([%d.]+)" );
};
_DevOptions = _DevOptionsOriginal;


local L = _DevLocalization;
local NS = CreateFrame( "Frame", "_Dev" );

NS.Font = CreateFont( "_DevFont" );
NS.ScriptSlashCommandBackup = SlashCmdList[ "SCRIPT" ];




--[[****************************************************************************
  * Function: _Dev.NilFunction                                                 *
  * Description: Recycled generic function placeholder.                        *
  ****************************************************************************]]
function NS.NilFunction () end
--[[****************************************************************************
  * Function: _Dev.Print                                                       *
  * Description: Write a string to the specified frame, or to the default chat *
  *   frame when unspecified. Output color defaults to yellow.                 *
  ****************************************************************************]]
do
	local tostring = tostring;
	function NS.Print ( Message, ChatFrame, Color )
		if ( not Color ) then
			Color = NORMAL_FONT_COLOR;
		end
		( ChatFrame or DEFAULT_CHAT_FRAME ):AddMessage( tostring( Message ), Color.r, Color.g, Color.b, Color.id );
	end
end
--[[****************************************************************************
  * Function: _Dev.Error                                                       *
  * Description: Displays an error message with the current error handler.     *
  ****************************************************************************]]
function NS.Error ( Message, ForcePrint )
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
	function NS.IsUIObject ( Value )
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
	function NS.Round ( Float, Precision )
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
function NS.Count ( Table )
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
function NS.Exec ( Script, ... )
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
function NS.ScriptSlashCommand ( Input )
	NS.ScriptSlashCommandBackup( Input and Input:gsub( "||", "|" ) or nil );
end
--[[****************************************************************************
  * Function: _Dev.OpenChatScriptBinding                                       *
  * Description: Key binding to open chat prefixed with the shortest localized *
  *   /script equivalent slash command.                                        *
  ****************************************************************************]]
function NS.OpenChatScriptBinding ()
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
function NS.ReloadUIBinding ()
	ReloadUI(); -- Allow late binding
end;
--[[****************************************************************************
  * Function: _Dev.ToggleAddOn                                                 *
  * Description: Toggles the given addon and reloads the UI immediately.  If   *
  *   the addon is load on demand, it will be loaded without a reload UI and   *
  *   its enabled or disabled status will not be modified. Returns an error    *
  *    string on failure.                                                      *
  ****************************************************************************]]
function NS.ToggleAddOn ( AddOnName )
	local Loaded, ErrorReason;
	if ( IsAddOnLoaded( AddOnName ) ) then
		DisableAddOn( AddOnName );
		ReloadUI();
		return;
	elseif ( IsAddOnLoadOnDemand( AddOnName ) ) then
		EnableAddOn( AddOnName );
		Loaded, ErrorReason = LoadAddOn( AddOnName );
		if ( Loaded ) then
			return;
		end
	else
		ErrorReason = select( 6, GetAddOnInfo( AddOnName ) );
		if ( not ErrorReason or ErrorReason == "DISABLED" or ErrorReason == "INSECURE" ) then
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
function NS.ToggleAddOnSlashCommand ( Input )
	if ( Input and not Input:find( "^%s*$" ) ) then
		-- Call will reload UI unless it fails
		local ErrorString = NS.ToggleAddOn( Input );
		if ( ErrorString ) then -- Error
			NS.Error( L.TOGGLEADDON_ERROR_FORMAT:format( Input, ErrorString ), true );
		end
	end
end


--[[****************************************************************************
  * Function: _Dev:MODIFIER_STATE_CHANGED                                      *
  ****************************************************************************]]
function NS:MODIFIER_STATE_CHANGED ( _, Modifier, State )
	Modifier = Modifier:sub( 2 );
	if ( GetModifiedClick( "_DEV_ENABLECONSOLE" ):find( Modifier, 1, true ) ) then
		SetConsoleKey( State and "`" or nil );
	end
	if ( GetModifiedClick( "_DEV_FRAMES_INTERACTIVE" ):find( Modifier, 1, true ) ) then
		NS.Frames.SetInteractive( State );
	end
end
--[[****************************************************************************
  * Function: _Dev:ADDON_LOADED                                                *
  ****************************************************************************]]
function NS:ADDON_LOADED ( _, AddOn )
	if ( AddOn:lower() == AddOnName:lower() ) then
		NS:UnregisterEvent( "ADDON_LOADED" );
		NS.ADDON_LOADED = nil;

		if ( _DevOptions.Version ~= _DevOptionsOriginal.Version ) then
			-- Reset settings
			_DevOptions = _DevOptionsOriginal;
		end
		NS.Outline:OnLoad();
		NS.Stats:OnLoad();
		NS.Options:OnLoad();
	end
end
--[[****************************************************************************
  * Function: _Dev:OnEvent                                                     *
  * Description: Global event handler.                                         *
  ****************************************************************************]]
do
	local type = type;
	function NS:OnEvent ( Event, ... )
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
	function NS:OnUpdate ()
		Shift, Ctrl, Alt = IsShiftKeyDown(), IsControlKeyDown(), IsAltKeyDown();
		if ( Shift ~= LastShift ) then
			LastShift = Shift;
			NS:OnEvent( "MODIFIER_STATE_CHANGED", "*SHIFT", Shift );
		end
		if ( Ctrl ~= LastCtrl ) then
			LastCtrl = Ctrl;
			NS:OnEvent( "MODIFIER_STATE_CHANGED", "*CTRL", Ctrl );
		end
		if ( Alt ~= LastAlt ) then
			LastAlt = Alt;
			NS:OnEvent( "MODIFIER_STATE_CHANGED", "*ALT", Alt );
		end
	end
end




ConsoleExec( "fontsize 12" ); -- The console's font size
NS.Font:SetFontObject( NumberFontNormalSmall );

NS:SetScript( "OnEvent", NS.OnEvent );
NS:SetScript( "OnUpdate", NS.OnUpdate );
NS:RegisterEvent( "ADDON_LOADED" );

math.round = NS.Round;
table.count = NS.Count;

SlashCmdList[ "SCRIPT" ] = NS.ScriptSlashCommand;
SlashCmdList[ "_DEV_TOGGLEADDON" ] = NS.ToggleAddOnSlashCommand;