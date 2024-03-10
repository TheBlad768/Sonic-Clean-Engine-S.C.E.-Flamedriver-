
; =============== S U B R O U T I N E =======================================

LoadObjects_Data:
SetUp_ObjAttributes:
		move.l	(a1)+,mappings(a0)			; mapping offset

SetUp_ObjAttributes2:
		move.w	(a1)+,art_tile(a0)				; VRAM offset

SetUp_ObjAttributes3:
LoadObjects_ExtraData:
		move.w	(a1)+,priority(a0)				; priority
		move.b	(a1)+,width_pixels(a0)			; width
		move.b	(a1)+,height_pixels(a0)		; height
		move.b	(a1)+,mapping_frame(a0)		; frame number
		move.b	(a1)+,collision_flags(a0)		; collision number
		bset	#rbCoord,render_flags(a0)			; use screen coordinates
		addq.b	#2,routine(a0)				; next routine
		rts

; =============== S U B R O U T I N E =======================================

SetUp_ObjAttributesSlotted:
		moveq	#0,d0
		move.w	(a1)+,d1						; maximum number of objects that can be made in this array
		move.w	d1,d2
		move.w	(a1)+,d3						; base VRAM offset of object
		move.w	(a1)+,d4						; amount to add to base VRAM offset for each slot
		moveq	#0,d5
		move.w	(a1)+,d5						; index of slot array to use (RAM shift)
		lea	(Slotted_object_bits).w,a2
		adda.w	d5,a2						; get the address of the array to use
		move.b	(a2),d5
		beq.s	.create						; if array is clear, just make the object

.find
		lsr.b	d5								; check slot (each bit)
		bhs.s	.create						; if clear, make object
		addq.w	#1,d0						; increment bit number
		add.w	d4,d3						; add VRAM offset
		dbf	d1,.find							; repeat max times

		; delete
		moveq	#0,d0
		move.l	d0,address(a0)
		move.l	d0,x_pos(a0)
		move.l	d0,y_pos(a0)
		move.b	d0,subtype(a0)
		move.b	d0,render_flags(a0)
		move.w	d0,status(a0)					; if no open slots, then destroy this object period
		addq.w	#4*2,sp
		rts
; ---------------------------------------------------------------------------

.create
		bset	d0,(a2)							; turn this slot on
		move.b	d0,ros_bit(a0)
		move.w	a2,ros_addr(a0)				; keep track of slot address and bit number
		move.w	d3,art_tile(a0)				; use correct VRAM offset
		move.l	(a1)+,mappings(a0)			; mapping address
		move.w	(a1)+,priority(a0)				; priority
		move.b	(a1)+,width_pixels(a0)			; width
		move.b	(a1)+,height_pixels(a0)		; height
		move.b	(a1)+,mapping_frame(a0)		; frame number
		move.b	(a1)+,collision_flags(a0)		; collision number
		bset	#2,status(a0)						; turn object slotting on
		st	objoff_3A(a0)					; reset DPLC frame
		bset	#2,render_flags(a0)				; use screen coordinates
		addq.b	#2,routine(a0)				; next routine
		rts

; =============== S U B R O U T I N E =======================================

Perform_DPLC:
		moveq	#0,d0
		move.b	mapping_frame(a0),d0		; get the frame number
		cmp.b	objoff_3A(a0),d0				; if frame number remains the same as before, don't do anything
		beq.s	.return
		move.b	d0,objoff_3A(a0)
		movea.l	(a2)+,a3						; source address of art
		move.w	art_tile(a0),d4
		andi.w	#$7FF,d4					; isolate tile location offset
		lsl.w	#5,d4							; convert to VRAM address
		movea.l	(a2)+,a2						; address of DPLC script
		add.w	d0,d0
		adda.w	(a2,d0.w),a2					; apply offset to script
		move.w	(a2)+,d5						; get number of DMA transactions
		bmi.s	.return						; skip if zero queues
		moveq	#0,d3

