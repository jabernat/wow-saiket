--[[****************************************************************************
  * _DevPad.GUI by Saiket                                                      *
  * _DevPad.GUI.lua - UI for managing _DevPad.                                 *
  ****************************************************************************]]


local AddOnName, me = ...;
_DevPad.GUI = me;

me.Frame = CreateFrame( "Frame" );
me.Callbacks = LibStub( "CallbackHandler-1.0" ):New( me );




--- Load saved variables and position windows.
function me.Frame:ADDON_LOADED ( Event, AddOn )
	if ( AddOn == AddOnName ) then
		self:UnregisterEvent( Event );
		self[ Event ] = nil;

		local Options = _DevPadGUIOptions;
		if ( Options and Options.List ) then
			me.List:Unpack( Options.List );
		end
		me.Editor:Unpack( ( Options and Options.Editor )
			or { StickTarget = "List"; StickPoint = "RT"; } );

		-- Replace settings last in case of errors loading them
		self:RegisterEvent( "PLAYER_LOGOUT" );
		_DevPadGUIOptions = nil; -- GC options
	end
end
--- Save settings before exiting.
function me.Frame:PLAYER_LOGOUT ()
	_DevPadGUIOptions = {
		List = me.List:Pack();
		Editor = me.Editor:Pack();
	};
end


do
	local Active = IsLoggedIn();
	--- Keeps the default UI from hiding open dialogs when zoning.
	function me.Frame:PLAYER_LEAVING_WORLD ()
		Active = false;
	end
	function me.Frame:PLAYER_ENTERING_WORLD ()
		Active = true;
	end
	--- @return True if the dialog was hidden.
	local function Hide ( self )
		if ( self:IsShown() ) then
			self:Hide();
			return true;
		end
	end
	local Backup = CloseSpecialWindows;
	--- Hook to hide dialog windows when escape is pressed.
	-- Used instead of UISpecialFrames to prevent closing when zoning.
	function CloseSpecialWindows ( ... )
		return Backup( ... )
			or Active and ( Hide( me.Editor ) or Hide( me.List ) );
	end
end




me.Frame:SetScript( "OnEvent", _DevPad.Frame.OnEvent );
me.Frame:RegisterEvent( "ADDON_LOADED" );
me.Frame:RegisterEvent( "PLAYER_ENTERING_WORLD" );
me.Frame:RegisterEvent( "PLAYER_LEAVING_WORLD" );