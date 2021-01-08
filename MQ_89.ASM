$debug
        NAME MQ
        EXTRN CODE(ROM_R)
        EXTRN CODE(ROM_W)
        EXTRN DATA(?ROM_R?BYTE)
        EXTRN DATA(?ROM_W?BYTE)


dis_h   equ 0f5h
dis_l   equ 0ffh


p00 data 80h
p11 data 90h
p22 data 0a0h
p33 data 0b0h
FM BIT 0b6h             ;讯响器
DM BIT 0b7h             ;电子阀
flag    bit 0b1h        ;F功能键指示
auto    bit 0b0h        ;自动除皮指示
point   bit 0cah        ;小数点指示
flag1   bit 7ah         ;累计键的切换指示


CLJL DATA 21H           ;总累计缓冲区     (4字节)
CLJL2 DATA 22H
CLJL3 DATA 23H
CLJL4 DATA 24H
BLJL DATA 25H           ;斑累计缓冲区     (4字节)
bljl2 data 26h
bljl3 data 27h
bljl4 data 28h
BLJCL DATA 29H          ;斑累计次数缓冲区 (2字节)
BLJCH1 DATA 2aH
CLJCL DATA 2bH
CLJC2 DATA 2cH
CLJC3 DATA 2dH
CLJC4 DATA 2eH         ;总累计次数缓冲区 (4字节)
YZL DATA 2fH            ;预置重量缓冲区(2字节)
YZH DATA 30H
Y2L DATA 31H    ;预置上限缓冲区(2字节)
Y2H DATA 32H
dis_point  data 33h     ;显示指针
zero    data 34h        ;初始零点*2
timer_1 data 36h
PZL DATA 37H            ;皮重缓冲区(2字节)
PZH DATA 38H
MZL DATA 39H            ;毛重缓冲区(2字节)
MZH DATA 3aH
buf data 3bh            ;4字节缓冲区
JZ1L DATA 3fH           ;净重缓冲区(2字节)
JZ1H DATA 40H
buf1 data 41h           ;4字节缓冲区
BU DATA 45H             ;放最高字节BCD码
result  data 46h        ;A/D转换结果存放区
DIAPL DATA 50H
          ;显示缓冲区(4个)

              ORG 0000H
              LJMP STAR

;        org 3
;        lcall int_0     ;外部中断0,A/D转换开始
;        reti

              ORG 000BH
              Ljmp LP1  ;定时器0溢出中断

        org 13h
        lcall int_1     ;外部中断1,A/D转换结束
        reti



STAR:                          ;断电记忆

                mov sp,#5ah
                clr dm
                lcall delay500
                clr fm
                clr flag
                clr flag1
        clr auto
        mov r0,#21h
memr:
        mov ?rom_r?byte,r0
        push 0
        lcall rom_r
        pop 0
        mov a,r7
        mov @r0,a
        inc r0
        cjne r0,#33h,memr
        mov ?rom_r?byte,#0
        lcall rom_r
        cjne r7,#0ffh,lpp_1
        setb auto
lpp_1:
                mov dis_point,#0
              MOV TMOD,#91h                   ;设定时方式1
              MOV TH0,#dis_h
              MOV TL0,#dis_l
              SETB TR0
              setb it1
              setb it0
        mov a,#4
        mov ip,a        ;设置外部中断为高优先级
        mov a,#86h
        mov ie,a      ;设置外部和定时器0中断
              lcall zijian
                mov a,#0
                mov mzl,a         ;毛重清0
                mov mzh,a
                mov pzl,a       ;皮重清0
                mov pzh,a
        mov jz1l,a      ;净重清0
        mov jz1h,a
                mov BLJCL,A     ;斑累计次数清0
                mov BLJCH1,A
                mov BLJL,A      ;斑累计清0
                mov BLJL2,A
                mov BLJL3,A
                mov BLJL4,A
llp:
                LCALL adc
        clr c
        subb a,zero+1
        mov r7,a
        mov a,b
        subb a,zero
        mov r6,a
        cjne r6,#27h,ll_1
        ajmp ll_2
ll_1:
        jc ll_3
ll_2:
        mov r6,#0
        mov r7,#0
ll_3:
                MOV PZh,r6
                MOV PZl,r7
                lcall wg_dis
LOOP1:
                lcall key_opr
                mov a,R6
                CJNE A,#0EeH,KEYs
                LCALL TJ                      ;"F"键吗
                sjmp llp
