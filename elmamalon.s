;*******************************************************************************
;   UNIVERSIDAD DEL VALLE DE GUATEMALA
;   IE2023 PROGRAMACIÓN DE MICROCONTROLADORES 
;   AUTOR: JORGE SILVA
;   COMPILADOR: PIC-AS (v2.36), MPLAB X IDE (v6.00)
;   PROYECTO: PROYECTO 1
;   HARDWARE: PIC16F887
;   CREADO: 30/08/2022
;   ÚLTIMA MODIFCACIÓN: 09/09/2022
;*******************************************************************************
PROCESSOR 16F887
#include <xc.inc>
;*******************************************************************************
;Palabra de configuración generada por MPLAB
;*******************************************************************************
; PIC16F887 Configuration Bit Settings

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT 
  CONFIG  WDTE = OFF            
  CONFIG  PWRTE = ON           
  CONFIG  MCLRE = OFF           
  CONFIG  CP = OFF              
  CONFIG  CPD = OFF             
  CONFIG  BOREN = OFF           
  CONFIG  IESO = OFF            
  CONFIG  FCMEN = OFF           
  CONFIG  LVP = OFF             

; CONFIG2
  CONFIG  BOR4V = BOR40V        
  CONFIG  WRT = OFF    
  
;*******************************************************************************
;MACRO
;*******************************************************************************
resetTMR0 macro
    banksel	PORTD
    movlw	132		    ;Valor N calculado para delay de 2ms
    movwf	TMR0               
    bcf		INTCON, 2           ;Apagamos la interrupción del TMR0
endm

resetTMR1 macro
    banksel	PORTD
    movlw	00001011B	
    movwf	TMR1H
    movlw	11011100B	
    movwf	TMR1L		;TMR1  a 1 segundos
    bcf		TMR1IF		;Apagamos la interrupción del TMR0
endm
    
separarval  macro	divisor,cociente,residuo    
  ;Macro de separar una variable menor a 99 en 2 displays
  ;para ello debemos divider el valor para que sean 2 valores distintos
    movwf	CONT	    ;El dividendo se encuentra en W, 
			    ;pasamos w a cont
    clrf	CONT+1	    ;Limpiamos la variable que está sobre w
	
    incf	CONT+1	    ;Aumentamos cont en 1
    movlw	divisor	    ;Pasamos la litera del divisor a w
	
    subwf	CONT,f	    ;Restamos de w cont, y seguarda en cont
    btfsc	STATUS,0    ;Si el carry es 0, decrementamos cont+1
    goto	$-4
	
    decf	CONT+1,w    ;Decrementamos cont+1 y pasa a w
    movwf	cociente    ;Pasamos w al cociente
	
    movlw	divisor	    ;Pasamos el divisor a w
    addwf	CONT,w	    ;Agregamos nuevamente cont a w
    movwf	residuo	    ;Pasamos w como residuo
  endm
  
;*******************************************************************************
;VARIABLES
;*******************************************************************************
PSECT udata_bank0
;Interrupciones
W_TEMP: 
    DS 2	;Bandera para el Push de la interrupción
STATUS_TEMP:
    DS 2	;Bandera para el POP de la interrupción

;Displays
MULTIPLEXEO:
    DS 2	;Bandera que permite el cambio de display para el multiplexado
DISPLAY0:
    DS 2	;Valor del primer display
DISPLAY1:
    DS 2	;Valor del segundo display
DISPLAY2:
    DS 2	;Valor del tercer display
DISPLAY3:
    DS 2	;Valor del cuarto display
RES1:	
    DS 2	; 1 byte
COCI1:		
    DS 2	; 1 byte
CONT:		
    DS 2	; 1 byte
   
;PORTB    
STATE:
    DS 2	;Indica el estado actual
MODE:
    DS 2	;Indica el modo
    
;Tiempo
SEGUNDOS:
    DS 2	;Aquí se guardan los segundos
MINUTOS:
    DS 2	;Aqui se guardan los minutos
HORAS:
    DS 2	;Aqui se guardan los minutos
  
;******************************************************************************* 
; VECTOR RESET
;******************************************************************************* 
PSECT code, delta=2, abs
 org 0x0000
    goto main
    
