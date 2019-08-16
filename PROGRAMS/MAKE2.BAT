@echo off
ASM\tasm /zi /z /ml /m8 /iLIBS KONTR2\main_k2.asm
ASM\tasm /zi /z /ml /m8 /iLIBS LIBS\math.asm
ASM\tasm /zi /z /ml /m8 /iLIBS LIBS\integr.asm
ASM\tasm /zi /z /ml /m8 /iLIBS LIBS\gui.asm
ASM\tlink /x /c /3 main_k2.obj, kontr2.exe
del *.obj
