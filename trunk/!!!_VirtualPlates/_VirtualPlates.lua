--[[****************************************************************************
  * _VirtualPlates by Saiket                                                   *
  * _VirtualPlates.lua - Adds depth to the default nameplate frames.           *
  ****************************************************************************]]


local AddOnName = ...;
local me = CreateFrame( "Frame", "_VirtualPlates", WorldFrame );
me.Version = GetAddOnMetadata( AddOnName, "Version" ):match( "^([%d.]+)" );

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
	ScaleFactor = 10;
};


me.CameraClip = 4; -- Yards from camera when nameplates begin fading out
me.PlateLevels = 3; -- Frame level difference between plates so one plate's children don't overlap the next closest plate


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
	local function ReparentChildren ( Plate, ... ) -- Also saves a list of all original regions into the plate frame
		local Visual = Plates[ Plate ];
		for Index = 1, select( "#", ... ) do
			local Child = select( Index, ... );
			if ( Child ~= Visual ) then
				local LevelOffset = Child:GetFrameLevel() - Plate:GetFrameLevel();
				Child:SetParent( Visual );
				Child:SetFrameLevel( Visual:GetFrameLevel() + LevelOffset ); -- Maintain relative frame levels
				Plate[ #Plate + 1 ] = Child;
			end
		end
	end
	local function ReparentRegions ( Plate, ... )
		local Visual = Plates[ Plate ];
		for Index = 1, select( "#", ... ) do
			local Region = select( Index, ... );
			Region:SetParent( Visual );
			Plate[ #Plate + 1 ] = Region;
		end
	end

	function PlateAdd ( Plate )
		local Visual = CreateFrame( "Frame", nil, Plate );
		Plates[ Plate ] = Visual;

		Visual:SetPoint( "TOP" );
		Visual:SetSize( Plate:GetSize() );

		ReparentChildren( Plate, Plate:GetChildren() );
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

		-- Force recalculation of effective depth for all child frames
		local Depth = WorldFrame:GetDepth();
		WorldFrame:SetDepth( Depth + 1 );
		WorldFrame:SetDepth( Depth );
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
	local Depth, Visual, Scale;
	local MinScale, MaxScale, ScaleFactor;
	function PlatesUpdate ()
		for Plate, Visual in pairs( PlatesVisible ) do
			Depth = Visual:GetEffectiveDepth(); -- Note: Depth of the actual plate is blacklisted, so use child Visual instead
			if ( Depth <= 0 ) then -- Too close to camera; Completely hidden
				SetAlpha( Visual, 0 );
			else
				SortOrder[ #SortOrder + 1 ] = Plate;
				Depths[ Plate ] = Depth;
			end
		end


		if ( #SortOrder > 0 ) then
			MinScale, MaxScale = me.OptionsCharacter.MinScale, me.OptionsCharacter.MaxScaleEnabled and me.OptionsCharacter.MaxScale;
			ScaleFactor = me.OptionsCharacter.ScaleFactor;

			sort( SortOrder, SortFunc );
			for Index, Plate in ipairs( SortOrder ) do
				Depth, Visual = Depths[ Plate ], Plates[ Plate ];

				if ( Depth < me.CameraClip ) then -- Begin fading as nameplate passes behind screen
					SetAlpha( Visual, Depth / me.CameraClip );
				else
					SetAlpha( Visual, 1 );
				end

				Visual:SetFrameLevel( Index * me.PlateLevels );

				Scale = ScaleFactor / Depth;
				if ( Scale < MinScale ) then
					Scale = MinScale;
				elseif ( MaxScale and Scale > MaxScale ) then
					Scale = MaxScale;
				end
				Visual:SetScale( Scale );
				if ( not InCombat ) then
					Plate:SetSize( Visual:GetWidth() * Scale, Visual:GetHeight() * Scale );
				end
			end
			wipe( SortOrder );
		end
	end
end




--[[****************************************************************************
  * Function: _VirtualPlates:ADDON_LOADED                                      *
  ****************************************************************************]]
function me:ADDON_LOADED ( Event, AddOn )
	if ( AddOn == AddOnName ) then
		me:UnregisterEvent( Event );
		me[ Event ] = nil;

		local OptionsCharacter = _VirtualPlatesOptionsCharacter;
		_VirtualPlatesOptionsCharacter = me.OptionsCharacter;

		if ( OptionsCharacter and OptionsCharacter.Version ~= me.Version ) then -- Update settings of old versions
			local Version = OptionsCharacter.Version;
			if ( Version == "3.2.2.1" or Version == "3.2.2.2" or Version == "3.2.2.3" ) then
				Version = "3.2.2.4"; -- Added max scale option
				OptionsCharacter.MaxScale = 3;
				OptionsCharacter.MaxScaleEnabled = false;
			end
			if ( Version == "3.2.2.4" or Version == "3.2.2.5" or Version == "3.3.0.1" ) then
				Version = "3.3.5.1"; -- Removed support for LibCamera-1.0 and variable ScaleFactors
				OptionsCharacter.ScaleFactor = OptionsCharacter.ScaleFactor1;
			end
			OptionsCharacter.Version = me.Version;
		end

		me.Synchronize( OptionsCharacter ); -- Loads defaults if either are nil
	end
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
		Plate:SetSize( Visual:GetSize() );
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
  * Function: _VirtualPlates.SetScaleFactor                                    *
  * Description: Sets the normal scale factor.                                 *
  ****************************************************************************]]
function me.SetScaleFactor ( Value )
	if ( Value ~= me.OptionsCharacter.ScaleFactor ) then
		me.OptionsCharacter.ScaleFactor = Value;

		me.Config.ScaleFactor:SetValue( Value );
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
	me.SetScaleFactor( OptionsCharacter.ScaleFactor );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", me.OnEvent );
	WorldFrame:HookScript( "OnUpdate", me.OnUpdate ); -- First OnUpdate handler to run
	me:RegisterEvent( "ADDON_LOADED" );
	me:RegisterEvent( "PLAYER_REGEN_DISABLED" );
	me:RegisterEvent( "PLAYER_REGEN_ENABLED" );


	-- Add method overrides to be applied to plates' Visuals
	local GetParent = me.GetParent;
	do
		local function AddPlateOverride( MethodName )
			PlateOverrides[ MethodName ] = function ( self, ... )
				self = GetParent( self );
				return self[ MethodName ]( self, ... );
			end
		end
		AddPlateOverride( "GetParent" );
		AddPlateOverride( "SetAlpha" );
		AddPlateOverride( "GetAlpha" );
		AddPlateOverride( "GetEffectiveAlpha" );
	end
	-- Method overrides to use plates' OnUpdate script handlers instead of their Visuals' to preserve handler execution order
	do
		local type = type;
		do
			local function OnUpdateOverride ( self, ... ) -- Wrapper to replace self parameter with plate's Visual
				self.OnUpdate( Plates[ self ], ... );
			end
			local SetScript = me.SetScript;
			function PlateOverrides:SetScript ( Script, Handler, ... )
				if ( type( Script ) == "string" and Script:lower() == "onupdate" ) then
					self = GetParent( self );
					self.OnUpdate = Handler;
					return self:SetScript( Script, Handler and OnUpdateOverride or nil, ... );
				else
					return SetScript( self, Script, Handler, ... );
				end
			end
		end
		do
			local GetScript = me.GetScript;
			function PlateOverrides:GetScript ( Script, ... )
				if ( type( Script ) == "string" and Script:lower() == "onupdate" ) then
					return GetParent( self ).OnUpdate;
				else
					return GetScript( self, Script, ... );
				end
			end
		end
		do
			local function VarArg ( self, ... ) -- Saves a reference to the hooked script
				self.OnUpdate = self:GetScript( "OnUpdate" );
				return ...;
			end
			local HookScript = me.HookScript;
			function PlateOverrides:HookScript ( Script, Handler, ... )
				if ( type( Script ) == "string" and Script:lower() == "onupdate" ) then
					self = GetParent( self );
					return VarArg( self, self:HookScript( Script, function ( self, ... ) -- Wrapper to replace self parameter with plate's Visual
						Handler( Plates[ self ], ... );
					end, ... ) );
				else
					return HookScript( self, Script, Handler, ... );
				end
			end
		end
	end
end
