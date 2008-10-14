--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.Backdrop.lua - Factory for uniform background panels.               *
  ****************************************************************************]]


local _Clean = _Clean;
local me = {
	Padding = 3;
};
_Clean.Backdrop = me;




--[[****************************************************************************
  * Function: _Clean.Backdrop.Create                                           *
  * Description: Returns a new backdrop frame.                                 *
  ****************************************************************************]]
function me.Create ( Parent )
	local Backdrop = CreateFrame( "Model", nil, Parent );

	local Cover = Backdrop:CreateTexture( nil, "OVERLAY" );
	local Color = _Clean.Colors.Background;
	Cover:SetAllPoints( Backdrop );
	Cover:SetTexture( Color.r, Color.g, Color.b, 0.75 );

	return Backdrop;
end
--[[****************************************************************************
  * Function: _Clean.CastingBar.HideArtwork                                    *
  * Description: This version does not have a border, has no progress spark,   *
  *   and does not flash when done casting.                                    *
  ****************************************************************************]]
function me.Add ( Parent, Padding )
	local Backdrop = me.Create( Parent );

	local Level = Parent:GetFrameLevel();
	Parent:SetFrameLevel( Level + 1 );
	Backdrop:SetFrameLevel( Level );

	Padding = Padding or 0;
	Backdrop:SetPoint( "TOPRIGHT", Padding, Padding );
	Backdrop:SetPoint( "BOTTOMLEFT", -Padding, -Padding );

	return Backdrop;
end