KEYS:           CJNE A,#0DeH,KEY_LJ
                LCALL QD                    ;调启动子程序
                sjmp llp
KEY_LJ:         CJNE A,#7eH,K_3
                jb flag1,k_12
                LCALL BLJ1                  ;斑累计子程序
                sjmp llp
k_12:           lcall bljc1
K_3:
        sjmp llp


;外部中断0
;打开定时器1,开始A/D计数
int_0:
        setb  tr1
        ret

;外部中断1
;关闭定时器,返回A/D结果
int_1:
        push psw
        push acc
        push 3
        clr tr1
        mov a,tl1
        add a,#35
        mov tl1,a
        mov a,th1
        addc a,#0
        mov th1,a
                CLR C
                mov a,th1
                rrc a
                mov r3,a
                mov a,tl1
                rrc a
                clr c
                subb a,#11h
                push acc
                mov a,r3
                subb a,#27h
        clr c
        rrc a
                mov result,a
                pop acc
        rrc a
        mov result+1,a
        mov th1,#0
        mov tl1,#0
        setb tr1
        pop 3
        pop acc
        pop psw
        ret

adc:
        mov b,result
        mov a,result+1
        mov r6,result
        mov r7,result+1
        ret



QD:
                SETB dm
qd1:                lcall key_opr
                cjne r6,#77h,ll1     ;清除键退出
                ljmp l4
ll1:
                cjne r6,#0beh,ll2    ;除皮键进行除皮切换
                cpl auto
ll2:
                LCALL adc
        clr c
        mov a,r7
        subb a,zero+1
        mov r7,a
        mov a,r6
        subb a,zero
        mov r6,a
        cjne r6,#27h,qd_ll1
        ajmp qd_ll2
qd_ll1:
        jc qd_ll3
qd_ll2:
        mov r6,#0
        mov r7,#0
qd_ll3:
               MOV MZL,r7
                mov mzh,r6
        mov a,pzh
        cjne a,mzh,q_l0
        sjmp q_l1
q_l0:
        jc q_l2
q_l1:
        mov a,pzl
        cjne a,mzl,q_l3
        sjmp q_l2
q_l3:
        jc q_l2
        sjmp ll2
q_l2:
                mov a,mzl
                subb a,pzl
                mov jz1l,a
                mov a,mzh
                subb a,pzh
                mov jz1h,a           ;送净重高位
                lcall wg_dis
                lcall delay500
l0:
                mov buf,jz1h          ;净重分离压缩BCD码
                mov buf+1,jz1l
                mov r0,#buf
                mov r7,#2h
                lcall bcd
                mov a,buf
                CJNE A,YZh,L1      ;比较高位
                MOV A,buf+1
                CJNE A,YZl,L2      ;比较低位
                LJMP L4
L1:             JC l3
L4:             CLR dm          ;关闭电子阀,讯响器响
                setb fm

                ajmp lL7
L2:             JC l3
                LJMP L4
l3:             ajmp qd1  ;进行adc采样等侍
ll7:
                MOV A,bljcl               ;斑累计次数加1
                ADD A,#1
                da a                     ;十进制调正
                mov bljcl,a
                mov a,bljch1
                addc a,#0
                da a
                mov bljch1,A

                MOV  A,JZ1L          ;斑累计重量累加(4字节)
                ADD A,BLJl
                MOV BLJL,A
                MOV A,JZ1H
                ADDC A,BLJl2
                MOV BLJL2,A
                MOV A,BLJL3
                ADDC A,#0
                MOV BLJL3,A
                MOV A,BLJL4
                ADDC A,#0
                MOV BLJL4,A
;总累计
        mov a,cljcl
        add a,#1
        da a
        mov cljcl,a
        mov a,cljc2
        addc a,#0
        da a
        mov cljc2,a
        mov a,cljc3
        addc a,#0
        da a
        mov cljc3,a
        mov a,cljc4
        addc a,#0
        da a
        mov cljc4,a

        mov a,cljl
        add a,jz1l
        mov cljl,a
        mov a,cljl2
        addc a,jz1h
        mov cljl2,a
        mov a,cljl3
        addc a,#0
        mov cljl3,a
        mov a,cljl4
        addc a,#0
        mov cljl4,a
               lcall save
        clr fm
q_ll7:
                lcall key_opr
                cjne r6,#077h,ll8   ;按清除键,退出
                ajmp l6
