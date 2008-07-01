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

local BackdropTable = {};
me.BackdropTable = BackdropTable;

local Hooks = {};
me.Hooks = Hooks;

me.LastUpdatedFrame = nil;
me.UpdateNewFrames = false;


-- Commonly used functions
local select = select;
local type = type;




--[[****************************************************************************
  * Function: _Clean.Skin.HookMetaIndex                                        *
  * Description: Gets the metatable index of a given frame or frame type, and  *
  *   hooks its base Frame object methods along with any additional methods.   *
  ****************************************************************************]]
function me:HookMetaIndex ( ... )
	local MetaIndex = getmetatable( type( self ) == "string"
		and CreateFrame( self ) or self ).__index;

	hooksecurefunc( MetaIndex, "CreateTexture", Hooks.CreateTexture );
	hooksecurefunc( MetaIndex, "SetBackdrop", Hooks.SetBackdrop );
	local Method;
	for Index = 1, select( "#", ... ) do
		Method = select( Index, ... );
		hooksecurefunc( MetaIndex, Method, Hooks[ Method ] );
	end
end

--[[****************************************************************************
  * Function: _Clean.Skin:UpdateTexture                                        *
  * Description: Replaces a texture's current path.                            *
  ****************************************************************************]]
function me:UpdateTexture ()
	if ( self ) then
		local Path = self:GetTexture();
		if ( Replacements[ Path ] ) then
			self:SetTexture( Path );
		end
	end
end
local UpdateTexture = me.UpdateTexture;
--[[****************************************************************************
  * Function: _Clean.Skin.ScanRegions                                          *
  * Description: Replaces all textures in the given set of regions.            *
  ****************************************************************************]]
function me.ScanRegions ( ... )
	for Index = 1, select( "#", ... ) do
		local Region = select( Index, ... );
		if ( Region:IsObjectType( "Texture" ) ) then
			UpdateTexture( Region );
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
  * Function: _Clean.Skin.Hooks.CreateFrameHook                                *
  * Description: Hook to replace textures in templates.                        *
  ****************************************************************************]]
function Hooks.CreateFrame ()
	me.UpdateNewFrames = true;
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:CreateTexture                                  *
  * Description: Replaces textures in templated texture objects.               *
  ****************************************************************************]]
function Hooks:CreateTexture ( Name, _, InheritsFrom )
	if ( InheritsFrom ) then
		if ( Name ) then
			UpdateTexture( _G[ Name ] ); -- May miss textures with duplicate names
		else
			me.ScanRegions( self:GetRegions() );
		end
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:SetTexture                                     *
  * Description: Replaces recognized textures.                                 *
  ****************************************************************************]]
function Hooks:SetTexture ( Path, ... )
	if ( not Hooks.DisableSetTexture and type( Path ) == "string" ) then
		local Replacement = Replacements[ Path ];
		if ( Replacement ) then
			Hooks.DisableSetTexture = true;
			self:SetTexture( Replacement );
			Hooks.DisableSetTexture = nil;
		end
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:SetBackdrop                                    *
  * Description: Replaces textures in backgrounds.                             *
  ****************************************************************************]]
function Hooks:SetBackdrop ( Backdrop )
	if ( Backdrop ) then
		me.ScanRegions( self:GetRegions() );
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:SetDisabledTexture                             *
  ****************************************************************************]]
function Hooks:SetDisabledTexture ( Texture )
	if ( not Hooks.DisableSetDisabledTexture and Replacements[ Texture ] ) then
		Hooks.DisableSetDisabledTexture = true;
		self:SetDisabledTexture( Replacements[ Texture ] );
		Hooks.DisableSetDisabledTexture = nil;
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:SetHighlightTexture                            *
  ****************************************************************************]]
function Hooks:SetHighlightTexture ( Texture )
	if ( not Hooks.DisableSetHighlightTexture and Replacements[ Texture ] ) then
		Hooks.DisableSetHighlightTexture = true;
		self:SetHighlightTexture( Replacements[ Texture ] );
		Hooks.DisableSetHighlightTexture = nil;
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:SetNormalTexture                               *
  ****************************************************************************]]
