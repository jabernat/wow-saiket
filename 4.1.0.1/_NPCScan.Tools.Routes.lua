--[[****************************************************************************
  * _NPCScan.Tools by Saiket                                                   *
  * _NPCScan.Tools.Routes.lua - Data source for Routes to import NPCData.      *
  ****************************************************************************]]


local Routes = LibStub( "AceAddon-3.0" ):GetAddon( "Routes" );
assert( Routes.SetupSourcesOptTables, -- Routes GCs this method by default
	"Routes must be modified to allow external data sources." );
local me, AddOnName, Tools = {}, ...;
Routes.plugins[ AddOnName ] = me;




--- @return Data table populated with available data sources for MapName.
function me.Summarize ( Data, MapName )
	local MapIDTarget = Routes.LZName[ MapName ][ 2 ];
	for NpcID, MapID in pairs( Tools.NPCMapIDs ) do
		if ( MapID == MapIDTarget ) then
			local PointCount = #Tools.NPCPointData[ NpcID ] / 4;
			Data[ ( "%s;%s;%d;%d" ):format( AddOnName, "Note", NpcID, PointCount ) ]
				= Tools.L.DATASOURCE_FORMAT:format( NpcID, Tools.NPCNames[ NpcID ] );
		end
	end
	return Data;
end
do
	local Max = 2 ^ 16 - 1;
	--- Adds each node for a given NpcID and MapName to Nodes.
	-- @return DataSourceID, LocalizedName, NodeType
	function me.AppendNodes ( Nodes, MapName, NodeType, NpcID )
		assert( NodeType == "Note", "Wrong node type." );
		NpcID = tonumber( NpcID );
		local Data = assert( Tools.NPCPointData[NpcID], "Node data missing." );

		for Index = 1, #Data, 4 do
			local X, X2, Y, Y2 = Data:byte( Index, Index + 3 );
			X, Y = ( X * 256 + X2 ) / Max, ( Y * 256 + Y2 ) / Max;
			Nodes[ #Nodes + 1 ] = Routes:getID( X, Y );
		end
		return NpcID, Tools.L.DATASOURCE_FORMAT:format( NpcID, Tools.NPCNames[ NpcID ] ), "Note";
	end
end


--- @return True if module methods can be queried.
function me.IsActive ()
	return true;
end
--- Called when module is enabled.
function me.AddCallbacks ()
end
--- Called when module is disabled.
function me.RemoveCallbacks ()
end


Routes:SetupSourcesOptTables();