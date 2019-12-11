IO8259_0	EQU	0250H	
IO8259_1		EQU		0251H	
Con_8253	EQU	0263H	
T0_8253	EQU	0260H	

COM_ADD	EQU	0273H
PA_ADD	EQU	0270H
PB_ADD	EQU		0271H
PC_ADD	EQU	0272H

_STACK	SEGMENT		STACK	
	DW	200 DUP(?)	 
_STACK		ENDS		
			
_DATA	SEGMENT	WORD PUBLIC 'DATA'	
halfsec	DB	0	;0.5秒计数
Sec		DB	0	;秒
Min		DB	0	;分
hour		DB	0	;时
buffer	DB	8 DUP(0)	;显示缓冲区，8个字节
buffer1	DB	8 DUP(0)		;显示缓冲区，8个字节
bNeedDisplay	DB	0	;需要刷新显示
number	DB	0	;设置哪一位时间
bFlash	DB	0	;设置时是否需要刷新

VICODE	DB	40H,79H,24H,30H,19H
		DB	12H,02H,78H,00H,18H		
		DB	80H,03H,43H,21H,06H,0EH
		
KEYVALUE DB 0FFH
KEYSTATE DB 00H	
	
_DATA	ENDS		
			
CODE	SEGMENT			
START	PROC	NEAR	
	ASSUME	CS:CODE, DS:_DATA, SS:_STACK
	MOV	AX,_DATA	
	MOV	DS,AX	
	MOV	ES,AX	
	NOP		
	CALL	InitKeyDisplay	;对键盘、数码管扫描控制器8255初始化
	mov	sec,0		;时分秒赋初值23:58:00
	mov	min,58	
	mov	hour,23	
	MOV		bNeedDisplay,1	;显示初始值
	CALL		Init8253	
	CALL		Init8259	
	CALL		WriIntver	
	STI		
MAIN:	CALL	GetKeyA	;按键扫描
	JNB	Main1	
	CMP	AL,0FH	;设置时间
	JNZ		Main1	
	CALL	SetTime	
Main1:	CMP		bNeedDisplay,0	
	JZ	MAIN	
	CALL	Display_LED	;显示时分秒
	MOV	bNeedDisplay,0	;1s定时到刷新转速
Main2:	JMP		MAIN	              ;循环进行实验内容介绍与测速功能测试
SetTime	PROC	NEAR	
	LEA		SI,buffer1	
	CALL	TimeToBuffer	
	MOV	Number,0	
Key:		CMP	bFlash,0	
	JZ	Key2	
	LEA		SI,buffer1	
	LEA		DI,buffer	
	MOV	CX,8	
	REP	MOVSB	
	CMP	halfsec,0	
	JNZ	FLASH	
	MOV		BL,number	
	NOT	BL	
	AND	BX,07H	
	LEA		SI,buffer	
	MOV	BYTE PTR [SI+BX],10H	;当前设置位置产生闪烁效果
FLASH:	LEA	SI,buffer	
	CALL		Display8	
	MOV	bFlash,0	
Key2:	CALL	GetKeyA	
	JNB	Key	
	CMP		AL,0EH	;放弃设置
	JNZ	Key1	
	JMP		Exit	
Key1:	CMP	AL,0FH	
	JZ	SetTime8	
SetTime1:	CMP	AL,10	
	JNB	Key		;无效按键
	CMP	number,0	
	JNZ		SetTime2	
	CMP	AL,3		;调整时的十位数
	JNB	Key	
	MOV		buffer1 + 7,AL	
	JMP	SetTime7	
SetTime2:	CMP		number,1	
	JNZ		SetTime3	
	CMP	buffer1 + 7,1	;调整时的个位数
	JZ	SetTime2_1	
	CMP	AL,4	
	JNB	Key	
SetTime2_1:	MOV		buffer1 + 6,AL	
	INC	number	
	JMP	SetTime7	
SetTime3:	CMP	number,3	
	JNZ	SetTime4	
	CMP	AL,6		;调整分的十位数
	JNB	Key	
	MOV	buffer1 + 4,AL	
	JMP		SetTime7		
