--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * _NPCScan.Overlay.GeometryQuadTree.lua - Algorithm to extract geometry data *
  *   from binary data strings.                                                *
  ****************************************************************************]]


local NS = select( 2, ... );

local Callback;
local Left, Top, Right, Bottom; -- Rectangular search area

local SelectFromBlock;
do
	local WORD_SIZE = 2;
	local DWORD_SIZE = 2 * WORD_SIZE;
	local ReadDWORD, ReadSignedWORD;
	do
		local byte = string.byte;
		--- @return A ``DWORD`` from `Data` starting at `Index`, and the index of the first byte after it.
		function ReadDWORD ( Data, Index )
			local B1, B2, B3, B4 = byte( Data, Index + 1, Index + DWORD_SIZE );
			return B1 * 2 ^ 24 + B2 * 2 ^ 16 + B3 * 2 ^ 8 + B4, Index + DWORD_SIZE;
		end
		local MIN_SHORT, MAX_SHORT = -2 ^ ( 16 - 1 ), 2 ^ ( 16 - 1 ) - 1;
		--- @return A ``signed WORD`` from `Data` starting at `Index`, and the index of the first byte after it.
		function ReadSignedWORD ( Data, Index )
			local B1, B2 = byte( Data, Index + 1, Index + WORD_SIZE );
			local Value = B1 * 2 ^ 8 + B2;
			if ( Value > MAX_SHORT ) then
				Value = MIN_SHORT + Value - MAX_SHORT - 1;
			end
			return Value, Index + WORD_SIZE;
		end
	end
	--- @return An (``X``, ``Y``) coordinate from `Data` starting at `Index`, and the index of the first byte after it.
	local function ReadVertex ( Data, Index )
		local X, Index = ReadSignedWORD( Data, Index );
		return X, ReadSignedWORD( Data, Index );
	end
	local VERTEX_SIZE = 2 * WORD_SIZE;
	local BLOCK_STUB = 0; -- Sentinel address value indicating a block is a stub
	local Q1_OFFSET = 0;
	local Q2_OFFSET = Q1_OFFSET + DWORD_SIZE;
	local Q3_OFFSET = Q2_OFFSET + DWORD_SIZE;
	local Q4_OFFSET = Q3_OFFSET + DWORD_SIZE;
	local GEOMETRY_OFFSET = Q4_OFFSET + DWORD_SIZE;
	--- Runs `Callback` for each triangle within the rectangle specified to `MapQuadTreeSelect`.
	-- @param Start  Index of first byte of block within `Data` (0-based).
	-- @param BlockSize  Width and height of this block.
	-- @see `NS:MapQuadTreeSelect`
	function SelectFromBlock ( Data, Start, BlockSize, BlockCenterX, BlockCenterY )
		if ( Start == BLOCK_STUB ) then -- No entry for this block
			return;
		elseif ( not Start ) then
			Start = 0; -- Root block
		end
		-- Check overlap with sub-blocks
		if ( BlockCenterY < Top ) then -- Check top two sub-blocks
			if ( BlockCenterX < Right ) then -- Quadrant 1
				SelectFromBlock( Data, ReadDWORD( Data, Start + Q1_OFFSET ), BlockSize / 2,
					BlockCenterX + BlockSize / 4,
					BlockCenterY + BlockSize / 4 );
			end
			if ( Left < BlockCenterX ) then -- Quadrant 2
				SelectFromBlock( Data, ReadDWORD( Data, Start + Q2_OFFSET ), BlockSize / 2,
					BlockCenterX - BlockSize / 4,
					BlockCenterY + BlockSize / 4 );
			end
		end
		if ( Bottom < BlockCenterY ) then -- Check bottom two sub-blocks
			if ( Left < BlockCenterX ) then -- Quadrant 3
				SelectFromBlock( Data, ReadDWORD( Data, Start + Q3_OFFSET ), BlockSize / 2,
					BlockCenterX - BlockSize / 4,
					BlockCenterY - BlockSize / 4 );
			end
			if ( BlockCenterX < Right ) then -- Quadrant 4
				SelectFromBlock( Data, ReadDWORD( Data, Start + Q4_OFFSET ), BlockSize / 2,
					BlockCenterX + BlockSize / 4,
					BlockCenterY - BlockSize / 4 );
			end
		end

		-- Child points
		local NpcID, Ax, Ay, Bx, By, Cx, Cy;
		local NumEntries, Index = ReadDWORD( Data, Start + GEOMETRY_OFFSET );
		for Point = 1, NumEntries do
			NpcID, Index = ReadDWORD( Data, Index );
			if ( false ) then
				Index = Index + VERTEX_SIZE; -- Skip
			else -- NpcID is displayed
				Ax, Ay, Index = ReadVertex( Data, Index );
				-- Clip to view
				if ( Left < Ax and Ax < Right
					and Bottom < Ay and Ay < Top
				) then -- Within view
					Callback( NpcID, Ax, Ay );
				end
			end
		end

		-- Child lines
		NumEntries, Index = ReadDWORD( Data, Index );
		for Line = 1, NumEntries do
			NpcID, Index = ReadDWORD( Data, Index );
			if ( false ) then
				Index = Index + 2 * VERTEX_SIZE; -- Skip
			else -- NpcID is displayed
				Ax, Ay, Index = ReadVertex( Data, Index );
				Bx, By, Index = ReadVertex( Data, Index );
				-- Clip to view
				if ( ( Left < Ax or Left < Bx )
					and ( Right > Ax or Right > Bx )
					and ( Bottom < Ay or Bottom < By )
					and ( Top > Ay or Top > By )
				) then -- Within view
					Callback( NpcID, Ax, Ay, Bx, By );
				end
			end
		end

		-- Child triangles
		NumEntries, Index = ReadDWORD( Data, Index );
		for Triangle = 1, NumEntries do
			NpcID, Index = ReadDWORD( Data, Index );
			if ( false ) then
				Index = Index + 3 * VERTEX_SIZE; -- Skip
			else -- NpcID is displayed
				Ax, Ay, Index = ReadVertex( Data, Index );
				Bx, By, Index = ReadVertex( Data, Index );
				Cx, Cy, Index = ReadVertex( Data, Index );
				-- Clip to view
				if ( ( Left < Ax or Left < Bx or Left < Cx )
					and ( Right > Ax or Right > Bx or Right > Cx )
					and ( Bottom < Ay or Bottom < By or Bottom < Cy )
					and ( Top > Ay or Top > By or Top > Cy )
				) then -- Within view
					Callback( NpcID, Ax, Ay, Bx, By, Cx, Cy );
				end
			end
		end
	end
end

local MAP_SIZE = 65536; -- Width and height of root quad tree block
--- Runs `Callback` for each point, line, and triangle within the given rectangle.
-- @param Data  Binary data string representing a quad tree of geometry.
-- @param ...  `Callback`, and rectangle to search within: ((`Left`, `Top`),
--   (`Right`, `Bottom`)).  Rectangle coordinates are in map coordinates.
-- `Callback` gets called with an ``NpcID`` and from one to three (``X``, ``Y``)
--   coordinates, for points, lines, and triangles.
function NS.GeometryQuadTreeSelect ( Data, ... )
	Callback, Left, Top, Right, Bottom = ...;
	-- Assume player cannot leave map's maximum boundaries
	return SelectFromBlock( Data, nil, -- Root block is always first
		MAP_SIZE, 0, 0 ); -- Root block is centered
end