function Hooks:SetNormalTexture ( Texture )
	if ( not Hooks.DisableSetNormalTexture and Replacements[ Texture ] ) then
		Hooks.DisableSetNormalTexture = true;
		self:SetNormalTexture( Replacements[ Texture ] );
		Hooks.DisableSetNormalTexture = nil;
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:SetPushedTexture                               *
  ****************************************************************************]]
function Hooks:SetPushedTexture ( Texture )
	if ( not Hooks.DisableSetPushedTexture and Replacements[ Texture ] ) then
		Hooks.DisableSetPushedTexture = true;
		self:SetPushedTexture( Replacements[ Texture ] );
		Hooks.DisableSetPushedTexture = nil;
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:SetColorValueTexture                           *
  ****************************************************************************]]
function Hooks:SetColorValueTexture ( Texture )
	if ( not Hooks.DisableSetColorValueTexture and Replacements[ Texture ] ) then
		Hooks.DisableSetColorValueTexture = true;
		self:SetColorValueTexture( Replacements[ Texture ] );
		Hooks.DisableSetColorValueTexture = nil;
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:SetColorValueThumbTexture                      *
  ****************************************************************************]]
function Hooks:SetColorValueThumbTexture ( Texture )
	if ( not Hooks.DisableSetColorValueThumbTexture and Replacements[ Texture ] ) then
		Hooks.DisableSetColorValueThumbTexture = true;
		self:SetColorValueThumbTexture( Replacements[ Texture ] );
		Hooks.DisableSetColorValueThumbTexture = nil;
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:SetColorWheelTexture                           *
  ****************************************************************************]]
function Hooks:SetColorWheelTexture ( Texture )
	if ( not Hooks.DisableSetColorWheelTexture and Replacements[ Texture ] ) then
		Hooks.DisableSetColorWheelTexture = true;
		self:SetColorWheelTexture( Replacements[ Texture ] );
		Hooks.DisableSetColorWheelTexture = nil;
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:SetColorWheelThumbTexture                      *
  ****************************************************************************]]
function Hooks:SetColorWheelThumbTexture ( Texture )
	if ( not Hooks.DisableSetColorWheelThumbTexture and Replacements[ Texture ] ) then
		Hooks.DisableSetColorWheelThumbTexture = true;
		self:SetColorWheelThumbTexture( Replacements[ Texture ] );
		Hooks.DisableSetColorWheelThumbTexture = nil;
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:SetBlipTexture                                 *
  ****************************************************************************]]
function Hooks:SetBlipTexture ( Texture )
	if ( not Hooks.DisableSetBlipTexture and Replacements[ Texture ] ) then
		Hooks.DisableSetBlipTexture = true;
		self:SetBlipTexture( Replacements[ Texture ] );
		Hooks.DisableSetBlipTexture = nil;
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:SetIconTexture                                 *
  ****************************************************************************]]
function Hooks:SetIconTexture ( Texture )
	if ( not Hooks.DisableSetIconTexture and Replacements[ Texture ] ) then
		Hooks.DisableSetIconTexture = true;
		self:SetIconTexture( Replacements[ Texture ] );
		Hooks.DisableSetIconTexture = nil;
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:SetThumbTexture                                *
  ****************************************************************************]]
function Hooks:SetThumbTexture ( Texture )
	if ( not Hooks.DisableSetThumbTexture and Replacements[ Texture ] ) then
		Hooks.DisableSetThumbTexture = true;
		self:SetThumbTexture( Replacements[ Texture ] );
		Hooks.DisableSetThumbTexture = nil;
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:SetStatusBarTexture                            *
  ****************************************************************************]]
function Hooks:SetStatusBarTexture ( Texture, Layer )
	if ( not Hooks.DisableSetStatusBarTexture and Replacements[ Texture ] ) then
		Hooks.DisableSetStatusBarTexture = true;
		self:SetStatusBarTexture( Replacements[ Texture ], Layer );
		Hooks.DisableSetStatusBarTexture = nil;
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:SetCheckedTexture                              *
  ****************************************************************************]]
function Hooks:SetCheckedTexture ( Texture )
	if ( not Hooks.DisableSetCheckedTexture and Replacements[ Texture ] ) then
		Hooks.DisableSetCheckedTexture = true;
		self:SetCheckedTexture( Replacements[ Texture ] );
		Hooks.DisableSetCheckedTexture = nil;
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin.Hooks:SetDisabledCheckedTexture                      *
  ****************************************************************************]]