.loop
		move.w	(a2)+,d3						; art source offset
		move.l	d3,d1
		andi.w	#$FFF0,d1					; isolate all but lower 4 bits
		add.l	a3,d1						; get final source address of art
		move.w	d4,d2						; destination VRAM address
		andi.w	#$F,d3
		addq.w	#1,d3
		lsl.w	#4,d3							; d3 is the total number of words to transfer (maximum 16 tiles per transaction)
		add.w	d3,d4
		add.w	d3,d4
		jsr	(Add_To_DMA_Queue).w			; add to queue
		dbf	d5,.loop							; keep going

.return
		rts

; =============== S U B R O U T I N E =======================================

Set_IndexedVelocity:
		moveq	#0,d1
		move.b	subtype(a0),d1
		add.w	d1,d1
		add.w	d1,d0
		move.l	Obj_VelocityIndex(pc,d0.w),x_vel(a0)
		btst	#0,render_flags(a0)
		beq.s	.return
		neg.w	x_vel(a0)

.return
		rts
; ---------------------------------------------------------------------------

Obj_VelocityIndex:
		dc.w -$100, -$100		; 0
		dc.w $100, -$100		; 4
		dc.w -$200, -$200	; 8
		dc.w $200, -$200		; C
		dc.w -$300, -$200	; 10
		dc.w $300, -$200		; 14
		dc.w -$200, -$200	; 18
		dc.w 0, -$200		; 1C
		dc.w -$400, -$300	; 20
		dc.w $400, -$300		; 24
		dc.w $300, -$300		; 28
		dc.w -$400, -$300	; 2C
		dc.w $400, -$300		; 30
		dc.w -$200, -$200	; 34
		dc.w $200, -$200		; 38
		dc.w 0, -$100			; 3C
		dc.w -$40, -$700		; 40
		dc.w -$80, -$700		; 44
		dc.w -$180, -$700		; 48
		dc.w -$100, -$700		; 4C
		dc.w -$200, -$700	; 50
		dc.w -$280, -$700	; 54
		dc.w -$300, -$700	; 58
		dc.w 0, -$100			; 5C
		dc.w -$100, -$100		; 60
		dc.w $100, -$100		; 64
		dc.w -$200, -$100		; 68
		dc.w $200, -$100		; 6C
		dc.w -$200, -$200	; 70
		dc.w $200, -$200		; 74
		dc.w -$300, -$200	; 78
		dc.w $300, -$200		; 7C
		dc.w -$300, -$300	; 80
		dc.w $300, -$300		; 84
		dc.w -$400, -$300	; 88
		dc.w $400, -$300		; 8C
		dc.w -$200, -$300	; 90
		dc.w $200, -$300		; 94

; =============== S U B R O U T I N E =======================================

Displace_PlayerOffObject:
		moveq	#standing_mask,d0
		and.b	status(a0),d0										; is Sonic or Tails standing on the object?
		beq.s	.return											; if not, branch
		bclr	#p1_standing_bit,status(a0)
		beq.s	.return
		lea	(Player_1).w,a1
		bclr	#Status_OnObj,status(a1)
		bset	#Status_InAir,status(a1)

.return
		rts

; =============== S U B R O U T I N E =======================================

Go_CheckPlayerRelease:
		movem.l	d7-a0/a2-a3,-(sp)
		lea	(Player_1).w,a1
		btst	#Status_OnObj,status(a1)
		beq.s	.notp1
		movea.w	interact(a1),a0
		bsr.w	CheckPlayerReleaseFromObj

.notp1
		movem.l	(sp)+,d7-a0/a2-a3
		rts

; =============== S U B R O U T I N E =======================================

Obj_Song_Fade_Transition:
		music	mus_FadeOut									; fade out music
		move.w	#(2*60)-30,$2E(a0)
		move.l	#Song_Fade_Transition_Wait,address(a0)

Song_Fade_Transition_Return:
		rts
; ---------------------------------------------------------------------------

Song_Fade_Transition_Wait:
		subq.w	#1,$2E(a0)
		bpl.s	Song_Fade_Transition_Return
		move.b	subtype(a0),d0
		move.b	d0,(Current_music+1).w
		jsr	(Play_Music).w										; play music
		jmp	(Delete_Current_Sprite).w

