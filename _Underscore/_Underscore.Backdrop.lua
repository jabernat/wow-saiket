--[[****************************************************************************
  * _Underscore by Saiket                                                      *
  * _Underscore.Backdrop.lua - Factory for uniform background panels.          *
  ****************************************************************************]]


local me = CreateFrame( "Frame" );
_Underscore.Backdrop = me;

me.Padding = 3;

local Colors = _Underscore.Colors;

local BorderSize = 4;
local BorderColor = Colors.Foreground;
local BorderTexture = [[Interface\AddOns\]]..( ... )..[[\Skin\BackdropBorder]];
local BorderAlpha = 0.15;
local BorderFadeTime = 0.75;




--[[****************************************************************************
  * Function: _Underscore.Backdrop:Create                                      *
  * Description: Returns a new backdrop frame.  Optional Padding argument      *
  *   specifies a non-default padding size.  If false, no anchors are set.     *
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
		local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy;
		function CreateSide ( self, Center, Index ) -- Creates and initializes a corner and side texture
			Index = Index * 2 - 1;
			local Side, Corner = self:CreateTexture( nil, "BACKGROUND" ), self:CreateTexture( nil, "BACKGROUND" );

			Side:SetTexture( BorderTexture );
			Side:SetBlendMode( "ADD" );
			Side:SetVertexColor( me.R, me.G, me.B, me.A );
			URx, URy, ULx, ULy, LLx, LLy, LRx, LRy = unpack( SideCoords, Index, Index + 7 );
			Side:SetTexCoord( ULx, ULy, LLx, LLy, URx, URy, LRx, LRy );
			if ( Index % 4 == 1 ) then -- Top or bottom
				Side:SetHeight( me.Size );
				Side:SetPoint( "LEFT", Center );
				Side:SetPoint( "RIGHT", Center );
			else -- Left or right
				Side:SetWidth( me.Size );
				Side:SetPoint( "TOP", Center );
				Side:SetPoint( "BOTTOM", Center );
			end
			Center[ #Center + 1 ] = Side;

			Corner:SetTexture( BorderTexture );
			Corner:SetBlendMode( "ADD" );
			Corner:SetVertexColor( me.R, me.G, me.B, me.A );
			URx, URy, ULx, ULy, LLx, LLy, LRx, LRy = unpack( CornerCoords, Index, Index + 7 );
			Corner:SetTexCoord( ULx, ULy, LLx, LLy, URx, URy, LRx, LRy );
			Corner:SetSize( me.Size, me.Size );
			Center[ #Center + 1 ] = Corner;

			return Side, Corner;
		end
	end
	local R, G, B = unpack( Colors.Background );
	function me:Create ( Padding )
		local Center = self:CreateTexture( nil, "BACKGROUND" );
		Center:SetTexture( R, G, B, 0.75 );

		if ( Padding ~= false ) then
			Padding = Padding or me.Padding;
			Center:SetPoint( "TOPRIGHT", Padding, Padding );
			Center:SetPoint( "BOTTOMLEFT", -Padding, -Padding );
		end

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

		me[ #me + 1 ] = Center;
		return Center;
	end
end




--[[****************************************************************************
  * Function: _Underscore.Backdrop.BorderSet                                   *
  * Description: Immediately sets the size and color of all border textures.   *
  ****************************************************************************]]
do
	local ipairs = ipairs;
	function me.BorderSet ( Size, ... )
		me.Size, me.R, me.G, me.B, me.A = Size, ...;
		for _, Backdrop in ipairs( me ) do
			for _, Texture in ipairs( Backdrop ) do
				Texture:SetVertexColor( ... );
				Texture:SetSize( Size, Size );
			end
		end
	end
end
do
	local StartSize, StartR, StartG, StartB, StartA;
	local EndSize, EndR, EndG, EndB, EndA;
--[[****************************************************************************
  * Function: _Underscore.Backdrop.BorderBlend                                 *
  * Description: Blends borders to a size and color on an S-curve.             *
  ****************************************************************************]]
	function me.BorderBlend ( Size, R, G, B, A )
		if ( not Size ) then
			Size = BorderSize;
		end
		if ( not R ) then
			R, G, B = unpack( Colors.Foreground );
		end
		if ( not A ) then
			A = BorderAlpha;
		end
		if ( Size ~= EndSize or R ~= EndR or G ~= EndG or B ~= EndB or A ~= EndA ) then
			-- Change target color
			StartSize, EndSize = me.Size, Size; -- Start using current values
			StartR, EndR = me.R, R;
			StartG, EndG = me.G, G;
			StartB, EndB = me.B, B;
			StartA, EndA = me.A, A;

			me.Time = BorderFadeTime;
			me:Show();
		end
	end
--[[****************************************************************************
  * Function: _Underscore.Backdrop:OnUpdate                                    *
  ****************************************************************************]]
	local cos = math.cos;
	local Pi = math.pi;
	function me:OnUpdate ( Elapsed )
		self.Time = self.Time - Elapsed;

		if ( self.Time <= 0 ) then -- Done
			self:Hide();
			self.BorderSet( EndSize, EndR, EndG, EndB, EndA );
		else
			local Percent = ( cos( Pi * self.Time / BorderFadeTime ) + 1 ) / 2;
			self.BorderSet( Percent * ( EndSize - StartSize ) + StartSize,
				Percent * ( EndR - StartR ) + StartR,
				Percent * ( EndG - StartG ) + StartG,
				Percent * ( EndB - StartB ) + StartB,
				Percent * ( EndA - StartA ) + StartA );
		end
	end
end


do
	local Stack = {}; -- Stack of statuses
	local Priority, Size, R, G, B, A = {}, {}, {}, {}, {}, {};
--[[****************************************************************************
  * Function: _Underscore.Backdrop.BorderAddStatus                             *
  * Description: Adds a given status identified by a non-nil value.  Priority  *
  *   is used to override other borders.                                       *
  ****************************************************************************]]
	function me.BorderAddStatus ( NewStatus, NewPriority, NewSize, NewR, NewG, NewB, NewA )
		assert( NewStatus ~= nil, "Status must be non-nil!" );
		assert( tonumber( NewPriority ), "Priority must be numeric!" );
		local TopLast = Stack[ #Stack ];

		if ( Priority[ NewStatus ] ~= NewPriority ) then -- Recalculate stack position
			local NewIndex, OldIndex = 1; -- Default to bottom

			for Index = #Stack, 1, -1 do -- Find new position, and also check for old position if updating
				local Status = Stack[ Index ];
				if ( NewStatus == Status ) then
					OldIndex = Index + 1;
				end
				if ( NewPriority >= Priority[ Status ] ) then
					NewIndex = Index + 1;
					break;
				end
			end

			if ( NewIndex ~= OldIndex ) then -- Have to add new and remove old
				tinsert( Stack, NewIndex, NewStatus );
				if ( Priority[ NewStatus ] ) then -- Was already in stack
					if ( not OldIndex ) then -- Search rest of stack for old position
						for Index = NewIndex - 2, 1, -1 do
							if ( NewStatus == Stack[ Index ] ) then
								OldIndex = Index;
								break;
							end
						end
					end
					tremove( Stack, OldIndex );
				end
			end
			Priority[ NewStatus ] = NewPriority;
		end

		-- Update if top status changed
		local Top = Stack[ #Stack ];
		if ( Top == NewStatus ) then
			if ( Size[ Top ] == NewSize and R[ Top ] == NewR and G[ Top ] == NewG and B[ Top ] == NewB and A[ Top ] == NewA ) then
				return; -- No change
			end
			me.BorderBlend( NewSize, NewR, NewG, NewB, NewA );
		elseif ( Top ~= TopLast ) then
			me.BorderBlend( Size[ Top ], R[ Top ], G[ Top ], B[ Top ], A[ Top ] );
		end
		Size[ NewStatus ], R[ NewStatus ], G[ NewStatus ], B[ NewStatus ], A[ NewStatus ] = NewSize, NewR, NewG, NewB, NewA;
	end
--[[****************************************************************************
  * Function: _Underscore.Backdrop.BorderRemoveStatus                          *
  * Description: Removes a status by its identifying table.                    *
  ****************************************************************************]]
	function me.BorderRemoveStatus ( Status )
		if ( Priority[ Status ] ) then
			Priority[ Status ], Size[ Status ], R[ Status ], G[ Status ], B[ Status ], A[ Status ] = nil;

			for Index = #Stack, 1, -1 do
				if ( Stack[ Index ] == Status ) then
					tremove( Stack, Index );
					if ( Index == #Stack + 1 ) then -- Was top; use next status
						local Top = Stack[ #Stack ];
						me.BorderBlend( Size[ Top ], R[ Top ], G[ Top ], B[ Top ], A[ Top ] );
					end
					break;
				end
			end
		end
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Initialize "current values" to defaults
	me.Size = BorderSize;
	me.R, me.G, me.B = unpack( BorderColor );
	me.A = BorderAlpha;

	me:Hide();
	me:SetScript( "OnUpdate", me.OnUpdate );
end