;******************************************************************************* 
; INTERRUPCIONES  
;******************************************************************************* 
PSECT code, delta=2, abs
 org 0x0004
PUSH:
    movwf   W_TEMP	    ;copiamos w al registro
    swapf   STATUS, W	    ;Cambios STATUS para guadarlo en w
    movwf   STATUS_TEMP	    ;Guradamos status en el banko cero del registro
    
ISR:
    btfsc   T0IF	    ;Encendemos la bandera del tmr0 y llamamos su
    call    int_tmr0	    ;interrupción
    
    btfsc   TMR1IF	    ;Encedemos la bandera del tmr1 y llamamos su
    call    int_tmr1	    ;interrupcion
    
    btfsc   RBIF	    ;Bandera de PORTB
    call    int_estados	    ;Interrupcion del puerto B
    
POP:
    swapf   STATUS_TEMP, W  
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
retfie
    
int_tmr0:
    resetTMR0
    btfsc	MULTIPLEXEO, 0	; Si MULTIPLEXEO en bit 0 es 1, va a DISPLAYMU
    call	DISPLAYMU
    btfsc	MULTIPLEXEO, 1	; Si MULTIPLEXEO en bit 1 es 1, va a DISPLAYMD
    call	DISPLAYMD
    btfsc	MULTIPLEXEO, 2	; Si MULTIPLEXEO en bit 2 es 1, va a DISPLAYHU
    call	DISPLAYHU
    btfsc	MULTIPLEXEO, 3	; Si MULTIPLEXEO en bit 3 es 1, va a DISPLAYHD
    call	DISPLAYHD
    
DISPLAYMU:
    clrf	MULTIPLEXEO	;Limpiamos para hacer el multiplexeo en orden
    bsf		MULTIPLEXEO, 1	;Pondemos el multiplexado en el primer display
    clrf	PORTD		;Limpiamos puerto de los transistores
    bsf		PORTD, 0	;Encendemos el transitor del primer display
    movf	DISPLAY0, W	;Movemos el valor del primer display a W
    movwf	PORTA		;Presentamos el resultado en el display
    
    RETURN

DISPLAYMD:
    clrf	MULTIPLEXEO	;Limpiamos para hacer el multiplexeo en orden
    bsf		MULTIPLEXEO, 2	;Pondemos el multiplexado en el segundo display
    clrf	PORTD		;Limpiamos puerto de los transistores
    bsf		PORTD, 1	;Encendemos el transitor del segundo display
    movf	DISPLAY1, W	;Movemos el valor del segundo display a W
    movwf	PORTA		;Presentamos el resultado en el display
    
    RETURN
    
DISPLAYHU:
    clrf	MULTIPLEXEO	;Limpiamos para hacer el multiplexeo en orden
    bsf		MULTIPLEXEO, 3	;Pondemos el multiplexado en el tecer display
    clrf	PORTD		;Limpiamos puerto de los transistores
    bsf		PORTD, 2	;Encendemos el transitor del tercer display
    movf	DISPLAY2, W	;Movemos el valor del tercer display a W
    movwf	PORTA		;Presentamos el resultado en el display
    
    RETURN    

DISPLAYHD:
    clrf	MULTIPLEXEO	;Limpiamos para hacer el multiplexeo en orden
    bsf		MULTIPLEXEO, 4	;Pondemos el multiplexado en el cuarto display
    clrf	PORTD		;Limpiamos puerto de los transistores
    bsf		PORTD, 3	;Encendemos el transitor del cuarto display
    movf	DISPLAY3, W	;Movemos el valor del cuarto display a W
    movwf	PORTA		;Presentamos el resultado en el display
    
    RETURN        
    
int_tmr1:
    resetTMR1		    ; Limpiar TMR1
    incf	SEGUNDOS    ; Aumentar segundos
	  
    RETURN
    
int_estados:
    btfss	PORTB, 0	;Si se presiona el botón ir a modos
    goto	int_modos
    
    btfsc	MODE, 2		;Si el bit 2 es cero
    goto	config_reloj	;ir al modo configuración de reloj
    
    btfsc	MODE, 3		;Si el bit 3 es cero
    goto	config_alarma	;ir al modo de configurar la alarma
    
    bcf RBIF		    ;Terminamos la interrupción
    
