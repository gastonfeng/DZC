
FM BIT P3.0                         ;Ѷ����
DM BIT P3.1                         ;���ӷ�
CLJL DATA 21H                        ;���ۼƻ�����     (4�ֽ�)
BLJL DATA 25H                        ;���ۼƻ�����     (4�ֽ�)
CLJCL DATA 65H                       ;���ۼƴ��������� (4�ֽ�)
BLJCL DATA 32H                       ;���ۼƴ��������� (2�ֽ�)
BLJCH DATA 33H
PZL DATA 34H                         ;Ƥ�ػ�����(2�ֽ�)
PZH DATA 35H
YZL DATA 36H                         ;Ԥ������������(2�ֽ�)
YZH DATA 37H
MZL DATA 38H                         ;ë�ػ�����(2�ֽ�)
MZH DATA 39H
DIAPL DATA 50H                      ;��ʾ������(4��)
YZ2L DATA 42H                        ;Ԥ�����޻�����(2�ֽ�)
YZ2H DATA 43H
JZ1L DATA 40H                        ;���ػ�����(2�ֽ�)
JZ1H DATA 41H
              ORG 0000H
              LJMP STAR
                ORG 000BH
                AJMP LP1


STAR:                                      ;�ϵ����
                LCALL ZIJIAN
                MOV TMOD,#10                   ;�趨ʱ��ʽ1
                SETB TR0
LP:             MOV TH0,#0F5H
                MOV TL0,#031H
                JNB TF0,LOOP
                CLR TF0
                setb ea
                setb et0
LOOP:           MOV BLJCL,#0                     ;�Ͱ��ۼƴ���
                LCALL ADC
                MOV A,R4                     ;Ƥ�ص�λ
                MOV PZL,A
                MOV A,R5
                MOV PZH,A
                MOV A,BLJCL
                ADD A,#1
                DA A
                MOV BLJCL,A
                MOV A,BLJCH
                ADDC A,#0
                DA A
                MOV BLJCH,A
                MOV @R0,PZL
                LCALL BCD                     ;��BCD����
                LCALL FL                      ;�������ӳ���
LOOP1:          LCALL KEY_OPR
                CJNE A,#0E7H,KEY1
                MOV R6,#0H
                LCALL TJ                      ;"F"����
KEY1:           CJNE A,#0EBH,KEY2
                MOV R6,#1
                LCALL SJ                      ;�����ּ������ӳ���
KEY2:           CJNE A,#0EDH,KEY3
                MOV R6,#2H
                LCALL SJ
KEY3:           CJNE A,#0EEH,KEYS
                MOV R6,#3H
                LCALL SJ
KEYS:           CJNE A,#0D7H,KEY4
                MOV R6,#0D7H
                LCALL QD                    ;�������ӳ���
KEY4:           CJNE A,#0DBH,KEY5
                MOV R6,#4H
                LCALL SJ
KEY5:           CJNE A,#0DDH,KEY6
                MOV R6,#5H
                LCALL SJ
KEY6:           CJNE A,#0DEH,KEYCPJ
                MOV R6,#6H
                LCALL SJ
KEYCPJ:         CJNE A,#0B7H,KEY_7
                LCALL CP                     ;����Ƥ�ӳ���
KEY_7:          CJNE A,#0BBH,KEY_8
                MOV R6,#7H
                LCALL SJ
KEY_8:          CJNE A,#0BDH,KEY_9
                MOV R6,#9
                LCALL SJ
KEY_9:          CJNE A,#0BEH,KEY_LJ
                MOV R6,#9H
                LCALL SJ
KEY_LJ:         CJNE A,#77H,KEY_lj1
                LCALL BLJ1                  ;���ۼ��ӳ���
key_lj1:        cjne a,#77h,key_0
                lcall bljc1
KEY_0:          CJNE A,#7BH,K_1
                MOV R6,#0
                LCALL SJ
K_1:            CJNE A,#7DH,KEY_CLR          ;С�����
                LCALL DIAN
KEY_CLR:        CJNE A,#7EH,LOOP1
                CLR P3.1

ADC:            JB INT0,ADC
                MOV TL0,#0
                MOV TH0,#0
                SETB TR0
WH:             JNB INT0,WH
WL:             JB INT0,WL
                CLR TR0
                CLR C
                MOV A,TL0
                RRC A
                MOV R2,A
                SUBB A,#11H
                MOV R4,A
                MOV A,TH0
                RRC A
                MOV R3,A
                SUBB A,#27H
                MOV R5,A
                RET

QD:             SETB P3.1
                LCALL ADC
                MOV A,R4
                MOV MZL,A
                SUBB A,PZL         ;����(��λ)
                ADD A,JZ1L
                MOV JZ1L,A
                MOV BLJL,A          ;���ۼƾ���
                MOV A,R5
                MOV MZH,A
                SUBB A,PZH         ;����(��λ)
                ADD A,JZ1H
                MOV JZ1H,A
                INC BLJL
                MOV BLJL,A
L0:             CJNE A,YZL,L1
                MOV A,JZ1L
                CJNE A,YZH,L2
                LJMP L3