; =============== S U B R O U T I N E =======================================

Obj_Song_Fade_ToLevelMusic:
		music	mus_FadeOut									; fade out music
		move.w	#2*60,$2E(a0)
		move.l	#Song_Fade_ToLevelMusic_Wait,address(a0)

Song_Fade_ToLevelMusic_Return:
		rts
; ---------------------------------------------------------------------------

Song_Fade_ToLevelMusic_Wait:
		subq.w	#1,$2E(a0)
		bpl.s	Song_Fade_ToLevelMusic_Return
		bsr.s	Restore_LevelMusic
		jmp	(Delete_Current_Sprite).w

; =============== S U B R O U T I N E =======================================

Restore_LevelMusic:
		lea	(Level_data_addr_RAM.Music).w,a2						; load music playlist
		moveq	#0,d0
		move.b	(a2),d0
		move.w	d0,(Current_music).w
		btst	#Status_Invincible,(Player_1+status_secondary).w
		beq.s	.play
		moveq	#signextendB(mus_Invincible),d0					; if invincible, play invincibility music

.play
		jmp	(Play_Music).w										; play music

; =============== S U B R O U T I N E =======================================

StackLoad_Routine:
		movea.l	(sp)+,a1

Load_Routine:
		andi.w	#$FE,d0
		adda.w	(a1,d0.w),a1
		jmp	(a1)

; =============== S U B R O U T I N E =======================================

HurtCharacter_Directly2:
		tst.b	invulnerability_timer(a1)
		bne.s	HurtCharacter_Directly.return
		btst	#Status_Invincible,status_secondary(a1)
		bne.s	HurtCharacter_Directly.return

HurtCharacter_Directly:
		tst.w	(Debug_placement_mode).w
		bne.s	.return

		; hurt character
		movea.w	a0,a2
		movea.w	a1,a0
		bsr.w	HurtCharacter
		movea.w	a2,a0

.return
		rts

; =============== S U B R O U T I N E =======================================

EnemyDefeated:
		bsr.s	EnemyDefeat_Score
		movea.w	objoff_44(a0),a1
		tst.w	y_vel(a1)
		bmi.s	.bouncedown
		move.w	y_pos(a1),d0
		cmp.w	y_pos(a0),d0
		bhs.s	.bounceup
		neg.w	y_vel(a1)
		rts
; ---------------------------------------------------------------------------

.bouncedown:
		addi.w	#$100,y_vel(a1)									; bounce down
		rts
; ---------------------------------------------------------------------------

.bounceup:
		subi.w	#$100,y_vel(a1)									; bounce up
		rts

; =============== S U B R O U T I N E =======================================

EnemyDefeat_Score:
		bset	#7,status(a0)
		clr.b	collision_flags(a0)
		moveq	#0,d0
		move.w	(Chain_bonus_counter).w,d0
		addq.w	#2,(Chain_bonus_counter).w
		cmpi.w	#6,d0
		blo.s		.notreachedlimit
		moveq	#6,d0

.notreachedlimit:
		move.w	d0,objoff_3E(a0)
		lea	Enemy_Points(pc),a2
		move.w	(a2,d0.w),d0
		cmpi.w	#16*2,(Chain_bonus_counter).w						; have 16 enemies been destroyed?
		blo.s		.notreachedlimit2									; if not, branch
		move.w	#1000,d0										; fix bonus to 10000
		move.w	#10,objoff_3E(a0)

.notreachedlimit2:
		bsr.w	HUD_AddToScore
		move.l	#Obj_Explosion,address(a0)
		clr.b	routine(a0)
		rts

; =============== S U B R O U T I N E =======================================

