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
	local Backdrop = CreateFrame( "Frame", nil, Parent );

	local Cover = Backdrop:CreateTexture( nil, "OVERLAY" );
	Cover:SetAllPoints( Backdrop );
	local R, G, B = unpack( _Clean.Colors.Background );
	Cover:SetTexture( R, G, B, 0.75 );

	return Backdrop;
end
--[[****************************************************************************
  * Function: _Clean.Backdrop.Add                                              *
  * Description: Similar to Create, but also sets the backdrop with padding.   *
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