SetTime4:	CMP		number,4	
	JNZ	SetTime5	
	MOV		buffer1 + 3,AL	;调整分的个位数
	INC	number	
	JMP		SetTime7	
SetTime5:	CMP	number,6	
	JNZ	SetTime6	
	CMP	AL,6		;调整秒的十位数
	JB	SetTime5_1	
	JMP	Key	
SetTime5_1:	MOV	buffer1 + 1,AL	
	JMP	SetTime7	
SetTime6:	MOV		buffer1,AL	;调整秒的个位数
SetTime7:	INC	number	
	CMP		number,8	
	JNB	SetTime8	
	MOV	bFlash,1	;需要刷新
	JMP		Key		
SetTime8:	MOV		AL,buffer1 + 1	;确认
	MOV		BL,10	
	MUL	BL	
	ADD	AL,buffer1	
	MOV		sec,AL		;秒
	MOV	AL,buffer1 + 4	
	MUL	BL	
	ADD	AL,buffer1 + 3	
	MOV	min,AL	;分
	MOV	AL,buffer1 + 7	
	MUL	BL	
	ADD	AL,buffer1 + 6	
	MOV	hour,AL	;时
	JMP		Exit	
Exit:	RET		
SetTime		ENDP		
;hour min sec转化成可显示格式
TimeToBuffer	PROC	NEAR	
	MOV	AL,sec	
	XOR	AH,AH	
	MOV	BL,10	
	DIV	BL	
	MOV	[SI],AH	
	MOV	[SI + 1],AL	;秒
	MOV	BYTE PTR [SI + 2],10H	;这位不显示
	MOV	AL,min	
	XOR	AH,AH	
	DIV	BL	
	MOV	[SI + 3],AH	
	MOV		[SI + 4],AL		;分
	MOV	BYTE PTR [SI + 5],10H  	;这位不显示
	MOV		AL,hour	
	XOR		AH,AH	
	DIV	BL	
	MOV		[SI + 6],AH		
	MOV	[SI + 7],AL	;时
	RET		
TimeToBuffer	ENDP		
;显示时分秒
Display_LED	PROC	NEAR	
	LEA		SI,buffer	
	CALL	TimeToBuffer	
	LEA		SI,buffer	
	CALL	Display8		;显示
	RET		
Display_LED		ENDP		
;0.5s产生一次中断
Timer0Int:	PUSH		AX	
	PUSH		DX	
	MOV	bFlash,1	
	INC	halfsec	
	CMP	halfsec,2	
	JNZ		Timer0Int1	
	MOV	bNeedDisplay,1	
	MOV		halfsec,0	
	INC	sec	
	CMP	sec,60	
	JNZ	Timer0Int1	
	MOV	sec,0	
	INC	min	
	CMP		min,60	
	JNZ	Timer0Int1	
	MOV		min,0	
	INC	hour	
	CMP	hour,24	
	JNZ		Timer0Int1	
	MOV	hour,0	
Timer0Int1:	MOV	DX,IO8259_0	
	MOV	AL,20H	
	OUT	DX,AL	
	POP	DX	
	POP	AX	
	IRET			
Init8253	PROC		NEAR	
	MOV	DX,Con_8253	
	MOV	AL,34H	
	OUT	DX,AL	;计数器T0设置在模式2状态,HEX计数
	MOV	DX,T0_8253	
	MOV	AL,12H	
	OUT	DX,AL	
	MOV	AL,7AH	
	OUT	DX,AL	;CLK0=62.5kHz,0.5s定时
	RET		
Init8253		ENDP		
Init8259	PROC	NEAR	
	MOV	DX,IO8259_0	
	MOV		AL,13H	
	OUT		DX,AL	
	MOV		DX,IO8259_1	
	MOV		AL,08H	
	OUT	DX,AL	
	MOV	AL,09H	
	OUT		DX,AL	
	MOV	AL,0FEH	
	OUT		DX,AL	
	RET		
