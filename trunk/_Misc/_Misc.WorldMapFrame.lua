--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * _Misc.WorldMapFrame.lua - Modifies the WorldMap frame.                     *
  *                                                                            *
  * + Adds a tooltip to show the TLoc of the cursor when over the world map.   *
  ****************************************************************************]]


local _Misc = _Misc;
local L = _MiscLocalization;
local me = CreateFrame( "Frame", nil, WorldMapButton );
_Misc.WorldMapFrame = me;

me.Text = me:CreateFontString( nil, "ARTWORK", "NumberFontNormalSmall" );




--[[****************************************************************************
  * Function: _Misc.WorldMapFrame.OnUpdate                                     *
  * Description: Sets the position of the tooltip and updates its contents. If *
  *   the mouse isn't over the map, the tooltip is hidden.                     *
  ****************************************************************************]]
do
	local MouseIsOver = MouseIsOver;
	local GetCursorPosition = GetCursorPosition;
	local floor = floor;
	function me:OnUpdate ( Elapsed )
		if ( MouseIsOver( self ) ) then
			local Scale = self:GetEffectiveScale();
			local CursorPositionX, CursorPositionY = GetCursorPosition();
			CursorPositionX = CursorPositionX / Scale;
			CursorPositionY = CursorPositionY / Scale;
	
			me:SetPoint( "TOPRIGHT", UIParent, "BOTTOMLEFT", CursorPositionX - 5, CursorPositionY - 20 );
	
			me.Text:SetFormattedText( L.WORLDMAPFRAME_COORDS_FORMAT,
				floor( ( CursorPositionX - self:GetLeft() ) / self:GetWidth() * 10000 + 0.5 ) / 100,
				floor( ( 1 - ( CursorPositionY - self:GetBottom() ) / self:GetHeight() ) * 10000 + 0.5 ) / 100
			);
			me:SetWidth( me.Text:GetStringWidth() + 8 );
			me:Show();
		else
			me:Hide();
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:Hide();
	me:SetHeight( 24 );
	me:SetFrameStrata( "TOOLTIP" );
	me:SetToplevel( false );
	me:SetClampedToScreen( true );
	me:SetAlpha( 0.5 );
	me:SetBackdrop( { 
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background";
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border";
		edgeSize = 16;
		insets = { left = 5, right = 5, top = 4, bottom = 4 };
	} );
	me.Text:SetPoint( "CENTER" );

	me.Text:SetTextColor( NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b );
	me:SetBackdropBorderColor( TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b );
	me:SetBackdropColor( TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b );

	-- Register to show and hide on mouseover and mouseout
	_Misc.HookScript( WorldMapButton, "OnUpdate", me.OnUpdate );
end