HurtCharacter_WithoutDamage:
		lea	(Player_1).w,a1
		move.b	#id_SonicHurt,routine(a1)							; hit animation
		bclr	#Status_OnObj,status(a1)
		bclr	#Status_Push,status(a1)								; player is not standing on/pushing an object
		bset	#Status_InAir,status(a1)
		move.l	#words_to_long(-$200,-$300),x_vel(a1)				; set speed of player
		clr.w	ground_vel(a1)									; zero out inertia
		move.b	#id_Hurt,anim(a1)								; set falling animation
		sfx	sfx_Death,1

; =============== S U B R O U T I N E =======================================

Check_PlayerAttack:
		btst	#Status_Invincible,status_secondary(a1)
		bne.s	loc_85822
		cmpi.b	#id_SpinDash,anim(a1)
		beq.s	loc_85822
		cmpi.b	#id_Roll,anim(a1)
		beq.s	loc_85822
		moveq	#0,d0
		move.b	character_id(a1),d0
		add.w	d0,d0
		move.w	off_857EA(pc,d0.w),d0
		jmp	off_857EA(pc,d0.w)
; ---------------------------------------------------------------------------

off_857EA: offsetTable
		offsetTableEntry.w Check_SonicAttack	; 0 - Sonic
		offsetTableEntry.w Check_SonicAttack	; 1 - Tails
		offsetTableEntry.w Check_SonicAttack	; 2 - Knuckles
; ---------------------------------------------------------------------------

Check_SonicAttack:
		moveq	#0,d0
		rts
; ---------------------------------------------------------------------------

loc_85822:
		moveq	#1,d0
		rts

; =============== S U B R O U T I N E =======================================

Check_PlayerCollision:
		move.b	collision_property(a0),d0
		beq.s	.return
		clr.b	collision_property(a0)
		andi.w	#3,d0
		add.w	d0,d0
		movea.w	.players(pc,d0.w),a1
		move.w	a1,objoff_44(a0)
		moveq	#1,d1

.return
		rts
; ---------------------------------------------------------------------------

.players
		dc.w Player_1
		dc.w Player_1
		dc.w Player_1
		dc.w Player_1

; =============== S U B R O U T I N E =======================================

Load_LevelResults:
		lea	(Player_1).w,a1
		btst	#7,status(a1)
		bne.s	.return
		btst	#Status_InAir,status(a1)
		bne.s	.return
		cmpi.b	#id_SonicDeath,routine(a1)
		bhs.s	.return
		bsr.s	Set_PlayerEndingPose
		clr.b	(TitleCard_end_flag).w
		bsr.w	Create_New_Sprite
		bne.s	.return
		move.l	#Obj_LevelResults,address(a1)

.return
		rts

; =============== S U B R O U T I N E =======================================

Set_PlayerEndingPose:
		move.b	#$81,object_control(a1)
		move.b	#id_Landing,anim(a1)
		clr.b	spin_dash_flag(a1)
		clr.l	x_vel(a1)
		clr.w	ground_vel(a1)
		bclr	#p1_pushing_bit,status(a0)
		bclr	#p2_pushing_bit,status(a0)
		bclr	#Status_Push,status(a1)
		bclr	#Status_Roll,status(a1)
		beq.s	.return										; if the player doesn't roll, branch

		; fix player ypos
		move.b	y_radius(a1),d0
		move.w	default_y_radius(a1),y_radius(a1)
		sub.b	default_y_radius(a1),d0
		ext.w	d0
		tst.b	(Reverse_gravity_flag).w
		beq.s	.notgrav
		neg.w	d0

.notgrav
		add.w	d0,y_pos(a1)

.return
		rts

; =============== S U B R O U T I N E =======================================

Stop_Object:
		clr.l	x_vel(a1)
		clr.w	ground_vel(a1)
		rts

; =============== S U B R O U T I N E =======================================

Restore_PlayerControl:
		lea	(Player_1).w,a1

Restore_PlayerControl2:
		clr.b	object_control(a1)
		bclr	#Status_InAir,status(a1)
		move.w	#bytes_to_word(id_Wait,id_Wait),anim(a1)
		clr.b	anim_frame(a1)
		clr.b	anim_frame_timer(a1)
		rts

; =============== S U B R O U T I N E =======================================

