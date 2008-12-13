--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.Skin.lua - Reskins textures from the default UI.                    *
  ****************************************************************************]]


do --NOTE(Comment out file.)
	return;
end
message( "WARNING! Skin module active!" );

local _Clean = _Clean;
local me = CreateFrame( "Frame" );
_Clean.Skin = me;

local Replacements = {
	-- Action buttons
	[ "interface\\buttons\\ui-quickslot2" ]        = "Interface\\AddOns\\_Clean\\Skin\\ActionButtonNormal"; -- Filled
	[ "interface\\buttons\\buttonhilight-square" ] = "Interface\\AddOns\\_Clean\\Skin\\ActionButtonHighlight"; -- Highlight
	[ "interface\\buttons\\ui-quickslot-depress" ] = "Interface\\AddOns\\_Clean\\Skin\\ActionButtonPushed"; -- Pressed


	--[[ Red button template
	[ "interface\\buttons\\ui-panel-button-up" ] = "Interface\\GLUES\\COMMON\\Glue-Panel-Button-Up-Blue";
	[ "interface\\buttons\\ui-dialogbox-button-up" ] = "Interface\\GLUES\\COMMON\\Glue-Panel-Button-Up-Blue";
	]]

	[ "interface\\glues\\common\\glue-panel-button-up" ] = "interface\\glues\\common\\glue-panel-button-up-blue";
	[ "interface\\glues\\common\\glue-panel-button-down" ] = "interface\\glues\\common\\glue-panel-button-down-blue";
	[ "interface\\glues\\common\\glue-panel-button-highlight" ] = "interface\\glues\\common\\glue-panel-button-highlight-blue";

	[ "interface\\buttons\\ui-panel-button-up" ] = "Interface\\AddOns\\_Clean\\Skin\\UI-Panel-Button-Up";
	[ "interface\\buttons\\ui-panel-button-down" ] = "Interface\\AddOns\\_Clean\\Skin\\UI-Panel-Button-Down";
	[ "interface\\buttons\\ui-panel-button-highlight" ] = "Interface\\AddOns\\_Clean\\Skin\\UI-Panel-Button-Highlight";


	-- Make yellow highlights blue
	[ "interface\\friendsframe\\ui-friendsframe-highlightbar" ] = "interface\\questframe\\ui-questlogtitlehighlight";
	[ "interface\\questframe\\ui-questtitlehighlight" ] = "interface\\questframe\\ui-questlogtitlehighlight";
	[ "interface\\buttons\\ui-listbox-highlight" ] = "interface\\buttons\\ui-listbox-highlight2";
};
me.Replacements = Replacements;

