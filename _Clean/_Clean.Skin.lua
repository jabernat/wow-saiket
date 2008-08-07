--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.Skin.lua - Reskins textures from the default UI.                    *
  ****************************************************************************]]


local _Clean = _Clean;
local me = CreateFrame( "Frame" );
_Clean.Skin = me;

local Replacements = {
	-- Backdrops
	--[ "Interface\\DialogFrame\\UI-DialogBox-Border" ]     = "Interface\\Tooltips\\UI-Tooltip-Border";
	--[ "Interface\\DialogFrame\\UI-DialogBox-Background" ] = "Interface\\Tooltips\\UI-Tooltip-Background";

	-- Action buttons
	[ "Interface\\Buttons\\UI-Quickslot2" ]        = "Interface\\AddOns\\_Clean\\Skin\\ActionButtonNormal"; -- Filled
	--[ "Interface\\Buttons\\UI-Quickslot" ]         = "Interface\\AddOns\\_Clean\\Skin\\LiteStepFlatBase"; -- Empty
	[ "Interface\\Buttons\\ButtonHilight-Square" ] = "Interface\\AddOns\\_Clean\\Skin\\ActionButtonHighlight"; -- Highlight
	[ "Interface\\Buttons\\UI-Quickslot-Depress" ] = "Interface\\AddOns\\_Clean\\Skin\\ActionButtonPushed"; -- Pressed
	--[ "Interface\\Buttons\\CheckButtonHilight" ]   = "Interface\\AddOns\\_Clean\\Skin\\ActionButtonChecked"; -- Active spell
};
me.Replacements = Replacements;

local Hooks = {};
me.Hooks = Hooks;




--[[****************************************************************************
  * Function: _Clean.Skin:UpdateTexture                                        *
  * Description: Replaces a texture's current path.                            *
  ****************************************************************************]]
do
	local Path;
	function me:UpdateTexture ()
		if ( self ) then
			Path = self:GetTexture();
			if ( Replacements[ Path ] ) then
				self:SetTexture( Path ); -- Let SetTexture do the replacement
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.ScanRegions                                          *
  * Description: Replaces all textures in the given set of regions.            *
  ****************************************************************************]]
do
	local select = select;
	local Region;
	function me.ScanRegions ( ... )
		for Index = 1, select( "#", ... ) do
			Region = select( Index, ... );
			if ( Region:IsObjectType( "Texture" ) ) then
				me.UpdateTexture( Region );
			end
		end
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.UpdateFrame                                          *
  * Description: Replaces all textures of a frame.                             *
  ****************************************************************************]]
function me:UpdateFrame ()
	me.ScanRegions( self:GetRegions() );
end




--[[****************************************************************************
  * Function: _Clean.Skin:OnEvent                                              *
  * Description: Schedules full updates when LoadOnDemand addons load.         *
  ****************************************************************************]]
function me:OnEvent ()
	-- ADDON_LOADED
	self:Show();
end
--[[****************************************************************************
  * Function: _Clean.Skin:OnUpdate                                             *
  * Description: Handles texture update requests at most once per frame.       *
  ****************************************************************************]]
do
	local EnumerateFrames = EnumerateFrames;
	local Frame;
	function me:OnUpdate ( Elapsed )
		Frame = self.LastUpdatedFrame;
		while ( EnumerateFrames( Frame ) ) do
			Frame = EnumerateFrames( Frame );
			me.UpdateFrame( Frame );
		end
		self.LastUpdatedFrame = Frame;
		self:Hide();
	end
end




--------------------------------------------------------------------------------
-- _Clean.Skin.Hooks
--------------------

--[[****************************************************************************
  * Function: _Clean.Skin.Hooks.CreateFrame                                    *
  * Description: Hook to replace textures in templates.                        *
  ****************************************************************************]]
function Hooks.CreateFrame ( _, _, _, InheritsFrom )
	if ( InheritsFrom ) then
		me:Show();
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:CreateTexture                                  *
  * Description: Replaces textures in templated texture objects.               *
  ****************************************************************************]]
