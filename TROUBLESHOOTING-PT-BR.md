# Solução: Problemas com Unreal Gold nativo Linux (Patch Unreal Testing Master)

## Problemas Identificados
1. **Jogo não inicia** - Erro OpenGL: "SDL erro in create open gl context: could not created GL context"
2. **Sem áudio** - Música e efeitos sonoros não funcionam

## Ambiente
- **Sistema:** Linux Mint 22.1 (baseado em Ubuntu 24.04)
- **Jogo:** Unreal Gold com Patch **Unreal Testing Master** (não 227k)
- **Versão:** 64-bit (`~/UnrealGold/System64/`)
- **Executável:** `unreal-bin-amd64` (64-bit)

## Diagnóstico

### Problema 1: Erro OpenGL ao iniciar
**Erro exibido:**
```
XOpenGL: SDL erro in create open gl context: could not created GL context
```

### Problema 2: Verificar dependências de áudio faltantes
```bash
cd ~/UnrealGold/System64
ldd ALAudio.so | grep "not found"
```

**Resultado inicial:**
```
libxmp.so.4 => not found
libmpg123.so => not found
```

### Confirmar arquitetura dos binários
```bash
file unreal-bin-amd64
file ALAudio.so
file Core.so
file Engine.so
```

Todos devem ser **ELF 64-bit**.

## Solução

### PASSO 1: Corrigir erro OpenGL (necessário para o jogo iniciar)

**⚠️ IMPORTANTE:** O arquivo `UnrealLinux.ini` só é criado pelo jogo após a primeira tentativa de execução. Se o arquivo não existir ainda:

1. Execute o jogo uma vez (mesmo que dê erro):
```bash
cd ~/UnrealGold/System64
./UnrealLinux.bin
```

2. O jogo vai falhar, mas criará o arquivo `UnrealLinux.ini`

3. Agora prossiga com a edição abaixo:

Edite o arquivo de configuração:
```bash
nano ~/UnrealGold/System64/UnrealLinux.ini
```

Procure pela seção `[Engine.Engine]` e **modifique as linhas**:

**DE:**
```ini
[Engine.Engine]
;GameRenderDevice=OpenGLDrv.OpenGLRenderDevice
GameRenderDevice=XOpenGLDrv.XOpenGLRenderDevice
```

**PARA:**
```ini
[Engine.Engine]
GameRenderDevice=OpenGLDrv.OpenGLRenderDevice
#GameRenderDevice=XOpenGLDrv.XOpenGLRenderDevice
```

**Explicação:** O driver `XOpenGLDrv` não funciona corretamente em sistemas modernos. Use o `OpenGLDrv` padrão.

Salve o arquivo (`Ctrl+O`, `Enter`, `Ctrl+X` no nano).

**Teste se o jogo inicia agora:**
```bash
cd ~/UnrealGold/System64
./UnrealLinux.bin
```

O jogo deve iniciar, mas ainda sem áudio.

### PASSO 2: Corrigir o problema de áudio

### PASSO 2: Corrigir o problema de áudio

#### 2.1. Instalar bibliotecas necessárias
```bash
# libxmp já estava instalado (versão 64-bit)
dpkg -l | grep libxmp

# libmpg123 já estava instalado como libmpg123-0t64
dpkg -l | grep libmpg123
```

#### 2.2. Criar links simbólicos para as bibliotecas
```bash
cd ~/UnrealGold/System64

# Link para libxmp
ln -sf /usr/lib/x86_64-linux-gnu/libxmp.so.4 ./libxmp.so.4

# Link para libmpg123
ln -sf /usr/lib/x86_64-linux-gnu/libmpg123.so.0 ./libmpg123.so
```

#### 2.3. Verificar permissões de execução
```bash
chmod +x *.so unreal-bin-amd64
```

#### 2.4. Verificar se as dependências foram resolvidas
```bash
ldd ALAudio.so | grep "not found"
```

Não deve aparecer nada.

#### 2.5. Executar o jogo
```bash
cd ~/UnrealGold/System64
./UnrealLinux.bin
```

## Resultado
✅ **Jogo inicia corretamente** (sem erro OpenGL)  
✅ **Áudio funcionando completamente** (música e efeitos sonoros)

## Resumo Rápido

Para quem tem os mesmos problemas:

**1. Corrigir OpenGL (~/UnrealGold/System64/UnrealLinux.ini):**
```ini
[Engine.Engine]
GameRenderDevice=OpenGLDrv.OpenGLRenderDevice
#GameRenderDevice=XOpenGLDrv.XOpenGLRenderDevice
```

**2. Criar links para bibliotecas de áudio:**
```bash
cd ~/UnrealGold/System64
ln -sf /usr/lib/x86_64-linux-gnu/libxmp.so.4 ./libxmp.so.4
ln -sf /usr/lib/x86_64-linux-gnu/libmpg123.so.0 ./libmpg123.so
chmod +x *.so unreal-bin-amd64
```

**3. Executar:**
```bash
./UnrealLinux.bin
```

## Observações Importantes

### Arquivo UnrealLinux.ini
- **O arquivo `UnrealLinux.ini` só é criado após a primeira execução do jogo**
- Se o arquivo não existir, execute o jogo uma vez (mesmo que dê erro) para criá-lo
- Só depois disso você pode editá-lo para corrigir o problema do OpenGL

### Para versão 32-bit (~/UnrealGold/System/)
Se estiver usando a versão 32-bit, as bibliotecas necessárias são:
- `libxmp4:i386`
- `libmpg123-0:i386`

E os links devem apontar para:
- `/usr/lib/i386-linux-gnu/libxmp.so.4`
- `/usr/lib/i386-linux-gnu/libmpg123.so.0`

### Erro comum: Bibliotecas misturadas
Não misture bibliotecas 32-bit e 64-bit na mesma pasta. Use:
- **System/** → executável 32-bit + bibliotecas 32-bit
- **System64/** → executável 64-bit + bibliotecas 64-bit

### Verificar quais bibliotecas você tem instaladas
```bash
# Procurar libxmp
find /usr/lib -name "libxmp.so*" 2>/dev/null

# Procurar libmpg123
find /usr/lib -name "libmpg123.so*" 2>/dev/null
```

## Alternativa: Desabilitar música de módulos

Se não conseguir instalar as bibliotecas, você pode desabilitar a música tracker editando `~/UnrealGold/System64/UnrealLinux.ini`:

```ini
[Galaxy.GalaxyAudioSubsystem]
UseDigitalMusic=False
UseCDMusic=False
```

Ou mudar para outro driver de áudio:
```ini
[Engine.Engine]
AudioDevice=Audio.GenericAudioSubsystem
```

Isso manterá os efeitos sonoros funcionando, mas sem música.

## Créditos
Solução documentada após troubleshooting colaborativo em 23/11/2025.
