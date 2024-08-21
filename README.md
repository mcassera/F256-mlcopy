# F256-mlcopy
A utility for SuperBASIC to use the DMA engine if memcopy fails

If you are having issues with the SuperBASIC command `MEMCOPY` locking up, this short machine language routine will do the same function without issues.

To use it, either `BLOAD` the `mlcopy$0900.bin` file into memory location $0900 at the start of your program, or add the basic loader program to your own BASIC programs.

# Usage
Much like the `MEMCOPY` command you need to supply three variables, the source location of the data you wish to copy, the target location of where you want the data copied to, and the number of bytes you wish to copy.
This information is entered into the computer via `POKEL` commands. This is then followed by a call command to the program. It would look like this in your program:

```
POKEL $0903,data source
POKEL $0906,destination 
POKEL $0909,number of bytes to copy
CALL $0900
```

# Notes
This utility is located in unused memory under SuperBASIC's variable storage. 

It uses zero page memory locations $c0 - $c6 to communicate with the kernel.


