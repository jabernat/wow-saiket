--[[****************************************************************************
  * GuildBankSearch by Saiket, originally by Harros                            *
  * Locales/Locale-zhTW.lua - Localized string constants (zhTW) by jyuny1.     *
  ****************************************************************************]]


if ( GetLocale() ~= "zhTW" ) then
	return;
end


-- See http://wow.curseforge.com/addons/guild-bank-search/localization/zhTW/
GuildBankSearchLocalization = setmetatable( {
	ALL = "|cffcccccc(所有)|r",
	CLEAR = "清除",
	FILTER = "物品搜索",
	ITEM_CATEGORY = "分類物品",
	ITEM_LEVEL = "物品等級:",
	NAME = "名稱:",
	QUALITY = "品質:",
	REQUIRED_LEVEL = "需要等級:",
	SLOT = "欄位:",
	SUB_TYPE = "副類別:",
	TYPE = "類別:",
}, { __index = GuildBankSearchLocalization; } );