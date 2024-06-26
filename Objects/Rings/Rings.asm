; ---------------------------------------------------------------------------
; Ring (Object)
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Obj_Ring:
		move.l	#Map_Ring,mappings(a0)
		move.w	#make_art_tile(ArtTile_Ring,1,1),art_tile(a0)
		move.b	#4,render_flags(a0)
		move.w	#$100,priority(a0)
		move.b	#7|$40,collision_flags(a0)
		move.w	#bytes_to_word(16/2,16/2),height_pixels(a0)			; set height and width
		move.l	#.anim,address(a0)

.anim
		tst.b	routine(a0)
		bne.s	.collect
		jmp	(Sprite_OnScreen_Test_Collision).w
; ---------------------------------------------------------------------------

.collect
		clr.b	routine(a0)
		move.l	#.sparkle,address(a0)
		move.w	#$80,priority(a0)
		jsr	(GiveRing).w

.sparkle
		lea	Ani_RingSparkle(pc),a1
		jsr	(Animate_Sprite).w
		tst.b	routine(a0)
		bne.s	.delete
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

.delete
		jmp	(Delete_Current_Sprite).w

; ---------------------------------------------------------------------------
; Bouncing ring (Object)
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Obj_Bouncing_Ring:
		moveq	#0,d0
		move.b	routine(a0),d0
		add.b	d0,d0
		jmp	off_1A658(pc,d0.w)
; ---------------------------------------------------------------------------

off_1A658:
		bra.w	loc_1A67A	; 0
		bra.w	loc_1A75C	; 2
		bra.w	loc_1A7C2	; 4
		bra.w	loc_1A7D6	; 6
		bra.w	loc_1A7E4	; 8
; ---------------------------------------------------------------------------

Obj_Bouncing_Ring_Reverse_Gravity:
		moveq	#0,d0
		move.b	routine(a0),d0
		add.b	d0,d0
		jmp	off_1A670(pc,d0.w)
; ---------------------------------------------------------------------------

off_1A670:
		bra.w	loc_1A67A	; 0
		bra.w	loc_1A7E8	; 2
		bra.w	loc_1A7C2	; 4
		bra.w	loc_1A7D6	; 6
		bra.w	loc_1A7E4	; 8
; ---------------------------------------------------------------------------

loc_1A67A:
		move.l	#Obj_Bouncing_Ring,d6
		tst.b	(Reverse_gravity_flag).w
		beq.s	+
		move.l	#Obj_Bouncing_Ring_Reverse_Gravity,d6
+		movea.w	a0,a1
		moveq	#0,d5
		move.w	(Ring_count).w,d5
		moveq	#32,d0	; max rings
		cmp.w	d0,d5
		blo.s		+
		move.w	d0,d5
+		subq.w	#1,d5
		move.w	#$288,d4
		bra.s	loc_1A6B6
; ---------------------------------------------------------------------------

loc_1A6AE:
		jsr	(Create_New_Sprite3).w
		bne.s	loc_1A738

loc_1A6B6:
		move.l	d6,address(a1)
		addq.b	#2,routine(a1)
		move.l	#Map_Ring,mappings(a1)
		move.w	#make_art_tile(ArtTile_Ring,1,1),art_tile(a1)
		move.b	#$84,render_flags(a1)
		move.w	#$180,priority(a1)
		move.w	x_pos(a0),x_pos(a1)
		move.w	y_pos(a0),y_pos(a1)
		move.b	#7|$40,collision_flags(a1)
		move.w	#bytes_to_word(16/2,16/2),height_pixels(a1)			; set height and width
		move.w	#bytes_to_word(16/2,16/2),y_radius(a1)				; set y_radius and x_radius
		tst.w	d4
		bmi.s	loc_1A728
		move.w	d4,d0
		jsr	(GetSineCosine).w
		move.w	d4,d2
		move.w	d2,-(sp)
		clr.w	d2
		move.b	(sp)+,d2
		asl.w	d2,d0
		asl.w	d2,d1
		move.w	d0,d2
		move.w	d1,d3
		addi.b	#$10,d4
		bhs.s	loc_1A728
		subi.w	#$80,d4
		bhs.s	loc_1A728
		move.w	#$288,d4

loc_1A728:
		movem.w	d2-d3,x_vel(a1)
		neg.w	d2
		neg.w	d4
		dbf	d5,loc_1A6AE
		st	(Ring_spill_anim_counter).w

loc_1A738:
		sfx	sfx_RingLoss											; play ring loss sound
		clr.w	(Ring_count).w
		move.b	#$80,(Update_HUD_ring_count).w
		tst.b	(Reverse_gravity_flag).w
		bne.s	loc_1A7E8

loc_1A75C:
		jsr	(MoveSprite2).w
		addi.w	#$18,y_vel(a0)
		bmi.s	loc_1A7B0
		move.b	(V_int_run_count+3).w,d0
		add.b	d7,d0
		andi.b	#7,d0
		bne.s	loc_1A7B0
		tst.b	render_flags(a0)
		bpl.s	loc_1A79C
		jsr	(RingCheckFloorDist).w
		tst.w	d1
		bpl.s	loc_1A79C
		add.w	d1,y_pos(a0)
		move.w	y_vel(a0),d0
		asr.w	#2,d0
		sub.w	d0,y_vel(a0)
		neg.w	y_vel(a0)

loc_1A79C:
		tst.b	(Ring_spill_anim_counter).w
		beq.s	loc_1A7E4
		move.w	(Camera_max_Y_pos).w,d0
		addi.w	#224,d0
		cmp.w	y_pos(a0),d0
		blo.s		loc_1A7E4

loc_1A7B0:
		move.w	(Level_repeat_offset).w,d0
		sub.w	d0,x_pos(a0)
		jmp	(Draw_And_Touch_Sprite).w
