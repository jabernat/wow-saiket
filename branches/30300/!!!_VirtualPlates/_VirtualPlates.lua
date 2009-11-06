--[[****************************************************************************
  * _VirtualPlates by Saiket                                                   *
  * _VirtualPlates.lua - Adds depth to the default nameplate frames.           *
  ****************************************************************************]]


local me = CreateFrame( "Frame", "_VirtualPlates" );
me.Version = GetAddOnMetadata( "!!!_VirtualPlates", "Version" ):match( "^([%d.]+)" );

local Plates = {};
me.Plates = Plates;
local PlatesVisible = {};
me.PlatesVisible = PlatesVisible;


me.OptionsCharacter = {
	Version = me.Version;
};
me.OptionsCharacterDefault = {
	Version = me.Version;
	MinScale = 0;
	MaxScale = 3;
	MaxScaleEnabled = false;
	ScaleFactor1 = 10;
	ScaleFactor2 = 30;
	ScaleFactor2Enabled = false;
};


me.CameraClip = 4; -- Yards from camera when nameplates begin fading out


local InCombat = false;
local DepthCamera = 0;

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
	local Depth, Visual, Level, Scale;
	local MinScale, MaxScale, ScaleFactor;
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
			MinScale, MaxScale = me.OptionsCharacter.MinScale, me.OptionsCharacter.MaxScaleEnabled and me.OptionsCharacter.MaxScale;
			ScaleFactor = me.OptionsCharacter.ScaleFactor1;
			if ( me.OptionsCharacter.ScaleFactor2Enabled ) then -- Adjust with camera zoom
				ScaleFactor = ScaleFactor + ( me.OptionsCharacter.ScaleFactor2 - ScaleFactor ) * DepthCamera / 50
			end

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

				Scale = ScaleFactor / Depth;
				if ( Scale < MinScale ) then
					Scale = MinScale;
				elseif ( MaxScale and Scale > MaxScale ) then
					Scale = MaxScale;
				end
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
  * Function: _VirtualPlates:LibCamera_UpdateDistance                          *
  ****************************************************************************]]
function me:LibCamera_UpdateDistance ( Event, NewDepth )
	DepthCamera = NewDepth;
end
--[[****************************************************************************
  * Function: _VirtualPlates:VARIABLES_LOADED                                  *
  ****************************************************************************]]
function me:VARIABLES_LOADED ()
	me.VARIABLES_LOADED = nil;

	-- Don't throw an error if the client doesn't have this CVar yet
	pcall( SetCVar, "nameplateAllowOverlap", 1 );


	local OptionsCharacter = _VirtualPlatesOptionsCharacter;
	_VirtualPlatesOptionsCharacter = me.OptionsCharacter;

	if ( OptionsCharacter and OptionsCharacter.Version ~= me.Version ) then -- Update settings of old versions
		local Version = OptionsCharacter.Version;
		if ( Version == "3.2.2.1" or Version == "3.2.2.2" or Version == "3.2.2.3" ) then
			Version = "3.2.2.4"; -- Added max scale option
			OptionsCharacter.MaxScale = 3;
			OptionsCharacter.MaxScaleEnabled = false;
		end
		OptionsCharacter.Version = me.Version;
	end

	me.Synchronize( OptionsCharacter ); -- Loads defaults if either are nil
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




--[[****************************************************************************
  * Function: _VirtualPlates.SetMinScale                                       *
  * Description: Sets the minimum scale plates will be shrunk to.              *
  ****************************************************************************]]
function me.SetMinScale ( Value )
	if ( Value ~= me.OptionsCharacter.MinScale ) then
		me.OptionsCharacter.MinScale = Value;

		me.Config.MinScale:SetValue( Value );
		return true;
	end
end
--[[****************************************************************************
  * Function: _VirtualPlates.SetMaxScale                                       *
  * Description: Sets the maximum scale plates will grow to.                   *
  ****************************************************************************]]
function me.SetMaxScale ( Value )
	if ( Value ~= me.OptionsCharacter.MaxScale ) then
		me.OptionsCharacter.MaxScale = Value;

		me.Config.MaxScale:SetValue( Value );
		return true;
	end
end
--[[****************************************************************************
  * Function: _VirtualPlates.SetMaxScaleEnabled                                *
  * Description: Enables clamping nameplates to a maximum scale.               *
  ****************************************************************************]]
function me.SetMaxScaleEnabled ( Enable )
	if ( Enable ~= me.OptionsCharacter.MaxScaleEnabled ) then
		me.OptionsCharacter.MaxScaleEnabled = Enable;

		me.Config.MaxScaleEnabled:SetChecked( Enable );
		me.Config.MaxScaleEnabled.setFunc( Enable and "1" or "0" );
		return true;
	end
end
--[[****************************************************************************
  * Function: _VirtualPlates.SetScaleFactor1                                   *
  * Description: Sets the normal scale factor.                                 *
  ****************************************************************************]]
function me.SetScaleFactor1 ( Value )
	if ( Value ~= me.OptionsCharacter.ScaleFactor1 ) then
		me.OptionsCharacter.ScaleFactor1 = Value;

		me.Config.ScaleFactor1:SetValue( Value );
		return true;
	end
end
--[[****************************************************************************
  * Function: _VirtualPlates.SetScaleFactor2                                   *
  * Description: Sets the scale factor used at max camera zoom.                *
  ****************************************************************************]]
function me.SetScaleFactor2 ( Value )
	if ( Value ~= me.OptionsCharacter.ScaleFactor2 ) then
		me.OptionsCharacter.ScaleFactor2 = Value;

		me.Config.ScaleFactor2:SetValue( Value );
		return true;
	end
end
--[[****************************************************************************
  * Function: _VirtualPlates.SetScaleFactor2Enabled                            *
  * Description: Enables increasing scale factor based on camera zoom.         *
  ****************************************************************************]]
function me.SetScaleFactor2Enabled ( Enable )
	if ( Enable ~= me.OptionsCharacter.ScaleFactor2Enabled ) then
		me.OptionsCharacter.ScaleFactor2Enabled = Enable;

		me.Config.ScaleFactor2Enabled:SetChecked( Enable );
		me.Config.ScaleFactor2Enabled.setFunc( Enable and "1" or "0" );

		LibStub( "LibCamera-1.0" )[ Enable and "RegisterCallback" or "UnregisterCallback" ]( me, "LibCamera_UpdateDistance" );
		return true;
	end
end


--[[****************************************************************************
  * Function: _VirtualPlates.Synchronize                                       *
  * Description: Synchronizes addon settings with an options table.            *
  ****************************************************************************]]
function me.Synchronize ( OptionsCharacter )
	-- Load defaults if settings omitted
	if ( not OptionsCharacter ) then
		OptionsCharacter = me.OptionsCharacterDefault;
	end

	me.SetMinScale( OptionsCharacter.MinScale );
	me.SetMaxScale( OptionsCharacter.MaxScale );
	me.SetMaxScaleEnabled( OptionsCharacter.MaxScaleEnabled );
	me.SetScaleFactor1( OptionsCharacter.ScaleFactor1 );
	me.SetScaleFactor2( OptionsCharacter.ScaleFactor2 );
	me.SetScaleFactor2Enabled( OptionsCharacter.ScaleFactor2Enabled );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", me.OnEvent );
	me:SetScript( "OnUpdate", me.OnUpdate );
	me:RegisterEvent( "VARIABLES_LOADED" );
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
