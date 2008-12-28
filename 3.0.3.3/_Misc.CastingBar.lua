--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.CastingBar.lua - Modifies the casting bar.                           *
  *                                                                            *
  * + Adds a label to the casting bar that shows cast time remaining.          *
  ****************************************************************************]]


local L = _MiscLocalization;
local _Misc = _Misc;
local me = CreateFrame( "Frame", nil, CastingBarFrame );
_Misc.CastingBar = me;

local Icon = me:CreateTexture( nil, "ARTWORK" );
me.Icon = Icon;
local TimeText = me:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" );
me.TimeText = TimeText;




--[[****************************************************************************
  * Function: _Misc.CastingBar.SetIcon                                         *
  * Description: Update the cast icon.                                         *
  ****************************************************************************]]
function me.SetIcon ( Path )
	me.Icon:SetTexture( ( Path ~= "Interface\\Icons\\Temp" ) and Path or nil );
end


--[[****************************************************************************
  * Function: _Misc.CastingBar:PLAYER_ENTERING_WORLD                           *
  ****************************************************************************]]
function me:PLAYER_ENTERING_WORLD ()
	if ( UnitChannelInfo( "player" ) ) then
		self:UNIT_SPELLCAST_CHANNEL_START();
	elseif ( UnitCastingInfo( "player" ) ) then
		self:UNIT_SPELLCAST_START();
	end
end
--[[****************************************************************************
  * Function: _Misc.CastingBar:UNIT_SPELLCAST_START                            *
  ****************************************************************************]]
function me:UNIT_SPELLCAST_START ()
	me.SetIcon( select( 4, UnitCastingInfo( "player" ) ) );
end
--[[****************************************************************************
  * Function: _Misc.CastingBar:UNIT_SPELLCAST_CHANNEL_START                    *
  ****************************************************************************]]
function me:UNIT_SPELLCAST_CHANNEL_START ()
	me.SetIcon( select( 4, UnitChannelInfo( "player" ) ) );
end

--[[****************************************************************************
  * Function: _Misc.CastingBar:OnEvent                                         *
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
  * Function: _Misc.CastingBar:OnUpdate                                        *
  * Description: Update the cast time text.                                    *
  ****************************************************************************]]
do
	local GetTime = GetTime;
	local max = max;
	local SpellFunction, Parent, Time;
	function me:OnUpdate ()
		Parent = self:GetParent();
		if ( Parent.casting ) then
			SpellFunction = UnitCastingInfo;
		elseif ( Parent.channeling ) then
			SpellFunction = UnitChannelInfo;
		end

		if ( SpellFunction ) then
			Time = select( 6, SpellFunction( "player" ) );
			self.TimeText:SetFormattedText( L.CASTINGBAR_TIMETEXT_FORMAT,
				Time and max( 0, Time / 1000 - GetTime() ) or 0 );
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:RegisterEvent( "PLAYER_ENTERING_WORLD" );
	me:RegisterEvent( "UNIT_SPELLCAST_START" );
	me:RegisterEvent( "UNIT_SPELLCAST_CHANNEL_START" );
	me:SetScript( "OnEvent", me.OnEvent );
	me:SetScript( "OnUpdate", me.OnUpdate );
	me.Icon:SetWidth( 32 );
	me.Icon:SetHeight( 32 );
	me.Icon:SetPoint( "LEFT", CastingBarFrame, 2, 0 );
	me.Icon:SetAlpha( 0.75 );
	me.Icon:SetTexCoord( 0.08, 0.92, 0.08, 0.92 );
	me.TimeText:SetPoint( "LEFT", CastingBarFrameText, "RIGHT" );

	CastingBarFrameText:SetWidth( 0 );
end
