--[[****************************************************************************
  * _DevPad.GUI by Saiket                                                      *
  * _DevPad.GUI.lua - UI for managing _DevPad.                                 *
  ****************************************************************************]]


local AddOnName, NS = ...;
_DevPad.GUI = NS;

NS.Frame = CreateFrame( "Frame" );
NS.Callbacks = LibStub( "CallbackHandler-1.0" ):New( NS );




--- Load saved variables and position windows.
function NS.Frame:ADDON_LOADED ( Event, AddOn )
	if ( AddOn == AddOnName ) then
		self:UnregisterEvent( Event );
		self[ Event ] = nil;

		local Options = _DevPadGUIOptions;
		if ( Options and Options.List ) then
			NS.List:Unpack( Options.List );
		end
		NS.Editor:Unpack( ( Options and Options.Editor )
			or { StickTarget = "List"; StickPoint = "RT"; } );

		-- Replace settings last in case of errors loading them
		self:RegisterEvent( "PLAYER_LOGOUT" );
		_DevPadGUIOptions = nil; -- GC options
	end
end
--- Save settings before exiting.
function NS.Frame:PLAYER_LOGOUT ()
	_DevPadGUIOptions = {
		List = NS.List:Pack();
		Editor = NS.Editor:Pack();
	};
end


do
	-- Ugly way of catching the escape keybind without also making the dialogs
	-- close when other windows open/when zoning/etc.
	local Listener = CreateFrame( "Frame", nil, WorldFrame );
	Listener:EnableKeyboard( true );
	Listener:SetPropagateKeyboardInput( true );

	local Allowed;
	--- Catches the game menu bind just before it fires.
	Listener:SetScript( "OnKeyDown", function ( self, Key )
		Allowed = ( NS.Editor:IsShown() or NS.List:IsShown() )
			and GetBindingFromClick( Key ) == "TOGGLEGAMEMENU";
	end );
	--- Disallows closing the dialogs once the game menu bind is processed.
	hooksecurefunc( "ToggleGameMenu", function ()
		Allowed = nil;
	end );

	--- @return True if the dialog was hidden.
	local function Hide ( self )
		if ( self:IsShown() ) then
			self:Hide();
			return true;
		end
	end
	local Backup = CloseSpecialWindows;
	--- Hook to hide dialog windows when escape is pressed.
	-- Used instead of UISpecialFrames to close *only* from escape.
	function CloseSpecialWindows ( ... )
		return Backup( ... )
			or Allowed and ( Hide( NS.Editor ) or Hide( NS.List ) );
	end
end


--- @return Color code representing (R,G,B).
function NS.FormatColorCode ( R, G, B )
	return ( "|cff%02x%02x%02x" ):format( R * 255 + 0.5, G * 255 + 0.5, B * 255 + 0.5 );
end




NS.Frame:SetScript( "OnEvent", _DevPad.Frame.OnEvent );
NS.Frame:RegisterEvent( "ADDON_LOADED" );
NS.Frame:RegisterEvent( "PLAYER_ENTERING_WORLD" );
NS.Frame:RegisterEvent( "PLAYER_LEAVING_WORLD" );