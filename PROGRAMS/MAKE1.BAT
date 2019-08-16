@echo off
ASM\tasm /zi /z /ml /m8 /iLIBS KONTR1\main_k1.asm
ASM\tasm /zi /z /ml /m8 /iLIBS LIBS\math.asm
ASM\tasm /zi /z /ml /m8 /iLIBS LIBS\integr.asm
ASM\tasm /zi /z /ml /m8 /iLIBS LIBS\gui.asm
ASM\tlink /x /c /3 main_k1.obj, kontr1.exe
del *.obj
