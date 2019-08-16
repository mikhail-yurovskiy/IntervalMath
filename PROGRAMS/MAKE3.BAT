@echo off
ASM\tasm /zi /z /ml /m8 /iLIBS KONTR3\main_k3.asm
ASM\tasm /zi /z /ml /m8 /iLIBS LIBS\math.asm
ASM\tasm /zi /z /ml /m8 /iLIBS LIBS\gui.asm
ASM\tlink /x /c /3 main_k3.obj, kontr3.exe
del *.obj