ll8:
                LCALL adc
                lcall delay500
        clr c
        mov a,r7
        subb a,zero+1
        mov r7,a
        mov a,r6
        subb a,zero
        mov r6,a
        cjne r6,#27h,qd_ll10
        ajmp qd_ll20
qd_ll10:
        jc qd_ll30
qd_ll20:
        mov r6,#0
        mov r7,#0
qd_ll30:
               MOV MZL,r7
                mov mzh,r6
                mov a,mzl
                subb a,pzl
                mov jz1l,a
                mov a,mzh
                subb a,pzh
                mov jz1h,a           ;送净重高位
                mov a,jz1h      ;判净重为0吗
                cjne a,#00,l5
                mov a,jz1l
                cjne a,#00,l5
                ajmp l6          ;为0进行斑累计次数,重量累加
l5:             ajmp q_Ll7       ;不为0等待清除键按下
l6:                            ;
                clr dm
               lcall wg_dis
               mov a,#0
               mov mzh,a
               mov mzl,a
               mov jz1h,a
               mov jz1l,a
               mov timer_1,#1
                RET


wg_dis:
                mov buf,pzh
                mov buf+1,pzl
                mov r0,#buf
                mov r7,#2
                lcall bcd
                MOV A,BUF
                aNL A,#0F0H
                SWAP A
                MOV DIAPL+7,A
                MOV A,BUF
                ANL A,#0FH
                ORL A,#10H
                MOV DIAPL+6,A
                MOV A,BUF+1
                ANL A,#0F0H
                SWAP A
                MOV DIAPL+5,A
                MOV A,BUF+1
                ANL A,#0FH
                MOV DIAPL+4,A
                jnb auto,mz_dis
jz_dis:
                mov buf,jz1h
                mov buf+1,jz1l
                mov r0,#buf
                mov r7,#2
                lcall bcd
                MOV A,BUF
                ANL A,#0F0H
                SWAP A
                MOV DIAPL+3,A
                MOV A,BUF
                ANL A,#0FH
                ORL A,#10H
                MOV DIAPL+2,A
                MOV A,BUF+1
                ANL A,#0F0H
                SWAP A
                MOV DIAPL+1,A
                MOV A,BUF+1
                ANL A,#0FH
                MOV DIAPL+0,A
               ajmp wg_end
mz_dis:
                mov buf,mzh
                mov buf+1,mzl
                mov r0,#buf
                mov r7,#2h
                lcall bcd
                MOV A,BUF
                ANL A,#0F0H
                SWAP A
                MOV DIAPL+3,A
                MOV A,BUF
                ANL A,#0FH
                ORL A,#10H
                MOV DIAPL+2,A
                MOV A,BUF+1
                ANL A,#0F0H
                SWAP A
                MOV DIAPL+1,A
                MOV A,BUF+1
                ANL A,#0FH
                MOV DIAPL+0,A
wg_end:
                ret



KEY_OPR:
                mov r6,#0ffh
                MOV R2,#0
                MOV R7,#0FEH
key_opr1:       MOV A,R7
                mov p11,a
                mov a,p11
                cpl a
                anl a,#0f0h
                jnz key_rd
                inc r2
                mov a,r7
                rl a
                jnb acc.4,k_10
                mov r7,a
                AJMP KEY_OPR1
KEY_Rd:         LCALL DELAY20
                LCALL DELAY20
                LCALL DELAY20
                LCALL DELAY20
                MOV A,R7
                ORL A,#0F0H
                MOV P11,A
                MOV A,P11
                ORL A,#0FH
                CJNE A,#0FFH,KEY_YES
                MOV B,#0
                AJMP KEY_OPR1
KEY_YES:        ANL A,#0F0H
                MOV B,A
                MOV A,R7
                ANL A,#0FH
                ORL B,A
                MOV A,B
                CJNE A,6,KEY_NOSAME
                ajmp key_nosame
KEY_NOSAME:     MOV R6,B
                AJMP K_OPR
K_10:
                RET
K_OPR:          MOV A,B
KEY1:           CJNE A,#0EdH,KEY2
                MOV R6,#1
                AJMP K_10
KEY2:           CJNE A,#0EbH,KEY3
                MOV R6,#2H
                AJMP K_10
KEY3:           CJNE A,#0E7H,KEY4
                MOV R6,#3H
                AJMP K_10
