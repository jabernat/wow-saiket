--[[****************************************************************************
  * _VirtualPlates by Saiket                                                   *
  * _VirtualPlates.lua - Adds depth to the default nameplate frames.           *
  ****************************************************************************]]


local me = CreateFrame( "Frame", "_VirtualPlates" );

local Plates = {};
me.Plates = Plates;
local PlatesVisible = {};
me.PlatesVisible = PlatesVisible;


me.ScaleFactor = 10; -- Nameplates this number of yards away will be scaled to
                     -- their normal size (i.e. larger number = larger nameplates)
me.CameraClip = 4; -- Yards from camera when nameplates begin fading out


local InCombat = false;

local WorldFrameGetChildren = WorldFrame.GetChildren;
local PlateOverrides = {}; -- [ MethodName ] = Function overrides for Visuals




--[[****************************************************************************
  * Function: _VirtualPlates:PlateOnShow                                       *
  * Description: WoW re-anchors most regions when it shows a nameplate, so     *
  *   restore those anchors to the Visual frame.                               *
  ****************************************************************************]]
do
	local select = select;
	local function ResetPoint ( Plate, Region, ... )
		if ( select( 2, ... ) == Plate ) then
			Region:SetPoint( ..., Plates[ Plate ], select( 3, ... ) );
		end
	end

	function me:PlateOnShow ()
		local Visual = Plates[ self ];
		PlatesVisible[ self ] = Visual;

		-- Reposition all regions
		for Index, Region in ipairs( self ) do
			for Point = 1, Region:GetNumPoints() do
				ResetPoint( self, Region, Region:GetPoint( Point ) );
			end
		end
	end
end
--[[****************************************************************************
  * Function: _VirtualPlates:PlateOnHide                                       *
  ****************************************************************************]]
function me:PlateOnHide ()
	PlatesVisible[ self ] = nil;
end




--[[****************************************************************************
  * Function: local PlateAdd                                                   *
  * Description: Adds and skins a new nameplate.                               *
  ****************************************************************************]]