L1:             JC L3
L4:             CLR P3.1          ;�رյ��ӷ�,Ѷ������
                MOV TMOD,#00H       ;���Ƶ��Ϊ3K
                SETB TR0
L5:             MOV TH0,#03H
                MOV TL0,#10H
                JNB TF0,$
                CLR TF0
                CPL P3.0
                SJMP L5
L2:             JC L3
                LJMP L4
                MOV @R0,MZL
                LCALL BCD           ;��BCD����
                LCALL FL
L3:             RET

CP:             LCALL ADC                ;��Ƥ�ӳ���
                MOV A,R4
                MOV MZL,A
                SUBB A,PZL
                MOV JZ1L,A
                MOV A,R5
                MOV MZH,A
                SUBB A,PZH
                MOV JZ1H,A
                SETB B.0
                MOV A,PZL                ;����ʾƤ��
                MOV @R0,A
                LCALL BCD               ;��BCD����
                LCALL FL2                ;�������ӳ���
                setb b.1
                MOV A,MZL               ;����ʾë��
                MOV @R0,A
                LCALL BCD
                LCALL FL
                RET
KEY_OPR:        MOV R6,#0
                MOV R7,#0FEH
KEY_RD0:        CJNE R6,#4,KEY_RD
                AJMP KEY_OPR1
KEY_Rd:         LCALL DELAY20
                MOV A,R7
                RL A
                MOV R7,A
                INC R6
                ORL A,#0FH
                MOV P1,A
                MOV A,P1
                ORL A,#0F0H
                CJNE A,#0FFH,KEY_OPR
                AJMP KEY_RD0
KEY_OPR1:       MOV A,R7
                RL A
                MOV R7,A
                ORL A,#0FH
                MOV P1,A
                MOV A,P1
                ORL A,#0F0H
                CJNE A,#0FFH,KEY_YES
                MOV B,#0
                AJMP KEY_OPR1
KEY_YES:        ANL A,#0FH
                MOV B,A
                MOV A,R7
                ANL A,#0F0H
                ORL B,A
                MOV A,B
                CJNE A,R6,KEY_NOSAME
                MOV R6,B
                RET
KEY_NOSAME:     MOV R6,B
                LCALL DELAY20
                AJMP KEY_OPR1
DELAY20:        MOV 61H,#0C8H            ;��ʱ20ms������
LOOP20:         LCALL DELAY              ;��ʱ100US
                DJNZ 61H,LOOP20
                RET
DELAY:          MOV 62H,#11H
LOOP3:           DJNZ 62H,LOOP3
                RET
SJ:             MOV R6,YZL
                MOV A,#00
SJ2:            CJNE A,R6,SJ1
SJ3:            MOV R6,YZH
                RET
SJ1:            INC A
                CJNE A,#9,SJ2
                LJMP SJ3
BLJ1:           clr b                               ;���ۼ������ӳ���,��ʾ
                MOV A,BLJL
                MOV @R0,A
                LCALL BCD
                LCALL FL
TJ:             LCALL KEY_OPR
                CJNE A,#0E7H,F_KEY_1
                AJMP TJ
F_KEY_1:        CJNE A,#0EBH,F_KEY_2
                LCALL YZ1                   ;��Ԥ�������ӳ���
F_KEY_2:        CJNE A,#0EDH,F_KEY_LJ
                LCALL YZ_2                  ;��Ԥ�����������ӳ���
F_KEY_LJ:       CJNE A,#77H,F_KEY_lj1
                LCALL CLJ1                   ;�����ۼ��ӳ���
f_key_lj1:      cjne a,#77h,f_key_cp
                lcall cljc1
F_KEY_CP:       CJNE A,#0B7H,LOOP5
                LCALL ZCP                   ;���Զ���Ƥ�ӳ���
LOOP5:          RET
DISPLAY:        MOV R1,#57H                 ;��ʾ�ӳ���
DIS:            MOV 60H,#40H                 ;����λѡ��
                MOV A,@R1                   ;ȡ��ʾ����
                SJMP DISP_2
DISP_1:         MOV DPTR,#LED_TB
D3:             MOV A,@R1
                MOVC A,@A+DPTR
DISP_2:         CPL A                       ;����ȡ��
                MOV P0,A                    ;������P0��
                MOV A,60H
                MOV P2,A                    ;λѡ����P2��
                LCALL DELAY1                  ;��ʱ1MS
                CLR A
                MOV P2,A                    ;����ʾ
                DEC R1
                MOV 60H,A
                RR A
                MOV 60H,A
                JB B.0,D4
                JB B.1,D5
D1:             JNB ACC.7,DISP_1
                MOV A,R1
                ADD A,#7
                MOV R1,A
                RET
D4:             JB ACC.6,DI
                JB ACC.3,DI
                SJMP D1
D5:             JB ACC.3,DI
                SJMP D1
DI:             MOV DPTR,#LED_TB1
                AJMP D3
LED_TB:         DB 0C0H,0F9H,0A4H,0B0H
                DB 99H,92H,82H,0F8H,80H
                DB 90H