KEY4:           CJNE A,#0DdH,KEY5
                MOV R6,#4H
                AJMP K_10
KEY5:           CJNE A,#0DbH,KEY6
                MOV R6,#5H
                AJMP K_10
KEY6:           CJNE A,#0D7H,KEY_7
                MOV R6,#6H
                AJMP K_10
KEY_7:          CJNE A,#0BdH,KEY_8
                MOV R6,#7H
                AJMP K_10
KEY_8:          CJNE A,#0BbH,KEY_9
                MOV R6,#8
                AJMP K_10
KEY_9:          CJNE A,#0B7H,KEY_0
                MOV R6,#9H
                AJMP K_10
KEY_0:          CJNE A,#7dH,k_10
                MOV R6,#0
                AJMP K_10



BLJ1:           setb flag1
                mov buf,bljl4
                mov buf+1,bljl3
                mov buf+2,bljl2
                mov buf+3,bljl
                mov r0,#buf
                mov r7,#4
                lcall bcd
                MOV buf1,buf+3
                mov buf1+1,buf+2
                mov buf1+2,buf+1
                mov buf1+3,bUf
                LCALL FLN
B_5:            LCALL KEY_OPR
                CJNE R6,#0FFH,B_2      ;没键按下等待
                SJMP B_5
b_2:            cjne r6,#77h,b_3       ;清除键退出
        mov a,#0
        mov bljl,a
        mov bljl2,a
        mov bljl3,a
        mov bljl4,a
        mov bljcl,a
        mov bljch1,a
        ajmp blj1
b_3:            cjne r6,#0eeh,b_4     ; F键退出
                sjmp b_1
b_4:            AJMP B_5              ;其它键按下等待
B_1:            RET


bljc1:           clr flag1
                 mov buF,BLJCH1
                 mov buF+1,bljcl
                 MOV A,BUF
                 ANL A,#0F0H
                 SWAP A
                MOV DIAPL+3,A
                MOV A,BUF
                ANL A,#0FH
                MOV DIAPL+2,A
                MOV A,BUF+1
                ANL A,#0F0H
                SWAP A
                MOV DIAPL+1,A
                MOV A,BUF+1
                ANL A,#0FH
                MOV DIAPL+0,A
                mov diapl+7,#0bh
                mov diapl+6,#00h
                mov diapl+5,#00h
                mov diapl+4,#00h
BC_5:           LCALL KEY_OPR
                CJNE R6,#0FFH,BC_2;没键按下等待
                AJMP BC_5
BC_2:           CJNE R6,#77H,BC_3       ;清除键 退出
        mov a,#0
        mov bljl,a
        mov bljl2,a
        mov bljl3,a
        mov bljl4,a
        mov bljcl,a
        mov bljch1,a
        ajmp bljc1
BC_3:           CJNE R6,#0EEH,BC_4      ;F 键 退出
                SJMP BC_1
BC_4:           AJMP BC_5              ;其它键等待
BC_1:           ret


;第二功能键处理子程序
TJ:

                  setb flag
                  lcall key_opr
                  mov a,R6
        cjne a,#0eeh,f_keycpj
        ajmp f_key3
F_KEYCPJ:         CJNE A,#0BeH,F_KEY_LJ
                LCALL ZCP                     ;调除皮子程序
                ajmp f_key3
F_KEY_LJ:         CJNE A,#7eH,F_KEY1
                jb flag1,k_13
                LCALL CLJ1                  ;斑累计子程序
                ajmp f_key3
k_13:           lcall Cljc1
                ajmp f_key3
F_KEY1:           CJNE A,#1H,F_KEY2
                LCALL YZ1               ;上限予置子程序
                ajmp f_key3
F_KEY2:           CJNE A,#2,F_KEY_5
                LCALL YZ_2
F_KEY_5: CJNE R6,#77H,F_KEY4
                SJMP F_KEY3
f_key4:
        ajmp tj
F_KEY3:
        lcall save
f_key41:
        lcall key_opr
        cjne r6,#0ffh,f_key41
                CLR FLAG
                ret

ZIJIAN:         MOV diapl,#18h                ;显示8个8子程序
                MOV diapl+1,#18h
                mov diapl+2,#18h
                mov diapl+3,#18h
                mov diapl+4,#18h
                mov diapl+5,#18h
                mov diapl+6,#18h
                mov diapl+7,#18h
