# Linux Combined US 1.2 Bring-up Checkpoint

Data do checkpoint: 5 de setembro de 2026

Branch: `port/linux-baseline`

Baseline anterior:

    7262ff9 linux: add Combined US 1.2 vanilla baseline

## Objetivo

Este checkpoint registra o primeiro bring-up nativo Linux do perfil
experimental Gran Turismo 2 Combined baseado no executável NTSC-U 1.2.

O perfil continua deliberadamente vanilla.

Os patches e enhancements específicos de GT2 atualmente validados para
NTSC-U 1.1 permanecem desabilitados.

## Identificação da revisão

Executável do Combined:

- Serial: SCUS-94488
- Entry PC: 0x8005D600
- Load address: 0x80010000
- Text size: 0x00099000
- SHA-1 do EXE Combined: 1021831c56ffb2617a6d6cebaa5694fcbc130583

A auditoria demonstrou que a reversão do patch de intro do Combined produz
exatamente o SHA-1 conhecido do executável NTSC-U 1.2:

    3030aa271c0a4022fc69ce09d76a6bc75e69a32a

Portanto, o perfil atual é tratado como:

    NTSC-U 1.2 base + Combined Disc patchset

## Estado do build nativo Linux

Confirmado:

- configuração nativa Linux do PSXRecomp
- psxrecomp-bios compilado
- psxrecomp-game compilado
- OpenBIOS recompilada
- SCUS_944.88 recompilado de MIPS para C
- runtime C/C++ compilado
- SDL inicializado
- OpenGL inicializado
- ELF Linux x86-64 linkado
- disco montado
- memory cards funcionando
- controle DualSense detectado
- debug server funcionando

Executável utilizado:

    titles/combined-us12/build-linux/Gran_Turismo_2_Combined_US_1_2_Recompiled

## Codegen atual

O baseline atual gerou aproximadamente:

- 2,5 GB de código C
- 944 arquivos C
- 746 avisos de reserved opcode
- 832 avisos de out-of-function
- 246 linhas de pre-pass

Esses avisos ainda não foram demonstrados como causa de erro de runtime.

Não alterar a estratégia de discovery apenas com base nesses números.

## Primeiro teste com timeout

O primeiro smoke test chegou à inicialização do runtime, mas terminou após
o wrapper aplicar sinais de encerramento.

Durante esse teste apareceu:

    malloc(): unsorted double linked list corrupted

Como o teste utilizava SIGINT seguido eventualmente de SIGKILL, esse resultado
não era suficiente para concluir que havia corrupção de heap durante a
execução normal.

Por isso foi executado um segundo diagnóstico sem timeout externo.

## Diagnóstico live

O runtime foi executado normalmente e observado por aproximadamente
30 segundos.

### T+2 segundos

Processo vivo.

Debug server ainda não aceitava conexão.

### T+5 segundos

Processo vivo.

Debug server ainda não aceitava conexão.

### T+10 segundos

Processo vivo.

Debug server ainda não aceitava conexão.

### T+20 segundos

Debug server disponível.

Estado observado:

    frame        = 91
    COP0 EPC     = 0xBFC05784
    COP0 SR      = 0x40000401
    I_MASK       = 0x0000000C
    I_STAT       = 0x00000001

O runtime ainda estava executando código da BIOS/kernel.

### T+30 segundos

Estado observado:

    frame        = 734/735
    COP0 EPC     = 0x8007C558
    COP0 SR      = 0x40000401
    COP0 CAUSE   = 0x00000400
    I_MASK       = 0x0000008D
    I_STAT       = 0x00000001
    RA           = 0x8007AB3C
    SP           = 0x801FFE58

O endereço 0x8007C558 está dentro do espaço carregado do executável GT2.

Isso confirma que o runtime:

    OpenBIOS
        ->
    kernel PS1
        ->
    SCUS_944.88
        ->
    código do GT2

## Heap

Antes do encerramento controlado:

    PREQUIT_ALIVE=1
    PREQUIT_MALLOC_CORRUPTION=0
    PREQUIT_OTHER_HEAP_ERRORS=0