StartNewLevel:
		move.w	d0,(Current_zone_and_act).w
		move.w	d0,(Apparent_zone_and_act).w
		st	(Restart_level_flag).w
		clr.b	(Last_star_post_hit).w

.return:
		rts

; =============== S U B R O U T I N E =======================================

Play_SFX_Continuous:
		and.b	(V_int_run_count+3).w,d1
		bne.s	StartNewLevel.return
		jmp	(Play_SFX).w										; play sfx

; =============== S U B R O U T I N E =======================================

Wait_NewDelay:
		subq.w	#1,$2E(a0)
		bmi.s	.end
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

.end
		bclr	#7,render_flags(a0)
		move.w	#(2*60)-1,$2E(a0)
		movea.l	$34(a0),a1
		jmp	(a1)

; =============== S U B R O U T I N E =======================================

Wait_FadeToLevelMusic:
		subq.w	#1,$2E(a0)
		bmi.s	.end
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

.end
		bclr	#7,render_flags(a0)
		move.w	#(2*60)-1,$2E(a0)
		jsr	(Create_New_Sprite).w
		bne.s	.notfree
		move.l	#Obj_Song_Fade_ToLevelMusic,address(a1)

.notfree
		movea.l	$34(a0),a1
		jmp	(a1)

; =============== S U B R O U T I N E =======================================

Player_IntroRightMove:
		move.w	#bytes_to_word(btnR,btnR),d0					; set right move
		tst.w	$2E(a0)
		beq.s	.notjump
		subq.w	#1,$2E(a0)
		move.w	#bytes_to_word(btnA+btnR,btnR),d0			; keep jumping

.notjump
		btst	#Status_Push,status(a1)							; player hitting a solid?
		beq.s	.notpush										; if not, branch
		move.w	#$1F,$2E(a0)
		move.w	#bytes_to_word(btnA+btnR,btnA+btnR),d0		; set player jump

.notpush
		move.w	d0,(Ctrl_1_logical).w
		rts

; =============== S U B R O U T I N E =======================================

BossDefeated_StopTimer:
		clr.b	(Update_HUD_timer).w

BossDefeated:
		move.w	#$3F,$2E(a0)

BossDefeated_NoTime:
		bclr	#7,render_flags(a0)
		moveq	#100,d0
		jmp	(HUD_AddToScore).w

; =============== S U B R O U T I N E =======================================

BossFlash:
		lea	.palram(pc),a1
		lea	.palcycle(pc,d0.w),a2
		bra.s	CopyWordData_3
; ---------------------------------------------------------------------------

.palram
		dc.w Normal_palette_line_1+$C
		dc.w Normal_palette_line_1+$1C
		dc.w Normal_palette_line_1+$1E
.palcycle
		dc.w 8, $866, $222
		dc.w $888, $CCC, $EEE

; =============== S U B R O U T I N E =======================================

CopyWordData_8:
		movea.w	(a1)+,a3
		move.w	(a2)+,(a3)+

CopyWordData_7:
		movea.w	(a1)+,a3
		move.w	(a2)+,(a3)+

CopyWordData_6:
		movea.w	(a1)+,a3
		move.w	(a2)+,(a3)+

CopyWordData_5:
		movea.w	(a1)+,a3
		move.w	(a2)+,(a3)+

CopyWordData_4:
		movea.w	(a1)+,a3
		move.w	(a2)+,(a3)+

CopyWordData_3:
		movea.w	(a1)+,a3
		move.w	(a2)+,(a3)+

CopyWordData_2:
		movea.w	(a1)+,a3
		move.w	(a2)+,(a3)+

CopyWordData_1:
		movea.w	(a1)+,a3
		move.w	(a2)+,(a3)+
		rts

; =============== S U B R O U T I N E =======================================

Check_CameraXBoundary:
		tst.w	x_vel(a0)
		beq.s	+
		bmi.s	++
		move.w	(Camera_X_pos).w,d0
		addi.w	#$130,d0
		cmp.w	x_pos(a0),d0
		bhi.s	+
		clr.w	x_vel(a0)
