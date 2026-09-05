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
