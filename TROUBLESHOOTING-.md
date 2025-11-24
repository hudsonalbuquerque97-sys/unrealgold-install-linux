# Troubleshooting: Unreal Gold Native Linux Issues (Unreal Testing Master Patch)

## Identified Problems
1. **Game won't start** - OpenGL Error: "SDL erro in create open gl context: could not created GL context"
2. **No audio** - Music and sound effects don't work

## Environment
- **System:** Linux Mint 22.1 (based on Ubuntu 24.04)
- **Game:** Unreal Gold with **Unreal Testing Master** Patch (not 227k)
- **Version:** 64-bit (`~/UnrealGold/System64/`)
- **Executable:** `unreal-bin-amd64` (64-bit)

## Diagnosis

### Problem 1: OpenGL Error on Startup
**Error displayed:**
```
XOpenGL: SDL erro in create open gl context: could not created GL context
```

### Problem 2: Check for Missing Audio Dependencies
```bash
cd ~/UnrealGold/System64
ldd ALAudio.so | grep "not found"
```

**Initial result:**
```
libxmp.so.4 => not found
libmpg123.so => not found
```

### Confirm Binary Architecture
```bash
file unreal-bin-amd64
file ALAudio.so
file Core.so
file Engine.so
```

All should be **ELF 64-bit**.

## Solution

### STEP 1: Fix OpenGL Error (required for game to start)

**⚠️ IMPORTANT:** The `UnrealLinux.ini` file is only created by the game after the first execution attempt. If the file doesn't exist yet:

1. Run the game once (even if it errors):
```bash
cd ~/UnrealGold/System64
./UnrealLinux.bin
```

2. The game will fail, but it will create the `UnrealLinux.ini` file

3. Now proceed with the edit below:

Edit the configuration file:
```bash
nano ~/UnrealGold/System64/UnrealLinux.ini
```

Look for the `[Engine.Engine]` section and **modify the lines**:

**FROM:**
```ini
[Engine.Engine]
;GameRenderDevice=OpenGLDrv.OpenGLRenderDevice
GameRenderDevice=XOpenGLDrv.XOpenGLRenderDevice
```

**TO:**
```ini
[Engine.Engine]
GameRenderDevice=OpenGLDrv.OpenGLRenderDevice
#GameRenderDevice=XOpenGLDrv.XOpenGLRenderDevice
```

**Explanation:** The `XOpenGLDrv` driver doesn't work correctly on modern systems. Use the standard `OpenGLDrv`.

Save the file (`Ctrl+O`, `Enter`, `Ctrl+X` in nano).

**Test if the game starts now:**
```bash
cd ~/UnrealGold/System64
./UnrealLinux.bin
```

The game should start, but still without audio.

### STEP 2: Fix Audio Issue

#### 2.1. Install Required Libraries
```bash
# libxmp was already installed (64-bit version)
dpkg -l | grep libxmp

# libmpg123 was already installed as libmpg123-0t64
dpkg -l | grep libmpg123
```

#### 2.2. Create Symbolic Links for Libraries
```bash
cd ~/UnrealGold/System64

# Link for libxmp
ln -sf /usr/lib/x86_64-linux-gnu/libxmp.so.4 ./libxmp.so.4

# Link for libmpg123
ln -sf /usr/lib/x86_64-linux-gnu/libmpg123.so.0 ./libmpg123.so
```

#### 2.3. Verify Execution Permissions
```bash
chmod +x *.so unreal-bin-amd64
```

#### 2.4. Check if Dependencies Were Resolved
```bash
ldd ALAudio.so | grep "not found"
```

Nothing should appear.

#### 2.5. Run the Game
```bash
cd ~/UnrealGold/System64
./UnrealLinux.bin
```

## Result
✅ **Game starts correctly** (no OpenGL error)  
✅ **Audio working completely** (music and sound effects)

## Quick Summary

For those who have the same problems:

**1. Fix OpenGL (~/UnrealGold/System64/UnrealLinux.ini):**
```ini
[Engine.Engine]
GameRenderDevice=OpenGLDrv.OpenGLRenderDevice
#GameRenderDevice=XOpenGLDrv.XOpenGLRenderDevice
```

**2. Create links for audio libraries:**
```bash
cd ~/UnrealGold/System64
ln -sf /usr/lib/x86_64-linux-gnu/libxmp.so.4 ./libxmp.so.4
ln -sf /usr/lib/x86_64-linux-gnu/libmpg123.so.0 ./libmpg123.so
chmod +x *.so unreal-bin-amd64
```

**3. Run:**
```bash
./UnrealLinux.bin
```

## Important Notes

### UnrealLinux.ini File
- **The `UnrealLinux.ini` file is only created after the game's first execution**
- If the file doesn't exist, run the game once (even if it errors) to create it
- Only then can you edit it to fix the OpenGL problem

### For 32-bit Version (~/UnrealGold/System/)
If you're using the 32-bit version, the required libraries are:
- `libxmp4:i386`
- `libmpg123-0:i386`

And the links should point to:
- `/usr/lib/i386-linux-gnu/libxmp.so.4`
- `/usr/lib/i386-linux-gnu/libmpg123.so.0`

### Common Error: Mixed Libraries
Don't mix 32-bit and 64-bit libraries in the same folder. Use:
- **System/** → 32-bit executable + 32-bit libraries
- **System64/** → 64-bit executable + 64-bit libraries

### Check Which Libraries You Have Installed
```bash
# Search for libxmp
find /usr/lib -name "libxmp.so*" 2>/dev/null

# Search for libmpg123
find /usr/lib -name "libmpg123.so*" 2>/dev/null
```

## Alternative: Disable Module Music

If you can't install the libraries, you can disable tracker music by editing `~/UnrealGold/System64/UnrealLinux.ini`:

```ini
[Galaxy.GalaxyAudioSubsystem]
UseDigitalMusic=False
UseCDMusic=False
```

Or switch to another audio driver:
```ini
[Engine.Engine]
AudioDevice=Audio.GenericAudioSubsystem
```

This will keep sound effects working, but without music.

## Credits
Solution documented after collaborative troubleshooting on 11/23/2025.