LED_TB1:        DB 40H,79H,24H,30H,19H,12H
                DB 02H,78H,00H,10H
DELAY1:         MOV 14H,#0AH
                LCALL DELAY
                DJNZ 14H,DELAY1
                RET
ZIJIAN:         MOV A,#00H                  ;��ʾ8��8�ӳ���
                MOV P0,A
                MOV P2,#0FFH
                RET
yz1:            setb b.1
                LCALL KEY_OPR
                CJNE A,#07EH,YZ1_1
                SJMP YZ1
YZ1_1:          CJNE A,#0D7H,YZ1_2
                SJMP YZ1
YZ1_2:          CJNE A,#0B7H,YZ1_3
                SJMP YZ1
YZ1_3:          CJNE A,77H,YZ1_4
                SJMP YZ1
YZ1_4:          CJNE A,7EH,YZ1_5
                SJMP YZ1
YZ1_5:          CJNE A,#7DH,YZ1_6
                LCALL DIAN             ;��С������ʾ�ӳ���
YZ1_6:          LCALL SJ
                RET
YZ_2:           LCALL YZ1
                RET
ZCP:            SETB B.0
                MOV A,PZL                   ;�Զ���Ƥ,����ʾƤ��
                MOV @R0,A
                LCALL BCD
                LCALL FL2
                SETB B.1
                MOV A,JZ1L               ;����ʾ����
                MOV @R0,A
                LCALL BCD
                LCALL FL
                RET
BCD:            ;˫�ֽ�ʮ�������޷�������ת���ɶ��ֽ�BCD���޷�������
                ;���:��������[R0]��
                ;����:�����[R0]��,����λ��R3��
                MOV a,R1
                push acc
                mov a,r0
                inc a
                mov r1,a
                CLR A
                XCH A,@R0
                MOV R3,A
                CLR A
                XCH A,@R1
                MOV R4,A
                MOV R2,#4
bcd3:           MOV A,@R1
                SWAP A
                MOV @R1,A
                CLR A
                XCHD A,@R1
                XCH A,@R0
                SWAP A
                XCHD A,@R0
                MOV @R0,A
                MOV B,#10
                MUL AB
                MOV R4,A
                MOV R5,B
                MOV A,R3
                MOV B,#10
                ADD A,R5
                MOV R3,A
                CLR A
                ADDC A,B
                XCHD A,@R1
                DJNZ R2,BCD3
                MOV A,R3
                RLC A
                JNC BCD4
                MOV A,@R1
                ADD A,#1
                DA A
                MOV R1,A
                MOV A,@R0
                ADDC A,#0
                DA A
                MOV @R0,A
BCD4:           POP ACC
                MOV R1,A
                RET
LP1:            PUSH R1
                PUSH ACC
                push b
                LCALL DISPLAY
                pop b
                POP ACC
                POP R1
                RETI
FL:             MOV R1,#54H
fl1:            MOV A,R3                ;��λ��
                MOV @R1,A
                INC R0
                MOV A,@R0
                ANL A,#0F0H             ;ǧ,��λ����
                SWAP A
                INC R1
                MOV @R1,A
                ANL A,#0FH
                INC R1
                MOV @R1,A
                MOV A,@R0                ;��,ʮλ����
                ANL A,#0F0H
                SWAP A
                INC R1
                MOV @R1,A
                MOV A,@R0
                ANL A,#0FH
                INC R1
                MOV @R1,A
                RET
FL2:            MOV R1,#50H
                AJMP FL1
                RET
DIAN:           MOV A,#0FFH         ;С������ʾ�ӳ���
                MOV P0,A
                SETB P2.6
                RET
clj1:           clr b
                MOV A,CLJL
                ADD A,BLJL
                MOV CLJL,A
                MOV @R1,CLJL
                MOV R7,#3             ;BCDѹ����ӵ�λ���λ���
CLJ1_1:         INC CLJL
                INC BLJL
                MOV A,CLJL
                ADDC A,BLJL
                MOV CLJL,A
                DJNZ R7,CLJ1_1
                RET
bljc1:          clr b
                mov @r0,bljcL
                LCALL FL
                ret
cljc1:          clr b
                MOV A,CLJCL
                ADD A,BLJCL
                DA A
                MOV CLJCL,A
                INC CLJCL
                MOV A,CLJCL
                ADDC A,BLJCH
                DA A
                MOV CLJCL,A
C1:             INC CLJCL
                MOV A,CLJCL
                ADDC A,#0
                DA  A
                MOV A,CLJCL
                INC CLJCL
                MOV A,CLJCL
                ADDC A,#0
                DA A
                MOV A,CLJCL
fln:            mov r1,#50h
cl2:            mov a, cljcl
                anl a,#0f0h
                swap a
                mov @r1,a
                mov a,cljcl
                anl a,#0fh
                inc r1
                mov @r1,a
                inc cljcl
                inc r1
                mov a,r1
                cjne a,#57h,cl2
                ajmp cl3
cl3:            RET
                END
