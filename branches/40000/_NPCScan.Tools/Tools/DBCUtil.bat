:: DBCUtil.bat: Converts all DBC files found in <DBFilesClient> to CSV files
@ECHO OFF

FOR /r "DBFilesClient" %%I IN (*.dbc) DO (
	ECHO Converting %%~I...
	Libs\DBCUtil.exe --overwrite --quiet "%%~I"
)

ECHO.
PAUSE