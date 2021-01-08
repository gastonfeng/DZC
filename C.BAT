@echo off
\c-51\bin\c-51 %1 -mt -I\c-51\include\ -r0 -q -L -D%2
if NOT EXIST %1.r03 goto end:
\c-51\bin\xlink -c8051 -FAOMF8051 %1 \c-51\lib\cl8051t -f LNK -l %1.map -o %1.hex -x
if NOT EXIST %1.hex goto end:
oh %1.hex to %1.bin
:end