zj_1:
        lcall adc
        mov zero,r6
        mov zero+1,r7
        lcall delay500
        lcall adc
        lcall delay500
        mov a,r6
        cjne a,zero,zj_1
        mov a,r7
        cjne a,zero+1,zj_1
        mov zero,r6
        mov zero+1,r7
        lcall delay500
        lcall delay500
                RET

yz1:
        mov a,yzh
        anl a,#0f0h
        cjne a,#0,yz_ll1
        mov diapl+7,#0ah
        ajmp yz_ll2
yz_ll1:
        swap a
                MOV DIAPL+7,a
yz_ll2:
        mov a,yzh
        anl a,#0fh;******#1fh
        orl a,#10h
                MOV DIAPL+6,a
        mov a,yzl
        anl a,#0f0h
        swap a
                MOV DIAPL+5,a
        mov a,yzl
        anl a,#0fh
                MOV DIAPL+4,a
                MOV DIAPL+3,#0ah
                MOV DIAPL+2,#0ah
                MOV DIAPL+1,#0ah
                MOV DIAPL+0,#0ah
yzl_1:
                lcall key_opr
                cjne r6,#0eeh,yzl_2     ;F键返回结束
                ljmp yz_end
yzl_2:
        cjne r6,#77h,yzl_l1       ;清除键按下送0等待
        mov yzh,#0
        mov yzl,#0
        ajmp yz1
yzl_l1:
                cjne r6,#0ah,yz1_10      ;判是数字键?
                AJMP YZl_3
YZ1_10:         JC yZ1_0       ;是数字
yzl_3:
        ajmp yzl_1      ;非数字键继续扫描键盘
YZ1_0:
        mov diapl+7,#0ah
        mov diapl+6,#0ah
        mov diapl+5,#0ah
                MOV DIAPL+4,r6
yzl_4:          ;第二位数字输入
        lcall key_opr
        cjne r6,#0eeh,yzl_5           ;F键返回结束
        ajmp yz_end
yzl_5:
        cjne r6,#77h,yzl_6      ;清除键重新予置
        ajmp yz1
yzl_6:
        cjne r6,#7bh,yzl_7      ;小数点处理
        mov a,diapl+4
        add a,#10h
        mov diapl+4,a
        ajmp yzl_4
yzl_7:
        cjne r6,#0ah,yzl_8      ;非数字键继续扫描键盘
        ajmp yzl_4
yzl_8:
        jnc yzl_4
        mov diapl+5,diapl+4
        mov diapl+4,r6
yzl_9:  ;第三位数字输入
        lcall key_opr
        cjne r6,#0eeh,yzl_10     ;F 键退出
        ajmp yz_end
yzl_10:
        cjne r6,#77h,yzl_11      ;清除键重新予置
        ajmp yz1
yzl_11:
        cjne r6,#7bh,yzl_12      ;小数点处理
        mov a,diapl+4
        add a,#10h
        mov diapl+4,a
        ajmp yzl_9
yzl_12:
        cjne r6,#0ah,yzl_13      ;非数字键继续扫描键盘
        ajmp yzl_9
yzl_13:
        jnc yzl_9
        mov diapl+6,diapl+5
        mov diapl+5,diapl+4
        mov diapl+4,r6
yzl_14:         ;第四位数字输入
        lcall key_opr
        cjne r6,#0eeh,yzl_15       ;    F键退出
        ajmp yz_end
yzl_15:
        cjne r6,#77h,yzl_16      ;清除键重新予置
        ajmp yz1
yzl_16:
        cjne r6,#7bh,yzl_17      ;小数点处理
        mov a,diapl+4
        add a,#10h
        mov diapl+4,a
        ajmp yzl_14
yzl_17:
        cjne r6,#0ah,yzl_18      ;非数字键继续扫描键盘
        ajmp yzl_14
yzl_18:
        jnc yzl_14
        mov diapl+7,diapl+6
        mov diapl+6,diapl+5
        mov diapl+5,diapl+4
        mov diapl+4,r6

yz_end:
        mov r0,#diapl+4
yze_3:
        mov a,@r0
        cjne a,#10h,yze_1
        ajmp yze_2
yze_1:
        jnc yze_2
        inc r0
        cjne r0,#diapl+8,yze_3
        mov a,diapl+4
        orl a,#10h
         mov diapl+4,a
