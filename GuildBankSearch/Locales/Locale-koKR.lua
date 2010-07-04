--[[****************************************************************************
  * GuildBankSearch by Saiket, originally by Harros                            *
  * Locales/Locale-koKR.lua - Localized string constants (ko-KR)               *
  ****************************************************************************]]


if ( GetLocale() ~= "koKR" ) then
	return;
end


-- See http://wow.curseforge.com/addons/guild-bank-search/localization/koKR/
local GuildBankSearch = select( 2, ... );
GuildBankSearch.L = setmetatable( {
	ALL = "|cffcccccc(모두)|r",
	CLEAR = "삭제",
	FILTER = "필터",
	ITEM_CATEGORY = "아이템 분류",
	ITEM_LEVEL = "아이템 레벨:",
	NAME = "이름:",
	QUALITY = "품질:",
	REQUIRED_LEVEL = "필요 레벨:",
	SLOT = "슬롯:",
	SUB_TYPE = "부-종류:",
	TYPE = "종류:",
}, { __index = GuildBankSearch.L; } );