function Hooks:SetDisabledCheckedTexture ( Texture )
	if ( not Hooks.DisableSetDisabledCheckedTexture and Replacements[ Texture ] ) then
		Hooks.DisableSetDisabledCheckedTexture = true;
		self:SetDisabledCheckedTexture( Replacements[ Texture ] );
		Hooks.DisableSetDisabledCheckedTexture = nil;
	end
end




--[[****************************************************************************
  * Function: _Clean.Skin:ADDON_LOADED                                         *
  ****************************************************************************]]
function me:ADDON_LOADED ()
	self.UpdateNewFrames = true;
end
--[[****************************************************************************
  * Function: _Clean.Skin:VARIABLES_LOADED                                     *
  ****************************************************************************]]
function me:VARIABLES_LOADED ()
	self.UpdateNewFrames = true; -- Schedule update on first screen draw
	self:RegisterEvent( "ADDON_LOADED" );
end

--[[****************************************************************************
  * Function: _Clean.Skin:OnEvent                                              *
  * Description: Schedules full updates when LoadOnDemand addons load.         *
  ****************************************************************************]]
function me:OnEvent ( Event, ... )
	if ( type( self[ Event ] ) == "function" ) then
		self[ Event ]( self, Event, ... );
	end
end
--[[****************************************************************************
  * Function: _Clean.Skin:OnUpdate                                             *
  * Description: Handles texture update requests at most once per frame.       *
  ****************************************************************************]]
function me:OnUpdate ( Elapsed )
	if ( self.UpdateNewFrames ) then
		self.UpdateNewFrames = false;

		local Frame = self.LastUpdatedFrame;
		while ( EnumerateFrames( Frame ) ) do
			Frame = EnumerateFrames( Frame );
			me.UpdateFrame( Frame );
		end
		self.LastUpdatedFrame = Frame;
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnUpdate", me.OnUpdate );
	me:SetScript( "OnEvent", me.OnEvent );
	me:RegisterEvent( "VARIABLES_LOADED" );

	-- Hook textures
	hooksecurefunc( getmetatable( me:CreateTexture() ).__index, "SetTexture", Hooks.SetTexture );


	-- Hook frame methods
	me.HookMetaIndex( me ); -- Frame
	me.HookMetaIndex( "Cooldown" );
	me.HookMetaIndex( ChatFrameEditBox ); -- EditBox
	me.HookMetaIndex( GameTooltip ); -- GameTooltip
	me.HookMetaIndex( UIErrorsFrame ); -- MessageFrame
	me.HookMetaIndex( MiniMapPing ); -- Model
	me.HookMetaIndex( WorldStateScoreScrollFrame ); -- ScrollFrame
	me.HookMetaIndex( GuildEventMessageFrame ); -- ScrollingMessageFrame
	me.HookMetaIndex( ItemTextPageText ); -- SimpleHTML
	me.HookMetaIndex( CharacterModelFrame ); -- PlayerModel
	me.HookMetaIndex( DressUpModel ); -- DressUpModel
	me.HookMetaIndex( TabardModel ); -- TabardModel
	me.HookMetaIndex( "Button",
		"SetDisabledTexture", "SetHighlightTexture",
		"SetNormalTexture", "SetPushedTexture" );
	me.HookMetaIndex( TutorialFrameCheckButton, -- CheckButton
		"SetDisabledTexture", "SetHighlightTexture", "SetNormalTexture",
		"SetPushedTexture", "SetCheckedTexture", "SetDisabledCheckedTexture" );
	me.HookMetaIndex( ColorPickerFrame, -- ColorSelect
		"SetColorValueTexture", "SetColorValueThumbTexture",
		"SetColorWheelTexture", "SetColorWheelThumbTexture" );
	me.HookMetaIndex( Minimap, -- Minimap
		"SetBlipTexture", "SetIconTexture" );
	me.HookMetaIndex( OpacitySliderFrame, -- Slider
		"SetThumbTexture" );
	me.HookMetaIndex( CastingBarFrame, -- StatusBar
		"SetStatusBarTexture" );


	-- Hook frame creation
	hooksecurefunc( "CreateFrame", Hooks.CreateFrame );
end
