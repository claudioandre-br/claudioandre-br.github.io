;**********************************************************************
; Arquivo:	    pTeste.asm                                            *
; Versão:		0.8                                                   *
;                                                                     *
; Criado em:	05/07/2004                                            *
; Autor:		Claudio André                                         *
;**********************************************************************
; Arquivos requeridos (Files required):                               *
; - P16f84A.inc                                                       *
; - Eprom.h                                                           *
;**********************************************************************
; O código presente neste programa é licenciado nos termos da         *
; licença GNU GPL.                                                    *
;                                                                     *
; This source code is licenced under the GNU General Public License   *
; terms.                                                              *
;                                                                     *
; '00000'. Turn off all leds. Apagar todos os leds.                   *
; '00001'. Turn on odd leds. Acender leds ímpares.                    *
; '00010'. Turn on even leds. Acender leds pares.                     *
; '00011'. Turn on all leds. Acender todos os leds.                   *
; '00100'. Count. Contador                                            *
; '00101'. Move "leds" from left to right. Mover luz esq. para dir.   *
; '00110'. Move "leds" from right to left. Mover luz dir. para esq.   *
; '01000'. Do all functions. Executar todas as funções.               *
; '01001'. Count from 0 to 9. Contar de 0 a 9.                        *
; '01010'. Count from 9 to 0. Contar de 9 a 0.                        *
; '01100'. Reset count at eeprom. Zerar contador na eeprom            *
; '1xxxx'. Turn on leds according to PortA values.                    *
;		   Acender leds conforme interruptores na Porta A.            *
;**********************************************************************

; Define processor and include processor variables.
; Define o processador e "include" de suas variáveis.
; Include extern routines definitions. Inclui definição das rotinas externas.
	List 	 p=16f84A
	#include "P16F84A.inc"
	#include "Eprom.h"

; This '__CONFIG' directive is used to embed configuration data within .asm file.
; A diretiva '__CONFIG' é usada para introduzira palavra de configuração no arquivo .asm.
;	__CONFIG _CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC

; Variable definitions.
; Definição das variáveis.
	UDATA
varPortaA		RES	1
varFeito		RES	1
varFazTudo		RES	1
varIndiceTodas	RES	1
varContador		RES	1
varTempW		RES	1
varTempStatus	RES	1
varTempo		RES	1
varTempo1		RES	1
varTempo2		RES	1
varPosicaoLuz	RES	1
varFlagControle	RES	1

;Auxiliary variables. Variáveis auxiliares.
varAuxiliar1	RES	1
varAuxiliar2	RES	1

; Constants definitions.
; Definição das constantes. 
	constant conLimite = 0x007

; *********************************************************************

; Processor reset vector
; Posição do vector de reset
    org 	0x000
    goto	Main

; Interrupt vector location, if any.
; Posição do vector de interrupção, se definada(s).
	org		0x004
	goto	TrataEvento

; Reorganize main rotine address.
; Forçar endereço de início do programa principal.
 	org     0x005	

; Program startup.
; Início do programa.
Main
	;Set PortA as input and PortB as output.
	;Configurar Porta A como entrada.
	;			Porta B como saida.
	bsf		STATUS, RP0
	clrf	TRISB
	movlw 	b'00011111'
	movwf 	TRISA

	;Interrupt TMR0.
	;Habilitar interrupção TMR0.
	bsf		INTCON, T0IE

	;Divide frequency of TMR0 by 256.
	;Ajustar o divisor de frequência de TMR0 em 256.
	movlw	b'00000111'
	movwf	OPTION_REG
	
	bcf		STATUS, RP0

	;Inicialize variable. Inicializar variável.
	clrf	varFazTudo
	clrf	varFlagControle
	bsf		varPortaA, 0x006

	;Read saved data in eeprom. Ler contador salvo na eeprom.
	movlw	0x010  ;Address in eeprom. Endereço na eeprom.
	call	LerEeprom

	;Done. Data is at W. Lido, valor está em W.
	movwf	varContador

	;First time execution. Execução inicial.
	movlw	0x008
	movwf	varPosicaoLuz

	;Start up. Turn off all leds.
    ;Inicialização. Apagar todos os leds.
	clrf	PORTB