do
	local select = select;
	local function UpdateNewTexture( ... )
		me.UpdateTexture( select( select( "#", ... ), ... ) );
	end
	function Hooks:CreateTexture ( _, _, InheritsFrom )
		if ( InheritsFrom ) then -- Could have inherited texture path
			UpdateNewTexture( self:GetRegions() );
		end
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:SetBackdrop                                    *
  * Description: Replaces textures in backgrounds.                             *
  ****************************************************************************]]
function Hooks:SetBackdrop ( Backdrop )
	if ( Backdrop and next( Backdrop ) ) then
		me.ScanRegions( self:GetRegions() );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnUpdate", me.OnUpdate );
	me:SetScript( "OnEvent", me.OnEvent );
	me:RegisterEvent( "ADDON_LOADED" );


	-- Gets a method's hook, and creates a generic one if necessary.
	local function GetHook ( Method )
		if ( not Hooks[ Method ] ) then
			-- Create generic hook
			local Disabled = {};
			Hooks[ Method ] = function ( self, Path, ... )
				if ( not Disabled[ self ] ) then
					Path = Replacements[ Path ];
					if ( Path ) then
						Disabled[ self ] = true;
						self[ Method ]( self, Path, ... );
						Disabled[ self ] = nil;
					end
				end
			end;
		end
		return Hooks[ Method ];
	end

	-- Hooks all given methods for a frame/uiobject type.
	local function HookMetaIndex ( self, ... )
		local MetaIndex = getmetatable( type( self ) == "string"
			and CreateFrame( self, nil, me ) or self ).__index;

		hooksecurefunc( MetaIndex, "CreateTexture", GetHook( "CreateTexture" ) );
		hooksecurefunc( MetaIndex, "SetBackdrop", GetHook( "SetBackdrop" ) );
		for Index = 1, select( "#", ... ) do
			local Method = select( Index, ... );
			hooksecurefunc( MetaIndex, Method, GetHook( Method ) );
		end
	end


	-- Hook textures
	hooksecurefunc( getmetatable( me:CreateTexture() ).__index, "SetTexture", GetHook( "SetTexture" ) );

	-- Hook frame methods
	HookMetaIndex( me ); -- Frame
	HookMetaIndex( ActionButton1Cooldown ); -- Cooldown
	HookMetaIndex( ChatFrameEditBox ); -- EditBox
	HookMetaIndex( GameTooltip ); -- GameTooltip
	HookMetaIndex( UIErrorsFrame ); -- MessageFrame
	HookMetaIndex( MiniMapPing ); -- Model
	HookMetaIndex( WorldStateScoreScrollFrame ); -- ScrollFrame
	HookMetaIndex( GuildEventMessageFrame ); -- ScrollingMessageFrame
	HookMetaIndex( ItemTextPageText ); -- SimpleHTML
	HookMetaIndex( CharacterModelFrame ); -- PlayerModel
	HookMetaIndex( DressUpModel ); -- DressUpModel
	HookMetaIndex( TabardModel ); -- TabardModel
	HookMetaIndex( ScriptErrorsButton, -- Button
		"SetDisabledTexture", "SetHighlightTexture",
		"SetNormalTexture", "SetPushedTexture" );
	HookMetaIndex( TutorialFrameCheckButton, -- CheckButton
		"SetDisabledTexture", "SetHighlightTexture", "SetNormalTexture",
		"SetPushedTexture", "SetCheckedTexture", "SetDisabledCheckedTexture" );
	HookMetaIndex( ColorPickerFrame, -- ColorSelect
		"SetColorValueTexture", "SetColorValueThumbTexture",
		"SetColorWheelTexture", "SetColorWheelThumbTexture" );
	HookMetaIndex( Minimap, -- Minimap
		"SetBlipTexture", "SetIconTexture" );
	HookMetaIndex( OpacitySliderFrame, -- Slider
		"SetThumbTexture" );
	HookMetaIndex( CastingBarFrame, -- StatusBar
		"SetStatusBarTexture" );


	-- Hook frame creation (after we're done with HookMetaIndex)
	hooksecurefunc( "CreateFrame", Hooks.CreateFrame );
end
