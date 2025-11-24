#!/bin/bash
set -e

# VERSÃO v1 CORRIGIDA - Foco em 64-bit (System64)
# Correções principais:
# 1. tar -xjf → unzip (arquivo ZIP, não tar.bz2!)
# 2. Launcher aponta para System64/unreal-bin-amd64
# 3. Desktop entry com paths consistentes
# 4. Links simbólicos com paths dinâmicos

# Detecta idioma do sistema
if [[ "$LANG" == pt_* ]] || [[ "$LANGUAGE" == pt_* ]]; then
    LANG_PT=true
else
    LANG_PT=false
fi

msg() {
    local pt="$1"
    local en="$2"
    if $LANG_PT; then
        echo "$pt"
    else
        echo "$en"
    fi
}

WINE_PREFIX="$HOME/.wine/drive_c"
GAMES_DIR="$HOME/Games"
PATCH_URL="https://archive.org/download/unreal-227k-patch-linux/Unreal-227k-Patch-Linux.zip"

msg "══════════════════════════════════════════════════" \
    "══════════════════════════════════════════════════"
msg "       Instalador UnrealGold para Linux (v1-FIXED)" \
    "       UnrealGold Linux Installer (v1-FIXED)"
msg "══════════════════════════════════════════════════" \
    "══════════════════════════════════════════════════"
echo ""
msg "NOTA: Este patch é compatível apenas com Unreal (Gold) 64-bit." \
    "NOTE: This patch is compatible only with Unreal (Gold) 64-bit."
echo ""

# [1/9] Verificar dependências
msg "[1/9] Verificando dependências..." \
    "[1/9] Checking dependencies..."

MISSING_DEPS=()
for cmd in wget unzip convert; do  # ← CORRIGIDO: unzip ao invés de tar
    if ! command -v $cmd &> /dev/null; then
        MISSING_DEPS+=($cmd)
    fi
done

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    msg "ERRO: Dependências faltando: ${MISSING_DEPS[*]}" \
        "ERROR: Missing dependencies: ${MISSING_DEPS[*]}"
    msg "Instale com: sudo apt install wget unzip imagemagick" \
        "Install with: sudo apt install wget unzip imagemagick"
    exit 1
fi

msg "✔ Dependências OK!" \
    "✔ Dependencies OK!"

# [2/9] Procurar instalação do UnrealGold
msg "[2/9] Procurando instalação do UnrealGold no Wine..." \
    "[2/9] Looking for Unreal installation in Wine..."

UNREALGOLD_PATH="$WINE_PREFIX/UnrealGold"

if [ ! -d "$UNREALGOLD_PATH" ]; then
    msg "ERRO: Instalação do UnrealGold não encontrada no Wine." \
        "ERROR: UnrealGold installation not found in Wine."
    echo ""
    msg "Instale primeiro o Unreal (Gold) via Wine." \
        "Install Unreal (Gold) first via Wine."
    msg "Caminho esperado: $UNREALGOLD_PATH" \
        "Expected path: $UNREALGOLD_PATH"
    echo ""
    msg "IMPORTANTE: Este script é apenas para UnrealGold." \
        "IMPORTANT: This script is for UnrealGold only."
    exit 1
fi

msg "✔ UnrealGold encontrado!" \
    "✔ UnrealGold found!"

# Definir paths finais
GAME_LINUX_PATH="$GAMES_DIR/UnrealGold"
ICON_DIR="$HOME/.local/share/icons/hicolor"
DESKTOP_FILE="$HOME/.local/share/applications/unrealgold.desktop"
LAUNCHER_NAME="unreal gold"

echo ""

# [3/9] Copiar arquivos
msg "[3/9] Copiando arquivos para $GAME_LINUX_PATH ..." \
    "[3/9] Copying files to $GAME_LINUX_PATH ..."

