# Interval math calculations
## About
There is a few of my old projects implemented during my studies at the university. You can get an idea about what interval math is on [Wikipedia](https://en.wikipedia.org/wiki/Interval_arithmetic).

All that projects are written using x86 assembler for MS-DOS. No hardware floating-point math is used, all the math has a software implementation based on simple integer arithmetic. There is a hand-made windows-based GUI with a mouse. Use [dosbox](https://www.dosbox.com/) to launch them.

Why to use asm and MS-DOS without floating point? Well, the answer is simple: just for fun. :)

## Project structure
All sources are located in the project directories with several common libraries for math and GUI that located in the LIBS directory. There are bat-files to compile projects, but you will need [TASM](https://en.wikipedia.org/wiki/Turbo_Assembler) that should be located in the ASM directory. Already compiled binaries are located in the root.

## Screenshots
![Input form](https://github.com/mikhail-yurovskiy/interval-math/blob/master/SCREENSHOTS/KONTR1-1.png)
![Integration results](https://github.com/mikhail-yurovskiy/interval-math/blob/master/SCREENSHOTS/KONTR1-2.png)
!["Please wait" form](https://github.com/mikhail-yurovskiy/interval-math/blob/master/SCREENSHOTS/KONTR3-1.png)
![Graph results](https://github.com/mikhail-yurovskiy/interval-math/blob/master/SCREENSHOTS/KONTR3-2.png)