+		rts
; ---------------------------------------------------------------------------
+		move.w	(Camera_X_pos).w,d0
		addi.w	#$10,d0
		cmp.w	x_pos(a0),d0
		blo.s		+
		clr.w	x_vel(a0)
+		rts

; =============== S U B R O U T I N E =======================================

Resize_MaxYFromX:
		move.w	(Camera_X_pos).w,d0

-		move.l	(a1)+,d1
		cmp.w	d1,d0
		bhi.s	-
		swap	d1
		tst.w	d1
		bpl.s	+
		andi.w	#$7FFF,d1
		move.w	d1,(Camera_max_Y_pos).w
+		move.w	d1,(Camera_target_max_Y_pos).w
		rts

; =============== S U B R O U T I N E =======================================

Change_ActSizes:
		lea	(Level_data_addr_RAM.xstart).w,a1
		move.l	(a1)+,d0
		move.l	d0,(Camera_min_X_pos).w
		move.l	d0,(Camera_target_min_X_pos).w
		move.l	(a1)+,d0
		move.l	d0,(Camera_min_Y_pos).w
		move.l	d0,(Camera_target_min_Y_pos).w
		rts

; =============== S U B R O U T I N E =======================================

Change_ActSizes2:
		lea	(Level_data_addr_RAM.xstart).w,a1
		move.w	(a1)+,(Camera_stored_min_X_pos).w
		move.w	(a1)+,(Camera_stored_max_X_pos).w
		move.w	(a1)+,(Camera_stored_min_Y_pos).w
		move.w	(a1)+,d1
		move.w	d1,(Camera_stored_max_Y_pos).w
		move.w	d1,(Camera_target_max_Y_pos).w

		; create change level size object
		lea	Child7_ChangeLevSize(pc),a2
		jmp	(CreateChild7_Normal2).w

; =============== S U B R O U T I N E =======================================

Obj_IncLevEndXGradual:
		move.w	(Camera_max_X_pos).w,d0
		move.l	objoff_30(a0),d1
		addi.l	#$4000,d1
		move.l	d1,objoff_30(a0)
		swap	d1
		add.w	d1,d0
		cmp.w	(Camera_stored_max_X_pos).w,d0
		bhs.s	.end
		move.w	d0,(Camera_max_X_pos).w
		rts
; ---------------------------------------------------------------------------

.end
		move.w	(Camera_stored_max_X_pos).w,(Camera_max_X_pos).w
		jmp	(Delete_Current_Sprite).w

; =============== S U B R O U T I N E =======================================

Obj_DecLevStartXGradual:
		move.w	(Camera_min_X_pos).w,d0
		move.l	objoff_30(a0),d1
		addi.l	#$4000,d1
		move.l	d1,objoff_30(a0)
		swap	d1
		sub.w	d1,d0
		cmp.w	(Camera_stored_min_X_pos).w,d0
		ble.s		.end
		move.w	d0,(Camera_min_X_pos).w
		rts
; ---------------------------------------------------------------------------

.end
		move.w	(Camera_stored_min_X_pos).w,(Camera_min_X_pos).w
		jmp	(Delete_Current_Sprite).w

; =============== S U B R O U T I N E =======================================

Obj_IncLevEndYGradual:
		move.w	(Camera_max_Y_pos).w,d0
		move.l	objoff_30(a0),d1
		addi.l	#$8000,d1
		move.l	d1,objoff_30(a0)
		swap	d1
		add.w	d1,d0
		cmp.w	(Camera_stored_max_Y_pos).w,d0
		bgt.s	.end
		move.w	d0,(Camera_max_Y_pos).w
		rts
; ---------------------------------------------------------------------------

.end
		move.w	(Camera_stored_max_Y_pos).w,(Camera_max_Y_pos).w
		jmp	(Delete_Current_Sprite).w

; =============== S U B R O U T I N E =======================================

