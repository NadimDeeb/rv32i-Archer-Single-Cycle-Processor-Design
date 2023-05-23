int fib_array[11];

void main () {
    int i;
    for (i = 0; i < 11; i++) {
        fib_array[i] = fib_rec(i);
    }
}

int fib_rec (int a) {
    if (a <= 1)
        return a;
    else
        return fib_rec(a-1) + fib_rec(a-2);
}

===

RISC-V assembly

.globl  main
.data

fib_array:                  # location of the fib array


.text
main:
    add     t0,x0,x0        # initialize iteration counter i to zero.    X"B3", X"02", X"00", X"00", 
    addi    t1,x0,11        # initialize upper loop bound.               X"13", X"03", X"B0", X"00", 
    la      t2,fib_array    # initialize fib_array index           X"97", X"03", X"00", X"10", X"93", X"83", X"83", X"FF", 
loop:
    bge     t0,t1,end       # if i >= 11 exit loop.                X"63", X"DE", X"62", X"00",
    addi    a0,t0,0         # initialize parameter register a0 to t0 (i)            X"13", X"85", X"02", X"00",
    jal     fib_rec         # call fib_rec function               X"EF", X"00", X"C0", X"01",
    sw      a0,0(t2)        # store result in fib array           X"23", X"A0", X"A3", X"00",
    addi    t2,t2,4         # increment fib_array index           X"93", X"83", X"43", X"00",
    addi    t0,t0,1         # increment loop iteration count       X"93", X"82", X"12", X"00",
    j       loop            # jump to the top of the loop          X"6F", X"F0", X"9F", X"FE",
end:
    addi	a0,x0,10        # set a0 to 10 (exit code)             X"13", X"05", X"A0", X"00",
    ecall                                                       X"73", X"00", X"00", X"00",


fib_rec:
    addi    sp,sp,-12       # push ra and a0 on the stack       X"13", X"01", X"41", X"FF",
    sw      ra,0(sp)                                X"23", X"20", X"11", X"00",
    sw      a0,4(sp)                                  X"23", X"22", X"A1", X"00",

    addi    t3,x0,1         # t3 = 1                      X"13", X"0E", X"10", X"00",
    blt     t3,a0,recursive # if a0 > 1 goto recursive    X"63", X"44", X"AE", X"00",
    j       return          # return a0                    X"6F", X"00", X"40", X"02",

recursive:

    addi    a0,a0,-1        # a0 = a0 - 1                  X"13", X"05", X"F5", X"FF", 
    jal     fib_rec         # call fib_rec                  X"EF", X"F0", X"5F", X"FE",
    sw      a0,8(sp)        # save result on the stack      X"23", X"24", X"A1", X"00",

    lw      a0,4(sp)        # load original a0               X"03", X"25", X"41", X"00",
    addi    a0,a0,-2        # a0 = a0 - 2                    X"13", X"05", X"E5", X"FF",
    jal     fib_rec         # call fib_rec                   X"EF", X"F0", X"5F", X"FD",

    lw      a1,8(sp)        # load result of first fib_rec call in to a1         X"83", X"25", X"81", X"00", 
    add     a0,a0,a1        # a0 = a0 + a1                         X"33", X"05", X"B5", X"00",

return:
    lw      ra,0(sp)        # pop return address form the stack     X"83", X"20", X"01", X"00",
    addi    sp,sp,12        # deallocate stack space               X"13", X"01", X"C1", X"00",
    ret                     # return                               X"67", X"80", X"00", X"00",

=====
RV32I machine code

            X"B3", X"02", X"00", X"00", X"13", X"03", X"B0", X"00", 
            X"97", X"03", X"00", X"10", X"93", X"83", X"83", X"FF", 
            X"63", X"DE", X"62", X"00", X"13", X"85", X"02", X"00", 
            X"EF", X"00", X"C0", X"01", X"23", X"A0", X"A3", X"00", 
            X"93", X"83", X"43", X"00", X"93", X"82", X"12", X"00", 
            X"6F", X"F0", X"9F", X"FE", X"13", X"05", X"A0", X"00", 
            X"73", X"00", X"00", X"00", X"13", X"01", X"41", X"FF", 
            X"23", X"20", X"11", X"00", X"23", X"22", X"A1", X"00", 
            X"13", X"0E", X"10", X"00", X"63", X"44", X"AE", X"00", 
            X"6F", X"00", X"40", X"02", X"13", X"05", X"F5", X"FF", 
            X"EF", X"F0", X"5F", X"FE", X"23", X"24", X"A1", X"00", 
            X"03", X"25", X"41", X"00", X"13", X"05", X"E5", X"FF", 
            X"EF", X"F0", X"5F", X"FD", X"83", X"25", X"81", X"00", 
            X"33", X"05", X"B5", X"00", X"83", X"20", X"01", X"00", 
            X"13", X"01", X"C1", X"00", X"67", X"80", X"00", X"00",

11111110100111111111 00000 1101111
FE9FF06F

 X"73",X"AF",X"02",X"00",  #CSRRS

        #CSRRS_CSRRC
            X"93", X"82", X"52", X"00",
            X"13", X"02", X"62", X"00",
            X"33", X"83", X"42", X"02",
            X"73",X"AF",X"02",X"00",  --csrrs
            X"73",X"BF",X"02",X"00",  --csrrc
            X"33", X"93", X"42", X"02",
            X"33", X"b3", X"42", X"02",
            X"33", X"a3", X"42", X"02",

        #MULT
            X"b7", X"f2", X"23", X"f4",
            X"93", X"82", X"52", X"00",
            X"37", X"f2", X"23", X"f4",
            X"13", X"02", X"62", X"00",
            X"33", X"83", X"42", X"02",
            X"33", X"93", X"42", X"02",
            X"33", X"b3", X"42", X"02",
            X"33", X"a3", X"42", X"02",
        #DIV
            X"b7", X"02", X"53", X"b3",
            X"93", X"82", X"f2", X"3f",
            X"37", X"f2", X"23", X"f4",
            X"13", X"02", X"c2", X"07",
            X"33", X"c3", X"42", X"02",
            X"b3", X"d3", X"42", X"02",
            X"33", X"e4", X"42", X"02",
            X"b3", X"f4", X"42", X"02",

        #testpipeline
            X"93", X"02", X"a0", X"00",
            X"13", X"03", X"50", X"00",
            X"b3", X"83", X"62", X"00",
            X"6f", X"00", X"c0", X"00",
            X"13", X"00", X"00", X"00",
            X"13", X"04", X"b0", X"07",
            X"13", X"04", X"c0", X"00",


            X"93", X"02", X"a0", X"00",
            X"13", X"03", X"50", X"00",
            X"b3", X"83", X"62", X"00",
            X"13", X"00", X"00", X"00",
            X"13", X"00", X"00", X"00",
            X"63", X"86", X"62", X"06",
            X"23", X"20", X"70", X"00",
            X"03", X"24", X"00", X"00",
            X"13", X"04", X"a4", X"00",
            X"33", X"84", X"62", X"02", --mult
            X"33", X"04", X"84", X"02",
            X"33", X"c4", X"62", X"02", --div
            X"33", X"c4", X"52", X"02",
            X"6f", X"00", X"c0", X"00",
            X"13", X"04", X"80", X"3e",
            X"13", X"04", X"80", X"3e",
            X"33", X"04", X"80", X"00",
            X"73", X"AF", X"22", X"00",