yze_2:
        mov a,diapl+6
        cjne a,#10h,yze_4        ;
        ajmp yze_5
yze_4:
        jnc yze_5
        mov diapl+7,diapl+6
        mov diapl+6,diapl+5
        mov diapl+5,diapl+4
        mov diapl+4,#0
        ajmp yze_2
yze_5:
        mov a,diapl+6
        anl a,#0fh
        mov b,a
        mov a,diapl+7
        cjne a,#0ah,yze_99
        mov a,#00
yze_99:  swap a
        orl a,b
        mov yzh,a
        mov a,diapl+5
        anl a,#0fh;************
        swap a
        mov b,a
        mov a,diapl+4
        anl a,#0fh;************
        orl a,b
        mov yzl,a
Y_2:        lcall key_opr         ;没键按下等待
        CJNE R6,#0FFH,Y_1
        AJMP Y_2
Y_1:        CJNE R6,#0EEH,Y_3      ;F键按下退出
        SJMP Y_0
Y_3:    CJNE R6,#77H,Y_2            ;清除键按下皮重清0
        mov yzh,#0
        mov yzl,#0
        ljmp yz1
Y_0:            CLR FLAG
                ret



YZ_2:                        ;上限预置子程序
                MOV DIAPL+7,#0ah
                MOV DIAPL+6,#0ah
                MOV DIAPL+5,#0ah
                MOV DIAPL+4,#0ah
        mov a,y2h
        anl a,#0f0h
        cjne a,#0,yz_221
        mov diapl+3,#0ah
        ajmp yz_222
yz_221:
        swap a
                MOV DIAPL+3,a
yz_222:
        mov a,y2h
        anl a,#0fh
        ORL A,#10h
                MOV DIAPL+2,a
        mov a,y2l
        anl a,#0f0h
        swap a
                MOV DIAPL+1,a
        mov a,y2l
        anl a,#0fh
                MOV DIAPL+0,a
yzl_103:
                lcall key_opr
                cjne r6,#0eeh,yzl_203     ;F键返回结束
                ljmp yz_end1
yzl_203:
                cjne r6,#0ah,yz1_100     ;判是数字键?
                AJMP YZl_30
YZ1_100:         JC yZ1_00       ;是数字
yzl_30:
        ajmp yzl_103      ;非数字键继续扫描键盘
YZ1_00:
        mov diapl+3,#0ah
        mov diapl+2,#0ah
        mov diapl+1,#0ah
                MOV DIAPL+0,r6
yzl_40:          ;第二位数字输入
        lcall key_opr
        cjne r6,#0eeh,yzl_50           ;F键返回结束
        ajmp yz_end1
yzl_50:
        cjne r6,#77h,yzl_60      ;清除键重新予置
        ajmp yz_2
yzl_60:
        cjne r6,#7bh,yzl_70      ;小数点处理
        mov a,diapl+0
        add a,#10h
        mov diapl+0,a
        ajmp yzl_4
yzl_70:
        cjne r6,#0ah,yzl_80      ;非数字键继续扫描键盘
        ajmp yzl_40
yzl_80:
        jnc yzl_40
        mov diapl+1,diapl+0
        mov diapl+0,r6
yzl_90:  ;第三位数字输入
        lcall key_opr
        cjne r6,#0eeh,yzl_100
        ajmp yz_end1
yzl_100:
        cjne r6,#77h,yzl_110      ;清除键重新予置
        ajmp yz_2
yzl_110:
        cjne r6,#7bh,yzl_120      ;小数点处理
        mov a,diapl+0
        add a,#10h
        mov diapl+0,a
        ajmp yzl_90
yzl_120:
        cjne r6,#0ah,yzl_130      ;非数字键继续扫描键盘
        ajmp yzl_90
yzl_130:
        jnc yzl_90
        mov diapl+2,diapl+1
        mov diapl+1,diapl+0
        mov diapl+0,r6
yzl_140:         ;第四位数字输入
        lcall key_opr
        cjne r6,#0eeh,yzl_150
        ajmp yz_end1
yzl_150:
        cjne r6,#77h,yzl_160      ;清除键重新予置
        ajmp yz_2
yzl_160:
        cjne r6,#7bh,yzl_170      ;小数点处理
        mov a,diapl+0
        add a,#10h
        mov diapl+0,a
        ajmp yzl_14
yzl_170:
        cjne r6,#0ah,yzl_180      ;非数字键继续扫描键盘
        ajmp yzl_140
