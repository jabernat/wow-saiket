--[[****************************************************************************
  * _NPCScan.Tools by Saiket                                                   *
  * _NPCScan.Tools.lua - Tools to help maintain _NPCScan/_NPCScan.Overlay.     *
  ****************************************************************************]]


local _NPCScan = _NPCScan;
local NS = select( 2, ... );
_NPCScan.Tools = NS;

NS.Matrix = { -- A simple implementation of affine (3x3) transformation matrices.
	Meta = { __index = {}; };
	MetaSymbolic = { __index = {}; };
};
local MatrixMeta = NS.Matrix.Meta;
local MatrixMetaSymbolic = NS.Matrix.MetaSymbolic;




--- @return A new matrix instance.
function MatrixMeta.__index:New ( ... )
	-- Create a new identity matrix
	local Matrix = setmetatable( {}, self.Meta );
	for Position = 1, 9 do
		Matrix[ Position ] = select( Position, ... ) or ( Position % 4 == 1 and 1 or 0 );
	end
	return Matrix;
end
--- @return A new matrix instance with elements identical to this one.
function MatrixMeta.__index:Copy ()
	return self:New( unpack( self ) );
end
do
	local floor = floor;
	--- @return The result of matrix multiplication Op1 * Op2.
	function MatrixMeta.__mul ( Op1, Op2 )
		local Result = Op1:New();

		for Index = 1, 9 do
			local Value = 0;
			for Position = 1, 3 do
				Value = Value + Op1[ floor( ( Index - 1 ) / 3 ) * 3 + Position ] * Op2[ ( Position - 1 ) * 3 + ( Index - 1 ) % 3 + 1 ];
			end
			Result[ Index ] = Value;
		end

		return Result;
	end
end


--- @return The result of translating this matrix by (X,Y).
function MatrixMeta.__index:Translate ( X, Y )
	return self:New( 1, 0, X, 0, 1, Y ) * self;
end
--- @return The result of scaling this matrix by (ScaleX,ScaleY).
function MatrixMeta.__index:Scale ( ScaleX, ScaleY )
	return self:New( ScaleX, 0, 0, 0, ScaleY, 0 ) * self;
end
--- @param Sin..Cos  An angle in rads or precalculated sin/cos values.
-- @return The result of rotating this matrix.
function MatrixMeta.__index:Rotate ( Sin, Cos )
	if ( not Cos ) then
		local Angle = Sin;
		Sin = math.sin( Angle );
		Cos = math.cos( Angle );
	end
	return self:New( Cos, Sin, 0, -Sin, Cos, 0 ) * self;
end
--- @return The result of shearing this matrix by (FactorX,FactorY).
function MatrixMeta.__index:Shear ( FactorX, FactorY )
	return self:New( 1, FactorX or 0, 0, FactorY or 0, 1, 0 ) * self;
end




do
	local Values = {};
	local floor = floor;
	local wipe = wipe;
	--- @return Matrix of symbolic equations used to calculate multiplication of Op1 * Op2.
	-- @see MatrixMeta.__mul
	function MatrixMetaSymbolic.__mul ( Op1, Op2 )
		local Result = Op1:New();
		for Index = 1, 9 do
			for Position = 1, 3 do
				local Arg1, Arg2 = Op1[ floor( ( Index - 1 ) / 3 ) * 3 + Position ], Op2[ ( Position - 1 ) * 3 + ( Index - 1 ) % 3 + 1 ];
				if ( Arg1 ~= 0 and Arg2 ~= 0 ) then
					if ( Arg1 == 1 ) then
						Values[ #Values + 1 ] = "( "..Arg2.." )";
					elseif ( Arg2 == 1 ) then
						Values[ #Values + 1 ] = "( "..Arg1.." )";
					else
						Values[ #Values + 1 ] = "( "..Arg1.." ) * ( "..Arg2.." )";
					end
				end
			end

			if ( #Values == 0 ) then
				Result[ Index ] = 0;
			elseif ( #Values == 1 and Values[ 1 ] == 1 ) then
				Result[ Index ] = 1;
			else
				Result[ Index ] = table.concat( Values, " + " );
			end
			wipe( Values );
		end
		return Result;
	end
end




MatrixMeta.__index.Meta = MatrixMeta;
Identity = MatrixMeta.__index:New();

setmetatable( MatrixMetaSymbolic.__index, MatrixMeta );
MatrixMetaSymbolic.__index.Meta = MatrixMetaSymbolic;
IdentitySymbolic = MatrixMetaSymbolic.__index:New();