Classificação:

    ACTIVE_RUNTIME_STATUS=ALIVE_AND_NO_HEAP_ERROR_BEFORE_QUIT
    HEAP_CORRUPTION_PHASE=NOT_OBSERVED

Portanto não existe, neste checkpoint, evidência de corrupção de heap durante
a execução normal do jogo.

Não iniciar investigação ASan baseada somente no primeiro teste com timeout.

## Encerramento

O comando `quit` do debug server respondeu:

    {"ok":false,"err":"emu busy or frozen"}

Mesmo assim, posteriormente o processo terminou com:

    RUNTIME_EXIT_CODE=0
    FORCED_TERM=0
    FORCED_KILL=0

O processo portanto não precisou de SIGTERM ou SIGKILL.

A relação entre a resposta `emu busy or frozen` e a saída posterior com
código zero ainda deve ser investigada futuramente.

## Uso de memória observado

Por volta de 30 segundos:

- VmRSS: aproximadamente 527 MB
- VmData: aproximadamente 1,98 GB
- Threads: 7

Ainda não há evidência suficiente para classificar isso como vazamento.

## Status dos milestones

PASS:

- identificar revisão Combined US 1.2
- compilar recompiler Linux
- recompilar OpenBIOS
- recompilar SCUS_944.88 para C
- linkar runtime Linux x86-64
- iniciar runtime Linux
- inicializar OpenGL
- detectar DualSense
- montar disco
- entrar no espaço de código do GT2

PENDENTE:

- confirmar visualmente a tela inicial
- confirmar menu principal
- navegar nos menus
- carregar overlay de corrida
- iniciar primeira corrida
- validar vídeo durante corrida
- validar áudio
- validar input durante gameplay

## Próxima sessão

Retomar utilizando o runtime já compilado antes de regenerar o codegen de
2,5 GB.

Ordem recomendada:

1. Executar o runtime atual.
2. Manter PSX_OVERLAY_AUTOCOMPILE_OFF=1.
3. Esperar pelo menos 20 segundos para o debug server ficar disponível.
4. Observar visualmente a janela.
5. Registrar screenshot do primeiro conteúdo renderizado.
6. Consultar PC, EPC, frame e registradores.
7. Determinar se chegou à tela inicial ou ao menu.
8. Se houver travamento, identificar primeiro o PC guest.
9. Só então revisar seeds/discovery.
10. Não ativar patches GT2 NTSC-U 1.1.

Variável para o primeiro bring-up:

    export PSX_OVERLAY_AUTOCOMPILE_OFF=1

## Limite atual do milestone

Este checkpoint comprova:

    GT2 Combined NTSC-U 1.2
        ->
    MIPS para C
        ->
    PSXRecomp
        ->
    OpenBIOS
        ->
    SDL/OpenGL
        ->
    Linux x86-64
        ->
    execução de código GT2

Ele ainda não comprova menu funcional ou primeira corrida.

A criação de uma Platform API e o port para Nintendo Switch devem continuar
depois da validação do primeiro menu e da primeira corrida no Linux.

## Playable Linux baseline checkpoint

Checkpoint: 2026-09-05

The Combined NTSC-U 1.2 Linux profile has now progressed beyond initial
bring-up and is confirmed playable in Arcade Mode.

Validated during interactive native Linux sessions:

- visible GT2 title sequence
- Arcade Mode title/menu
- Game Selection
- Level Selection
- Car Selection
- Course Selection
- Starting Grid
- Road Race gameplay
- Rally gameplay
- replay rendering
- DualSense gameplay input
- HUD and 3D rendering
- CD-ROM streaming
- XA sector delivery
- repeated gameplay transitions
- approximately eight minutes of continuous runtime testing
- clean process exit
- no fatal/runtime/dispatch exception detected by the diagnostic filter

The full-cycle diagnostic finished near frame 26280 with active 3D
rendering and active CD/XA traffic.