config_reloj:
    btfss	PORTB, 1	;Si botón 1 se apacha
    goto	inc_min		;incrementamos los minutos
    
    btfss	PORTB, 2	;Si botón 2 se apacha
    goto	dec_min		;decrementamos los minutos
    
    btfss	PORTB, 3	;Si botón 3 se apacha
    goto	inc_h		;incrementamos las horas
    
    btfss	PORTB, 4	;Si botón 4 se apccha
    goto	dec_h		;decremenramos las horas
    
    bcf RBIF			;Terminamos la interrupción 
 
inc_min:
    incf	MINUTOS	    ;Incremenramos los minutos
    clrf	SEGUNDOS    ;Reiniciamos los segundos
    resetTMR1		    ;Reiniciamos el contador
    
    bcf RBIF		    ;Terminamos la interrupción
 
dec_min:
    decf	MINUTOS	    ;Decrementamos los minutos
    clrf	SEGUNDOS    ;Reiniciamos los segundos
    resetTMR1		    ;Reiniciamos el contador
    
    bcf RBIF		    ;Terminamos la interrupción
    
inc_h:
    incf	HORAS	    ;Incrementamos las horas
    clrf	SEGUNDOS    ;Reiniciamos los segundos
    resetTMR1		    ;Reiniciamos el contador
    
    bcf RBIF		    ;Terminamos la interrupción
    
dec_h:
    decf	HORAS	    ;Decrementamos las horas
    clrf	SEGUNDOS    ;Reiniciamos los segundos
    resetTMR1		    ;Reiniciamos el contador
    
    bcf RBIF		    ;Terminamos la interrupción
    
config_alarma:
    bcf RBIF		    ;Terminamos la interrupción
    
    
    
    
int_modos:
    incf	STATE	    ;Se incrementa el estado
    btfsc	STATE, 2    ;Si el bit 2 está set, limpiamos STATE
    clrf	STATE	    ;Solo dejamos a STATE funcionar en 2 bits
    
    btfsc	STATE, 0    ;Si el bit está en cero
    goto	int_alarma  ;vamos al modo alarma
    goto	int_reloj   ;sino al modo reloj

int_reloj:
    btfsc	STATE, 1    ;Si el bit es 1
    goto	edit_reloj  ;ir al editor de reloj
    goto	show_reloj  ;sino solo mostar el reloj
    
int_alarma:
    btfsc	STATE, 1    ;Si el bit es 1
    goto	edit_alarma ;ir al editor de alarma
    goto	show_alarma ;sino solo mostar la alarma

edit_reloj:
    clrf	MODE	    ;Limpiamos el modo
    bsf		MODE, 2	    
    clrf	PORTC	    ;Limpiamos PORTD
    bsf		PORTC, 5    ;Encendemos led indicador
    
    bcf RBIF		    ;Terminamos la interrupción
    
show_reloj:
	clrf	MODE	    ; Limpiaamos el modo
	bsf	MODE, 0	    
	clrf	PORTC	    ;Limpiar PORTC

	bcf RBIF		    ;Terminamos la interrupción
    
edit_alarma:
    clrf	MODE	    ;Limpiamos el modo
    bsf		MODE, 3	    
    clrf	PORTC	    ;Limpiamos PORTD
    bsf		PORTC, 6	    ;Encendemos led indicador
  
    bcf RBIF		    ;Terminamos la interrupción
    
show_alarma:
    clrf	MODE	    ;Limpiamos el modo
    bsf		MODE, 1	   
    clrf	PORTC	    ;Limpiar PORTD
    bsf		PORTC, 6    ;Indicador de alarma
    
    bcf RBIF		    ;Terminamos la interrupción
    
;******************************************************************************* 
;CONFIGURACIÓN PRINCIPAL
;*******************************************************************************        
PSECT CODE, delta=2, abs
    ORG 100h
    
main:
    call	basic
    call	osci
    call	conftmr0
    call	conftmr1
    call	interrupciones
    call	conf_estados
    clrf	SEGUNDOS
    clrf	MINUTOS
    clrf	HORAS
    clrf	STATE
    clrf	MODE
    bsf		MODE, 0
    banksel	PORTD
    banksel	PORTA
    