mkdir -p "$GAME_LINUX_PATH"
cp -r "$UNREALGOLD_PATH"/* "$GAME_LINUX_PATH"

msg "✔ Arquivos copiados!" \
    "✔ Files copied!"

# [4/9] Baixar patch
msg "[4/9] Baixando patch Unreal-227k-Patch-Linux.zip do archive.org..." \
    "[4/9] Downloading Unreal-227k-Patch-Linux.zip patch from archive.org..."

cd /tmp
if [ -f "Unreal-227k-Patch-Linux.zip" ]; then
    rm Unreal-227k-Patch-Linux.zip
fi

wget -q --show-progress -O Unreal-227k-Patch-Linux.zip "$PATCH_URL"

msg "✔ Patch baixado!" \
    "✔ Patch downloaded!"

# [5/9] Extrair patch
msg "[5/9] Extraindo e aplicando patch..." \
    "[5/9] Extracting and applying patch..."

# ← CORRIGIDO: usar unzip para arquivo .zip
unzip -o Unreal-227k-Patch-Linux.zip >/dev/null

# Copiar conteúdo extraído
if [ -d "Unreal-227k-Patch-Linux" ]; then
    cp -r Unreal-227k-Patch-Linux/* "$GAME_LINUX_PATH/"
    rm -rf Unreal-227k-Patch-Linux
fi

rm Unreal-227k-Patch-Linux.zip

msg "✔ Patch Unreal-227k-Patch-Linux aplicado!" \
    "✔ Patch Unreal-227k-Patch-Linux applied!"

# [6/9] Ajustar permissões e configurações
msg "[6/9] Ajustando permissões e configurações..." \
    "[6/9] Setting permissions and configurations..."

# ← CORRIGIDO: Verificar se System64 existe
if [ ! -d "$GAME_LINUX_PATH/System64" ]; then
    msg "ERRO: System64 não encontrado! Este script requer a versão 64-bit." \
        "ERROR: System64 not found! This script requires the 64-bit version."
    exit 1
fi

chmod +x "$GAME_LINUX_PATH/System64/"*-bin* 2>/dev/null || true
chmod +x "$GAME_LINUX_PATH/System64/"*.bin 2>/dev/null || true

# Corrigir paths nos arquivos .ini
cd "$GAME_LINUX_PATH/System64"

# Backup dos arquivos .ini originais
for ini_file in *.ini; do
    if [ -f "$ini_file" ] && [ ! -f "${ini_file}.bak" ]; then
        cp "$ini_file" "${ini_file}.bak"
    fi
done

# Corrigir todos os arquivos .ini
for ini_file in *.ini; do
    if [ -f "$ini_file" ]; then
        sed -i 's/\\/\//g' "$ini_file" 2>/dev/null || true
        sed -i "s|C:.*Unreal|$GAME_LINUX_PATH|gi" "$ini_file" 2>/dev/null || true
        sed -i "s|Z:.*Unreal|$GAME_LINUX_PATH|gi" "$ini_file" 2>/dev/null || true
        sed -i 's|[A-Z]:\\|/|gi' "$ini_file" 2>/dev/null || true
    fi
done

# Garantir pastas essenciais
mkdir -p "$GAME_LINUX_PATH/Maps"
mkdir -p "$GAME_LINUX_PATH/Music"
mkdir -p "$GAME_LINUX_PATH/Sounds"
mkdir -p "$GAME_LINUX_PATH/Textures"

msg "✔ Permissões e configurações ajustadas!" \
    "✔ Permissions and configurations set!"

# [7/9] Criar ícones
msg "[7/9] Criando ícones..." \
    "[7/9] Creating icons..."

ICON_SOURCE=""
for icon_path in "$GAME_LINUX_PATH/Help/Unreal.ico" \
                 "$GAME_LINUX_PATH/System/Unreal.ico" \
                 "$GAME_LINUX_PATH/Unreal.ico"; do
    if [ -f "$icon_path" ]; then
        ICON_SOURCE="$icon_path"
        msg "  → Ícone encontrado: $icon_path" \
            "  → Icon found: $icon_path"
        break
    fi
done

if [ -n "$ICON_SOURCE" ]; then
    for size in 16 22 24 32 48 64 128 256; do
        mkdir -p "$ICON_DIR/${size}x${size}/apps"
        convert "$ICON_SOURCE"[0] -resize ${size}x${size} \
            "$ICON_DIR/${size}x${size}/apps/unrealgold.png" 2>/dev/null || true
    done
    
    mkdir -p "$HOME/.local/share/pixmaps"
    convert "$ICON_SOURCE"[0] -resize 48x48 \
        "$HOME/.local/share/pixmaps/unrealgold.png" 2>/dev/null || true
    
    msg "✔ Ícones criados em múltiplos tamanhos!" \
        "✔ Icons created in multiple sizes!"
else
    msg "⚠ Ícone original não encontrado, será usado ícone padrão" \
        "⚠ Original icon not found, default icon will be used"
fi

# [8/9] Criar launcher global
msg "[8/9] Criando launcher no sistema..." \
    "[8/9] Creating system launcher..."

# ← CORRIGIDO: Launcher aponta para System64/unreal-bin-amd64
LAUNCHER_SCRIPT="#!/bin/bash
cd \"$GAME_LINUX_PATH/System64\" || exit 1
exec ./unreal-bin-amd64 \"\$@\""

echo "$LAUNCHER_SCRIPT" | sudo tee /usr/local/bin/$LAUNCHER_NAME >/dev/null
sudo chmod +x /usr/local/bin/$LAUNCHER_NAME

msg "✔ Launcher criado: $LAUNCHER_NAME" \
    "✔ Launcher created: $LAUNCHER_NAME"

# [9/9] Criar entrada no menu
msg "[9/9] Criando entrada no menu de aplicativos..." \
    "[9/9] Creating application menu entry..."

mkdir -p "$(dirname "$DESKTOP_FILE")"

# ← CORRIGIDO: Desktop entry com paths consistentes System64
if $LANG_PT; then
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Unreal Gold
GenericName=Jogo de Tiro em Primeira Pessoa
Comment=Jogo clássico de FPS da Epic Games
Exec=$GAME_LINUX_PATH/System64/unreal-bin-amd64
Icon=unrealgold
Terminal=false
Categories=Game;ActionGame;
Keywords=unreal;fps;tiro;ação;epicgames;
StartupNotify=true
Path=$GAME_LINUX_PATH/System64
EOF
else
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Unreal Gold
GenericName=First Person Shooter
Comment=Classic FPS game by Epic Games
Exec=$GAME_LINUX_PATH/System64/unreal-bin-amd64
Icon=unrealgold
Terminal=false
Categories=Game;ActionGame;
Keywords=unreal;fps;shooter;action;epicgames;
StartupNotify=true
Path=$GAME_LINUX_PATH/System64
EOF
fi

chmod +x "$DESKTOP_FILE"

# [10/9] Configurar bibliotecas 64-bit
msg "[10/9] Configurando bibliotecas 64-bit..." \
    "[10/9] Setting up 64-bit libraries..."

# ← CORRIGIDO: Links simbólicos com paths dinâmicos
cd "$GAME_LINUX_PATH/System64"

# Função para criar link seguro
create_lib_link() {
    local lib_name="$1"
    local lib_path=$(ldconfig -p 2>/dev/null | grep "$lib_name" | grep "x86-64" | awk '{print $NF}' | head -1)
    
    if [ -n "$lib_path" ] && [ -f "$lib_path" ]; then
        ln -sf "$lib_path" "./$lib_name"
        msg "  → $lib_name: OK" "  → $lib_name: OK"
    else
        msg "  ⚠ $lib_name: não encontrada" "  ⚠ $lib_name: not found"
    fi
}

# [10/9] Configurar bibliotecas 64-bit
msg "[10/9] Configurando bibliotecas 64-bit..." \
    "[10/9] Setting up 64-bit libraries..."

cd "$GAME_LINUX_PATH/System64"

# Função para encontrar, copiar e renomear biblioteca
copy_and_rename_lib() {
    local search_pattern="$1"
    local target_name="$2"
    
    # Busca em ordem de prioridade
    local lib_path=$(find /usr/lib/x86_64-linux-gnu -name "$search_pattern" 2>/dev/null | head -1)
    
    if [ -z "$lib_path" ]; then
        # Fallback: tentar em /usr/lib
        lib_path=$(find /usr/lib -name "$search_pattern" 2>/dev/null | head -1)
    fi
    
    if [ -n "$lib_path" ] && [ -f "$lib_path" ]; then
        cp "$lib_path" "./$target_name"
        msg "  → $target_name: OK (copiado de $lib_path)" \
            "  → $target_name: OK (copied from $lib_path)"
        return 0
    else
        msg "  ⚠ $search_pattern: não encontrada" \
            "  ⚠ $search_pattern: not found"
        return 1
    fi
}

# Copiar e renomear bibliotecas essenciais
copy_and_rename_lib "libxmp.so.4*" "libxmp.so.4"
copy_and_rename_lib "libmpg123.so.0*" "libmpg123.so"

msg "✔ Bibliotecas copiadas e renomeadas!" \
    "✔ Libraries copied and renamed!"

# Verificar e instalar libs faltantes se necessário
if command -v apt-get >/dev/null 2>&1; then
    msg "Verificando bibliotecas do sistema..." \
        "Checking system libraries..."
    
    LIBS_NEEDED=()
    dpkg -l | grep -q "libxmp4" || LIBS_NEEDED+=("libxmp4")
    dpkg -l | grep -q "libmpg123-0" || LIBS_NEEDED+=("libmpg123-0")
    
    if [ ${#LIBS_NEEDED[@]} -gt 0 ]; then
        msg "Instalando: ${LIBS_NEEDED[*]}" \
            "Installing: ${LIBS_NEEDED[*]}"
        sudo apt-get install -y "${LIBS_NEEDED[@]}" 2>/dev/null || true
    fi
fi

# Criar UnrealLinux.ini
msg "Criando UnrealLinux.ini..." \
    "Creating UnrealLinux.ini..."

cat << 'EOF' > "$GAME_LINUX_PATH/System64/UnrealLinux.ini"
﻿[URL]
Protocol=unreal
ProtocolDescription=Unreal Protocol
Name=Player
Map=Index.unr
LocalMap=Unreal.unr
AltLocalMap=UPack.unr
EntryMap=Entry.unr
EntryMap=EntryII.unr
EntryMap=EntryIII.unr
Host=
Portal=
MapExt=unr
SaveExt=usa
Port=7777

[FirstRun]
FirstRun=227

[Engine.Engine]
GameRenderDevice=OpenGLDrv.OpenGLRenderDevice
#GameRenderDevice=XOpenGLDrv.XOpenGLRenderDevice
;AudioDevice=SwFMOD.SwFMOD
AudioDevice=ALAudio.ALAudioSubsystem
NetworkDevice=IpDrv.TcpNetDriver
;Console=UBrowser.UBrowserConsole
Console=UMenu.UnrealConsole
;Console=Engine.Console
;Console=UPak.UPakConsole
Language=int
GameEngine=Engine.GameEngine
DemoRecordingDevice=Engine.DemoRecDriver
EditorEngine=Editor.EditorEngine
WindowedRenderDevice=OpenGLDrv.OpenGLRenderDevice
DefaultGame=UnrealShare.SinglePlayer
DefaultServerGame=UnrealShare.DeathMatchGame
ViewportManager=SDL2Drv.SDL2Client
Render=Render.Render
Input=Engine.Input
Canvas=Engine.Canvas
DisableStdin=0
PhysicsEngine=PhysXPhysics.PhysXPhysics
RunCount=8

[Core.System]
PurgeCacheDays=0
SavePath=../Save
CachePath=../Cache
CacheExt=.uxx
UseCPU=-1
NoRunAway=True
NoCacheSearch=True
Force1msTimer=True
UseRegularAngles=False
LangPaths=../SystemLocalized/<lang>/*.<lang>
LangPaths=*.<lang>
LangPaths=../System/*.<lang>
Paths=../System64/*.u
Paths=../System/*.u
Paths=../Maps/*.unr
Paths=../Maps/UPak/*.unr
Paths=../Textures/*.utx
Paths=../Sounds/*.uax
Paths=../Music/*.umx
Paths=../Meshes/*.usm
Suppress=DevLoad
Suppress=DevSave
Suppress=DevNetTraffic
Suppress=DevGarbage
Suppress=DevKill
Suppress=DevReplace
Suppress=DevSound
Suppress=DevCompile
Suppress=DevBind
Suppress=DevBsp
Suppress=DevNet
Suppress=DevMusic
Suppress=DevAudio
Suppress=DevGraphics
Suppress=DevPhysics
Suppress=Dev
Suppress=ScriptWarning

[Engine.GameEngine]
CacheSizeMegs=256
UseSound=True
bServerSaveInventory=False
ServerActors=IpDrv.UdpBeacon
ServerActors=IpServer.UdpServerQuery
ServerActors=UBrowser.UBrowserUplink
ServerActors=UWebAdmin.WebAdminManager
; Oldstyle way. If you dislike auto updates, then simply comment ServerActors=UBrowser.UBrowserUplink and uncomment below.
;ServerActors=IpServer.UdpServerUplink MasterServerAddress=master.oldunreal.com MasterServerPort=27900
;ServerActors=IpServer.UdpServerUplink MasterServerAddress=master.hlkclan.net MasterServerPort=27900
;ServerActors=IpServer.UdpServerUplink MasterServerAddress=master2.oldunreal.com MasterServerPort=27900
;ServerActors=IpServer.UdpServerUplink MasterServerAddress=master.hypercoop.tk MasterServerPort=27900
;ServerActors=IpServer.UdpServerUplink MasterServerAddress=master.newbiesplayground.net MasterServerPort=27900
;ServerActors=IpServer.UdpServerUplink MasterServerAddress=master.errorist.tk MasterServerPort=27900
;ServerActors=IpServer.UdpServerUplink MasterServerAddress=master.qtracker.com MasterServerPort=27900
ServerPackages=Female1skins
ServerPackages=Female2skins
ServerPackages=Male1skins
ServerPackages=Male2skins
ServerPackages=Male3skins
ServerPackages=SkTrooperskins
ServerPackages=UnrealIntegrity

[Engine.Console]
GlobalConsoleKey=192
GlobalWindowKey=27
bConsoleCommandLog=True

[UMenu.UnrealConsole]
RootWindow=UMenu.UMenuRootWindow
UWindowKey=IK_Esc
ShowDesktop=True
MouseScale=0.900000
bShowConsole=False

[UMenu.UMenuMenuBar]
ShowHelp=True
GameUMenuDefault=UMenu.UMenuGameMenu
MultiplayerUMenuDefault=UMenu.UMenuMultiplayerMenu
OptionsUMenuDefault=UMenu.UMenuOptionsMenu
ModMenuClass=UMenu.UMenuModMenu

[UMenu.UMenuRootWindow]
GUIScale=1.000000
LookAndFeelClass=UMenu.UMenuMetalLookAndFeel

[Engine.ChannelDownload]
UseCompression=False
CompressDir="../Compress/"

[IpDrv.TcpNetDriver]
AllowDownloads=True
MaxDownloadSize=0
ConnectionTimeout=15.0
InitialConnectTimeout=500.0
AckTimeout=1.0
KeepAliveTime=1.0
MaxClientRate=20000
SimLatency=0
RelevantTimeout=5.0
SpawnPrioritySeconds=1.0
ServerTravelPause=4.0
NetServerMaxTickRate=20
LanServerMaxTickRate=35
LogMaxConnPerIPPerMin=True
MaxConnPerIPPerMinute=5
AllowFastDownload=True
DownloadSpeedLimit=524288
AllowOldClients=True
OldClientCompatMode=True
UseTransientNames=True
MaxCachedRPCNames=10
bCacheRPCNames=True
MaxTimedRPC=0
TimedRPCDuration=0.000000
MaxRPCPerTick=0
MaxConnPerIP=10
MaxRepRPCPerTick=120
ExcludedRPCNames=ServerMove
DownloadManagers=IpDrv.HTTPDownload
DownloadManagers=Engine.ChannelDownload

[IpDrv.HTTPDownload]
RedirectToURL=
ProxyServerHost=
ProxyServerPort=3128
UseCompression=True

[IpDrv.TcpipConnection]
SimPacketLoss=0
SimLatency=0

[IpDrv.UdpBeacon]
DoBeacon=True
BeaconTime=0.50
BeaconTimeout=5.0
BeaconPort=7776
BeaconProduct=Unreal

[IpServer.UdpServerQuery]
GameName=unreal

[IpServer.UdpServerUplink]
DoUplink=False
UpdateMinutes=1
MasterServerAddress=
MasterServerPort=27900
Region=0

[SDL2Drv.SDL2Client]
AllowCommandQKeys=False
IgnoreUngrabbedMouse=False
IgnoreHat=False
ScaleJBY=0.000000
ScaleJBX=0.000000
StartupFullscreen=True
JoystickHatNumber=0
JoystickNumber=0
UseJoystick=False
StatNetColour=(R=0.0,G=0.0,B=0.0,A=0.0)
ParticleDensity=0
NoFractalAnim=False
NoDynamicLights=False
Decals=True
MinDesiredFrameRate=28.000000
NoLighting=False
ScreenFlashes=True
SkinDetail=High
TextureDetail=High
FlatShading=False
CurvedSurfaces=False
CaptureMouse=True
Brightness=0.400000
MipFactor=1.000000
WindowedViewportX=1024
WindowedViewportY=768
WindowedColorBits=32
FullscreenViewportX=1024
FullscreenViewportY=768
FullscreenColorBits=32
AnimTexFrameRate=42.000000
SkyBoxFogMode=FOGDETAIL_None
UseDesktopFullScreen=False
ContinuousKeyEvents=True
LightMapLOD=3
FrameRateLimit=60.000000
WindowPosX=0
WindowPosY=0
UseRawHIDInput=False
UseHDTextures=True
UseNoSmoothWorld=False

[UWindow.WindowConsole]
ConsoleKey=192
LinuxConsoleKey=186
bConsoleShowColors=True
bConsoleLogChatOnly=False
bLogChatMessages=True
ConsoleKeyChar=96
bLogScriptWarnings=False

[Editor.EditorEngine]
UseSound=True
GridEnabled=True
SnapVertices=True
SnapDistance=10.000000
GridSize=(X=16.000000,Y=16.000000,Z=16.000000)
RotGridEnabled=True
RotGridSize=(Pitch=1024,Yaw=1024,Roll=1024)
GameCommandLine=-log
FovAngleDegrees=90.000000
GodMode=True
FreeMeshView=True
AutoSave=False
AutoSaveTimeMinutes=5
AutoSaveIndex=6
AskSave=True
EditorIni=UnrealEd
C_WorldBox=(R=0,G=0,B=107,A=0)
C_GroundPlane=(R=0,G=0,B=63,A=0)
C_GroundHighlight=(R=0,G=0,B=127,A=0)
C_BrushWire=(R=255,G=63,B=63,A=0)
C_Pivot=(R=0,G=255,B=0,A=0)
C_Select=(R=0,G=0,B=127,A=0)
C_AddWire=(R=127,G=127,B=255,A=0)
C_SubtractWire=(R=255,G=192,B=63,A=0)
C_GreyWire=(R=163,G=163,B=163,A=0)
C_Invalid=(R=163,G=163,B=163,A=0)
C_ActorWire=(R=127,G=63,B=0,A=0)
C_ActorHiWire=(R=255,G=127,B=0,A=0)
C_White=(R=255,G=255,B=255,A=0)
C_SemiSolidWire=(R=127,G=255,B=0,A=0)
C_NonSolidWire=(R=63,G=192,B=32,A=0)
C_WireGridAxis=(R=119,G=119,B=119,A=0)
C_ActorArrow=(R=163,G=0,B=0,A=0)
C_ScaleBox=(R=151,G=67,B=11,A=0)
C_ScaleBoxHi=(R=223,G=149,B=157,A=0)
C_Mover=(R=255,G=0,B=255,A=0)
C_OrthoBackground=(R=163,G=163,B=163,A=0)
C_Current=(R=0,G=0,B=0,A=0)
C_BrushVertex=(R=0,G=0,B=0,A=0)
C_BrushSnap=(R=0,G=0,B=0,A=0)
C_Black=(R=0,G=0,B=0,A=0)
C_Mask=(R=0,G=0,B=0,A=0)
C_WireBackground=(R=0,G=0,B=0,A=0)
C_ZoneWire=(R=0,G=0,B=0,A=0)
CodePath=..\
EditPackages=Core
EditPackages=Engine
EditPackages=Editor
EditPackages=Fire
EditPackages=IpDrv
EditPackages=UWindow
EditPackages=UnrealShare
EditPackages=UnrealI
EditPackages=IpServer
EditPackages=UBrowser
EditPackages=EFX
EditPackages=UMenu
EditPackages=UWebAdmin
EditPackages=Emitter
EditPackages=UPak
EditPackages=UDSDemo

[Engine.GameInfo]
bLowGore=False
bVeryLowGore=False
bCastShadow=True
bDecoShadows=True
bUseRealtimeShadow=True
ShadowDetailRes=128
bCastProjectorShadows=False
bBleedingEnabled=False
bBleedingDamageEnabled=False
bAllHealthStopsBleeding=False
bBandagesStopBleeding=False
BleedingDamageMin=5
BleedingDamageMax=20
bMessageAdminsAliases=True
bLogNewPlayerAliases=True
bLogDownloadsToClient=False
bHandleDownloadMessaging=False
bShowRecoilAnimations=True
bNoWalkInAir=True
AdminPassword=
GamePassword=
MaxSpectators=2
MaxPlayers=16
bAlwaysEnhancedSightCheck=True
bProjectorDecals=False
AnimTexFrameRate=42.000000
AutoAim=0.930000
ServerLogName=Server.log
LocalBatcherURL=..\NetGamesUSA.com\ngStats\ngStatsUT.exe
LocalBatcherParams=
LocalStatsURL=..\NetGamesUSA.com\ngStats\html\ngStats_Main.html
WorldBatcherURL=..\NetGamesUSA.com\ngWorldStats\bin\ngWorldStats.exe
WorldBatcherParams=-d ..\NetGamesUSA.com\ngWorldStats\logs
WorldStatsURL=http://www.netgamesusa.com
AccessManagerClass=Engine.AdminAccessManager
bMuteSpectators=False
bNoCheating=True
bLocalLog=False
bLocalLogQuery=True
bWorldLog=False
bRestrictMoversRetriggering=False
bNoMonsters=False
bHumansOnly=False
bCoopWeaponMode=False
bClassicDeathmessages=False
bUseClientReplicationInfo=True
bMultiThreadedShadows=True
bUseClassicBalance=True
DesiredMaxChannels=1024
InventoryDataIni=InventoryData
ServerSceneClass=

[UnrealShare.UnrealGameOptionsMenu]
bCanModifyGore=True

[Engine.DemoRecDriver]
DemoSpectatorClass=Engine.DemoRecSpectator
MaxClientRate=25000
ConnectionTimeout=15.0
InitialConnectTimeout=500.0
AckTimeout=1.0
KeepAliveTime=1.0
SimLatency=0
RelevantTimeout=5.0
SpawnPrioritySeconds=1.0
ServerTravelPause=4.0
NetServerMaxTickRate=60
LanServerMaxTickRate=60

[UBrowser.UBrowserConsole]
RootWindow=UBrowser.UBrowserRootWindow
UWindowKey=IK_Esc

[UBrowser.UBrowserMainClientWindow]
LANTabName=UBrowserLAN
InitialPage=PG_NewsPage
ServerListTitles=Populated Servers
ServerListTitles=Deathmatch
ServerListTitles=Team games
ServerListTitles=Cooperative
ServerListTitles=King of the Hill
ServerListTitles=Infiltration DM
ServerListTitles=Infiltration Standoff / Team
ServerListTitles=Serpentine
ServerListTitles=Capture the Flag
ServerListTitles=Crystal Castles
ServerListTitles=Unreal Forever
ServerListTitles=Domination
ServerListTitles=RTNP Deathmatch
ServerListTitles=DarkMatch
ServerListTitles=All Servers
ServerListTitles=LAN Servers
ServerListNames=UBrowserPopulated
ServerListNames=UBrowserDeathmatch
ServerListNames=UBrowserTeamGames
ServerListNames=UBrowserCoop
ServerListNames=UBrowserKingoftheHill
ServerListNames=UBrowserInfDM
ServerListNames=UBrowserInfStandoff
ServerListNames=UBrowserSerpentine
ServerListNames=UBrowserRealCTF
ServerListNames=UBrowserCC
ServerListNames=UBrowserU4E
ServerListNames=UBrowserDomination
ServerListNames=UBrowserRTNP
ServerListNames=UBrowserDarkMatch
ServerListNames=UBrowserAll
ServerListNames=UBrowserLAN

[UBrowserLAN]
ListFactories=UBrowser.UBrowserLocalFact,BeaconProduct=unreal
URLAppend=?LAN
AutoRefreshTime=10
bNoAutoSort=True

[UBrowserPopulated]
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,MinPlayers=1,bCompatibleServersOnly=True

[UBrowserDeathmatch]
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=InstaGib DeathMatch,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=FatBoy DM Remix *,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=InstaGib JumpMatch,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=SoulHarvest,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Cide Match,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=AEons DM,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Smartball Insta Gib,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=DeathMatch,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=AssualtProDM,bCompatibleServersOnly=True

[UBrowserTeamGames]
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Team Game,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=InstaGib Team,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=NoLamerUpsTDM,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Teamspiel,bCompatibleServersOnly=True

[UBrowserCoop]
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Coop Game,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Gioco Co-op,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Co-op-Spiel,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=CoooPG 2,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Koopgame,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=MONSTERMASH,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=[MONSTERMASH],bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=DeathMatch MonsterMash,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Hide and seek,bCompatibleServersOnly=True

[UbrowserKingoftheHill]
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=King of the Hill,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=UTeamFix King of the Hill,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Reverse KOTH,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=PURE King of the Hill,bCompatibleServersOnly=True

[UBrowserInfDM]
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=[INF] DeathMatch,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=[INF] DeathMatchGame(Fixed),bCompatibleServersOnly=True

[UBrowserInfStandoff]
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=[INF] StandoffCD,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=[INF] Standoff,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=[INF] TeamGame,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Infiltration Team Game Standoff,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Serpentine Team Game Standoff,bCompatibleServersOnly=True

[UBrowserSerpentine]
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Serpentine DM,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Serpentine TeamGame,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Serpentine CoopGame,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Serpentine King of the Hill,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=DarkSerpent,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Serpentine DarkMatch,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Serpentine DeathMatch MonsterMash,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Serpentine Team Game Standoff,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Serpentine DeathMatch,bCompatibleServersOnly=True

[UBrowserRealCTF]
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=RealCTF,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=RealCreeper,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=RealTeam,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=RealTeam Game,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=RealDM,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=NoName CTF,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=CTFGame,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Capture The Flag,bCompatibleServersOnly=True

[UBrowserCC]
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Crystal Standard Game,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Crystal TEAM Game,bCompatibleServersOnly=True

[UBrowserU4E]
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=U4eDM5,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=U4eDeathMatch,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=U4eDeathMatch1,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=U4eAllDM,bCompatibleServersOnly=True

[UBrowserDomination]
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Domination,bCompatibleServersOnly=True

[UBrowserRTNP]
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=GravityMatch,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=CloakMatch,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=TerranWeaponMatch,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=MarineMatch,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Serpentine GravityMatch,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Serpentine CloakMatch,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Serpentine TerranWeaponMatch,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Serpentine MarineMatch,bCompatibleServersOnly=True

[UBrowserDarkMatch]
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=Darkmatch,bCompatibleServersOnly=True
ListFactories=UBrowser.UBrowserSubsetFact,SupersetTag=UBrowserAll,GameType=JediDarkmatch,bCompatibleServersOnly=True

[UBrowserAll]
ListFactories=UBrowser.UBrowserGSpyFact
ListFactories=UBrowser.UBrowserMasterServerFact
;ListFactories=UBrowser.UBrowserGSpyFact,MasterServerAddress=master.oldunreal.com,MasterServerTCPPort=28900,GameName=unreal
;ListFactories=UBrowser.UBrowserGSpyFact,MasterServerAddress=master.hlkclan.net,MasterServerTCPPort=28900,GameName=unreal
;ListFactories=UBrowser.UBrowserGSpyFact,MasterServerAddress=master2.oldunreal.com,MasterServerTCPPort=28900,GameName=unreal
;ListFactories=UBrowser.UBrowserGSpyFact,MasterServerAddress=master.hypercoop.tk,MasterServerTCPPort=28900,GameName=unreal
;ListFactories=UBrowser.UBrowserGSpyFact,MasterServerAddress=master.newbiesplayground.net,MasterServerTCPPort=28900,GameName=unreal
;ListFactories=UBrowser.UBrowserGSpyFact,MasterServerAddress=master.errorist.tk,MasterServerTCPPort=28900,GameName=unreal
;ListFactories=UBrowser.UBrowserGSpyFact,MasterServerAddress=master.333networks.com,MasterServerTCPPort=28900,GameName=unreal

[UnrealShare.SinglePlayer]
bNoMonsters=False
bHumansOnly=True
bCoopWeaponMode=False
bClassicDeathmessages=True
bUseExactHSDetection=True
DesiredMaxChannels=1024
InventoryDataIni=InventoryData
ServerSceneClass=

[UnrealI.Intro]
bNoMonsters=False
bHumansOnly=False
bCoopWeaponMode=False
bClassicDeathmessages=False
DesiredMaxChannels=1024
InventoryDataIni=InventoryData
ServerSceneClass=

[UPak.UPakIntro]
bNoMonsters=False
bHumansOnly=False
bCoopWeaponMode=False
bClassicDeathmessages=False
DesiredMaxChannels=1024
InventoryDataIni=InventoryData
ServerSceneClass=

[Engine.PlayerPawn]
NetSpeed=20000

[UBrowser.UBrowserMasterServerFact]
MasterServerVersion=2
MasterServersURL=/masterserver.txt
MasterServersSite=www.oldunreal.com
MasterServersPort=80
LastCheckDay=

[UBrowser.UBrowserGSpyFact]
Region=0
MasterServerTimeout=20
GameName=unreal
MasterServers=(MasterServerAddress="master.oldunreal.com",MasterServerTCPPort=28900,MasterServerUdpPort=27900)
MasterServers=(MasterServerAddress="master.333networks.com",MasterServerTCPPort=28900,MasterServerUdpPort=27900)
MasterServers=(MasterServerAddress="master.hypercoop.tk",MasterServerTCPPort=28900,MasterServerUdpPort=27900)
MasterServers=(MasterServerAddress="master.errorist.eu",MasterServerTCPPort=28900,MasterServerUdpPort=27900)
MasterServers=(MasterServerAddress="master.newbiesplayground.net",MasterServerTCPPort=28900,MasterServerUdpPort=27900)
MasterServers=(MasterServerAddress="master.hlkclan.net",MasterServerTCPPort=28900,MasterServerUdpPort=27900)
MasterServers=(MasterServerAddress="master2.oldunreal.com",MasterServerTCPPort=28900,MasterServerUdpPort=27900)
Region=0
MasterServerTimeout=20
GameName=unreal

[OpenGLDrv.OpenGLRenderDevice]
OpenGLLibName=libGL.so.1
Translucency=True
VolumetricLighting=True
ShinySurfaces=True
Coronas=True
HighDetailActors=True
DetailTextures=True
FullMeshRendering=True
ZRangeHack=True
AAFilterHint=0
NoAATiles=False
NumAASamples=4
UseAA=True
RequestHighResolutionZ=True
MaskedTextureHack=True
SmoothMaskedTextures=False
UseVSync=On
UseFragmentProgram=False
UseCVA=False
UseMultiDrawArrays=False
TexDXT1ToDXT3=False
DynamicTexIdRecycleLevel=100
CacheStaticMaps=False
UseTexPool=True
UseTexIdPool=True
UseSSE2=True
UseSSE=True
BufferTileQuads=False
BufferClippedActorTris=True
SinglePassDetail=False
SinglePassFog=False
ColorizeDetailTextures=False
DetailClipping=False
UseDetailAlpha=True
DetailMax=1
RefreshRate=0
MaxTMUnits=0
NoFiltering=False
NoMaskedS3TC=False
MaxAnisotropy=4
UseTNT=False
Use16BitTextures=False
UseS3TC=True
UseAlphaPalette=False
AutoGenerateMipmaps=False
UseTrilinear=True
UsePrecache=False
AlwaysMipmap=False
ShareLists=False
UsePalette=False
UseMultiTexture=True
UseBGRATextures=True
UseZTrick=False
MaxLogTextureSize=8
MinLogTextureSize=0
OneXBlending=False
GammaCorrectScreenshots=True
GammaOffsetBlue=0.000000
GammaOffsetGreen=0.000000
GammaOffsetRed=0.000000
GammaOffset=0.000000
LODBias=0.000000
DescFlags=0
Description=
SceneNodeHack=True

[XOpenGLDrv.XOpenGLRenderDevice]
UseHWClipping=True
AlwaysMipmap=False
ShareLists=False
DetailTextures=True
DetailMax=2
MacroTextures=True
BumpMaps=True
DescFlags=0
Description=
Coronas=True
ShinySurfaces=True
VolumetricLighting=True
RefreshRate=0
UseTrilinear=True
UsePrecache=False
LODBias=0.000000
GammaCorrectScreenshots=False
GammaOffsetScreenshots=0.700000
HighDetailActors=True
MaxAnisotropy=4
UseAA=True
NumAASamples=4
UseVSync=Adaptive
NoBuffering=False
NoAATiles=True
NoFiltering=False
UseBufferInvalidation=True
GenerateMipMaps=False
OpenGLVersion=Core
;OpenGLVersion=ES
UsePersistentBuffers=False
MeshDetailTextures=False
MaxBindlessTextures=16384
UseBindlessTextures=True
UseBindlessLightmaps=False
GammaMultiplier=2.0
GammaMultiplierUED=2.0
ParallaxVersion=None
SimulateMultiPass=False
UseSRGBTextures=False
UseEnhancedLightmaps=True
UseShaderDrawParameters=True
UseOpenGLDebug=False
DebugLevel=2
NoDrawGouraud=False
NoDrawGouraudList=False
NoDrawComplexSurface=False
NoDrawTile=False
NoDrawSimple=False

[ALAudio.ALAudioSubsystem]
ALDevice=ALSADefault
OutputRate=44100Hz
SampleRate=44100Hz
SoundVolume=192
SpeechVolume=192
MusicVolume=192
EffectsChannels=64
AmbientFactor=0.700000
DopplerFactor=0.100000
bSoundAttenuate=True
MusicInterpolation=SPLINE
MusicDsp=DSP_ALL
MusicPanSeparation=50
MusicStereoMix=70
MusicAmplify=2
EmulateOldReverb=True
OldReverbIntensity=1.000000
ViewportVolumeIntensity=1.000000
ReverbIntensity=1.000000
UseAutoSampleRate=True
UseSpeechVolume=True
UseOriginalUnreal=True
UseDigitalMusic=True
UseReverb=True
UseHRTF=Autodetect
ProbeDevicesOnly=False
PreferredDevice=
DetectedDevices=Built-in Audio EstÃ©reo analÃ³gico
MusicStereoAngle=30
DetailStats=False

[SwFMOD.SwFMOD]
SoundVolume=192.000000
SpeechVolume=192.000000
MusicVolume=192.000000
AmbientFactor=0.700000
AmbientHysteresis=256.000000
SampleInterpolation=Spline
SampleFormat=PCMFLOAT
SampleRate=44100Hz
VirtualThreshold=0.000000
VirtualChannels=64
Channels=64
PriorityAmbient=192
PrioritySpeech=127
PrioritySound=255
PriorityMusic=0
HRTFFreq=4000.000000
HRTFMaxAngle=360.000000
HRTFMinAngle=180.000000
bHRTF=True
RolloffScale=1.000000
DistanceFactor=1.000000
DistanceMin=50.000000
DopplerScale=1.000000
ToMeters=0.020000
OverrideSpeakerMode=-1
OverrideDebugFlags=-1
OverrideInitFlags=-1
OverrideDSPBufferCount=-1
OverrideDSPBufferLength=-1
OverrideInputChannels=2
OverrideOutputChannels=-1
OverrideOutput=-1
MaxChannels=0
Driver=0
bOcclusion=True
LowSoundQuality=False
b3DCameraSounds=False
bPrecache=False
StatPositions=0
StatRender=0
StatChannels=0
StatChannelGroup=0
StatGlobal=0
bLogPlugins=0
EmulateOldReverb=True

[UMenu.UMenuNewGameClientWindow]
LastSelectedGame=Game.Game Intro1
LastSelectedSkill=1
bMutatorsSelected=False
bClassicChecked=True

[UnrealShare.VRikersGame]
DesiredMaxChannels=1024
InventoryDataIni=InventoryData
ServerSceneClass=
bNoMonsters=False
bHumansOnly=True
bCoopWeaponMode=False
bClassicDeathmessages=False

[Engine.GameReplicationInfo]
Region=0
ServerName=Unreal Server
ShortName=Unreal Server
AdminName=
AdminEmail=
MOTDLine1=
MOTDLine2=
MOTDLine3=
MOTDLine4=
ShowMOTD=False

[UPak.DuskFallsGame]
DesiredMaxChannels=1024
InventoryDataIni=InventoryData
ServerSceneClass=
bNoMonsters=False
bHumansOnly=True
bCoopWeaponMode=False
bClassicDeathmessages=True
EOF

msg "✔ UnrealLinux.ini criado!" \
    "✔ UnrealLinux.ini created!"

# Atualizar cache do sistema
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
gtk-update-icon-cache -f -t "$ICON_DIR" 2>/dev/null || true
xdg-desktop-menu forceupdate 2>/dev/null || true

msg "✔ Entrada no menu criada!" \
    "✔ Menu entry created!"

# Resumo final
echo ""
msg "══════════════════════════════════════════════════" \
    "══════════════════════════════════════════════════"
msg "    ✔ Instalação concluída com sucesso!" \
    "    ✔ Installation completed successfully!"
msg "══════════════════════════════════════════════════" \
    "══════════════════════════════════════════════════"
echo ""
msg "Versão instalada: Unreal (Gold) 64-bit" \
    "Installed version: Unreal (Gold) 64-bit"
msg "Patch aplicado: Unreal-testing-master (OldUnreal)" \
    "Applied patch: Unreal-testing-master (OldUnreal)"
echo ""
msg "Como jogar:" \
    "How to play:"
msg "  • Terminal: $LAUNCHER_NAME" \
    "  • Terminal: $LAUNCHER_NAME"
msg "  • Menu: Procure 'Unreal' nos seus aplicativos" \
    "  • Menu: Search 'Unreal' in your applications"
echo ""
msg "Localização: $GAME_LINUX_PATH" \
    "Location: $GAME_LINUX_PATH"
msg "Binário: $GAME_LINUX_PATH/System64/unreal-bin-amd64" \
    "Binary: $GAME_LINUX_PATH/System64/unreal-bin-amd64"
echo ""
msg "Divirta-se! 🎮" \
    "Have fun! 🎮"
echo ""