Loop
	;Avoid rebote. Evitar o efeito rebote.
	call	AntiRebote

	;Check if there is something to do. Verificar se há algo a fazer.
	movfw 	varPortaA
	subwf	PORTA, W
	btfsc	STATUS, Z
	goto 	Loop

	;Avoid rebote. Evitar o efeito rebote.
	call	AntiRebote

	;If working on "all tasks", varPortaA <> PORTA.
	;So, start processing only when its time to do another task.
	;Se estiver executando "todas tarefas", varPortaA <> PORTA sempre.
	;Portanto, apenas seguir processando se for uma nova tarefa.
	btfsc	varFazTudo, 0x005
	goto	Loop

	;There is something to do. Realizar a tarefa solicitada.
	clrf	varFeito

	;Check if processing "doing all". Verificar se está executando "faça tudo".
	movf 	varFazTudo, F
	btfsc	STATUS, Z
	call	SalvaEntrada

	;'00000'.
	;Turn off all leds. Apagar todos os leds.
    movf	varPortaA, F
	btfsc	STATUS, Z
	call	ApagaLeds

	;'00001'.
	;Turn on odd leds. Acender leds ímpares.
    movfw	varPortaA
	xorlw	b'00000001'
	btfsc	STATUS, Z
	call	AcendeImpar

	;'00010'.
	;Turn on even leds. Acender leds pares.
    movfw	varPortaA
	xorlw	b'00000010'
	btfsc	STATUS, Z
	call	AcendePar

    ;'00011'.
	;Turn on all leds. Acender todos os leds.
    movfw	varPortaA
	xorlw	b'00000011'
	btfsc	STATUS, Z
	call	AcendeTodos

	;'00100'. 
    ;Count from 0 to 9. Controla contagem de 0 a 9.
    movfw	varPortaA
	xorlw	b'00000100'
	btfsc	STATUS, Z
	call	ContaLiga

	;'00101'.
	;Move light leds from left to right. Mover luz nos leds da esq. para dir.
    movfw	varPortaA
	xorlw	b'00000101'
	btfsc	STATUS, Z
	call	AcendeLeds

	;'00110'.
	;Move light leds from right to left. Mover luz nos leds da dir. para esq. 
    movfw	varPortaA
	xorlw	b'00000110'
	btfsc	STATUS, Z
	call	AcendeLeds

	;'01000'.
	;Do all functions. Executar todas as funções.
    movfw	varPortaA
	xorlw	b'00001000'
	btfsc	STATUS, Z
	call	ExecutaTodas

	; '01001'.
	;Count from 0 to 9, with a 1s interval. Contar de 0 a 9 com intervalo de 1s.
    movfw	varPortaA
	xorlw	b'00001001'
	btfsc	STATUS, Z
	call	ContaTempo

	;'01010'.
	;Count from 9 to 0, with a 1s interval. Contar de 9 a 0 com intervalo de 1s.
    movfw	varPortaA
	xorlw	b'00001010'
	btfsc	STATUS, Z
	call	ContaTempo

	;'01100'.
	;Reset count value saved in eeprom. Zerar contador salvo na eeprom.
    movfw	varPortaA
	xorlw	b'00001100'
	btfsc	STATUS, Z
	call	LimpaEeprom

	;'1xxxx'.
	;Turn on leds according to varPortaA values. Acender leds conforme varPortaA.
	btfsc 	varPortaA, 0x004
	call	ReplicaAemB

	;No valid selecion. Seleção inválida.
	movf 	varFeito, F
	btfsc	STATUS, Z
	call	MostraErro

	;If working on "all tasks", varPortaA <> PORTA.
	;Then, set that the task selected is done.
	;Se estiver executando "todas tarefas", varPortaA <> PORTA sempre.
	;Portanto, informar que a tarefa solicitada foi concluida.
	btfss	varFazTudo, 0x001
	goto 	Loop

	;If starting "doing all", its not time to set task as done.
	;Se iniciando "todas tarefas", não setar tarefa como concluida.
	btfss	varFazTudo, 0x002  
	bsf		varFazTudo, 0x005

	;Not starting "doing all". Clean control bit.
	;Não mais iniciando "todas tarefas". Limpar bit de controle.
	bcf		varFazTudo, 0x002

	;Start again. Reiniciar o processamento.
	goto 	Loop


