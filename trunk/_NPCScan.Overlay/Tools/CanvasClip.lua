-- CanvasClip.lua: Turns the Canvas.lua rendering test into a minimap-like clipping tester.

local Overlay = _NPCScan.Overlay;
local Canvas = assert( _NPCScanOverlayCanvas, "Canvas tool must be loaded." );
local Window = Canvas:GetParent();
local me = Canvas;

local ROUNT_TEXTURE_PATH = [[Interface\CHARACTERFRAME\TempPortraitAlphaMask]];


local GetShapeIndex, SetShapeIndex, GetMinimapShape;
do
	local ClipTextures = {};
	local ClipTitle = Window:CreateFontString( nil, "OVERLAY", "NumberFontNormalSmallGray" );
	local Shapes = {
		"ROUND",
		"SQUARE",
		"CORNER-TOPRIGHT",
		"CORNER-TOPLEFT",
		"CORNER-BOTTOMLEFT",
		"CORNER-BOTTOMRIGHT",
		"SIDE-TOP",
		"SIDE-LEFT",
		"SIDE-BOTTOM",
		"SIDE-RIGHT",
		"TRICORNER-BOTTOMLEFT",
		"TRICORNER-BOTTOMRIGHT",
		"TRICORNER-TOPRIGHT",
		"TRICORNER-TOPLEFT",
	};
	local ShapeQuadrants = {
		[ "ROUND" ]                 = {  true,  true,  true,  true };
		[ "SQUARE" ]                = { false, false, false, false };
		[ "CORNER-TOPRIGHT" ]       = { false, false,  true, false };
		[ "CORNER-TOPLEFT" ]        = {  true, false, false, false };
		[ "CORNER-BOTTOMLEFT" ]     = { false,  true, false, false };
		[ "CORNER-BOTTOMRIGHT" ]    = { false, false, false,  true };
		[ "SIDE-TOP" ]              = {  true, false,  true, false };
		[ "SIDE-LEFT" ]             = {  true,  true, false, false };
		[ "SIDE-BOTTOM" ]           = { false,  true, false,  true };
		[ "SIDE-RIGHT" ]            = { false, false,  true,  true };
		[ "TRICORNER-BOTTOMLEFT" ]  = {  true,  true, false,  true };
		[ "TRICORNER-BOTTOMRIGHT" ] = { false,  true,  true,  true };
		[ "TRICORNER-TOPRIGHT" ]    = {  true, false,  true,  true };
		[ "TRICORNER-TOPLEFT" ]     = {  true,  true,  true, false };
	};
	local ShapeIndex;
	function GetShapeIndex()
		return ShapeIndex;
	end
	function SetShapeIndex( Index )
		ShapeIndex = ( Index - 1 ) % #Shapes + 1;
		local Shape = GetMinimapShape();
		ClipTitle:SetFormattedText( "%d. %s", ShapeIndex, Shape );

		for Index, Texture in ipairs( ClipTextures ) do
			if ( ShapeQuadrants[ Shape ][ Index ] ) then -- Rounded
				Texture:SetTexture( ROUNT_TEXTURE_PATH );
				local Left, Top = Index <= 2, Index % 2 == 1;
				Texture:SetTexCoord( Left and 0 or 0.5, Left and 0.5 or 1, Top and 0 or 0.5, Top and 0.5 or 1 );
			else -- Square
				Texture:SetTexture( [[Interface\Buttons\WHITE8X8]] );
			end
		end
	end
	function GetMinimapShape ()
		return Shapes[ GetShapeIndex() ];
	end

	Window:SetHeight( Window:GetHeight() + ( Canvas:GetWidth() - Canvas:GetHeight() ) ); -- Make square
	for Index = 1, 4 do
		local Texture = Window:CreateTexture( nil, "ARTWORK" );
		ClipTextures[ Index ] = Texture;
		Texture:SetVertexColor( 0.2, 0.1, 0 ); -- Dark brown
		local Left, Top = Index <= 2, Index % 2 == 1;
		Texture:SetPoint( "LEFT", Canvas, Left and "LEFT" or "CENTER" );
		Texture:SetPoint( "RIGHT", Canvas, Left and "CENTER" or "RIGHT" );
		Texture:SetPoint( "TOP", Canvas, Top and "TOP" or "CENTER" );
		Texture:SetPoint( "BOTTOM", Canvas, Top and "CENTER" or "BOTTOM" );
	end
	ClipTitle:SetPoint( "TOPLEFT", Canvas );
end


