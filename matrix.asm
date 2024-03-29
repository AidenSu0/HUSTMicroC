ADDR_8255_PA	EQU	270H	;8255 PA口
ADDR_8255_PB	EQU	271H	;8255 PB口
ADDR_8255_C	EQU	273H	;8255控制口
ADDR_273	EQU	230H	;IO区74HC273(16位I/O)
LINE           	EQU	ADDR_273	;行线1, 行线2
ROW1	EQU	ADDR_8255_PA	;列线1
ROW2	EQU	ADDR_8255_PB		;列线2
			
_STACK	SEGMENT	STACK	
	DW	100 DUP(?)	
_STACK	ENDS		
_DATA	SEGMENT		WORD PUBLIC 'DATA'	
HUAN   DB 00H,0C0H,00H,0C0H,0FEH,0C0H,07H,0FFH,0C7H,86H,6FH,6CH,3CH,60H,18H,60H
DB 1CH,60H,1CH,70H,36H,0F0H,36H,0D8H,61H,9CH,0C7H,0FH,3CH,06H,00H,00H
YING   DB 60H,00H,31H,0C0H,3FH,7EH,36H,66H,06H,66H,06H,66H,0F6H,66H,36H,66H
DB 37H,0E6H,37H,7EH,36H,6CH,30H,60H,30H,60H,78H,00H,0CFH,0FFH,00H,00H
SHI	   DB 00H,00H,06H,30H,07H,30H,0FH,0FFH,0CH,30H,1FH,0FFH,3BH,33H,7BH,33H
DB 1BH,0FFH,1BH,33H,19H,0B0H,18H,0E0H,18H,60H,18H,0FCH,19H,8FH,1FH,03H
YONG   DB 00,0,1FH,0FEH,18H,0C6H,18H,0C6H,18H,0C6H,1FH,0FEH,018H,0C6H,18H,0C6H
DB 18H,0C6H,1FH,0FEH,18H,0C6H,18H,0C6H,30H,0C6H,30H,0C6H,60H,0DEH,0C0H,0CCH
XING   DB 00H,00H,1FH,0FCH,18H,0CH,1FH,0FCH,18H,0CH,1FH,0FCH,01H,80H,19H,80H
DB 1FH,0FEH,31H,80H,31H,80H,6FH,0FCH,01H,80H,01H,80H,7FH,0FFH,00H,00H
YAN    DB 0,0,0FFH,0FFH,18H,0CCH,18H,0CCH,30H,0CCH,30H,0CCH,7FH,0FFH,7CH,0CCH
	   DB 0FCH,0CCH,3CH,0CCH,3CH,0CCH,3DH,8CH,3DH,8CH,33H,0CH,06H,0CH,0CH,0CH
SHI0   DB 01H,80H,00H,0C0H,3FH,0FFH,3CH,06H,67H,0CCH,06H,0C0H,0CH,0C0H,07H,0C0H
DB 06H,0C0H,7FH,0FFH,00H,0C0H,01H,0E0H,03H,30H,06H,18H,1CH,1CH,70H,18H
YAN0   DB 00H,00H,0FCH,60H,0CH,60H,6CH,0F0H,6CH,0D8H,6DH,8FH,6FH,0F8H,7EH,00H
DB 06H,0C6H,07H,66H,3FH,0ECH,0E7H,0ECH,06H,18H,1FH,0FFH,0CH,00H,00H,00H
YI	   DB 0CH,0C0H,0CH,60H,18H,7CH,1BH,6CH,33H,0CH,73H,18H,0F1H,98H,31H,98H
	   DB 30H,0F0H,30H,0F0H,30H,60H,30H,0F0H,31H,98H,33H,0FH,3EH,06H,30H,00H
NONE   DB 00H,00H,00H,00H,00H,00H,00H,00H,00H,00H,00H,00H,00H,00H,00H,00H
	   DB 00H,00H,00H,00H,00H,00H,00H,00H,00H,00H,00H,00H,00H,00H,00H,00H

HUAN_T 	DB 	32	DUP(?)
YING_T	DB	32	DUP(?)
SHI_T	DB	32	DUP(?)
YONG_T	DB	32	DUP(?)
XING_T	DB	32	DUP(?)
YAN_T	DB	32	DUP(?)
SHI0_T	DB	32	DUP(?)
YAN0_T	DB	32	DUP(?)
YI_T	DB	32	DUP(?)
NONE_T	DB	32	DUP(?)

_DATA	ENDS		
CODE	SEGMENT		
START	PROC	NEAR	
	ASSUME	CS:CODE, DS:_DATA, SS:_STACK
	MOV	AX,_DATA	
	MOV	DS,AX	
	MOV	ES,AX	
	NOP		
	CALL	INIT_IO	
	CALL		TEST_LED		;调用测试子程序,测试LED是否全亮
	CALL	TRANSFER
	CALL		CLEAR	