yzl_180:
        jnc yzl_140
        mov diapl+3,diapl+2
        mov diapl+2,diapl+1
        mov diapl+1,diapl+0
        mov diapl+0,r6

yz_end1:
        mov r0,#diapl+0
yze_30:
        mov a,@r0
        cjne a,#10h,yze_10
        ajmp yze_20
yze_10:
        jnc yze_20
        inc r0
        cjne r0,#diapl+4,yze_30
        mov a,diapl+0
        orl a,#10h
        mov diapl+0,a
yze_20:
        mov a,diapl+2
        cjne a,#10h,yze_40
        ajmp yze_50
yze_40:
        jnc yze_50
        mov diapl+3,diapl+2
        mov diapl+2,diapl+1
        mov diapl+1,diapl+0
        mov diapl+0,#0
        ajmp yze_20
yze_50:
        mov a,diapl+2
        anl a,#0fh
        mov b,a
        mov a,diapl+3
        swap a
        orl a,b
        mov y2h,a
        mov a,diapl+1
        swap a
        mov b,a
        mov a,diapl+0
        orl a,b
        mov y2l,a
Y_20:        lcall key_opr
        CJNE R6,#0FFH,Y_10
        AJMP Y_20
Y_10:        CJNE R6,#0EEH,Y_30
        SJMP Y_00
Y_30:CJNE R6,#77H,Y_20
        mov y2h,#0
        mov y2l,#0
        ljmp yz_2
Y_00:            CLR FLAG
                ret

ZCP:
                CPL auto
        jb auto,zcp_1
        mov ?rom_w?byte,#0
        mov ?rom_w?byte+1,#0
        mov ?rom_w?byte+2,#0
        mov p11,#0ffh
        lcall rom_w
        ajmp zcp_2
zcp_1:
        mov ?rom_w?byte,#0
        mov ?rom_w?byte+1,#0
        mov ?rom_w?byte+2,#0ffh
        mov p11,#0ffh
        lcall rom_w
zcp_2:
                clr FLAG
                RET


BCD:            ;N字节十六进制无符号整数转换成哆字节BCD码无符号整数
                ;入口:字节数在R7中,操作数在[R0]中
                ;出口:结果在[R0]中
                mov a,r7
                mov r2,a
                add a,r0
                mov r5,a
                xch a,r0
                mov r4,a
                clr a
                mov r3,a
hbcdn1: mov @r0,a
        inc r0
        djnz r2,hbcdn1
        mov a,r0
        mov r6,a
        mov a,r1
        push acc
        mov a,r7
        swap a
        rr a
        mov r1,a
hbcdn2: mov a,r4
        mov r0,a
        lcall rlcn
        mov a,r6
        mov r0,a
        mov a,r7
        mov r2,a
hbcdn3: dec r0
        mov a,@r0
        addc a,@r0
        da a
        mov @r0,a
        djnz r2,hbcdn3
        mov a,r3
        addc a,r3
        da a
        mov r3,a
        mov ov,c
        djnz r1,hbcdn2
        mov a,r5
        mov r0,a
        mov a,r6
        mov r1,a
        mov a,r7
        mov r2,a
hbcdn4: dec r0
        dec r1
        mov a,@r1
        mov @r0,a
        djnz r2,hbcdn4
        MOV BU,R3;最高字节BCD码放在缓冲区
        pop acc
        mov r1,a
        ret
rlcn:   mov a,r7
rlcn1:  mov r2,a
        push psw
        add a,r0
        mov r0,a
        pop psw
rlcn2:  dec r0
        mov a,@r0
        rlc a
        mov @r0,a
        djnz r2,rlcn2
        ret


LP1:
        PUSH 1          ;中断显示子程序
                PUSH ACC
                push b
        push psw
;关显示
        mov p22,#0
        mov p00,#0ffh
;位码设置
        mov a,#80h
        mov r1,dis_point
dis_l0:
        cjne r1,#0,dis_l1
        ajmp dis_l2
dis_l1:
        rr a
        dec r1
        ajmp dis_l0
dis_l2:
                mov p22,a
;段码设置
                mov a,#diapl
                add a,dis_point
                mov r1,a
                mov a,@r1
                cjne a,#9,dis_l6
DISP_1:         MOV DPTR,#LED_TB
                ajmp dis_l7
dis_l6:
                jc disp_1
                mov dptr,#led_tb1
                anl a,#0fh