SetShapeIndex( 1 );
Canvas:SetScript( "OnMouseWheel", function ( self, Delta )
	SetShapeIndex( GetShapeIndex() + Delta );
	self.Changed = true;
end );
Canvas:EnableMouseWheel( true );

Canvas.AlphaDefault = 0.3;
Canvas:SetAlpha( 0.3 );




local function DrawPoint ( X, Y, R, G, B )
	Overlay.TextureAdd( Canvas, "OVERLAY", R, G, B,
		X + 0.008, Y, X, Y + 0.02, X, Y - 0.02 );
	Overlay.TextureAdd( Canvas, "OVERLAY", R, G, B,
		X, Y + 0.008, X + 0.02, Y, X - 0.02, Y );
end

local DrawLabel, ClearLabels;
do
	local LabelsUsed = {};
	local LabelsUnused = {};
	function ClearLabels ()
		for Label in pairs( LabelsUsed ) do
			LabelsUsed[ Label ] = nil;
			LabelsUnused[ Label ] = true;
			Label:Hide();
		end
	end
	function DrawLabel ( X, Y, Text, R, G, B )
		local Label = next( LabelsUnused );
		if ( Label ) then
			LabelsUnused[ Label ] = nil;
			Label:Show();
		else
			Label = Window:CreateFontString( nil, "OVERLAY", "NumberFontNormalSmallGray" );
		end
		LabelsUsed[ Label ] = true;

		Label:SetPoint( "TOPLEFT", Canvas, "TOPLEFT", Canvas:GetWidth() * X, -Canvas:GetHeight() * Y );
		Label:SetText( Text );
		if ( R ) then
			Label:SetVertexColor( R, G, B );
		else
			Label:SetVertexColor( 1, 1, 1 );
		end
	end
end




local RotateMinimap = false;
local R, G, B = 1, 1, 1;
local SplitPoints, Quadrants = {};
local Facing = 0;
local FacingSin, FacingCos;

