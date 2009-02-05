--[[****************************************************************************
  * GuildBankSearch by Saiket, originally by Harros                            *
  * Localization.koKR.lua - Localized string constants (ko-KR) by freshworks.  *
  ****************************************************************************]]


if ( GetLocale() == "koKR" ) then
	local Title = "GuildBank|cffccccccSearch"..FONT_COLOR_CODE_CLOSE;
	GuildBankSearchLocalization = setmetatable(
		{
			TITLE = Title;

			FILTER = "필터";
			CLEAR = "삭제";

			NAME = "이름:";
			QUALITY = "품질:";
			ITEM_LEVEL = "아이템 레벨:";
			REQUIRED_LEVEL = "필요 레벨:";
			LEVELRANGE_SEPARATOR = "-";

			ITEM_CATEGORY = "아이템 분류";
			TYPE = "종류:";
			SUB_TYPE = "부-종류:";
			SLOT = "슬롯:";

			ALL = "|cffcccccc(모두)"..FONT_COLOR_CODE_CLOSE;
		}, { __index = GuildBankSearchLocalization; } );
end
