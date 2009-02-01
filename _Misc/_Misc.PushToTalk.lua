--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.PushToTalk.lua - Voice chat indicator frame.                         *
  *                                                                            *
  * + Adds a voice transmitting icon to the center of the screen.              *
  ****************************************************************************]]


local _Misc = _Misc;
local me = CreateFrame( "Frame", nil, UIParent );
_Misc.PushToTalk = me;

me.Enabled = false;
me.EnabledExternal = false;
me.Icon = me:CreateTexture( nil, "ARTWORK" );




--[[****************************************************************************
  * Function: _Misc.PushToTalk.UpdateIcon                                      *
  * Description: Hides or shows the push to talk icon.                         *
  ****************************************************************************]]
function me:UpdateIcon ()
	if ( self.Enabled or self.EnabledExternal ) then
		self.Icon:Show();
	else
		self.Icon:Hide();
	end
end


--[[****************************************************************************
  * Function: _Misc.PushToTalk:VOICE_PUSH_TO_TALK_START                        *
  ****************************************************************************]]
function me:VOICE_PUSH_TO_TALK_START ()
	self.Enabled = true;
	self:UpdateIcon();
end
--[[****************************************************************************
  * Function: _Misc.PushToTalk:VOICE_PUSH_TO_TALK_STOP                         *
  ****************************************************************************]]
function me:VOICE_PUSH_TO_TALK_STOP ()
	self.Enabled = false;
	self:UpdateIcon();
end
--[[****************************************************************************
  * Function: _Misc.PushToTalk:MODIFIER_STATE_CHANGED                          *
  ****************************************************************************]]
function me:MODIFIER_STATE_CHANGED ( _, Modifier, State )
	if ( Modifier == "RCTRL" ) then
		self.EnabledExternal = State == 1;
		self:UpdateIcon();
	end
end
--[[****************************************************************************
  * Function: _Misc.PushToTalk:OnEvent                                         *
  * Description: Keeps track of whether voice is transmitting or not.          *
  ****************************************************************************]]
me.OnEvent = _Misc.OnEvent;




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", me.OnEvent );
	me:RegisterEvent( "VOICE_PUSH_TO_TALK_START" );
	me:RegisterEvent( "VOICE_PUSH_TO_TALK_STOP" );
	me:RegisterEvent( "MODIFIER_STATE_CHANGED" );

	me:SetFrameStrata( "BACKGROUND" );
	me:SetWidth( 64 );
	me:SetHeight( 64 );
	me:SetAlpha( 0.5 );
	me:SetPoint( "CENTER", UIParent, "CENTER", 8, 0 );
	me.Icon:SetTexture( "Interface\\Common\\VoiceChat-Speaker" );
	me.Icon:Hide();
	me.Icon:SetAllPoints( me );
end
