--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.Backdrop.lua - Factory for uniform background panels.               *
  ****************************************************************************]]


local _Clean = _Clean;
local me = {
	Padding = 3;
};
_Clean.Backdrop = me;

local BorderSize = 4;
local BorderTexture = [[Interface\AddOns\_Clean\Skin\BackdropBorder]];
local BorderAlpha = 0.15;




--[[****************************************************************************
  * Function: _Clean.Backdrop:Create                                           *
  * Description: Returns a new backdrop frame.                                 *
  ****************************************************************************]]
do
	local CreateSide;
	do
		local CornerCoords = { 1, 0, 0.5, 0, 0.5, 1, 1, 1 }; -- UR, UL, LL, LR
		local SideCoords = { 0.5, 0, 0, 0, 0, 1, 0.5, 1 };
		for Index = 1, #CornerCoords - 2 do -- Extend so unpack returns 8 coords for initial indexes 1-8
			CornerCoords[ #CornerCoords + 1 ] = CornerCoords[ Index ];
			SideCoords[ #SideCoords + 1 ] = SideCoords[ Index ];
		end
		local R, G, B = unpack( _Clean.Colors.Foreground );
		local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy;
		function CreateSide ( self, Center, Index )
			Index = Index * 2 - 1;
			local Side, Corner = self:CreateTexture( nil, "BACKGROUND" ), self:CreateTexture( nil, "BACKGROUND" );

			Side:SetTexture( BorderTexture );
			Side:SetBlendMode( "ADD" );
			Side:SetVertexColor( R, G, B, BorderAlpha );
			URx, URy, ULx, ULy, LLx, LLy, LRx, LRy = unpack( SideCoords, Index, Index + 7 );
			Side:SetTexCoord( ULx, ULy, LLx, LLy, URx, URy, LRx, LRy );
			if ( Index % 4 == 1 ) then -- Top or bottom
				Side:SetHeight( BorderSize );
				Side:SetPoint( "LEFT", Center );
				Side:SetPoint( "RIGHT", Center );
			else -- Left or right
				Side:SetWidth( BorderSize );
				Side:SetPoint( "TOP", Center );
				Side:SetPoint( "BOTTOM", Center );
			end
			Center[ #Center + 1 ] = Side;

			Corner:SetTexture( BorderTexture );
			Corner:SetBlendMode( "ADD" );
			Corner:SetVertexColor( R, G, B, BorderAlpha );
			URx, URy, ULx, ULy, LLx, LLy, LRx, LRy = unpack( CornerCoords, Index, Index + 7 );
			Corner:SetTexCoord( ULx, ULy, LLx, LLy, URx, URy, LRx, LRy );
			Corner:SetWidth( BorderSize );
			Corner:SetHeight( BorderSize );
			Center[ #Center + 1 ] = Corner;

			return Side, Corner;
		end
	end
	local R, G, B = unpack( _Clean.Colors.Background );
	function me:Create ()
		local Center = self:CreateTexture( nil, "BACKGROUND" );
		Center:SetTexture( R, G, B, 0.75 );

		-- Clockwise
		local Side, Corner = CreateSide( self, Center, 1 ); -- Top, TopRight
		Side:SetPoint( "BOTTOM", Center, "TOP" );
		Corner:SetPoint( "BOTTOMLEFT", Center, "TOPRIGHT" );
		Side, Corner = CreateSide( self, Center, 2 ); -- Right, BottomRight
		Side:SetPoint( "LEFT", Center, "RIGHT" );
		Corner:SetPoint( "TOPLEFT", Center, "BOTTOMRIGHT" );
		Side, Corner = CreateSide( self, Center, 3 ); -- Bottom, BottomLeft
		Side:SetPoint( "TOP", Center, "BOTTOM" );
		Corner:SetPoint( "TOPRIGHT", Center, "BOTTOMLEFT" );
		Side, Corner = CreateSide( self, Center, 4 ); -- Left, TopLeft
		Side:SetPoint( "RIGHT", Center, "LEFT" );
		Corner:SetPoint( "BOTTOMRIGHT", Center, "TOPLEFT" );

		return Center;
	end
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
