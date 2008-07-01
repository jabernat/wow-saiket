--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.PushToTalk.lua - Voice chat indicator frame.                        *
  *                                                                            *
  * + Adds a voice transmitting icon to the center of the screen.              *
  * + Moves the in-game voice indicator to the center of the screen.           *
  ****************************************************************************]]


local _Clean = _Clean;
local me = CreateFrame( "Frame", nil, UIParent );
_Clean.PushToTalk = me;

me.Enabled = false;
me.EnabledExternal = false;
me.Icon = me:CreateTexture( nil, "ARTWORK" );




--[[****************************************************************************
  * Function: _Clean.PushToTalk.UpdateIcon                                     *
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
  * Function: _Clean.PushToTalk:VOICE_PUSH_TO_TALK_START                       *
  ****************************************************************************]]
function me:VOICE_PUSH_TO_TALK_START ()
	self.Enabled = true;
	self:UpdateIcon();
end
--[[****************************************************************************
  * Function: _Clean.PushToTalk:VOICE_PUSH_TO_TALK_STOP                        *
  ****************************************************************************]]
function me:VOICE_PUSH_TO_TALK_STOP ()
	self.Enabled = false;
	self:UpdateIcon();
end
--[[****************************************************************************
  * Function: _Clean.PushToTalk:MODIFIER_STATE_CHANGED                         *
  ****************************************************************************]]
function me:MODIFIER_STATE_CHANGED ( _, Modifier, State )
	if ( Modifier == "RCTRL" ) then
		self.EnabledExternal = State == 1;
		self:UpdateIcon();
	end
end
--[[****************************************************************************
  * Function: _Clean.PushToTalk:OnEvent                                        *
  * Description: Keeps track of whether voice is transmitting or not.          *
  ****************************************************************************]]
function me:OnEvent ( Event, ... )
	if ( type( me[ Event ] ) == "function" ) then
		me[ Event ]( self, Event, ... );
	end
end




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

	-- Voice chat indicator
	VoiceChatTalkers:EnableMouse( false );
	VoiceChatTalkers:SetUserPlaced( false );
	VoiceChatTalkers:SetMovable( false );
	VoiceChatTalkers:SetBackdrop( nil );
	VoiceChatTalkers:ClearAllPoints();
	VoiceChatTalkers:SetPoint( "BOTTOM", UIParent, "CENTER" );

	-- Hooks
	UIPARENT_MANAGED_FRAME_POSITIONS[ "VoiceChatTalkers" ] = nil;
end