loop:
    btfsc	MODE, 0		;Si bit 0 de MODE es 1
    call	reloj		;llamamos al reloj
	
    btfsc	MODE, 1		;Si bit 1 de MODE es 1
    call	alarma		;llamamos alarma
	
    btfsc	MODE, 2		;Si el bit 2 es 1 llamamos reloj
    call	reloj		;pero los botones cambian los valores 
	
    btfsc	MODE, 3		;Si el bit 3 es 1 llamamos alarma
    call	alarma  
    
    btfsc	MINUTOS, 7	;Si minutos llena los bits, se limita a 59 min
    call	min_lim_nt
    btfsc	HORAS, 7	;Si horas llena los biits, se limita a 23 horas
    call	h_lim_nt	
    call	seg_lim
    call	min_lim
    call	h_lim

goto    loop
    
;*******************************************************************************
;TABLA DE VALORES
;*******************************************************************************
tabla:			;Esta tabla traduce los valores a decimal
	clrf	PCLATH
	bsf	PCLATH, 0  
	andlw	0x0f
	addwf	PCL	    
	retlw	00111111B   ; 0
	retlw	00000110B   ; 1
	retlw	01011011B   ; 2
	retlw	01001111B   ; 3
	retlw	01100110B   ; 4
	retlw	01101101B   ; 5
	retlw	01111101B   ; 6
	retlw	00000111B   ; 7
	retlw	01111111B   ; 8
	retlw	01100111B   ; 9
	retlw	00000000B   ; Reinicio    
    
