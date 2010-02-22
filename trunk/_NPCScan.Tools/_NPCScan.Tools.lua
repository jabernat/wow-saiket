--[[****************************************************************************
  * _NPCScan.Tools by Saiket                                                   *
  * _NPCScan.Tools.lua - Tools to help maintain _NPCScan/_NPCScan.Overlay.     *
  ****************************************************************************]]


local _NPCScan = _NPCScan;
local me = {};
_NPCScan.Tools = me;

me.Matrix = {
	Meta = { __index = {}; };
	MetaSymbolic = { __index = {}; };
};
local MatrixMeta = me.Matrix.Meta;
local MatrixMetaSymbolic = me.Matrix.MetaSymbolic;




--------------------------------------------------------------------------------
-- _NPCScan.Tools.Matrix: A simple implementation of affine (3x3) transformation matrices.
---------------------------

--[[****************************************************************************
  * Function: _NPCScan.Tools.Matrix.Meta.__index:New                           *
  ****************************************************************************]]
function MatrixMeta.__index:New ( ... )
	-- Create a new identity matrix
	local Matrix = setmetatable( {}, self.Meta );
	for Position = 1, 9 do
		Matrix[ Position ] = select( Position, ... ) or ( Position % 4 == 1 and 1 or 0 );
	end
	return Matrix;
end
--[[****************************************************************************
  * Function: _NPCScan.Tools.Matrix.Meta.__index:Copy                          *
  ****************************************************************************]]
function MatrixMeta.__index:Copy ()
	return self:New( unpack( self ) );
end
--[[****************************************************************************
  * Function: _NPCScan.Tools.Matrix.Meta.__mul                                 *
  ****************************************************************************]]
do
	local floor = floor;
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


--[[****************************************************************************
  * Function: _NPCScan.Tools.Matrix.Meta.__index:Translate                     *
  ****************************************************************************]]
function MatrixMeta.__index:Translate ( X, Y )
	return self:New( 1, 0, X, 0, 1, Y ) * self;
end
--[[****************************************************************************
  * Function: _NPCScan.Tools.Matrix.Meta.__index:Scale                         *
  ****************************************************************************]]
function MatrixMeta.__index:Scale ( ScaleX, ScaleY )
	return self:New( ScaleX, 0, 0, 0, ScaleY, 0 ) * self;
end
--[[****************************************************************************
  * Function: _NPCScan.Tools.Matrix.Meta.__index:Rotate                        *
  * Description: Takes an angle in rads or a pair of sin/cos values.           *
  ****************************************************************************]]
function MatrixMeta.__index:Rotate ( Sin, Cos )
	if ( not Cos ) then
		local Angle = Sin;
		Sin = math.sin( Angle );
		Cos = math.cos( Angle );
	end
	return self:New( Cos, Sin, 0, -Sin, Cos, 0 ) * self;
end
--[[****************************************************************************
  * Function: _NPCScan.Tools.Matrix.Meta.__index:Shear                         *
  ****************************************************************************]]
function MatrixMeta.__index:Shear ( FactorX, FactorY )
	return self:New( 1, FactorX or 0, 0, FactorY or 0, 1, 0 ) * self;
end




--[[****************************************************************************
  * Function: _NPCScan.Tools.Matrix.MetaSymbolic.__mul                         *
  ****************************************************************************]]
do
	local Values = {};
	local floor = floor;
	local wipe = wipe;
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




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	MatrixMeta.__index.Meta = MatrixMeta;
	Identity = MatrixMeta.__index:New();

	setmetatable( MatrixMetaSymbolic.__index, MatrixMeta );
	MatrixMetaSymbolic.__index.Meta = MatrixMetaSymbolic;
	IdentitySymbolic = MatrixMetaSymbolic.__index:New();
end
