/*煤气自动灌装秤控制程序   1996-2-1
  根据原汇编程序改写为C*/

/*======================*/
/*  1996.6第一次修改,   */
/*  源程序丢失.         */
/*  1997.6.14第二次改   */
/*======================*/
#ifdef  SIM
#include <io451.h>
#else
#include <io51.h>
#endif

#define ON              0

#define SYSTEM_FLAG     0x55

#define MAX             4999

#define QD_KEY          0xf7
#define ONE             0xef
#define TEN             0xdf
#define HUR             0xbf
#define SOU             0x7f
#define BREAK           (QD_KEY&ONE)

#define SUM             10
#define TIMES           20
#define SYSTEM          30
#define PRE             40

/*----------------------*/
/*      EPROM操作代码   */
/*----------------------*/
#define EWEN    0x0100
#define EWDS    0
#define ERAL    0x0300
#define ERASE   0x0200

#ifdef  SIM
bit     DM=0xc7;    /*0x87*/
bit     FMQ=0xcf    /*0xb7*/;
bit     display=0xce    /*0xb6*/;
bit clk=0xda,cs=0xdb,di=0xd9,Do=0xd8;
#else
bit     DM=0x87;
bit     FMQ=0xb7;
bit     display=0xb6;
bit clk=0xa2,cs=0xa3,di=0xa1,Do=0xa0;
#endif


/*#pragma memory=idata*/
unsigned int filter[5];
#pragma memory=default

unsigned int pi,jing,pre,zero;
unsigned long sum,times,filter_sum;
unsigned char one,ten,hur,sou,filter_point;
union{
    unsigned int result;
    unsigned char a[2];
}b;
bit update=0;

#pragma memory=code
unsigned char TABLE[]={0x3,0x9f,0x25,0x0d,0x99,0x49,0x41,0x1f,0x1,0x09,0x11,0xc1,0x63,0x85,0x61,0x71};
#pragma memory=default

init();
int eprom(char address);
set_eprom(int command);
int write_eprom(int address,int Data);
delay(unsigned int times);
char key();
main_display();
sbuf(char a);
unsigned int weight();

main()
{
    init();
    if(key()==SOU)test();
    if(eprom(SYSTEM)!=SYSTEM_FLAG){
        set_eprom(EWEN);
        write_eprom(-1,0);
        write_eprom(SYSTEM,SYSTEM_FLAG);
        set_eprom(EWDS);
    }
    else{
        pre=eprom(PRE);
        one=pre%10;
        ten=(pre/10)%10;
        hur=(pre/100)%10;
        sou=(pre/1000)%10;
    }
    zijian();
    pi=jing=0;
    while(1){
        switch(key()){
            case ONE:{
                one>=9?one=0:one++;
                update=1;
                break;
            }
            case TEN:{
                ten>=9?ten=0:ten++;
                update=1;
                break;
            }
            case HUR:{
                hur>=9?hur=0:hur++;
                update=1;
                break;
            }
            case SOU:{
                sou>=4?sou=0:sou++;
                update=1;
                break;
            }
            case QD_KEY:{
                if(update){
                    set_eprom(EWEN);
                    write_eprom(PRE,pre);
                    set_eprom(EWDS);
                    update=0;
                }
                qd();
            }
        }
        pi=weight();
        pre=sou*1000+hur*100+ten*10+one;
        main_display();
        delay(100);
    }
}

init()
{
    char i;
    FMQ=0;
    SCON=0;
    TMOD=0x91;
    IT1=1;
    IP=4;
    IE=0x86;
    TR1=1;
    filter_point=filter_sum=0;
    for(i=0;i<sizeof(filter)/2-1;i++)filter[i]=0;
}

