; mlcopy
; A utility to run a DMA copy from SuperBASIC.
; mcassera 2024
;
; Set the source location, destination location, and byte count in basic
; by using POKEL command, than call the routine using the CALL command.
;
; In the current binary location:
;
; POKEL $0903,source
; POKEL $0906,destination
; POKEL $0909,number of bytes to copy
; CALL $0900


.cpu "w65c02"	


DMA_CTRL        =   $df00                       ; dma control register
DMA_CTRL_START  =   $80                         ; start dma operation
DMA_CTRL_ENABLE =   $01                         ; dma engine enabled

DMA_STATUS      =   $df01                       ; dma status register (read only)
DMA_STAT_BUSY   =   $80                         ; dma engine is busy

DMA_FILL_VALUE  =   $df01                       ; byte value for fill operation

DMA_SRC_ADDR    =   $df04                       ; dma source address
DMA_DST_ADDR    =   $df08                       ; dma destination address
DMA_COUNT       =   $df0c                       ; number of bytes to copy



Start:

*=$c0								            ; Set up buffer for Kernel communication
	.dsection zp						        ; Define position for zp (zero page)
	.cerror * > $cf, "Too many Zero page variables"

* = $0900


        .include "api.asm"		                ; This is the Kernel API for communication

SetupKernel:							        ; Set up the API to work with

	    .section zp						        ; Zero page section $20 to $28
event:	.dstruct	kernel.event.event_t
        .send
    

        jmp init_events                         ; start the code

source:     .byte   $00,$00,$00                 ; pokel from basic for the start of pixel data
dest:       .byte   $00,$00,$00                 ; set at the top of this program
size:       .byte   $00,$00,$00                 ; set how many bytes to copy

init_events:
        lda #<event
        sta kernel.args.events
        lda #>event
        sta kernel.args.events+1

        lda #kernel.args.timer.FRAMES		    ; set the Timer to Frames
        ora #kernel.args.timer.QUERY		    ; and query what frame we're on
        sta kernel.args.timer.units		        ; store in units parameter
        jsr kernel.Clock.SetTimer		        ; jsr to Kernel routine to get current frame
        adc #$01				                ; add 1 to Accumulator for next frame
        sta kernel.args.timer.absolute		    ; store in timer.absolute paramter
        sta kernel.args.timer.cookie		    ; saved as a cookie to the kernel (same as frame number)
        lda #kernel.args.timer.FRAMES		    ; set the Timer to Frames
        sta kernel.args.timer.units		        ; store in units parameter
        jsr kernel.Clock.SetTimer		        ; jsr to Kernel routine to set timer


handle_events:
        lda kernel.args.events.pending		    ; Peek at the queue to see if anything is pending
        bpl handle_events			            ; Nothing to do
        jsr kernel.NextEvent			        ; Get the next event.
        bcc dispatch			                ; run dispatch
        jmp handle_events			            ; go and check for another event        

dispatch:
        lda event.type				            ; get the event type from Kernel
        cmp #kernel.event.timer.EXPIRED		    ; is the event timer.EXPIRED?
        beq executeDMA			                ; load and run DMA
        jmp handle_events

executeDMA:
        pha                                     ; store some registers before we set the interrupt
        phx 
        php 
        sei                                     ; set the interrupt
        ldy $01                                 ; get our current i/o setting and push to stack
        phy 


        stz $01                                 ; set i/o to 0
        lda DMA_CTRL_ENABLE                     ; set DMA to enable
        sta DMA_CTRL                            ; and store in dma register

        lda source                              ; load the source address of the bitmap data
        sta DMA_SRC_ADDR                        ; and put into the DMA source register
        lda source+1
        sta DMA_SRC_ADDR+1
        lda source+2
        sta DMA_SRC_ADDR+2

        lda dest                                ; load the destination address for the dma
        sta DMA_DST_ADDR                        ; and store in the dma register
        lda dest+1
        sta DMA_DST_ADDR+1
        lda dest+2
        sta DMA_DST_ADDR+2

        lda size                                ; store size into the dma count register
        sta DMA_COUNT
        lda size+1
        sta DMA_COUNT+1
        lda size+2
        sta DMA_COUNT+2

        lda #$81                                ; start the dma engine
        sta DMA_CTRL 

wait_dma:                                       ; wait for dma to finish
        lda DMA_STATUS
        bmi wait_dma
        stz DMA_CTRL                            ; turn off the dma engine

        pla                                     ; restore the I/O control
        sta $01
        plp                                     ; restore values back to before we stopped the interrupt
        plx 
        pla 
        cli  

        rts                                     ; give control back to basic

        .end