dis_l7:
                MOVC A,@A+DPTR
DISP_2:         CPL A                    ;字型取反
                MOV P00,A               ;字形送P0口
                mov a,dis_point
                cjne a,#7,dis_l4
                mov dis_point,#0
                ajmp dis_l5
dis_l4:
                inc dis_point
dis_l5:
                mov th0,#dis_h
                mov tl0,#dis_l
                pop psw
                pop b
                POP ACC
                POP 1
                RETi

led_tb:         DB 0FCH,60H,0DAH,0F2H
                DB 66H,0B6H,0BEH,0e0H,0FEH,0F6H,00H
LED_TB1:        DB 0FDH,61H,0DBH,0F3H,67H,0B7H
                DB 0BFH,0e1H,0FFH,0F7H,00H,9ch


DIAN:
                SETB point
                RET


clj1:                              ;总累计
                setb flag1
CLJ1_1:
                mov buf,cljl4
                mov buf+1,cljl3
                mov buf+2,cljl2
                mov buF+3,cljl
                mov r0,#buf
                mov r7,#4
                lcall bcd
                mov buf1,buf+3
                mov buf1+1,buf+2
                mov buf1+2,buf+1
                mov buf1+3,buf
                LCALL FLN
CL_4:           LCALL KEY_OPR
                CJNE R6,#0FFH,CL_2      ;没键按等待
                AJMP CL_4
CL_2:           CJNE R6,#77H,CL_3       ;清除键 退出
                SJMP CL_1
CL_3:           CJNE R6,#0EEH,CL_5      ;F锓退出
                SJMP CL_1
CL_5:           AJMP CL_4
CL_1:           CLR FLAG
                RET


cljc1:
                clr flag1

                  ;总累计次数分离
        mov a,cljc4
                anl A,#0fh
                mov diapl+6,A
                mov a,cljc3
                anl a,#0f0h
                swap a
                mov diapl+5,a
                mov a,cljc3
                anl a,#0fh
                mov diapl+4,a
                mov a,cljc2
                anl a,#0f0h
                swap a
                mov diapl+3,a
                mov a,cljc2
                anl a,#0fh
                mov diapl+2,a
                mov a,cljcl
                anl a,#0f0h
                swap a
                mov diapl+1,a
                MOV A,CLJCL
                ANL A,#0FH
                MOV DIAPL+0,A
                mov diapl+7,#0bh        ;最高位显示C
CLC_5:          LCALL KEY_OPR
                CJNE R6,#0FFH,CLC_2      ;没键按下等待
                sJMP CLC_5
CLC_2:          CJNE R6,#77H,CLC_3      ;清除键退出
                SJMP CLC_1
CLC_3:          CJNE R6,#0EEH,CLC_4      ;F键退出
                SJMP CLC_1
CLC_4:          sJMP CLC_5
CLC_1:          CLR FLAG
                RET
FLN:                    ;n字节分离
cl2:            MOV a,buf1+1
                anl a,#0fh
                mov diapl+0,a
                mov a,buf1+1
                anl a,#0f0h
                swap a
                mov diapl+1,a
                MOV A,buf1+2
                anl a,#0fh
                mov diapl+2,a
                mov a,buf1+2
                anl a,#0f0h
                swap a
                mov diapl+3,a
                MOV A,buf1+3
                anl a,#0fh
                mov diapl+4,a
                mov a,buf1+3
                anl a,#0f0h
                swap a
                mov diapl+5,a
                mov a,BU
                anl a,#0fh
                mov diapl+6,a
                MOV A,BU
                anl a,#0f0h
                swap a
                mov diapl+7,a
cl3:            RET

DELAY20:        MOV 58H,#0C8H            ;延时20ms消抖动
LOOP20:         LCALL DELAY              ;延时100US
                DJNZ 58H,LOOP20
                RET

DELAY:          MOV 59H,#40h
LOOP3:          DJNZ 59H,LOOP3
                RET

delay500:
        mov timer_1,#25
d500:
        lcall delay20
        djnz timer_1,d500
        ret


save:
        mov r1,#21h
save_1:
        mov ?rom_w?byte,r1
        mov ?rom_w?byte+1,@r1
        mov ?rom_w?byte+2,@r1
        mov p11,#0f1h
        lcall rom_w
        inc r1
        cjne r1,#33h,save_1
        ret
                END