local RepaintTriangle;
do
	local function IsQuadrantRound ( X, Y ) -- Returns true if the quadrant is rounded
		return Quadrants[ Y <= 0 -- Y-axis is flipped
			and ( X >= 0 and 1 or 2 )
			 or ( X >= 0 and 4 or 3 ) ];
	end
	local Points, LastExitPoint, IsClockwise = {};
	local LastRoundX, LastRoundY;

	local AddRoundSplit; -- Adds rounded areas clipped in round minimap segments
	do
		local StartX, StartY;
		local Dx, Dy, Side;
		local Texture;
		function AddRoundSplit ( EndX, EndY )
			if ( IsClockwise ) then
				StartX, StartY = EndX, EndY;
				EndX, EndY = LastRoundX, LastRoundY;
			else
				StartX, StartY = LastRoundX, LastRoundY;
			end
			LastRoundX, LastRoundY = nil;

			Dx, Dy = EndX - StartX, EndY - StartY;
			if ( Dx == 0 ) then -- Draw with horizontal texture
				Texture = Overlay.TextureCreate( me, "ARTWORK", 1, 1, 1 );
				Texture:SetTexture( ROUNT_TEXTURE_PATH );

				Texture:SetAllPoints();
				Dx = 0.5 + StartX; -- TexCoord end position
				if ( Dy > 0 ) then
					Texture:SetPoint( "BOTTOMRIGHT", me:GetWidth() * ( StartX - 0.5 ), 0 );
					Texture:SetTexCoord( 0, Dx, 0, 1 );
				else
					Texture:SetPoint( "TOPLEFT", me:GetWidth() * Dx, 0 );
					Texture:SetTexCoord( Dx, 1, 0, 1 );
				end
			elseif ( Dy == 0 ) then -- Draw with vertical texture
				Texture = Overlay.TextureCreate( me, "ARTWORK", 1, 1, 1 );
				Texture:SetTexture( ROUNT_TEXTURE_PATH );

				Texture:SetAllPoints();
				Dy = 0.5 + StartY; -- TexCoord end position
				if ( Dx > 0 ) then
					Texture:SetPoint( "TOPLEFT", 0, me:GetHeight() * -Dy );
					Texture:SetTexCoord( 0, 1, Dy, 1 );
				else
					Texture:SetPoint( "BOTTOMRIGHT", 0, me:GetHeight() * ( 0.5 - StartY ) );
					Texture:SetTexCoord( 0, 1, 0, Dy );
				end
			else
				Side = ( EndX - StartX ) * StartY - ( EndY - StartY ) * StartX;
				if ( Side <= 0 ) then -- Center of circle inside clipped region; at least half of circle to draw
					--NOTE(Draw using two circular textures and a triangle.)
				else
					--NOTE(Have to split up into tris)
				end
			end
		end
	end

	local AddSplitPoints; -- Adds split points between the last exit intersection and the most recent entrance intersection
	do
		local StartX, StartY;
		local StartXReal, StartYReal;
		local EndX, EndY;
		local SplitX, SplitY, Side;
		local StartDistance2, StartPoint;
		local NearestDistance2, NearestPoint;
		local Distance2;
		local ForStart, ForEnd, ForStep;
		function AddSplitPoints ( EndXReal, EndYReal, WrapToStart )
			StartXReal, StartYReal = Points[ LastExitPoint ], Points[ LastExitPoint + 1 ];

			if ( IsQuadrantRound( StartXReal, StartYReal ) ) then
				LastRoundX, LastRoundY = StartXReal, StartYReal;
			else
				LastRoundX, LastRoundY = nil;
			end

			if ( #SplitPoints > 0 ) then
				if ( IsClockwise ) then
					StartX, StartY = EndXReal, EndYReal;
					EndX, EndY = StartXReal, StartYReal;
				else
					StartX, StartY = StartXReal, StartYReal;
					EndX, EndY = EndXReal, EndYReal;
				end

				-- Find first split point after start
				StartDistance2, StartPoint = math.huge;
				NearestDistance2, NearestPoint = math.huge;
				ForEnd, ForStep = #SplitPoints - 1, IsClockwise and -2 or 2;
				for Index = IsClockwise and ForEnd or 1, IsClockwise and 1 or ForEnd, ForStep do
					SplitX, SplitY = SplitPoints[ Index ], SplitPoints[ Index + 1 ];
					Side = ( EndX - StartX ) * ( SplitY - StartY ) - ( EndY - StartY ) * ( SplitX - StartX );

					if ( Side > 0 ) then -- Valid split point
						Distance2 = ( StartXReal - SplitX ) ^ 2 + ( StartYReal - SplitY ) ^ 2;
						if ( Distance2 < NearestDistance2 ) then
							NearestPoint, NearestDistance2 = Index, Distance2;
						end
						if ( Distance2 < StartDistance2 and Distance2 < ( EndXReal - SplitX ) ^ 2 + ( EndYReal - SplitY ) ^ 2 ) then
							StartPoint, StartDistance2 = Index, Distance2;
						end
					end
				end
				if ( not StartPoint ) then
					StartPoint = NearestPoint;
				end

				-- Add all split points after start
				if ( StartPoint ) then
					SplitX, SplitY = SplitPoints[ StartPoint ], SplitPoints[ StartPoint + 1 ];
					Points[ #Points + 1 ] = SplitX;
					Points[ #Points + 1 ] = SplitY;

					if ( LastRoundX ) then
						AddRoundSplit( SplitX, SplitY );
					elseif ( SplitX == 0 or SplitY == 0 ) then
						LastRoundX, LastRoundY = SplitX, SplitY;
					end

					ForStart, ForEnd = StartPoint + 2, StartPoint + #SplitPoints - 2;
					for Index = IsClockwise and ForEnd or ForStart, IsClockwise and ForStart or ForEnd, ForStep do
						SplitX, SplitY = SplitPoints[ ( Index - 1 ) % #SplitPoints + 1 ], SplitPoints[ Index % #SplitPoints + 1 ];
						Side = ( EndX - StartX ) * ( SplitY - StartY ) - ( EndY - StartY ) * ( SplitX - StartX );

						if ( Side > 0 ) then -- Valid split point
							Points[ #Points + 1 ] = SplitX;
							Points[ #Points + 1 ] = SplitY;

							if ( LastRoundX ) then
								AddRoundSplit( SplitX, SplitY );
							elseif ( SplitX == 0 or SplitY == 0 ) then
								LastRoundX, LastRoundY = SplitX, SplitY;
							end
						else
							break;
						end
					end
				end
			end

			if ( LastRoundX ) then
				AddRoundSplit( EndXReal, EndYReal );
			end
			LastExitPoint = nil;

			if ( not WrapToStart ) then
				-- Add re-entry point
				Points[ #Points + 1 ] = EndXReal;
				Points[ #Points + 1 ] = EndYReal;
			end
		end
	end

	local AddIntersection; -- Adds the intersection of a line with the minimap to the Points table
	do
		local ABx, ABy;
		local PointX, PointY;
		local IntersectPos, Intercept, Length, Temp;
		function AddIntersection ( Ax, Ay, Bx, By, PerpDist2, IsExiting )
			PointX, PointY = nil;
			ABx, ABy = Ax - Bx, Ay - By;

			-- Clip to square
			if ( Ax >= -0.5 and Ax <= 0.5 and Ay >= -0.5 and Ay <= 0.5 ) then
				PointX, PointY = Ax, Ay;
			else
				-- Test intersection with horizontal border
				Intercept = ABy < 0 and -0.5 or 0.5;
				IntersectPos = ( Ay - Intercept ) / ABy;
				if ( IntersectPos >= 0 and IntersectPos <= 1 ) then
					PointX = Ax - ABx * IntersectPos;
					if ( PointX >= -0.5 and PointX <= 0.5 ) then
						PointY = Intercept;
					end
				end

				-- Test vertical border intersection
				if ( not PointY ) then -- Was no horizontal intersect
					Intercept = ABx < 0 and -0.5 or 0.5;
					IntersectPos = ( Ax - Intercept ) / ABx;
					if ( IntersectPos >= 0 and IntersectPos <= 1 ) then
						PointY = Ay - ABy * IntersectPos;
						if ( PointY >= -0.5 and PointY <= 0.5 ) then
							PointX = Intercept;
						else
							return;
						end
					else
						return;
					end
				end
			end

			if ( IsQuadrantRound( PointX, PointY ) ) then
				-- Clip to circle
				if ( PerpDist2 < 0.25 ) then
					Length = ABx * ABx + ABy * ABy;
					Temp = ABx * Bx + ABy * By;

					IntersectPos = ( ( Temp * Temp - Length * ( Bx * Bx + By * By - 0.25 ) ) ^ 0.5 - Temp ) / Length;
					if ( IntersectPos >= 0 and IntersectPos <= 1 ) then
						PointX, PointY = Bx + ABx * IntersectPos, By + ABy * IntersectPos;
					else
						return;
					end
				else
					return;
				end
			end

			if ( LastExitPoint ) then
				AddSplitPoints( PointX, PointY );
			else
				if ( IsExiting ) then
					LastExitPoint = #Points + 1;
				end
				Points[ #Points + 1 ] = PointX;
				Points[ #Points + 1 ] = PointY;
			end
		end
	end

	local wipe = wipe;
	local ABx, ABy, BCx, BCy, ACx, ACy;
	local AInside, BInside, CInside;
	local IntersectPos, PerpX, PerpY;
	local ABPerpDist2, BCPerpDist2, ACPerpDist2;
	local Dot00, Dot01, Dot02, Dot11, Dot12;
	local Denominator, U, V;
	local Texture, Left, Top;
	function RepaintTriangle ( Ax, Ay, Bx, By, Cx, Cy )
		if ( RotateMinimap ) then
			Ax, Ay = Ax * FacingCos - Ay * FacingSin, Ax * FacingSin + Ay * FacingCos;
			Bx, By = Bx * FacingCos - By * FacingSin, Bx * FacingSin + By * FacingCos;
			Cx, Cy = Cx * FacingCos - Cy * FacingSin, Cx * FacingSin + Cy * FacingCos;
		end

		if ( -- If all points are on one side, cannot possibly intersect
			not ( ( Ax > 0.5 and Bx > 0.5 and Cx > 0.5 )
			or ( Ax < -0.5 and Bx < -0.5 and Cx < -0.5 )
			or ( Ay > 0.5 and By > 0.5 and Cy > 0.5 )
			or ( Ay < -0.5 and By < -0.5 and Cy < -0.5 ) )
		) then
			if ( IsQuadrantRound( Ax, Ay ) ) then
				AInside = Ax * Ax + Ay * Ay <= 0.25;
			else
				AInside = Ax <= 0.5 and Ax >= -0.5 and Ay <= 0.5 and Ay >= -0.5;
			end
			if ( IsQuadrantRound( Bx, By ) ) then
				BInside = Bx * Bx + By * By <= 0.25;
			else
				BInside = Bx <= 0.5 and Bx >= -0.5 and By <= 0.5 and By >= -0.5;
			end
			if ( IsQuadrantRound( Cx, Cy ) ) then
				CInside = Cx * Cx + Cy * Cy <= 0.25;
			else
				CInside = Cx <= 0.5 and Cx >= -0.5 and Cy <= 0.5 and Cy >= -0.5;
			end

			if ( AInside and BInside and CInside ) then -- No possible intersections
				Overlay.TextureAdd( me, "ARTWORK", R, G, B,
					Ax + 0.5, Ay + 0.5, Bx + 0.5, By + 0.5, Cx + 0.5, Cy + 0.5 );
			else
				ABx, ABy = Ax - Bx, Ay - By;
				BCx, BCy = Bx - Cx, By - Cy;
				ACx, ACy = Ax - Cx, Ay - Cy;

				-- Intersection between the side and a line perpendicular to it that passes through the center
				IntersectPos = ( Ax * ABx + Ay * ABy ) / ( ABx * ABx + ABy * ABy );
				PerpX, PerpY = Ax - IntersectPos * ABx, Ay - IntersectPos * ABy;
				ABPerpDist2 = PerpX * PerpX + PerpY * PerpY; -- From center to intersection squared

				IntersectPos = ( Bx * BCx + By * BCy ) / ( BCx * BCx + BCy * BCy );
				PerpX, PerpY = Bx - IntersectPos * BCx, By - IntersectPos * BCy;
				BCPerpDist2 = PerpX * PerpX + PerpY * PerpY;

				IntersectPos = ( Ax * ACx + Ay * ACy ) / ( ACx * ACx + ACy * ACy );
				PerpX, PerpY = Ax - IntersectPos * ACx, Ay - IntersectPos * ACy;
				ACPerpDist2 = PerpX * PerpX + PerpY * PerpY;


				if ( #Points > 0 ) then
					wipe( Points );
				end
				LastExitPoint = nil;

				-- Check intersection with circle with radius at minimap's corner
				if ( ABPerpDist2 < 0.5 or BCPerpDist2 < 0.5 or ACPerpDist2 < 0.5 ) then -- Inside radius ~= 0.71
					-- Find all polygon vertices
					IsClockwise = BCx * ( By + Cy ) + ABx * ( Ay + By ) + ( Cx - Ax ) * ( Cy + Ay ) > 0;
					if ( AInside ) then
						Points[ #Points + 1 ] = Ax;
						Points[ #Points + 1 ] = Ay;
					else
						AddIntersection( Ax, Ay, Cx, Cy, ACPerpDist2, true );
						AddIntersection( Ax, Ay, Bx, By, ABPerpDist2 );
					end
					if ( BInside ) then
						Points[ #Points + 1 ] = Bx;
						Points[ #Points + 1 ] = By;
					else
						AddIntersection( Bx, By, Ax, Ay, ABPerpDist2, true );
						AddIntersection( Bx, By, Cx, Cy, BCPerpDist2 );
					end
					if ( CInside ) then
						Points[ #Points + 1 ] = Cx;
						Points[ #Points + 1 ] = Cy;
					else
						AddIntersection( Cx, Cy, Bx, By, BCPerpDist2, true );
						AddIntersection( Cx, Cy, Ax, Ay, ACPerpDist2 );
					end
					if ( LastExitPoint ) then -- Final split points between C and A
						AddSplitPoints( Points[ 1 ], Points[ 2 ], true );
					end

					-- Draw tris between convex polygon vertices
					for Index = #Points, 6, -2 do
						Overlay.TextureAdd( me, "ARTWORK", R, G, B,
							Points[ 1 ] + 0.5, Points[ 2 ] + 0.5, Points[ Index - 3 ] + 0.5, Points[ Index - 2 ] + 0.5, Points[ Index - 1 ] + 0.5, Points[ Index ] + 0.5 );
					end
				end

				if ( #Points == 0 ) then -- No intersections
					-- Check if the center is in the triangle
					Dot00, Dot01 = ACx * ACx + ACy * ACy, ACx * BCx + ACy * BCy;
					Dot02 = ACx * -Cx - ACy * Cy;
					Dot11, Dot12 = BCx * BCx + BCy * BCy, BCx * -Cx - BCy * Cy;

					Denominator = Dot00 * Dot11 - Dot01 * Dot01;
					U, V = ( Dot11 * Dot02 - Dot01 * Dot12 ) / Denominator,
						( Dot00 * Dot12 - Dot01 * Dot02 ) / Denominator;

					if ( U > 0 and V > 0 and U + V < 1 ) then -- Entire minimap is contained
						for Index = 1, 4 do
							Texture = Overlay.TextureCreate( me, "ARTWORK", R, G, B );
							Left, Top = Index == 2 or Index == 3, Index <= 2;
							Texture:SetPoint( "LEFT", me, Left and "LEFT" or "CENTER" );
							Texture:SetPoint( "RIGHT", me, Left and "CENTER" or "RIGHT" );
							Texture:SetPoint( "TOP", me, Top and "TOP" or "CENTER" );
							Texture:SetPoint( "BOTTOM", me, Top and "CENTER" or "BOTTOM" );
							if ( Quadrants[ Index ] ) then -- Rounded
								Texture:SetTexture( ROUNT_TEXTURE_PATH );
								Texture:SetTexCoord( Left and 0 or 0.5, Left and 0.5 or 1, Top and 0 or 0.5, Top and 0.5 or 1 );
							else -- Square
								Texture:SetTexture( [[Interface\Buttons\WHITE8X8]] );
								Texture:SetTexCoord( 0, 1, 0, 1 );
							end
						end
					end
				end
			end
		end
	end
end




local MinimapShapes = { -- Credit to MobileMinimapButtons as seen at <http://www.wowwiki.com/GetMinimapShape>
	-- [ Shape ] = { Q1, Q2, Q3, Q4 }; where true = rounded and false = squared
	[ "ROUND" ]                 = {  true,  true,  true,  true };
	[ "SQUARE" ]                = { false, false, false, false };
	[ "CORNER-TOPRIGHT" ]       = {  true, false, false, false };
	[ "CORNER-TOPLEFT" ]        = { false,  true, false, false };
	[ "CORNER-BOTTOMLEFT" ]     = { false, false,  true, false };
	[ "CORNER-BOTTOMRIGHT" ]    = { false, false, false,  true };
	[ "SIDE-TOP" ]              = {  true,  true, false, false };
	[ "SIDE-LEFT" ]             = { false,  true,  true, false };
	[ "SIDE-BOTTOM" ]           = { false, false,  true,  true };
	[ "SIDE-RIGHT" ]            = {  true, false, false,  true };
	[ "TRICORNER-BOTTOMLEFT" ]  = { false,  true,  true,  true };
	[ "TRICORNER-BOTTOMRIGHT" ] = {  true, false,  true,  true };
	[ "TRICORNER-TOPRIGHT" ]    = {  true,  true, false,  true };
	[ "TRICORNER-TOPLEFT" ]     = {  true,  true,  true, false };
};
local LastQuadrants;

local Cos, Sin = math.cos, math.sin;
function Canvas:Repaint ( Ax, Ay, Bx, By, Cx, Cy )
	Overlay.TextureAdd( self, "BORDER", 0.1, 1, 0.1,
		Ax, Ay, Bx, By, Cx, Cy );

	ClearLabels();

	Quadrants = MinimapShapes[ GetMinimapShape and GetMinimapShape() ] or MinimapShapes[ "ROUND" ];
	if ( Quadrants ~= LastQuadrants ) then
		LastQuadrants = Quadrants;

		-- Cache split points
		wipe( SplitPoints );
		for Index = 1, 4 do
			local Left, Top = Index == 2 or Index == 3, Index <= 2;
			if ( Quadrants[ Index ] ) then -- Round
				-- Note: Cos/sin avoided for accuracy
				if ( not Quadrants[ ( Index - 2 ) % 4 + 1 ] ) then -- Transition from previous
					-- 0.5*(Cos|-Sin) of angle ( Index - 1 ) * math.pi / 2
					SplitPoints[ #SplitPoints + 1 ] = ( Top and 0.5 or 0 ) - ( Left and 0.5 or 0 );
					SplitPoints[ #SplitPoints + 1 ] = ( Top and 0 or 0.5 ) - ( Left and 0.5 or 0 );
				end
				if ( not Quadrants[ Index % 4 + 1 ] ) then -- Transition to next
					-- 0.5*(Cos|-Sin) of angle Index * math.pi / 2
					SplitPoints[ #SplitPoints + 1 ] = ( Top and 0 or 0.5 ) - ( Left and 0.5 or 0 );
					SplitPoints[ #SplitPoints + 1 ] = ( Top and 0 or 0.5 ) - ( Left and 0 or 0.5 );
				end
			else -- Square
				SplitPoints[ #SplitPoints + 1 ] = Left and -0.5 or 0.5;
				SplitPoints[ #SplitPoints + 1 ] = Top and -0.5 or 0.5;
			end
		end
	end

	if ( RotateMinimap ) then
		FacingCos = Cos( Facing );
		FacingSin = Sin( Facing );
	end

	RepaintTriangle( Ax - 0.5, Ay - 0.5, Bx - 0.5, By - 0.5, Cx - 0.5, Cy - 0.5 );
end
