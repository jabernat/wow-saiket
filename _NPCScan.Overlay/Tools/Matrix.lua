-- Matrix.lua: A simple (and inefficient) implementation of affine (3x3) transformation matrices.

do
	local TransformMeta = { __index = {};	};
	function TransformMeta.__index:New ( ... )
		-- Create a new identity matrix
		local Matrix = setmetatable( {}, TransformMeta );
		for Position = 1, 9 do
			Matrix[ Position ] = select( Position, ... ) or ( Position % 4 == 1 and 1 or 0 );
		end
		return Matrix;
	end
	function TransformMeta.__index:Copy ()
		return self:New( unpack( self ) );
	end
	function TransformMeta.__mul ( Op1, Op2 )
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

	function TransformMeta.__index:Translate ( X, Y )
		return self:New( 1, 0, X, 0, 1, Y ) * self;
	end
	function TransformMeta.__index:Scale ( ScaleX, ScaleY )
		return self:New( ScaleX, 0, 0, 0, ScaleY, 0 ) * self;
	end
	function TransformMeta.__index:Rotate ( Sin, Cos )
		if ( not Cos ) then
			local Angle = Sin;
			Sin = math.sin( Angle );
			Cos = math.cos( Angle );
		end
		return self:New( Cos, Sin, 0, -Sin, Cos, 0 ) * self;
	end
	function TransformMeta.__index:Shear ( FactorX, FactorY )
		return self:New( 1, FactorX or 0, 0, FactorY or 0, 1, 0 ) * self;
	end
	Identity = TransformMeta.__index.New();




	local SymbolicMeta = { __index = setmetatable( {}, TransformMeta ); };
	function SymbolicMeta.__index:New ( ... )
		return setmetatable( TransformMeta.__index.New( self, ... ), SymbolicMeta );
	end
	do
		local Values = {};
		function SymbolicMeta.__mul ( Op1, Op2 )
			local Result = Op1:New();
			for Index = 1, 9 do
				for Position = 1, 3 do
					local Arg1, Arg2 = Op1[ floor( ( Index - 1 ) / 3 ) * 3 + Position ], Op2[ ( Position - 1 ) * 3 + ( Index - 1 ) % 3 + 1 ];
					if ( Arg1 ~= 0 and Arg2 ~= 0 ) then
						if ( Arg1 == 1 ) then
							tinsert( Values, "( "..Arg2.." )" );
						elseif ( Arg2 == 1 ) then
							tinsert( Values, "( "..Arg1.." )" );
						else
							tinsert( Values, "( "..Arg1.." ) * ( "..Arg2.." )" );
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
	IdentitySymbolic = SymbolicMeta.__index.New();
end