The runtime completed with:

    RUNTIME_ERROR_COUNT=0
    RUNTIME_EXIT_CODE=0
    FORCED_TERM=0
    FORCED_KILL=0

### Memory-card status

Both 128 KiB memory-card images were detected successfully.

Slot 1 was loaded with four occupied blocks, which confirms that existing
card data can be recognized.

The memory-card hashes did not change during the full-cycle diagnostic:

    CARD1_CHANGED=NO
    CARD2_CHANGED=NO

Therefore memory-card reading is considered operational, but an intentional
save/write/load cycle still needs to be tested.

### Performance backlog

The runtime remains functionally playable but visible stutter has been
reported during gameplay.

Performance work is intentionally deferred until the vanilla functional
baseline is complete.

Items to investigate later include:

- frame pacing
- CPU usage
- GPU usage
- internal resolution scale
- current 5x renderer configuration
- debug/instrumentation overhead
- page faults and resident code growth
- generated-code working set
- OpenGL synchronization
- scheduler behavior
- CD/XA streaming stalls

Resident memory grew substantially during the longer tests while VmData
eventually stabilized. This is not yet classified as a memory leak.

### Current milestone status

Confirmed:

    Native Linux build       PASS
    OpenBIOS boot            PASS
    GT2 executable           PASS
    Visible presentation     PASS
    Menus                    PASS
    Arcade Mode              PASS
    Road Race                PASS
    Rally                    PASS
    Replay                   PASS
    Gameplay input           PASS
    Multi-minute stability   PASS

Still pending:

    Simulation Mode          PENDING
    Save write/load          PENDING
    Audio validation         PENDING
    Long soak                PENDING

The project should preserve this vanilla baseline before enabling
revision-specific enhancements or introducing portability abstractions.

## Memory-card save persistence checkpoint

Checkpoint date: 2026-09-05

The Linux NTSC-U 1.2 Combined baseline has now passed an intentional
memory-card write and process-restart persistence test.

Initial slot-1 card:

    size             = 131072 bytes
    occupied blocks  = 4
    SHA-256          = 8d30ee9396b7e6eaeea941119990a689d9640e187ce002afab1330d73ff46998

After the first interactive session:

    size             = 131072 bytes
    SHA-256          = b9c797086bdd0053921b7a340c1585db9d9b2b662a9bea1e092ecc3940d5cc01

The changed hash proves that the card image was modified by the runtime/game
session.

After a complete runtime shutdown and restart, slot 1 was loaded as:

    occupied blocks  = 7

and retained exactly the same post-save SHA-256:

    b9c797086bdd0053921b7a340c1585db9d9b2b662a9bea1e092ecc3940d5cc01

Therefore the following paths are now confirmed:

    existing card read       PASS
    game card write          PASS
    host file persistence    PASS
    reload after restart     PASS

Slot 2 remained unchanged, as expected.

Both test processes exited cleanly:

    SESSION_A_ERROR_COUNT = 0
    SESSION_B_ERROR_COUNT = 0

    SESSION_A_EXIT_CODE   = 0
    SESSION_B_EXIT_CODE   = 0

No SIGTERM or SIGKILL was required.

The diagnostic classified the result as:

    SAVE_WRITE_STATUS       = PASS
    SAVE_FILE_PERSISTENCE   = PASS
    RUNTIME_STABILITY       = PASS

Backups of the pre-test memory cards were retained in the local audit
directory and are intentionally not version-controlled.

### Remaining functional validation

Before declaring the Linux vanilla baseline broadly validated, the following
items remain useful:

- explicit Simulation Mode workflow checkpoint
- audio/music/SFX validation
- longer-duration soak

Performance optimization is now an independent workstream.

Known performance observations to investigate later include:

- visible gameplay stutter
- frame pacing
- current internal renderer scale of 5x
- CPU/GPU utilization
- generated-code working set
- resident-memory growth/page faults
- debug-tool overhead
- OpenGL synchronization
- scheduler behavior
- CD/XA streaming stalls

Do not mix these optimization experiments with revision-specific gameplay
patches until a performance baseline has been measured.