; Get the PortA setting and save it in the memory position used to control the program.
; Salva o valor da PortA em varPortaA usada para controlar a rotina a ser executada.
SalvaEntrada
	movfw	PORTA
	movwf	varPortaA

	;Disable interrupt (its possible to be set on by the previous routine).
	;Desabilitar interrupções, que podem ter sido habilitadas por outra rotina.
	bcf		INTCON, GIE

	return


; Return the mask used to display the number received in the parameter.
; Retorna a máscara para o display do número recebido como parâmetro.
ConverteDigito
	addwf	PCL, F		; Jump using the number in W. Posiciona conforme o número em W.
	retlw	b'00111111'	;0
	retlw	b'00000110'	;1
	retlw	b'01011011'	;2
	retlw	b'01001111'	;3
	retlw	b'01100110'	;4
	retlw	b'01101101'	;5
	retlw	b'01111101'	;6
	retlw	b'00000111'	;7
	retlw	b'01111111'	;8
	retlw	b'01101111'	;9


; Turn off all leds. 
; Apagar todos os leds.
ApagaLeds
	clrf 	PORTB

	;Processed. Processado.
 	bsf		varFeito, 0x006

	return

; Turn on odd leds.
; Acender leds ímpares.
AcendeImpar
    movlw	b'01010101'
	movwf 	PORTB

	;Processed. Processado.
 	bsf		varFeito, 0x006

	return


; Turn on odd leds.
; Acender leds ímpares.
AcendePar
    movlw	b'10101010'
	movwf 	PORTB

	;Processed. Processado.
 	bsf		varFeito, 0x006

	return


; Count RA3 from 0 to 9. 
; Controla contagem de RA3 entre 0 a 9.
ContaLiga
	incf	varContador, F	;Get the next number. Incrementar.

	;More than one digit. Mais de um dígito.
	movfw 	varContador
	sublw	0x00A
	btfsc	STATUS, Z
	clrf	varContador

	;Get the number mask and show it. ;Obtém a máscara e apresenta o número.
	movfw	varContador
	call	ConverteDigito
	movwf	PORTB

	;Save data in eeprom. Salvar contador na eeprom.
	movfw	varContador
	movwf	EEDATA  ;Data to save. Dado a ser salvo.
	movlw	0x010  ;Address in eeprom. Endereço na eeprom.
	call	GravarEeprom

	;Processed. Processado.
 	bsf		varFeito, 0x006

	return


; Move light leds from left to right (right to left), using a 1s interval.
; Mover a luz nos leds da esquerda para direita (direita para esquerda) com intervalo de 1s.
AcendeLeds
	;Allow this routine to be called by "doing all". 
	;Permite que esta rotina seja executada pela "executa todas funções"
	bsf		varFlagControle, 0x001

	call	MostraLuz

	;Start timer. Inicializa o timer.
	call	IniciaTimer

	;Processed. Processado.
 	bsf		varFeito, 0x006

	return


; Do all tasks/functions.
; Executar todas as funções.
ExecutaTodas
	clrf	varIndiceTodas

	bsf		varFazTudo, 0x001
	call	ImprementaExecutaTodas

	;Starting "doing all". Set control bit.
	;Iniciando "todas tarefas". Ligar o bit de controle.
	bsf		varFazTudo, 0x002

	;Clear flag of time controled functions. Limpa flag de controle de funções que usam timer.
	clrf	varFlagControle

	;Start timer. Inicializa o timer.
	call	IniciaTimer

	;Processed. Processado.
 	bsf		varFeito, 0x006

	return

; Count from 0 to 9 (9 to 0), with a 1s interval.  
; Contar de 0 a 9 (9 a 0) com intervalo de 1s, entre os números.
ContaTempo
	;Allow this routine to be called by "doing all". 
	;Permite que esta rotina seja executada pela "executa todas funções"
	bsf		varFlagControle, 0x001

	call	AutoConta

	;Start timer. Inicializa o timer.
	call	IniciaTimer

	;Processed. Processado.
 	bsf		varFeito, 0x006

	return


