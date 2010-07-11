--[[****************************************************************************
  * _Underscore.HUD by Saiket                                                  *
  * _Underscore.HUD.PushToTalk.lua - Voice chat indicator frame.               *
  ****************************************************************************]]


local HUD = select( 2, ... );
local me = CreateFrame( "Frame", nil, UIParent );
HUD.PushToTalk = me;

local Enabled = false;
local EnabledExternal = false;




--- Hides or shows the push to talk icon.
function me.Update ()
	if ( Enabled or EnabledExternal ) then
		me:Show();
	else
		me:Hide();
	end
end


--- Build-in voice chat started.
function me:VOICE_PUSH_TO_TALK_START ()
	Enabled = true;
	me.Update();
end
--- Build-in voice chat stopped.
function me:VOICE_PUSH_TO_TALK_STOP ()
	Enabled = false;
	me.Update();
end
--- Checks for external voice chat keybind if it's a modifier key.
function me:MODIFIER_STATE_CHANGED ()
	EnabledExternal = IsModifiedClick( "_UNDERSCORE_HUD_PUSHTOTALK_MOD" );
	me.Update();
end
--- Switches between normal-key and modifier-key binding modes.
function me:UPDATE_BINDINGS ()
	if ( GetBindingKey( "_UNDERSCORE_HUD_PUSHTOTALK" ) ) then -- Bound to a standard key
		me:UnregisterEvent( "MODIFIER_STATE_CHANGED" );
		EnabledExternal = false;
		me.Update();
	else -- Use the modifier binding
		me:RegisterEvent( "MODIFIER_STATE_CHANGED" );
		me:MODIFIER_STATE_CHANGED();
	end
end
--- Keybinding handler to catch normal-key presses.
function me.OnKeypress ( KeyDown )
	if ( not me:IsEventRegistered( "MODIFIER_STATE_CHANGED" ) ) then
		EnabledExternal = KeyDown == "down";
		me.Update();
	end
end




do
	--- Binds multiple keys to an action.
	local function SetBindings ( Action, ... )
		for Index = 1, select( "#", ... ) do
			SetBinding( select( Index, ... ), Action );
		end
	end
	--- Binds a key or modifier, and unbinds the other.
	-- @return True if changed without errors.
	local function BindKeyOrMod ( Key, OldModifier, ... )
		-- Clear previous binds
		SetBindings( nil, ... );
		SetModifiedClick( "_UNDERSCORE_HUD_PUSHTOTALK_MOD", nil );

		if ( not Key
			or SetBinding( Key, "_UNDERSCORE_HUD_PUSHTOTALK" )
			or pcall( SetModifiedClick, "_UNDERSCORE_HUD_PUSHTOTALK_MOD", Key )
		) then -- Changed successfully
			SaveBindings( GetCurrentBindingSet() );
			return true;
		else -- Restore previous binds
			SetBindings( "_UNDERSCORE_HUD_PUSHTOTALK", ... );
			SetModifiedClick( "_UNDERSCORE_HUD_PUSHTOTALK_MOD", OldModifier );
		end
	end
	--- Sets the external voice keybinding, and saves bindings.
	-- @param Key  A non-empty key or modifier string to bind to, or nil to unbind.
	-- @return True if bound successfully.
	function me.SetExternalKeybind ( Key )
		assert( not Key or ( type( Key ) == "string" and Key ~= "" ), "Invalid key/modifier name." );
		return BindKeyOrMod( Key, GetModifiedClick( "_UNDERSCORE_HUD_PUSHTOTALK_MOD" ), GetBindingKey( "_UNDERSCORE_HUD_PUSHTOTALK" ) );
	end
end
--- Slash command handler for SetExternalKeybind.
-- @see SetExternalKeybind
function me.SlashCommand ( Input )
	local Key = Input:trim();
	local Color, Format;
	if ( me.SetExternalKeybind( Key ~= "" and Key:upper() ) ) then -- Modifiers like CTRL must be uppercase
		Key = GetBindingKey( "_UNDERSCORE_HUD_PUSHTOTALK" ) or GetModifiedClick( "_UNDERSCORE_HUD_PUSHTOTALK_MOD" );
		Color, Format = NORMAL_FONT_COLOR, HUD.L.PUSHTOTALK_BIND;
	else
		Color, Format = RED_FONT_COLOR, HUD.L.PUSHTOTALK_BIND_ERROR;
	end
	DEFAULT_CHAT_FRAME:AddMessage( Format:format( Key ), Color.r, Color.g, Color.b );
end




me:Hide();
me:SetScript( "OnEvent", _Underscore.OnEvent );
me:RegisterEvent( "VOICE_PUSH_TO_TALK_START" );
me:RegisterEvent( "VOICE_PUSH_TO_TALK_STOP" );
me:RegisterEvent( "UPDATE_BINDINGS" );

me:SetFrameStrata( "BACKGROUND" );
me:SetSize( 64, 64 );
me:SetAlpha( 0.5 );
me:SetPoint( "CENTER", WorldFrame, 8, 0 );

local Icon = me:CreateTexture( nil, "ARTWORK" );
Icon:SetTexture( [[Interface\Common\VoiceChat-Speaker]] );
Icon:SetAllPoints();


SlashCmdList[ "_UNDERSCORE_HUD_PUSHTOTALK" ] = me.SlashCommand;