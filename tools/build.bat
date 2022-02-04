@echo off

set scriptDir=%~dp0
set projectRoot=%scriptDir%\..

if [%~1]==[--release] (
	mkdir %projectRoot%\bin\release\ >nul 2>nul
	cd %projectRoot%\bin\release\

	xcopy %projectRoot%\res\ %projectRoot%\bin\release\res\ /s /e /y /q
	odin run %projectRoot%\src\ -o:size -out:infecdead.exe -thread-count:8
) else (
	mkdir %projectRoot%\bin\debug\ >nul 2>nul
	cd %projectRoot%\bin\debug\

	xcopy %projectRoot%\res\ %projectRoot%\bin\debug\res\ /s /e /y /q
	odin run %projectRoot%\src\ -opt:0 -out:infecdead.exe -thread-count:8 -debug
)

cd %projectRoot%