; Reset count value saved in eeprom. 
; Zerar contador salvo na eeprom.
LimpaEeprom
	clrf	varContador

	;Save data in eeprom. Salvar contador na eeprom.
	movfw	varContador
	movwf	EEDATA  ;Data to save. Dado a ser salvo.
	movlw	0x010  ;Address in eeprom. Endereço na eeprom.
	call	GravarEeprom

	;Get the number mask and show it. ;Obtém a máscara e apresenta o número.
    movlw	b'11111101'	;G.
	movwf 	PORTB

	;Processed. Processado.
 	bsf		varFeito, 0x006

	return


; Turn on all leds.
; Acender todos os leds.
AcendeTodos
    movlw	b'11111111'
	movwf 	PORTB

	;Processed. Processado.
 	bsf		varFeito, 0x006

	return


; Turn on leds according to varPortaA values.
; Acender leds conforme valores em varPortaA.
ReplicaAemB
    movfw	varPortaA
	movwf 	PORTB

	;Processed. Processado.
 	bsf		varFeito, 0x006

	return


; Show the error message, no funcion selected.
; Mostrar mensagem de erro, nenhuma função válida selecionada.
MostraErro
    movlw	b'11111001'	;E.
	movwf 	PORTB

	;Processed. Processado.
 	bsf		varFeito, 0x006

	return


; Using software, avoid rebote. Wait 20,5ms
; Rotina de software que objetiva evitar o efeito rebote. Temporiza 20,5ms
AntiRebote
	movlw	0x0B0	;Count (256-176) 80 times. Contar (80 * 256) vezes.
	movwf	varTempo1

ContaExterna
	incfsz	varTempo1, F
	goto 	ContaInterna
	goto	FinalAtraso

ContaInterna
	clrf	varTempo2

ProcessoInterno
	incfsz	varTempo2, F
	goto	ProcessoInterno
	goto	ContaExterna

FinalAtraso
	return


; Interrupt routine.
; Rotina de tratamento de interrupção
TrataEvento
	;Save working information.
	;Salvar informações de trabalho.
	movwf   varTempW
	movfw	STATUS
	movwf	varTempStatus

	;Select bank 0. Selecionar banco 0.
	bcf		STATUS, RP0

	;Check if processing "doing all". Verificar se está executando "faça tudo".
	movf 	varFazTudo, F
	btfsc	STATUS, Z
	goto 	ProcessaEvento

	;Doing all tasks/functions.
	;Executando todas as funções.
    movfw	PORTA  ; Did the selection change ? Usuário alterou seleção nos switches ?
	xorlw	b'00001000'
	btfsc	STATUS, Z
	goto	ProcessaEvento

; The selection changed. Seleção de switches foi alterada.
NovaSelecao
	clrf	varFazTudo
	bsf		varPortaA, 0x006  ; Force a selection. Processa obrigatóriamente uma seleção.

	goto	FimEvento

; Controling the delay.
; Controlando o intervalo de tempo.
; 1s =((4 * 250ns * (256 - 12) * 256) * 16).
ProcessaEvento
	decfsz	varTempo, F
	goto	ReiniciarTempo

FinalizouTempo
	;Time finished, restart control bytes.
	;Tempo atingido, reiniciarlizar os registros de controle.
	movlw	0x010	;16
	movwf	varTempo

	;If doing time controled funcions, check if they have finished.
	;Garante que rotinas controladas pelo tempo foram concluidas antes de executar "doing all".
	movf	varFlagControle, F	
	btfsc	STATUS, Z
	goto	VerificaSeTodas

	;Select the task that should be done.
	;Selecionar a tarefa que deve ser feita.

    movfw	varPortaA
	xorlw	b'00000101'  ; -> .
	btfsc	STATUS, Z
	call 	MostraLuz

    movfw	varPortaA  
	xorlw	b'00000110'  ; <- .
	btfsc	STATUS, Z
	call 	MostraLuz

    movfw	varPortaA
	xorlw	b'00001001'  ; 0 -> 9.
	btfsc	STATUS, Z
	call 	AutoConta

    movfw	varPortaA  
	xorlw	b'00001010'  ; 9 -> 0.
	btfsc	STATUS, Z
	call 	AutoConta

	goto 	ReiniciarTempo