local PlateAdd;
do
	local select = select;
	local function ReparentRegions ( Plate, ... ) -- Also saves a list of all original regions into the plate frame
		local Visual = Plates[ Plate ];
		for Index = 1, select( "#", ... ) do
			local Region = select( Index, ... );
			if ( Region ~= Visual ) then
				Region:SetParent( Visual );
				Plate[ #Plate + 1 ] = Region;
			end
		end
	end

	function PlateAdd ( Plate )
		local Visual = CreateFrame( "Frame", nil, Plate );
		Plates[ Plate ] = Visual;

		Visual:SetPoint( "TOP" );
		Visual:SetWidth( Plate:GetWidth() );
		Visual:SetHeight( Plate:GetHeight() );

		ReparentRegions( Plate, Plate:GetChildren() );
		Plate.ChildCount = #Plate;
		ReparentRegions( Plate, Plate:GetRegions() );
		Visual:EnableDrawLayer( "HIGHLIGHT" ); -- Allows the highlight to show without enabling mouse events

		Plate:SetScript( "OnShow", me.PlateOnShow );
		Plate:SetScript( "OnHide", me.PlateOnHide );
		if ( Plate:IsVisible() ) then
			me.PlateOnShow( Plate );
		end

		-- Hook methods
		for Key, Value in pairs( PlateOverrides ) do
			Visual[ Key ] = Value;
		end
	end
end

--[[****************************************************************************
  * Function: local PlatesScan                                                 *
  * Description: Scans children of WorldFrame and handles new nameplates.      *
  ****************************************************************************]]
local PlatesScan;
do
	local select = select;
	local Frame, Region;
	function PlatesScan ( ... )
		for Index = 1, select( "#", ... ) do
			Frame = select( Index, ... );
			if ( not Plates[ Frame ] ) then
				Region = Frame:GetRegions();
				if ( Region and Region:GetObjectType() == "Texture" and Region:GetTexture() == [[Interface\TargetingFrame\UI-TargetingFrame-Flash]] ) then
					PlateAdd( Frame );
				end
			end
		end
	end
end
--[[****************************************************************************
  * Function: local PlatesUpdate                                               *
  * Description: Sorts, scales, and fades all nameplates based on depth.       *
  ****************************************************************************]]
local PlatesUpdate;
do
	local SortOrder, Depths = {}, {};
	local function SortFunc ( PlateA, PlateB )
		return Depths[ PlateA ] > Depths[ PlateB ];
	end

	local SetAlpha = me.SetAlpha; -- Backup since plate SetAlpha methods are overridden
	local sort, wipe = sort, wipe;
	local select, ipairs = select, ipairs;
	local Depth, Visual, Level, Scale
	function PlatesUpdate ()
		for Plate, Visual in pairs( PlatesVisible ) do
			Depth = Plate:GetEffectiveDepth();
			if ( Depth <= 0 ) then -- Too close to camera; Completely hidden
				SetAlpha( Visual, 0 );
			else
				SortOrder[ #SortOrder + 1 ] = Plate;
				Depths[ Plate ] = Depth;
			end
		end


		if ( #SortOrder > 0 ) then
			sort( SortOrder, SortFunc );
			for Index, Plate in ipairs( SortOrder ) do
				Depth, Visual = Depths[ Plate ], Plates[ Plate ];

				if ( Depth < me.CameraClip ) then -- Begin fading as nameplate passes behind screen
					SetAlpha( Visual, Depth / me.CameraClip );
				else
					SetAlpha( Visual, 1 );
				end

				Level = Index * 2;
				Visual:SetFrameLevel( Level );
				Level = Level - 1; -- Bars must be *behind* the parent plate
				for Index = 1, Plate.ChildCount do
					Plate[ Index ]:SetFrameLevel( Level );
				end
				Scale = me.ScaleFactor / Depth;
				Visual:SetScale( Scale );
				if ( not InCombat ) then
					Plate:SetWidth( Visual:GetWidth() * Scale );
					Plate:SetHeight( Visual:GetHeight() * Scale );
				end
			end
			wipe( SortOrder );
		end
	end
end




--[[****************************************************************************
  * Function: _VirtualPlates:PLAYER_LOGIN                                      *
  ****************************************************************************]]
function me:PLAYER_LOGIN ()
	-- Don't throw an error if the client doesn't have this CVar yet
	pcall( SetCVar, "nameplateAllowOverlap", 1 );
end
--[[****************************************************************************
  * Function: _VirtualPlates:PLAYER_REGEN_ENABLED                              *
  ****************************************************************************]]
function me:PLAYER_REGEN_ENABLED ()
	InCombat = false;
end
--[[****************************************************************************
  * Function: _VirtualPlates:PLAYER_REGEN_DISABLED                             *
  * Description: Restores plates to their real size before entering combat.    *
  ****************************************************************************]]
function me:PLAYER_REGEN_DISABLED ()
	InCombat = true;

	for Plate, Visual in pairs( Plates ) do
		Plate:SetWidth( Visual:GetWidth() );
		Plate:SetHeight( Visual:GetHeight() );
	end
end
--[[****************************************************************************
  * Function: _VirtualPlates:OnEvent                                           *
  ****************************************************************************]]
function me:OnEvent ( Event, ... )
	if ( type( self[ Event ] ) == "function" ) then
		self[ Event ]( self, Event, ... );
	end
end
--[[****************************************************************************
  * Function: _VirtualPlates:OnUpdate                                          *
  ****************************************************************************]]
do
	local ChildCount, NewChildCount = 0;
	function me:OnUpdate ()
		-- Check for new nameplates
		NewChildCount = WorldFrame:GetNumChildren();
		if ( ChildCount ~= NewChildCount ) then
			ChildCount = NewChildCount;

			PlatesScan( WorldFrameGetChildren( WorldFrame ) );
		end

		-- Apply depth to found plates
		PlatesUpdate();
	end
end
--[[****************************************************************************
  * Function: WorldFrame:GetChildren                                           *
  * Description: Returns Visual frames in place of real nameplates.            *
  ****************************************************************************]]
do
	local select, unpack = select, unpack;
	local Children = {};
	local function ReplaceChildren ( ... )
		local Count = select( "#", ... );
		for Index = 1, Count do
			local Frame = select( Index, ... );
			Children[ Index ] = Plates[ Frame ] or Frame;
		end
		for Index = Count + 1, #Children do -- Remove any extras from the last call
			Children[ Index ] = nil;
		end
		return unpack( Children );
	end
	function WorldFrame:GetChildren ( ... )
		return ReplaceChildren( WorldFrameGetChildren( WorldFrame, ... ) );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", me.OnEvent );
	me:SetScript( "OnUpdate", me.OnUpdate );
	me:RegisterEvent( "PLAYER_LOGIN" );
	me:RegisterEvent( "PLAYER_REGEN_DISABLED" );
	me:RegisterEvent( "PLAYER_REGEN_ENABLED" );


	-- Add method overrides to be applied to plates' Visuals
	local GetParent = me.GetParent;
	local function AddPlateOverride( MethodName )
		local MethodBackup = me[ MethodName ];
		PlateOverrides[ MethodName ] = function ( self, ... )
			return MethodBackup( GetParent( self ), ... );
		end
	end
	AddPlateOverride( "GetParent" );
	AddPlateOverride( "SetAlpha" );
	AddPlateOverride( "GetAlpha" );
	AddPlateOverride( "GetEffectiveAlpha" );
end