;******************************************************************************* 
;SUBRUTINAS
;*******************************************************************************
basic:
    banksel	ANSEL		;Configuramos los pines como digitales
    clrf	ANSEL
    banksel	ANSELH
    clrf	ANSELH
    
    banksel	TRISB		;Configuracmos los TRIS para que sean entradas   
    bsf		TRISB, 0	;RC0 ES ENTRADA (MODOS)
    bsf		TRISB, 1	;RC1 ES ENTRADA (DISPLAY#1 UP)
    bsf		TRISB, 2	;RC2 ES ENTRADA (DISPLAY#1 DOWN)
    bsf		TRISB, 3	;RC3 ES ENTRADA (DISPLAY#2 UP)
    bsf		TRISB, 4	;RC4 ES ENTRADA (DISPLAY#2 DOWN)
    
    banksel	TRISA		;Configuramos las salidas
    clrf	TRISA		;Salida de los display (multiplexados)
    
    banksel	TRISC		
    bcf		TRISC, 4	;Salida leds papadeantes
    bcf		TRISC, 5	;Led indica modoreloj
    bcf		TRISC, 6	;Led indica modoalarma
    
    banksel	TRISD
    bcf		TRISD, 0	;Transistor del primer display (salida)
    bcf		TRISD, 1	;Transistor del segundo display (salida)
    bcf		TRISD, 2	;Transistor del tercer display (salida)
    bcf		TRISD, 3	;Transistor del cuarto display (salida)
    
    bcf		OPTION_REG, 7	; Habilitar pull ups
    bsf		WPUB, 0		;(MODOS)
    bsf		WPUB, 1		;(DISPLAY#1 UP)
    bsf		WPUB, 2		;(DISPLAY#1 DOWN)
    bsf		WPUB, 3		;(DISPLAY#2 UP)
    bsf		WPUB, 4		;(DISPLAY#2 DOWN)
    
;    banksel	PORTA		;APAGAMOS PUERTOS PARA EVITAR INTERFENCIAS
;    clrf	PORTA
;    banksel	PORTB
;    clrf	PORTB
;    banksel	PORTC
;    clrf	PORTC
;    banksel	PORTD	
;    clrf	PORTD		 ;Buena práctica
  
    RETURN

osci:
    banksel	OSCCON		    ;Configuración del oscilador a 500kHz
    bcf		OSCCON, 6
    bsf		OSCCON, 5
    bsf		OSCCON, 4
    
    RETURN
    
conftmr0:
    banksel	TRISD
    banksel	OPTION_REG
    bcf		OPTION_REG, 5	    ;Asignamos prescaler de 1:2
    bcf		OPTION_REG, 3       
    bcf		OPTION_REG, 2     
    bcf		OPTION_REG, 1       
    bcf		OPTION_REG, 0      
    resetTMR0
    
    RETURN
    
conftmr1:
    banksel	PORTD
    bcf		T1CON, 6	    ;El timer siempre está contando
    bcf		T1CON, 5
    bsf		T1CON, 4	    ;Prescaler de 1:2
    bcf		T1CON, 3	    ;Low power está apagado
    bcf		T1CON, 1	    ;Oscialdor interno
    bsf		T1CON, 0	    ;Encendemos el TMR1
    resetTMR1
    
    RETURN
    
interrupciones:
    banksel	IOCB		    
    movlw	0b11111111	    ;Indicamos que todos los puertos de PORTB
    movwf	IOCB		    ;tendrán interrupción
    
    banksel	INTCON
    bsf		INTCON, 7	    ;Activamos las interrupcion globales
    bsf		INTCON, 6	    ;Activamos las interrupciones perifericas
    bsf		INTCON, 5	    ;Activamos la interrupcion del TMR0
    bcf		INTCON, 2	    ;Empezamos con la interrupción en 0
    bsf		INTCON, 3           ;Activamos la interrupcion del PORTB
    bcf		INTCON, 0           ;PORTB sin cambios de estado
    
    banksel	PIE1
    bsf		PIE1, 0		    ;Activamos interrupción del TMR1
    
    banksel	PIR1
    bcf		PIR1, 0	    ;Empezamos con la interrupcion en 0 (TMR1)
    
    RETURN
    
conf_estados:
    banksel	TRISD
    bsf		IOCB, 0		    ;Activamos la interrupcion de cada boton
    bsf		IOCB, 1
    bsf		IOCB, 2
    bsf		IOCB, 3
    bsf		IOCB, 4
	
    banksel	PORTD
    movf	PORTB, w    
    bcf		RBIF
    
    RETURN
    
reloj:
    movf	MINUTOS, w	; Pasar minutos a w
    separarval	10, COCI1, RES1	; Macro que divide minutos en 10 
	
    movf	RES1, w	; Pasar residuo1 a w
    call	tabla		; Llamar tabla 
    movwf	DISPLAY0	; Pasar valor de la tabla al primer display
	
    movf	COCI1, w	; Pasar cociente1 a w
    call	tabla		; Llamar tabla
    movwf	DISPLAY1	; Pasar valor de la tabla a segundo display
		
	
    movf	HORAS, w		; Pasar horas a w	
    separarval	10, COCI1, RES1	; Macro que divide horas en 10 
	
    movf	RES1, w	; Pasar residuo1 a w
    call	tabla		; Llamar tabla 
    movwf	DISPLAY2	; Pasar valor de la tabla al tercer display
	
    movf	COCI1, w	; Pasar residuo1 a w
    call	tabla		; Llamar tabla 
    movwf	DISPLAY3	; Pasar valor de la tabla al cuarto display
    
    RETURN

alarma:
    RETURN
    
seg_lim:
    movf    SEGUNDOS, w	;Pasamos el valor de segundos a w
    sublw   60		;Restamos 60 a W
    btfss   STATUS,2	
    return		;Si STATUS Es 1 entonces regresamos
    clrf    SEGUNDOS	;SI es 0 limpiamos los segundos
    incf    MINUTOS
    RETURN
    
min_lim:
    movf    MINUTOS, w	;Pasamos el valor de minutos a w
    sublw   60		;Restamos 60 a W
    btfss   STATUS, 2	
    return		;Si STATUS ES 1 regresamos
    clrf    MINUTOS	;Si es 0 entonces limpiamos minutoa
    incf    HORAS	;Al pasar 60 minutos incrementamos 1 hora
	
    RETURN
   
h_lim:
    movf    HORAS, w	;Paamos el valor de HORAS a w
    sublw   24		;Restamos 1 a W
    btfss   STATUS, 2	
    return		;Si STATUS ES 1 regresamos
    clrf    HORAS	;Si es 0 entonces limpiamos minutoa
	
    RETURN

min_lim_nt:
    decf	HORAS	    ; Decrementar horas
    clrf	MINUTOS	    ; Limpiar minutos
    movlw	00111011B   ; Pasar 59 a minutos
    movwf	MINUTOS
	
    RETURN

h_lim_nt:
    clrf	HORAS	    ; Limpiar horas
    movlw	00010111B   ; Pasar 23 a horas
    movwf	HORAS
    
    RETURN

END