; Execute the task related to "doing all functions". 
; Executar a tarefa que se aplicar a rotina "todas as funções".
VerificaSeTodas
	call 	ImprementaExecutaTodas

; Preparing to delay 62,4ms.
; Inicializando para aguardar 62,4ms.
ReiniciarTempo
	movlw	0x00C	;Count (256-12) 244 times. Contar 244 vezes.
	movwf	TMR0
	bcf		INTCON, T0IF
	
; Restore previous working information.
; Restaurar informações de trabalho anteriores.
FimEvento
	movfw	varTempStatus
	movwf	STATUS
	swapf   varTempW, F  ;Swapf do not affect STATUS. Swapf não altera STATUS.
	swapf   varTempW, W 

	retfie


; Do all tasks/functions implementation routine.
; Rotina que permite que todas as funções sejam executadas.
ImprementaExecutaTodas
	call	CaseFazTudo
	movwf	varPortaA

	;Set that the task have to be done.
	;Informar que a tarefa solicitada deve ser executada.
	bcf		varFazTudo, 0x005

	;Get the next number. Incrementar.
	incf 	varIndiceTodas, F

	;All tasks executed? Todas rotinas foram executadas?
	movfw 	varIndiceTodas
	sublw	conLimite
	btfsc	STATUS, Z
	clrf	varIndiceTodas

	return


; Execute a case statement using varIndiceTodas as task selector.
; Executa um case usando varIndiceTodas como indice de tarefa a executar.
CaseFazTudo
	movfw	varIndiceTodas
	addwf	PCL, F		;Jump using varIndiceTodas. Posiciona conforme varIndiceTodas.
	retlw	b'00000001'	;Turn on odd leds. Acender leds ímpares.
	retlw	b'00000010'	;Turn on even leds. Acender leds pares.
	retlw	b'00000011'	;Turn on all leds. Acender todos os leds.
	retlw	b'00000110' ;Move "leds" from right to left. Mover luz dir. para esq.
	retlw	b'00000101' ;Move "leds" from left to right. Mover luz esq. para dir.
	retlw	b'00001001' ;Count from 0 to 9. Contar de 0 a 9.
	retlw	b'00001010' ;Count from 9 to 0. Contar de 9 a 0.


; Start timer, in order to delay 1s.
; Inicia contador de tempo para 1s.
IniciaTimer
	movlw	0x010	;16
	movwf	varTempo
	bcf		INTCON, T0IF
	bsf		INTCON, GIE  ;Allow interrupt. Permitir interrupção.

	return


; Light on the leds, moving the led is on during the time.
; The current value of varPosicaoLuz is the displayed by the leds.
; Acende os leds alternadamente no tempo, movendo qual deles está aceso.
; O valor de varPosicaoLuz é a mostrada nos leds.
MostraLuz
	;Check what have to be done. O que fazer?
	btfsc	varPortaA, 0x000
	goto	Esquerda  ;From left to right. Esquerda para direita.
	goto	Direita   ;From right to left. Direita para esquerda.

Direita
	incf 	varPosicaoLuz, F	;Get the next position. Incrementar posição.

	;First time execution. Execução inicial.
	movfw 	varPosicaoLuz
	sublw	0x009
	btfsc	STATUS, Z
	clrf	varPosicaoLuz

	;All leds where processed. Todos os leds foram processados.
	movfw 	varPosicaoLuz
	sublw	0x008
	btfsc	STATUS, Z
	clrf	varPosicaoLuz

	;The last led to be processed. Ultimo led a ser processado.
	movfw 	varPosicaoLuz
	sublw	0x007
	btfss	STATUS, Z
	goto	FinalMostra

	;Finished. Finalizado.
	goto	VerificaFlagPosicao