;滚动显示多个字符
CHS_SHOW:	MOV		CX,9	
	LEA		SI,HUAN_T	
CHS_1:	PUSH	CX	
	MOV	CX,16		
CHS_2:	CALL	DISP_CH	
	INC	SI	
	INC	SI	
	LOOP		CHS_2	
	POP	CX	
	LOOP		CHS_1	
	JMP	CHS_SHOW	
;显示一个16*16点阵字子程序,字型码放在DPTR指出的地址
DISP_CH	PROC	NEAR	
	PUSH		CX	
	MOV	CX,8	
DISP_CH_1:	CALL	DISP1	
	LOOP		DISP_CH_1	
	POP		CX	
	RET		
DISP_CH	ENDP		
;显示一个16*16点阵字子程序,字型码放在显示缓冲区XBUFF
DISP1	PROC	NEAR	 
	PUSH		SI	
	PUSH		CX	
	MOV	CX,16	;计数器,16列依次被扫描
	MOV		BX,8000H		;列输出值保持单列为高电平接通循环扫描
REPEAT:		MOV		DX,ROW1	
	MOV 	AL,BL
	OUT		DX,AL	;左边行输出
	MOV		DX,ROW2	
	MOV 	AL,BH
	OUT		DX,AL	;右边行输出	
	
	LODSB		
	CALL	ADJUST	;调整AL,将AL中二进制数旋转180度
	MOV		DH,AL

	LODSB		
	CALL	ADJUST	;调整AL,将AL中二进制数旋转180度
	MOV		DL,AL	
	MOV 	AX,DX
	NOT		AX		;子模取反，保证低电平为有效位
	MOV		DX,LINE
	OUT		DX,AX	;列输出
	CALL	DL10MS	
	CALL		CLEAR	
	CLC			
	RCR	BX,1		;循环移位BX,行线扫描输出0
	LOOP	REPEAT	
	POP	CX	
	POP	SI	
	RET		
DISP1	ENDP		
INIT_IO		PROC	NEAR	
	MOV	DX,ADDR_8255_C	;8255控制字地址
	MOV	AL,80H	;设置8255的PA、PB、PC口为输出口
	OUT	DX,AL	;写控制字
	RET		
INIT_IO		ENDP		
CLEAR	PROC	NEAR	
	MOV	AX,0FFFFH	
	MOV	DX,LINE	
	OUT	DX,AX	
	MOV	AL,0	
	MOV	DX,ROW1	
	OUT	DX,AL	
	MOV	DX,ROW2	
	OUT	DX,AL	
	RET		
CLEAR	ENDP		
;测试LED子程序,点亮LED并延时1S
TEST_LED	PROC	NEAR		
	MOV	DX,LINE	
	XOR	AX,AX	
	OUT	DX,AX	
	MOV	AL,0FFH	
	MOV	DX,ROW1	
	OUT	DX,AL	
	MOV	DX,ROW2	
	OUT	DX,AL	
	CALL		DL500ms	
	CALL		DL500ms	
	RET		
TEST_LED		ENDP			
;调整AL中取到的字型码的一个字节,将最高位调整位最低位,最低位调整为最高位
ADJUST	PROC		NEAR	
	PUSH		CX	
	MOV	CX,8	
ADJUST1:	RCL	AL,1	
	XCHG	AL,AH	
	RCR		AL,1	
	XCHG	AL,AH	
	LOOP		ADJUST1	
	MOV		AL,AH	
	POP	CX	
	RET		
ADJUST	ENDP		
DL10ms	PROC		NEAR	
	PUSH		CX	
	MOV	CX,133	
	LOOP	$	
	POP		CX	
	RET		
DL10ms	ENDP			
DL500ms		PROC	NEAR	
	PUSH		CX	
	MOV		CX,0FFFFH	
	LOOP		$	
	POP	CX	
	RET		
DL500ms	ENDP	

;字模转置
TRANSFER 	PROC	NEAR
			LEA SI,HUAN
			LEA DI,HUAN_T
			MOV CX,10	
TRANS_ALL:	PUSH CX
			MOV CX,16	
			MOV DX,0100H	
CYC_LINE:	PUSH CX
			PUSH SI
			MOV BX,0000H 
			MOV CX,16
CYC_BIT:	LODSW 
			TEST AX,DX
			JZ	CTU			
			OR	BX,8000H 
CTU:		ROL	BX,1
			LOOP	CYC_BIT
			
			MOV AX,BX
			STOSW			
			ROL	DX,1
			POP SI
			POP CX
			LOOP CYC_LINE
			
			ADD SI,20H		
			POP CX
			LOOP	TRANS_ALL
			RET
TRANSFER ENDP

START	ENDP		
CODE	ENDS		
	END	START	