; ---------------------------------------------------------------------------

loc_1A7C2:
		addq.b	#2,routine(a0)
		clr.b	collision_flags(a0)
		move.w	#$80,priority(a0)
		jsr	(GiveRing).w

loc_1A7D6:
		lea	Ani_RingSparkle(pc),a1
		jsr	(Animate_Sprite).w
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

loc_1A7E4:
		jmp	(Delete_Current_Sprite).w
; ---------------------------------------------------------------------------

loc_1A7E8:
		jsr	(MoveSprite2_TestGravity).w
		addi.w	#$18,y_vel(a0)
		bmi.s	loc_1A83C
		move.b	(V_int_run_count+3).w,d0
		add.b	d7,d0
		andi.b	#7,d0
		bne.s	loc_1A83C
		tst.b	render_flags(a0)
		bpl.s	loc_1A828
		jsr	(RingCheckFloorDist_ReverseGravity).w
		tst.w	d1
		bpl.s	loc_1A828
		sub.w	d1,y_pos(a0)
		move.w	y_vel(a0),d0
		asr.w	#2,d0
		sub.w	d0,y_vel(a0)
		neg.w	y_vel(a0)

loc_1A828:
		tst.b	(Ring_spill_anim_counter).w
		beq.s	loc_1A7E4
		move.w	(Camera_max_Y_pos).w,d0
		addi.w	#224,d0
		cmp.w	y_pos(a0),d0
		blo.s		loc_1A7E4

loc_1A83C:
		move.w	(Level_repeat_offset).w,d0
		sub.w	d0,x_pos(a0)
		jmp	(Draw_And_Touch_Sprite).w

; ---------------------------------------------------------------------------
; Attracted ring (Object)
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Obj_Attracted_Ring:

		; init
		move.l	#Map_Ring,mappings(a0)
		move.w	#make_art_tile(ArtTile_Ring,1,1),art_tile(a0)
		move.b	#4,render_flags(a0)
		move.w	#$100,priority(a0)
		move.b	#7|$40,collision_flags(a0)
		move.w	#bytes_to_word(16/2,16/2),height_pixels(a0)			; set height and width
		move.w	#bytes_to_word(16/2,16/2),y_radius(a0)				; set y_radius and x_radius
		move.l	#loc_1A88C,address(a0)

loc_1A88C:
		tst.b	routine(a0)
		bne.s	AttractedRing_GiveRing
		bsr.s	AttractedRing_Move
		btst	#Status_LtngShield,(Player_1+status_secondary).w		; does player still have a lightning shield?
		bne.s	loc_1A8C6
		move.l	#Obj_Bouncing_Ring,address(a0)					; if not, change object
		move.b	#2,routine(a0)
		st	(Ring_spill_anim_counter).w

loc_1A8C6:
		out_of_xrange.s	loc_1A8E4
		jmp	(Draw_And_Touch_Sprite).w
; ---------------------------------------------------------------------------

loc_1A8E4:
		move.w	respawn_addr(a0),d0
		beq.s	loc_1A8F0
		movea.w	d0,a2
		bclr	#7,(a2)

loc_1A8F0:
		move.w	objoff_30(a0),d0									; load ring RAM address
		beq.s	loc_1A8FC
		movea.w	d0,a2
		clr.w	(a2)

loc_1A8FC:
		jmp	(Delete_Current_Sprite).w
; ---------------------------------------------------------------------------

AttractedRing_GiveRing:
		clr.b	collision_flags(a0)
		move.w	#$80,priority(a0)
		jsr	(GiveRing).w
		move.l	#loc_1A920,address(a0)
		clr.b	routine(a0)

loc_1A920:
		tst.b	routine(a0)
		bne.s	loc_1A934
		lea	Ani_RingSparkle(pc),a1
		jsr	(Animate_Sprite).w
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

loc_1A934:
		jmp	(Delete_Current_Sprite).w

; =============== S U B R O U T I N E =======================================

AttractedRing_Move:

		; move on x axis
		moveq	#48,d1
		move.w	(Player_1+x_pos).w,d0
		cmp.w	x_pos(a0),d0
		bge.s	AttractedRing_MoveRight							; if ring is to the left of the player, branch

		; move left
		neg.w	d1
		tst.w	x_vel(a0)
		bmi.s	AttractedRing_ApplyMovementX
		add.w	d1,d1
		add.w	d1,d1
		bra.s	AttractedRing_ApplyMovementX
; ---------------------------------------------------------------------------

AttractedRing_MoveRight:
		tst.w	x_vel(a0)
		bpl.s	AttractedRing_ApplyMovementX
		add.w	d1,d1
		add.w	d1,d1

AttractedRing_ApplyMovementX:
		add.w	d1,x_vel(a0)

		; move on y axis
		moveq	#48,d1
		move.w	(Player_1+y_pos).w,d0
		cmp.w	y_pos(a0),d0
		bge.s	AttractedRing_MoveUp							; if ring is below the player, branch

		; move down
		neg.w	d1
		tst.w	y_vel(a0)
		bmi.s	AttractedRing_ApplyMovementY
		add.w	d1,d1
		add.w	d1,d1
		bra.s	AttractedRing_ApplyMovementY
; ---------------------------------------------------------------------------

AttractedRing_MoveUp:
		tst.w	y_vel(a0)
		bpl.s	AttractedRing_ApplyMovementY
		add.w	d1,d1
		add.w	d1,d1

AttractedRing_ApplyMovementY:
		add.w	d1,y_vel(a0)
		jmp	(MoveSprite2).w
; ---------------------------------------------------------------------------

		include "Objects/Rings/Object Data/Anim - Rings.asm"
		include "Objects/Rings/Object Data/Map - Rings.asm"
