; ---------------------------------------------------------------------------
; Flamewing Z80 Driver (Flamedriver)
; See https://github.com/flamewing/flamedriver
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

SndDrvInit:
		SMPS_stopZ80a			; stop the Z80
		SMPS_resetZ80			; release Z80 reset

		; load SMPS sound driver
		lea	(Z80_SoundDriver).l,a0
		lea	(Z80_RAM).l,a1
		bsr.w	Kos_Decomp

		; load default variables
		moveq	#0,d1
		lea	(Z80_RAM+z80_stack).l,a1
		move.w	#bytesToXcnt(zTracksStart-z80_stack, 8),d0

-		movep.l	d1,0(a1)
		movep.l	d1,1(a1)
		addq.w	#8,a1
		dbf	d0,-

		; detect PAL region consoles
		btst	#6,(Graphics_flags).w
		beq.s	.notpal
		move.b	#1,(Z80_RAM+zPalFlag).l

.notpal
		SMPS_resetZ80a		; reset Z80
	rept 4
		nop
	endr
		SMPS_resetZ80		; release reset
		SMPS_startZ80
		rts

; ---------------------------------------------------------------------------
; Always replaces an index previous passed to this function
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Play_Music:
		SMPS_stopZ80
		move.b	d0,(Z80_RAM+zMusicNumber).l
		SMPS_startZ80
		rts

; ---------------------------------------------------------------------------
; Can handle up to two different indexes in one frame
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Play_SFX:
		SMPS_stopZ80
		cmp.b	(Z80_RAM+zSFXNumber0).l,d0
		beq.s	++
		tst.b	(Z80_RAM+zSFXNumber0).l
		bne.s	+
		move.b	d0,(Z80_RAM+zSFXNumber0).l
		SMPS_startZ80
		rts
+
		move.b	d0,(Z80_RAM+zSFXNumber1).l
+
		SMPS_startZ80
		rts

; =============== S U B R O U T I N E =======================================

Change_Music_Tempo:
		SMPS_stopZ80
		move.b	d0,(Z80_RAM+zTempoSpeedup).l
		SMPS_startZ80
		rts

; =============== S U B R O U T I N E =======================================

Play_Sample:
		SMPS_stopZ80
		move.b  d0,(Z80_RAM+zDACIndex).l
		SMPS_startZ80
		rts
