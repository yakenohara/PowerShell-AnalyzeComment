:: <License>------------------------------------------------------------

::  Copyright (c) 2019 Shinnosuke Yakenohara

::  This program is free software: you can redistribute it and/or modify
::  it under the terms of the GNU General Public License as published by
::  the Free Software Foundation, either version 3 of the License, or
::  (at your option) any later version.

::  This program is distributed in the hope that it will be useful,
::  but WITHOUT ANY WARRANTY; without even the implied warranty of
::  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
::  GNU General Public License for more details.

::  You should have received a copy of the GNU General Public License
::  along with this program.  If not, see <http://www.gnu.org/licenses/>.

:: -----------------------------------------------------------</License>

@echo off

::param check
if "%~1" == "" goto PARAM_ERROR
if NOT EXIST "%~1" (
goto NOT_FOUND_ERROR
)

::initialize
set fromDir=%~1
set outDir_comment=%fromDir%_comment
set outDir_code=%fromDir%_code

set tmpDir=%fromDir%_tmp
set outDir=%fromDir%_switched
@echo on

@echo %fromDir%

::出力ディレクトリ作成
if EXIST "%outDir_comment%" (
rmdir /s /q "%outDir_comment%"
)
xcopy "%fromDir%" "%outDir_comment%" /i /t

if EXIST "%outDir_code%" (
rmdir /s /q "%outDir_code%"
)
xcopy "%fromDir%" "%outDir_code%" /i /t

::do
@echo off
set ps1FileName=iterater.ps1
set param=\"%fromDir%\" \"%outDir_comment%\" \"%outDir_code%\"
@echo on
powershell -ExecutionPolicy Unrestricted "& \"%~dp0%ps1FileName%\" %param%"

@echo;
@echo Done!
@pause
@exit /B 0

:PARAM_ERROR
@echo Direcotory not specified
@exit /B 1

:NOT_FOUND_ERROR
@echo Specified directory "%~1" not found
@exit /B 1