Obj_DecLevStartYGradual:
		move.w	(Camera_min_Y_pos).w,d0
		move.l	objoff_30(a0),d1
		addi.l	#$4000,d1
		move.l	d1,objoff_30(a0)
		swap	d1
		sub.w	d1,d0
		cmp.w	(Camera_stored_min_Y_pos).w,d0
		ble.s		.end
		move.w	d0,(Camera_min_Y_pos).w
		rts
; ---------------------------------------------------------------------------

.end
		move.w	(Camera_stored_min_Y_pos).w,(Camera_min_Y_pos).w
		jmp	(Delete_Current_Sprite).w
; ---------------------------------------------------------------------------

Child6_IncLevX:
		dc.w 1-1
		dc.l Obj_IncLevEndXGradual
Child6_DecLevX:
		dc.w 1-1
		dc.l Obj_DecLevStartXGradual
Child6_IncLevY:
		dc.w 1-1
		dc.l Obj_IncLevEndYGradual
Child6_DecLevY:
		dc.w 1-1
		dc.l Obj_DecLevStartYGradual
Child1_ActLevelSize:
		dc.w 3-1
		dc.l Obj_IncLevEndXGradual
		dc.b 0, 0
		dc.l Obj_DecLevStartYGradual
		dc.b 0, 0
		dc.l Obj_IncLevEndYGradual
		dc.b 0, 0
Child7_ChangeLevSize:
		dc.w 4-1
		dc.l Obj_DecLevStartYGradual
		dc.b 0, 0
		dc.l Obj_IncLevEndYGradual
		dc.b 0, 0
		dc.l Obj_DecLevStartXGradual
		dc.b 0, 0
		dc.l Obj_IncLevEndXGradual
		dc.b 0, 0

; =============== S U B R O U T I N E =======================================

Reset_ObjectsPosition3:
		bsr.s	Reset_ObjectsPosition2
		move.w	(Camera_X_pos).w,(Camera_min_X_pos).w
		move.w	(Camera_X_pos).w,(Camera_max_X_pos).w
		move.w	(Camera_Y_pos).w,(Camera_min_Y_pos).w
		move.w	(Camera_Y_pos).w,(Camera_max_Y_pos).w
		rts
; ---------------------------------------------------------------------------

Reset_ObjectsPosition2:
		sub.w	d1,(Player_1+y_pos).w
		sub.w	d0,(Player_1+x_pos).w
		sub.w	d0,(Camera_X_pos).w
		sub.w	d1,(Camera_Y_pos).w
		sub.w	d0,(Camera_X_pos_copy).w
		sub.w	d1,(Camera_Y_pos_copy).w
		move.w	(Camera_max_Y_pos).w,(Camera_target_max_Y_pos).w
		bra.s	Offset_ObjectsDuringTransition
; ---------------------------------------------------------------------------

Reset_ObjectsPosition:
		move.w	(Camera_X_pos).w,d0

Reset_ObjectsPosition4:
		sub.w	d1,(Player_1+y_pos).w
		sub.w	d0,(Player_1+x_pos).w
		sub.w	d0,(Camera_X_pos).w
		sub.w	d1,(Camera_Y_pos).w
		sub.w	d0,(Camera_X_pos_copy).w
		sub.w	d1,(Camera_Y_pos_copy).w
		sub.w	d0,(Camera_min_X_pos).w
		sub.w	d0,(Camera_max_X_pos).w
		sub.w	d1,(Camera_min_Y_pos).w
		sub.w	d1,(Camera_max_Y_pos).w
		move.w	(Camera_max_Y_pos).w,(Camera_target_max_Y_pos).w

; =============== S U B R O U T I N E =======================================

Offset_ObjectsDuringTransition:
		lea	(Dynamic_object_RAM+next_object).w,a1
		moveq	#((Dynamic_object_RAM_end-Dynamic_object_RAM)/object_size)-1,d2

.check
		tst.l	address(a1)
		beq.s	.nextobj
		btst	#2,render_flags(a1)
		beq.s	.nextobj
		sub.w	d0,x_pos(a1)
		sub.w	d1,y_pos(a1)

.nextobj
		lea	next_object(a1),a1
		dbf	d2,.check
		rts