Init8259		ENDP		
WriIntver	PROC	NEAR	
	PUSH		ES	
	MOV	AX,0	
	MOV		ES,AX	
	MOV		DI,20H	
	LEA	AX,Timer0Int	
	STOSW		
	MOV	AX,CS	
	STOSW		
	POP		ES	
	RET		
WriIntver	ENDP
		
InitKeyDisplay PROC NEAR
	MOV	DX,COM_ADD
	MOV	AL,80H
	OUT	DX,AL		
	MOV AL,0FFH
	MOV DX,PA_ADD
	OUT	DX,AL
	MOV DX,PB_ADD
	OUT	DX,AL
	MOV AL,00H
	MOV	DX,PC_ADD
	OUT	DX,AL			
	RET
InitKeyDisplay ENDP

GetKeyA PROC NEAR
	PUSH BX			
	PUSH DX
	PUSH CX
	PUSH SI
	LEA SI,buffer
	CALL Display8
	POP SI
	MOV	DX,COM_ADD
	MOV	AL,82H		
	OUT DX,AL
	MOV AL,00H
	OUT	DX,AL		
	MOV AL,03H
	OUT DX,AL		
	MOV DX,PB_ADD	
	IN	AL,DX
	MOV	BL,AL
	MOV DX,COM_ADD
	MOV AL,01H
	OUT DX,AL
	MOV AL,02H
	OUT DX,AL
	MOV DX,PB_ADD
	IN	AL,DX
	MOV BH,AL
	MOV DX,PC_ADD			
	MOV AL,0FFH
	OUT DX,AL
	CMP BX,0FFFFH
	JNE	REDETECT
	JMP OVER
REDETECT:MOV CX,2BAH
DELAY:LOOP DELAY		
	MOV	DX,COM_ADD
	MOV AL,00H
	OUT	DX,AL		
	MOV AL,03H
	OUT DX,AL		
	MOV DX,PB_ADD	
	IN	AL,DX
	MOV	CL,AL
	MOV DX,COM_ADD
	MOV AL,01H
	OUT DX,AL
	MOV AL,02H
	OUT DX,AL
	MOV DX,PB_ADD
	IN	AL,DX
	MOV CH,AL
	MOV DX,PC_ADD			
	MOV AL,0FFH
	OUT DX,AL
	CMP CX,BX
	JE	KEYPRESS
	JMP OVER
KEYPRESS:				
	NOT BX
	MOV CL,0
CYC:TEST BX,0001H
	JNZ CYCEND
	INC CL
	SHR BX,1
	JMP CYC
CYCEND:MOV KEYVALUE,CL
	MOV KEYSTATE,01H
	MOV AL,0FFH
	JMP BACK
	
OVER:MOV BL,KEYSTATE
	MOV AL,0FFH
	MOV KEYSTATE,00H			
	CMP BL,01H
	JNZ BACK
	MOV AL,KEYVALUE
BACK:CMP AL,1FH	
	POP CX
	POP DX
	POP BX
	RET
GetKeyA ENDP

Display8 PROC NEAR
	PUSH DX				
	PUSH AX  
	PUSH CX
	PUSH SI  
	PUSH BX
	MOV DX,COM_ADD
	MOV AL,80H
	OUT	DX,AL		
	MOV CX,8
	MOV BL,0FEH
L:	MOV AL,0FFH   
	MOV DX,PB_ADD
	OUT DX,AL
	LODSB 
	PUSH SI
	LEA SI,VICODE
	MOV AH,0
	CMP AL,0FH
	JNG OK
	POP SI
	JMP COT
OK:	ADD SI,AX
	LODSB
	POP SI
	MOV DX,PA_ADD
	OR AL,80H			
	OUT DX,AL			
	MOV AL,BL			
	MOV DX,PB_ADD
	OUT DX,AL
COT:	ROL BL,1
	PUSH CX
	MOV CX,18AH
	LOOP $
	POP CX
	LOOP L
	MOV AL,0FFH   
	MOV DX,PB_ADD
	OUT DX,AL
	POP BX
	POP SI
	POP CX
	POP AX
	POP DX
	RET
Display8	ENDP

START	ENDP		
CODE	ENDS		
	END	START	



 




