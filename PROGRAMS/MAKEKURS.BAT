@echo off
ASM\tasm /zi /z /ml /m8 /iLIBS KURSOVIK\mainkurs.asm
ASM\tasm /zi /z /ml /m8 /iLIBS LIBS\math.asm
ASM\tasm /zi /z /ml /m8 /iLIBS LIBS\gui.asm
ASM\tlink /x /c /3 mainkurs.obj, kursovik.exe
del *.obj
