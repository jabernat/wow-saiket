--[[****************************************************************************
  * _Clean.HUD by Saiket                                                       *
  * _Clean.HUD.PushToTalk.lua - Voice chat indicator frame.                    *
  ****************************************************************************]]


local _Clean = _Clean;
local me = CreateFrame( "Frame", nil, UIParent );
_Clean.HUD.PushToTalk = me;

local Enabled = false;
local EnabledExternal = false;




--[[****************************************************************************
  * Function: _Clean.HUD.PushToTalk.Update                                     *
  * Description: Hides or shows the push to talk icon.                         *
  ****************************************************************************]]
function me.Update ()
	if ( Enabled or EnabledExternal ) then
		me:Show();
	else
		me:Hide();
	end
end


--[[****************************************************************************
  * Function: _Clean.HUD.PushToTalk:VOICE_PUSH_TO_TALK_START                   *
  ****************************************************************************]]
function me:VOICE_PUSH_TO_TALK_START ()
	Enabled = true;
	me.Update();
end
--[[****************************************************************************
  * Function: _Clean.HUD.PushToTalk:VOICE_PUSH_TO_TALK_STOP                    *
  ****************************************************************************]]
function me:VOICE_PUSH_TO_TALK_STOP ()
	Enabled = false;
	me.Update();
end
--[[****************************************************************************
  * Function: _Clean.HUD.PushToTalk:MODIFIER_STATE_CHANGED                     *
  ****************************************************************************]]
function me:MODIFIER_STATE_CHANGED ()
	EnabledExternal = IsModifiedClick( "_CLEAN_HUD_PUSHTOTALK_MOD" );
	me.Update();
end
--[[****************************************************************************
  * Function: _Clean.HUD.PushToTalk:UPDATE_BINDINGS                            *
  ****************************************************************************]]
function me:UPDATE_BINDINGS ()
	if ( GetBindingKey( "_CLEAN_HUD_PUSHTOTALK" ) ) then -- Bound to a standard key
		me:UnregisterEvent( "MODIFIER_STATE_CHANGED" );
		EnabledExternal = false;
		me.Update();
	else -- Use the modifier binding
		me:RegisterEvent( "MODIFIER_STATE_CHANGED" );
		me:MODIFIER_STATE_CHANGED();
	end
end
--[[****************************************************************************
  * Function: _Clean.HUD.PushToTalk.OnKeypress                                 *
  ****************************************************************************]]
function me.OnKeypress ( KeyDown )
	EnabledExternal = KeyDown == "down";
	me.Update();
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:Hide();
	me:SetScript( "OnEvent", _Clean.OnEvent );
	me:RegisterEvent( "VOICE_PUSH_TO_TALK_START" );
	me:RegisterEvent( "VOICE_PUSH_TO_TALK_STOP" );
	me:RegisterEvent( "UPDATE_BINDINGS" );

	me:SetFrameStrata( "BACKGROUND" );
	me:SetWidth( 64 );
	me:SetHeight( 64 );
	me:SetAlpha( 0.5 );
	me:SetPoint( "CENTER", WorldFrame, 8, 0 );

	local Icon = me:CreateTexture( nil, "ARTWORK" );
	Icon:SetTexture( [[Interface\Common\VoiceChat-Speaker]] );
	Icon:SetAllPoints();
end
