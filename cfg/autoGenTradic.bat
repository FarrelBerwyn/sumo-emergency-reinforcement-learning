@echo off
REM autoGenTradic.bat - Windows version for Python 3 and latest SUMO
REM This script generates random traffic for SUMO simulation

REM Check if SUMO_HOME is set
if "%SUMO_HOME%"=="" (
    echo Error: SUMO_HOME environment variable is not set
    echo Please set SUMO_HOME to your SUMO installation directory
    echo Example: set SUMO_HOME=C:\Program Files ^(x86^)\Eclipse\Sumo
    pause
    exit /b 1
)

REM Network file - change this to your network file
set NETWORK_FILE=cfg\Jakhospital.net.xml

REM Output directory for generated files
set OUTPUT_DIR=cfg

REM Get current directory and show it for debugging
echo Current directory: %CD%
echo Looking for network file: %NETWORK_FILE%
echo Output directory: %OUTPUT_DIR%

REM List XML files in current directory for debugging
echo Available XML files:
dir *.xml /b

REM Check if network file exists
if not exist "%NETWORK_FILE%" (
    echo Error: Network file %NETWORK_FILE% not found in current directory
    echo Please make sure you are running this script from the correct directory
    echo or update the NETWORK_FILE variable with the correct path
    pause
    exit /b 1
) else (
    echo Found network file: %NETWORK_FILE%
)

REM Generate passenger cars
python "%SUMO_HOME%\tools\randomTrips.py" ^
    --net-file "%NETWORK_FILE%" ^
    --period 0.5 ^
    --fringe-factor 1 ^
    --length ^
    --min-distance 1000 ^
    --max-distance 50000 ^
    --begin 0 ^
    --end 30 ^
    --route-file "%OUTPUT_DIR%\output.trips1.xml" ^
    --prefix passenger ^
    --seed 70 ^
    --validate ^
    --trip-attributes="type=\"car\" departSpeed=\"max\" departLane=\"best\""

if %errorlevel% neq 0 (
    echo Error generating passenger cars
    pause
    exit /b 1
)

REM Generate buses
python "%SUMO_HOME%\tools\randomTrips.py" ^
    --net-file "%NETWORK_FILE%" ^
    --period 0.9 ^
    --fringe-factor 1 ^
    --length ^
    --min-distance 1000 ^
    --max-distance 500000 ^
    --begin 0 ^
    --end 90 ^
    --route-file "%OUTPUT_DIR%\output.trips2.xml" ^
    --prefix bus ^
    --seed 30 ^
    --validate ^
    --trip-attributes="type=\"bus\" departSpeed=\"max\""

if %errorlevel% neq 0 (
    echo Error generating buses
    pause
    exit /b 1
)

REM Generate motorcycles
python "%SUMO_HOME%\tools\randomTrips.py" ^
    --net-file "%NETWORK_FILE%" ^
    --period 0.1 ^
    --fringe-factor 1 ^
    --length ^
    --min-distance 1000 ^
    --max-distance 500000 ^
    --begin 0 ^
    --end 109 ^
    --route-file "%OUTPUT_DIR%\output.trips3.xml" ^
    --prefix motor ^
    --seed 30 ^
    --validate ^
    --trip-attributes="type=\"motor\" departSpeed=\"max\" departLane=\"best\""

if %errorlevel% neq 0 (
    echo Error generating motor
    pause
    exit /b 1
)

if %errorlevel% neq 0 (
    echo Error converting trips to routes
    pause
    exit /b 1
)

REM Convert trips to routes
echo Converting trips to routes...

REM Check if duarouter exists
if exist "%SUMO_HOME%\bin\duarouter.exe" (
    echo Using duarouter from bin directory
    "%SUMO_HOME%\bin\duarouter.exe" ^
        --net-file "%NETWORK_FILE%" ^
        --route-files "%OUTPUT_DIR%\output.trips1.xml,%OUTPUT_DIR%\output.trips2.xml,%OUTPUT_DIR%\output.trips3.xml" ^
        --output-file "%OUTPUT_DIR%\all_routes.rou.xml" ^
        --ignore-errors ^
        --repair
) else if exist "%SUMO_HOME%\tools\duarouter.exe" (
    echo Using duarouter from tools directory
    "%SUMO_HOME%\tools\duarouter.exe" ^
        --net-file "%NETWORK_FILE%" ^
        --route-files "%OUTPUT_DIR%\output.trips1.xml,%OUTPUT_DIR%\output.trips2.xml,%OUTPUT_DIR%\output.trips3.xml" ^
        --output-file "%OUTPUT_DIR%\all_routes.rou.xml" ^
        --ignore-errors ^
        --repair
) else (
    echo Warning: duarouter not found, trying with python
    python "%SUMO_HOME%\tools\duarouter.py" ^
        --net-file "%NETWORK_FILE%" ^
        --route-files "%OUTPUT_DIR%\output.trips1.xml,%OUTPUT_DIR%\output.trips2.xml,%OUTPUT_DIR%\output.trips3.xml" ^
        --output-file "%OUTPUT_DIR%\all_routes.rou.xml" ^
        --ignore-errors ^
        --repair
)

if %errorlevel% neq 0 (
    echo Error converting trips to routes
    pause
    exit /b 1
)

echo.
echo Traffic generation completed successfully!
echo Generated files in cfg folder:
echo - cfg\output.trips1.xml ^(passenger cars^)
echo - cfg\output.trips2.xml ^(buses^)
echo - cfg\output.trips3.xml ^(motorcycles^)
echo.
pause