local Shades;
do
	local Foreground = _Clean.Colors.Foreground;
	local Background = _Clean.Colors.Dark;
	local WatchBarBubbles = { r = Background.r; g = Background.g; b = Background.b; a = 0.4; };
	Shades = {
		-- Make yellow highlights blue
		[ "interface\\friendsframe\\ui-friendsframe-highlightbar" ] = _Clean.Colors.Highlight;
		[ "interface\\questframe\\ui-questtitlehighlight" ] = _Clean.Colors.Highlight;
		[ "interface\\buttons\\ui-listbox-highlight2" ] = _Clean.Colors.Highlight;

		[ "interface\\achievementframe\\ui-achievement-alert-background" ] = Foreground;
		[ "interface\\achievementframe\\ui-achievement-header" ] = Background;
		[ "interface\\achievementframe\\ui-achievement-metalborder-joint" ] = Background;
		[ "interface\\achievementframe\\ui-achievement-metalborder-left" ] = Background;
		[ "interface\\achievementframe\\ui-achievement-metalborder-top" ] = Background;
		[ "interface\\achievementframe\\ui-achievement-tsunami-corners" ] = Foreground;
		[ "interface\\achievementframe\\ui-achievement-tsunami-horizontal" ] = Foreground;
		[ "interface\\achievementframe\\ui-achievement-woodborder-corner" ] = Background;
		[ "interface\\achievementframe\\ui-achievement-woodborder" ] = Background;
		[ "interface\\auctionframe\\auctionhousedressupframe-bottom" ] = Background;
		[ "interface\\auctionframe\\auctionhousedressupframe-corner" ] = Background;
		[ "interface\\auctionframe\\auctionhousedressupframe-top" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-auction-bot" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-auction-botleft" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-auction-botright" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-auction-top" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-auction-topleft" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-auction-topright" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-bid-bot" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-bid-botleft" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-bid-botright" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-bid-top" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-bid-topleft" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-bid-topright" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-browse-bot" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-browse-botleft" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-browse-botright" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-browse-top" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-browse-topleft" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-browse-topright" ] = Background;
		[ "interface\\auctionframe\\ui-auctionframe-filterbg" ] = Foreground;
		[ "interface\\auctionframe\\ui-auctionframe-filterlines" ] = Foreground;
		[ "interface\\bankframe\\ui-bankframe" ] = Background;
		[ "interface\\battlefieldframe\\ui-battlefield-bar" ] = Background;
		[ "interface\\battlefieldframe\\ui-battlefield-botleft" ] = Background;
		[ "interface\\battlefieldframe\\ui-battlefield-botright" ] = Background;
		[ "interface\\battlefieldframe\\ui-battlefield-topleft" ] = Background;
		[ "interface\\battlefieldframe\\ui-battlefield-topright" ] = Background;
		[ "interface\\battlefieldframe\\ui-battlefieldminimap-border" ] = Foreground;
		[ "interface\\buttons\\ui-button-borders" ] = Background;
		[ "interface\\calendar\\buttonframe" ] = Background;
		[ "interface\\calendar\\calendarframe_sides" ] = Background;
		[ "interface\\calendar\\calendarframe_topandbottom" ] = Background;
		[ "interface\\characterframe\\ui-characterframe-groupindicator" ] = Foreground;
		[ "interface\\characterframe\\ui-party-border" ] = Foreground;
		[ "interface\\chatframe\\chatframeborder" ] = Foreground;
		[ "interface\\chatframe\\chatframetab" ] = Foreground;
		[ "interface\\chatframe\\ui-chatinputborder-left" ] = Background;
		[ "interface\\chatframe\\ui-chatinputborder-right" ] = Background;
		[ "interface\\classtrainerframe\\ui-classtrainer-botleft" ] = Background;
		[ "interface\\classtrainerframe\\ui-classtrainer-botright" ] = Background;
		[ "interface\\classtrainerframe\\ui-classtrainer-horizontalbar" ] = Background;
		[ "interface\\classtrainerframe\\ui-classtrainer-scrollbar" ] = Background;
		[ "interface\\classtrainerframe\\ui-classtrainer-topleft" ] = Background;
		[ "interface\\classtrainerframe\\ui-classtrainer-topright" ] = Background;
		[ "interface\\containerframe\\ui-backpack-tokenframe" ] = Background;
		[ "interface\\containerframe\\ui-backpackbackground" ] = Background;
		[ "interface\\containerframe\\ui-bag-1slot" ] = Background;
		[ "interface\\containerframe\\ui-bag-components-bank" ] = Background;
		[ "interface\\containerframe\\ui-bag-components-keyring" ] = Background;
		[ "interface\\containerframe\\ui-bag-components" ] = Background;
		[ "interface\\dialogframe\\ui-dialogbox-background" ] = Background;
		[ "interface\\dialogframe\\ui-dialogbox-border" ] = Background;
		[ "interface\\dialogframe\\ui-dialogbox-corner" ] = Background;
		[ "interface\\dialogframe\\ui-dialogbox-divider" ] = Background;
		[ "interface\\dialogframe\\ui-dialogbox-header" ] = Background;
		[ "interface\\friendsframe\\guildframe-botleft" ] = Background;
		[ "interface\\friendsframe\\guildframe-botright" ] = Background;
		[ "interface\\friendsframe\\ignoreframe-botleft" ] = Background;
		[ "interface\\friendsframe\\ignoreframe-botright" ] = Background;
		[ "interface\\friendsframe\\ui-channelframe-botleft" ] = Background;
		[ "interface\\friendsframe\\ui-channelframe-botright" ] = Background;
		[ "interface\\friendsframe\\ui-channelframe-titlebar" ] = Foreground;
		[ "interface\\friendsframe\\ui-channelframe-verticalbar" ] = Background;
		[ "interface\\friendsframe\\ui-friendsframe-botleft" ] = Background;
		[ "interface\\friendsframe\\ui-friendsframe-botright" ] = Background;
		[ "interface\\friendsframe\\ui-friendsframe-buttonspatch" ] = Background;
		[ "interface\\friendsframe\\ui-friendsframe-topleft" ] = Background;
		[ "interface\\friendsframe\\ui-friendsframe-topright" ] = Background;
		[ "interface\\friendsframe\\ui-guildmember-patch" ] = Background;
		[ "interface\\friendsframe\\ui-ignoreframe-botleft" ] = Background;
		[ "interface\\friendsframe\\ui-ignoreframe-botright" ] = Background;
		[ "interface\\friendsframe\\whoframe-botleft" ] = Background;
		[ "interface\\friendsframe\\whoframe-botright" ] = Background;
		[ "interface\\friendsframe\\whoframe-columntabs" ] = Foreground;
		[ "interface\\groupframe\\ui-group-portrait" ] = Background;
		[ "interface\\guildbankframe\\ui-guildbankframe-emblemborder" ] = Foreground;
		[ "interface\\guildbankframe\\ui-guildbankframe-left" ] = Background;
		[ "interface\\guildbankframe\\ui-guildbankframe-right" ] = Background;
		[ "interface\\guildbankframe\\ui-guildbankframe-tab" ] = Background;
		[ "interface\\guildbankframe\\ui-guildframe-permissiontab" ] = Background;
		[ "interface\\helpframe\\helpframe-botleft" ] = Background;
		[ "interface\\helpframe\\helpframe-botright" ] = Background;
		[ "interface\\helpframe\\helpframe-bottom" ] = Background;
		[ "interface\\helpframe\\helpframe-top" ] = Background;
		[ "interface\\helpframe\\helpframe-topleft" ] = Background;
		[ "interface\\helpframe\\helpframe-topright" ] = Background;
		[ "interface\\helpframe\\helpframedivider" ] = Background;
		[ "interface\\helpframe\\helpframetab-active" ] = Background;
		[ "interface\\helpframe\\helpframetab-inactive" ] = Foreground;
		[ "interface\\itemsocketingframe\\ui-itemsocketingframe-scrollbar" ] = Background;
		[ "interface\\itemsocketingframe\\ui-itemsocketingframe" ] = Background;
		[ "interface\\itemtextframe\\ui-itemtext-botleft" ] = Background;
		[ "interface\\itemtextframe\\ui-itemtext-topleft" ] = Background;
		[ "interface\\keybindingframe\\ui-keybindingframe-bot" ] = Background;
		[ "interface\\keybindingframe\\ui-keybindingframe-botleft" ] = Background;
		[ "interface\\keybindingframe\\ui-keybindingframe-botright" ] = Background;
		[ "interface\\keybindingframe\\ui-keybindingframe-top" ] = Background;
		[ "interface\\keybindingframe\\ui-keybindingframe-topleft" ] = Background;
		[ "interface\\keybindingframe\\ui-keybindingframe-topright" ] = Background;
		[ "interface\\lfgframe\\lfgframe" ] = Background;
		[ "interface\\lfgframe\\lfgparentframe" ] = Background;
		[ "interface\\lfgframe\\lfmframe" ] = Background;
		[ "interface\\lootframe\\ui-lootpanel" ] = Background;
		[ "interface\\macroframe\\macroframe-botleft" ] = Background;
		[ "interface\\macroframe\\macroframe-botright" ] = Background;
		[ "interface\\macroframe\\macropopup-botleft" ] = Background;
		[ "interface\\macroframe\\macropopup-botright" ] = Background;
		[ "interface\\macroframe\\macropopup-topleft" ] = Background;
		[ "interface\\macroframe\\macropopup-topright" ] = Background;
		[ "interface\\mailframe\\mailpopup-bottom" ] = Background;
		[ "interface\\mailframe\\mailpopup-top" ] = Background;
		[ "interface\\mailframe\\ui-openmail-botleft" ] = Background;
		[ "interface\\mainmenubar\\ui-mainmenubar-dwarf" ] = WatchBarBubbles; -- Alternate reputation watch bar texture
		[ "interface\\merchantframe\\ui-buyback-botleft" ] = Background;
		[ "interface\\merchantframe\\ui-buyback-botright" ] = Background;
		[ "interface\\merchantframe\\ui-buyback-topleft" ] = Background;
		[ "interface\\merchantframe\\ui-buyback-topright" ] = Background;
		[ "interface\\merchantframe\\ui-merchant-botleft" ] = Background;
		[ "interface\\merchantframe\\ui-merchant-botright" ] = Background;
		[ "interface\\merchantframe\\ui-merchant-bottomborder" ] = Background;
		[ "interface\\merchantframe\\ui-merchant-topleft" ] = Background;
		[ "interface\\merchantframe\\ui-merchant-topright" ] = Background;
		[ "interface\\minimap\\minimap-trackingborder" ] = Background;
		[ "interface\\minimap\\ui-minimap-border" ] = Background;
		[ "interface\\moneyframe\\ui-moneyframe" ] = Background;
		[ "interface\\paperdollinfoframe\\skillframe-botleft" ] = Background;
		[ "interface\\paperdollinfoframe\\skillframe-botright" ] = Background;
		[ "interface\\paperdollinfoframe\\ui-character-activetab" ] = Background;
		[ "interface\\paperdollinfoframe\\ui-character-charactertab-bottomleft" ] = Background;
		[ "interface\\paperdollinfoframe\\ui-character-charactertab-bottomright" ] = Background;
		[ "interface\\paperdollinfoframe\\ui-character-charactertab-l1" ] = Background;
		[ "interface\\paperdollinfoframe\\ui-character-charactertab-l2" ] = Background;
		[ "interface\\paperdollinfoframe\\ui-character-charactertab-r1" ] = Background;
		[ "interface\\paperdollinfoframe\\ui-character-charactertab-r2" ] = Background;
		[ "interface\\paperdollinfoframe\\ui-character-general-bottomleft" ] = Background;
		[ "interface\\paperdollinfoframe\\ui-character-general-bottomright" ] = Background;
		[ "interface\\paperdollinfoframe\\ui-character-general-topleft" ] = Background;
		[ "interface\\paperdollinfoframe\\ui-character-general-topright" ] = Background;
		[ "interface\\paperdollinfoframe\\ui-character-honor-bottomleft" ] = Background;
		[ "interface\\paperdollinfoframe\\ui-character-honor-bottomright" ] = Background;
		[ "interface\\paperdollinfoframe\\ui-character-honor-topleft" ] = Background;
		[ "interface\\paperdollinfoframe\\ui-character-honor-topright" ] = Background;
		[ "interface\\paperdollinfoframe\\ui-character-inactivetab" ] = Foreground;
		[ "interface\\paperdollinfoframe\\ui-character-scrollbar" ] = Background;
		[ "interface\\paperdollinfoframe\\ui-character-statbackground" ] = Foreground;
		[ "interface\\paperdollinfoframe\\ui-reputationwatchbar" ] = WatchBarBubbles;
		[ "interface\\petpaperdollframe\\ui-petframe-frame" ] = Background;
		[ "interface\\petpaperdollframe\\ui-petframe-slots" ] = Background;
		[ "interface\\petpaperdollframe\\ui-petpaperdollframe-botleft" ] = Background;
		[ "interface\\petpaperdollframe\\ui-petpaperdollframe-botright" ] = Background;
		[ "interface\\petstableframe\\ui-petstable-bottomleft" ] = Background;
		[ "interface\\petstableframe\\ui-petstable-bottomright" ] = Background;
		[ "interface\\petstableframe\\ui-petstable-topleft" ] = Background;
		[ "interface\\petstableframe\\ui-petstable-topright" ] = Background;
		[ "interface\\pvpframe\\ui-character-pvp-elements" ] = Background;
		[ "interface\\pvpframe\\ui-character-pvp" ] = Background;
		[ "interface\\questframe\\ui-quest-botleft" ] = Background;
		[ "interface\\questframe\\ui-quest-botleftpatch" ] = Background;
		[ "interface\\questframe\\ui-questgreeting-botleft" ] = Background;
		[ "interface\\questframe\\ui-questgreeting-botright" ] = Background;
		[ "interface\\questframe\\ui-questgreeting-topleft" ] = Background;
		[ "interface\\questframe\\ui-questgreeting-topright" ] = Background;
		[ "interface\\questframe\\ui-questlog-botleft" ] = Background;
		[ "interface\\questframe\\ui-questlog-botright" ] = Background;
		[ "interface\\questframe\\ui-questlog-empty-botleft" ] = Background;
		[ "interface\\questframe\\ui-questlog-empty-botright" ] = Background;
		[ "interface\\questframe\\ui-questlog-empty-topleft" ] = Background;
		[ "interface\\questframe\\ui-questlog-empty-topright" ] = Background;
		[ "interface\\questframe\\ui-questlog-topleft" ] = Background;
		[ "interface\\questframe\\ui-questlog-topright" ] = Background;
		[ "interface\\questframe\\ui-questlogsorttab-left" ] = Background;
		[ "interface\\questframe\\ui-questlogsorttab-middle" ] = Background;
		[ "interface\\questframe\\ui-questlogsorttab-right" ] = Background;
		[ "interface\\raidframe\\ui-raidinfo-header" ] = Background;
		[ "interface\\raidframe\\ui-readycheckframe" ] = Background;
		[ "interface\\spellbook\\spellbook-skilllinetab" ] = Background;
		[ "interface\\spellbook\\ui-spellbook-tab-unselected" ] = Foreground;
		[ "interface\\spellbook\\ui-spellbook-tab1-selected" ] = Background;
		[ "interface\\spellbook\\ui-spellbook-tab3-selected" ] = Background;
		[ "interface\\spellbook\\ui-spellbookpanel-botleft" ] = Background;
		[ "interface\\spellbook\\ui-spellbookpanel-botright" ] = Background;
		[ "interface\\spellbook\\ui-spellbookpanel-topleft" ] = Background;
		[ "interface\\spellbook\\ui-spellbookpanel-topright" ] = Background;
		[ "interface\\tabardframe\\tabardframebackground" ] = Background;
		[ "interface\\tabardframe\\tabardframecustomizationframe" ] = Background;
		[ "interface\\tabardframe\\tabardframeouterframe" ] = Background;
		[ "interface\\talentframe\\ui-talentframe-botleft" ] = Background;
		[ "interface\\talentframe\\ui-talentframe-botright" ] = Background;
		[ "interface\\targetingframe\\ui-focustargetingframe" ] = Background;
		[ "interface\\targetingframe\\ui-partyframe" ] = Background;
		[ "interface\\targetingframe\\ui-smalltargetingframe-nomana" ] = Background;
		[ "interface\\targetingframe\\ui-smalltargetingframe" ] = Background;
		[ "interface\\targetingframe\\ui-targetingframe" ] = Background;
		[ "interface\\targetingframe\\ui-targetoftargetframe" ] = Background;
		[ "interface\\taxiframe\\ui-taxiframe-botleft" ] = Background;
		[ "interface\\taxiframe\\ui-taxiframe-botright" ] = Background;
		[ "interface\\taxiframe\\ui-taxiframe-topleft" ] = Background;
		[ "interface\\taxiframe\\ui-taxiframe-topright" ] = Background;
		[ "interface\\timemanager\\timerbackground" ] = Foreground;
		[ "interface\\tradeframe\\ui-tradeframe-botleft" ] = Background;
		[ "interface\\tradeframe\\ui-tradeframe-botright" ] = Background;
		[ "interface\\tradeframe\\ui-tradeframe-topleft" ] = Background;
		[ "interface\\tradeframe\\ui-tradeframe-topright" ] = Background;
		[ "interface\\tradeskillframe\\ui-tradeskill-botleft" ] = Background;
		[ "interface\\tutorialframe\\tutorialframeborder" ] = Background;
		[ "interface\\worldmap\\ui-worldmap-bottom1" ] = Background;
		[ "interface\\worldmap\\ui-worldmap-bottom2" ] = Background;
		[ "interface\\worldmap\\ui-worldmap-bottom3" ] = Background;
		[ "interface\\worldmap\\ui-worldmap-bottom4" ] = Background;
		[ "interface\\worldmap\\ui-worldmap-middle1" ] = Background;
		[ "interface\\worldmap\\ui-worldmap-middle2" ] = Background;
		[ "interface\\worldmap\\ui-worldmap-middle3" ] = Background;
		[ "interface\\worldmap\\ui-worldmap-middle4" ] = Background;
		[ "interface\\worldmap\\ui-worldmap-top1" ] = Background;
		[ "interface\\worldmap\\ui-worldmap-top2" ] = Background;
		[ "interface\\worldmap\\ui-worldmap-top3" ] = Background;
		[ "interface\\worldmap\\ui-worldmap-top4" ] = Background;
		[ "interface\\worldstateframe\\worldstatefinalscoreframe-bot" ] = Background;
		[ "interface\\worldstateframe\\worldstatefinalscoreframe-botleft" ] = Background;
		[ "interface\\worldstateframe\\worldstatefinalscoreframe-botright" ] = Background;
		[ "interface\\worldstateframe\\worldstatefinalscoreframe-top" ] = Background;
		[ "interface\\worldstateframe\\worldstatefinalscoreframe-topbackground" ] = Background;
		[ "interface\\worldstateframe\\worldstatefinalscoreframe-topleft" ] = Background;
		[ "interface\\worldstateframe\\worldstatefinalscoreframe-topright" ] = Background;
	};
end
me.Shades = Shades;

local Hooks = {};
me.Hooks = Hooks;




--[[****************************************************************************
  * Function: _Clean.Skin:UpdateTexture                                        *
  * Description: Replaces a texture's current path.                            *
  ****************************************************************************]]
do
	local Path, Shade;
	function me:UpdateTexture ()
		if ( self ) then
			Path = self:GetTexture();
			if ( Path ) then
				Path = Path:lower();
				if ( Replacements[ Path ] ) then
					self:SetTexture( Path ); -- Let SetTexture do the replacement
				end
				Shade = Shades[ Path ];
				if ( Shade ) then
					self:SetVertexColor( Shade.r, Shade.g, Shade.b, Shade.a );
				end
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
	local type = type;
	local function GetHook ( Method )
		if ( not Hooks[ Method ] ) then
			-- Create generic hook
			local Disabled = {};
			Hooks[ Method ] = function ( self, Path, ... )
				if ( not Disabled[ self ] and type( Path ) == "string" ) then
					Path = Replacements[ Path:lower() ];
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