Esquerda
	movf 	varPosicaoLuz, F  ;varPosicaoLuz = 0 ?
	btfsc	STATUS, Z
	goto	AjustaPosicao

	decfsz 	varPosicaoLuz, F  ;Get the previous position. Decrementar posição.
	goto	FinalMostra

	;The last led to be processed. Ultimo led a ser processado.
	goto	VerificaFlagPosicao

AjustaPosicao
	movlw	0x007 ;
	movwf	varPosicaoLuz  ;varPosicaoLuz = 07.
	goto	FinalMostra

; Doing "all tasks". Finished counting? Clean flag.
; Executando "todas tarefas". Concluida contagem? Limpar flag.
VerificaFlagPosicao
	movf 	varFazTudo, F  ;Doing all tasks/functions. ;Executando todas as funções.
	btfsc	STATUS, Z
	goto	FinalMostra

	;All leds where processed. Todos os leds foram processados.
	;Finished, clean flag. Concluida contagem, limpar flag.
	clrf	varFlagControle 

	;Restart varPosicaoLuz. Reiniciar varPosicaoLuz.
	;From left to right. Esquerda para direita.
	btfss	varPortaA, 0x000
	goto	FinalMostra  ;Its done. Feito.

	;Get the led to turn on. Obtém o led que deve ser aceso.
	call	CaseSelecionaLed
	movwf	PORTB

	;Set the value. Ajustar variável.
	movlw	0x008  ;From left to right. Esquerda para direita.
	movwf	varPosicaoLuz

	goto	FinalLuz

FinalMostra
	;Get the led to turn on. Obtém o led que deve ser aceso.
	call	CaseSelecionaLed
	movwf	PORTB

FinalLuz
	return


; Count from 0 to 9 (9 to 0) automatically, using a 1s interval to increment/decrement.
; Conta automaticamente de 0 a 9. Usa 1s de intervalo para somar/subtrair.
AutoConta
	;Check what have to be done. O que fazer?
	btfsc	varPortaA, 0x000
	goto	Crescente  	;Get the next number.
	goto	Decrescente ;Get the previous number.

Crescente
	incf 	varContador, F	;Get the next number. Incrementar.

	;More than one digit. Mais de um dígito.
	movfw 	varContador
	sublw	0x00A
	btfsc	STATUS, Z
	clrf	varContador

	goto 	VerificaFlagConta

Decrescente
	movf 	varContador, F  ; varContador = 0 ?
	btfsc	STATUS, Z
	goto	AjustaNumero

	decf 	varContador, F	;Get the previous number. Decrementar.
	goto	VerificaFlagConta

AjustaNumero
	movlw	0x009
	movwf	varContador  ; varContador = 09.
	goto	FinalConta

VerificaFlagConta
	;Doing "all tasks". Finished counting? Clean flag.
	;Executando "todas tarefas". Concluida contagem? Limpar flag.
	movf 	varContador, F  ; varContador = 0 ?
	btfss	STATUS, Z
	goto	FinalConta

	movf 	varFazTudo, F  ;Doing all tasks/functions. ;Executando todas as funções.
	btfss	STATUS, Z
	clrf	varFlagControle  ;Finished, clean flag. Concluida contagem, limpar flag.

FinalConta
	;Get the number mask and show it. ;Obtém a máscara e apresenta o número.
	movfw	varContador
	call	ConverteDigito
	movwf	PORTB

	return


; Simule a case statement using varPosicaoLuz to obtain the led configurarion.
; Its not possible (yet) to add PCL value. PCLATH value doesn´t point the right address.
; Simula um case usando varPosicaoLuz como indice para configuração dos leds.
; Não foi possível (ainda) somar PCL. O valor de PCLATH não se mantém adequado.
CaseSelecionaLed

	;Initialize loop control. Inicializa para executar looping.
	movfw	varPosicaoLuz 
	movwf	varAuxiliar1
	movlw	b'00000001'
	movwf	varAuxiliar2

	;Clear carry.
	bcf		STATUS, C

	;Finished? Feito?
	movf	varAuxiliar1, F
	btfsc	STATUS, Z
	goto 	FinalCase

LoopCase
	rlf		varAuxiliar2, F
	decfsz	varAuxiliar1, F
	goto	LoopCase

FinalCase
	movfw	varAuxiliar2
	return


	end