test()
{
    char i,a[8];
    zero=0;
    while(1){
        a[0]=TABLE[(b.result/16)%16];
        a[1]=TABLE[b.result%16];
        i=(b.result/4096)%16;
        a[2]=(i!=0)?TABLE[i]:0xff;
        a[3]=TABLE[(b.result/256)%16];
        a[4]=TABLE[10];
        a[5]=TABLE[10];
        i=10;
        a[6]=TABLE[i];
        a[7]=TABLE[10];
/*        display=~ON;*/
        sbuf(a[0]);
        sbuf(a[1]);
        sbuf(a[2]);
        sbuf(a[3]);
        sbuf(a[4]);
        sbuf(a[5]);
        sbuf(a[6]);
        sbuf(a[7]);
        delay(500);
    }
}

/*==================*/
/*  延时子程序      */
/*  单位:0.1mS      */
/*==================*/
delay(unsigned int times)
{
    unsigned int i;
    char j;
    for(i=0;i<times;i++)for(j=0;j<60;j++);
}

DELAY()
{
    clk=1;
    clk=0;
}

/*----------------------*/
/*  EPROM设置及擦除程序 */
/*  command=00xxH,EWDS  */
/*  command=01xxH,EWEN  */
/*  command=02ddH,ERASE */
/*  command=03xxH,ERAL  */
/*----------------------*/
int set_eprom(int command)
{
    char k;
    union a{
        int com;
        char opr[2];
    }set;
    set.com=command;
    cs=clk=di=0;
    Do=1;
    cs=1;
    while(!Do);
    di=1;
    DELAY();
    switch(set.opr[0]){
        case 0:{
            set.opr[1]=0;
            break;
        }
        case 1:{
            set.opr[1]=0x30;
            break;
        }
        case 2:{
            set.opr[1]|=0xc0;
            break;
        }
        case 3:{
            set.opr[1]=0x20;
            break;
        }
    }
    for(k=0;k<8;k++){
        di=set.opr[1]>>7;
        DELAY();
        set.opr[1]<<=1;
    }
    cs=clk=di=0;
}

/*--------------------------*/
/*  EPROM写入程序           */
/*  address=-1,写整个芯片   */
/*  address<256,写单个数据  */
/*--------------------------*/
int write_eprom(int address,int Data)
{
    union a{
        int i;
        char addr[2];
    }b;
    char k;
    b.i=address;
    cs=clk=di=0;
    Do=1;
    cs=1;
    while(!Do);
    di=1;
    DELAY();
    if(address==-1){
            b.addr[1]=0x10;
        }
        else{
            b.addr[1]|=0x40;
        }
    for(k=0;k<8;k++){
        di=b.addr[1]>>7;
        DELAY();
        b.addr[1]<<=1;
    }
    for(k=0;k<16;k++){
        di=Data>>15;
        DELAY();
        Data<<=1;
    }
    cs=clk=di=0;
}

/*------------------*/
/*  EPROM读出程序   */
/*------------------*/
int eprom(char address)
{
    char k,i;
    int result;
    address|=0x80;
    for(i=0;i<10;i++){
        cs=clk=di=0;
        Do=1;
        cs=1;
        while(!Do);
        cs=1;
        di=1;
        DELAY();
        for(k=0;k<8;k++){
            di=address>>7;
            DELAY();
            address<<=1;
        }
        if(Do==0)goto OK;
    }
    cs=clk=di=0;
    return -1;
OK:
    for(k=0;k<16;k++){
        result<<=1;
        DELAY();
        result=result|Do;
    }
    cs=clk=di=0;
    return result;
}

/****************************************/
/*  蜂鸣子程序(适用于无源蜂鸣器)        */
/*  cycle:蜂鸣器周期(频率),0.1mS的倍数  */
/*  time:持续时间,0.1mS的倍数           */
/****************************************/
sound(int cycle,unsigned int time)
{
    unsigned int i,j;
/*    for(i=0;i<(time/cycle);i++){
        FMQ=1;
        for(j=0;j<cycle;j++)delay(1);
        FMQ=0;
    }*/
    FMQ=1;
    delay(time);
    FMQ=0;
}

sbuf(char a)
{
    SBUF=a;
/*    while(!TI);*/
    TI=0;
}

