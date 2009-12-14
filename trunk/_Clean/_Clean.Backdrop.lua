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
  * Function: _Clean.Backdrop:Create                                           *
  * Description: Returns a new backdrop frame.                                 *
  ****************************************************************************]]
function me:Create ()
	local Texture = self:CreateTexture( nil, "BACKGROUND" );
	local R, G, B = unpack( _Clean.Colors.Background );
	Texture:SetTexture( R, G, B, 0.75 );

	return Texture;
end
--[[****************************************************************************
  * Function: _Clean.Backdrop:Add                                              *
  * Description: Similar to Create, but also sets the backdrop with padding.   *
  ****************************************************************************]]
function me:Add ( Padding )
	local Backdrop = me.Create( self );

	Padding = Padding or me.Padding;
	Backdrop:SetPoint( "TOPRIGHT", Padding, Padding );
	Backdrop:SetPoint( "BOTTOMLEFT", -Padding, -Padding );

	return Backdrop;
end