main_display()
{
    char i,a[8];
    if(pi>MAX){
/*        display=~ON;*/
        for(i=0;i<8;i++)sbuf(TABLE[14]-1);
/*        display=ON;*/
        sound(10,100);
    }
    else{
        a[0]=TABLE[(pre/10)%10];
        a[1]=TABLE[pre%10];
        i=(pre/1000)%10;
        a[2]=(i!=0)?TABLE[i]:0xff;
        a[3]=TABLE[(pre/100)%10]-1;
        a[4]=TABLE[(pi/10)%10];
        a[5]=TABLE[pi%10];
        i=(pi/1000)%10;
        a[6]=(i!=0)?TABLE[i]:0xff;
        a[7]=TABLE[(pi/100)%10]-1;
/*        display=~ON;*/
        sbuf(a[0]);
        sbuf(a[1]);
        sbuf(a[2]);
        sbuf(a[3]);
        sbuf(a[4]);
        sbuf(a[5]);
        sbuf(a[6]);
        sbuf(a[7]);
/*        display=ON;*/
    }
}


char key()
{
    char i;
    i=P1;
    delay(20);
    if(i==P1)return i;
    return 0xff;
}

zijian()
{
    unsigned char i;
    unsigned int l1,l2,tm[5];
    for(i=0;i<8;i++){
        sbuf(TABLE[8]-1);
    }
    zero=0;
    for(i=0;i<sizeof(filter);i++)weight();
loop:
    for(i=0;i<5;i++){
        tm[i]=weight();
        delay(255);
    }
    l1=(tm[0]+tm[2]+tm[3]+tm[4]+tm[1])/5;
    for(i=0;i<5;i++){
        tm[i]=weight();
        delay(255);
    }
    l2=(tm[1]+tm[2]+tm[3]+tm[4]+tm[0])/5;
    if(l1!=l2)goto loop;
    zero=l1;
    sound(10,100);
}

qd_display()
{
    unsigned int jing;
    char i,a[8];
    jing=weight();
    if(jing>=pi)jing=jing-pi;
        else return 1;
        a[0]=TABLE[(jing/10)%10];
        a[1]=TABLE[jing%10];
        i=(jing/1000)%10;
        a[2]=(i!=0)?TABLE[i]:0xff;
        a[3]=TABLE[(jing/100)%10]-1;
        a[4]=TABLE[(pi/10)%10];
        a[5]=TABLE[pi%10];
        i=(pi/1000)%10;
        a[6]=(i!=0)?TABLE[i]:0xff;
        a[7]=TABLE[(pi/100)%10]-1;
/*        display=~ON;*/
        sbuf(a[0]);
        sbuf(a[1]);
        sbuf(a[2]);
        sbuf(a[3]);
        sbuf(a[4]);
        sbuf(a[5]);
        sbuf(a[6]);
        sbuf(a[7]);
/*        display=ON;*/
    return 0;
}



qd()
{
    unsigned int tmp,ww,comp=0;
    sound(10,100);
    DM=ON;
    tmp=weight();
    while(1){
        ww=weight();
        comp=ww-tmp;
        tmp=ww;
        if(ww>=(pi+pre-comp))break;
        if(qd_display())break;
        if(key()==BREAK)break;
    }
    DM=~ON;
    qd_display();
    sound(10,500);
    write_eprom(SUM,sum+=jing);
    write_eprom(TIMES,times++);
    while(weight()!=0&&key()!=BREAK);
}

unsigned int weight()
{
    unsigned int result;
    char i;
    result=(b.result-10001);
    filter_sum+=result;
    filter_sum-=filter[filter_point];
    filter[filter_point]=result;
    filter_point=(filter_point>=sizeof(filter)/2-1)?0:filter_point+1;
    result=filter_sum/(sizeof(filter)/2);
    i=result%4;
    result=result/4;
    if(i>1)result++;
    result-=zero;
    return result;
}

/*外部中断1*/
interrupt [0x13] void EX1_int(void)
{
    b.a[1]=TL1;
    b.a[0]=TH1;
    TH1=0;
    TL1=0;
}
