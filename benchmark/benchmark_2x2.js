# ECE3242 Computer Architecture
# 2x2 Matrix Subtraction Benchmark Program
#
# Authors: Jacob Smith, Brandon Richardson
# 

#define ONE R0
set ONE 1

#define BASE R1
#define COUNT R2
#define ADDR R3
#define TEMP R4

# Initialize Operands
set BASE 50
set COUNT 7

INIT_MATRICES:
add ADDR BASE COUNT     # R3 <- R1 + R2
save ADDR COUNT         # MEM[R3] <- R2
subt COUNT COUNT ONE    # R2 <- R2 - 1
mov1 TEMP 51            # TEMP <- MEM[51]
jz TEMP INIT_MATRICES   # if R4 == 0, goto 3

# Output Operands
readm 50
readm 51
readm 52
readm 53
readm 54
readm 55
readm 56
readm 57

# Subtract Operands
#define ADDR_A R1
#define ADDR_B R2
#define TEMP R3
#define DATA_A R4
#define DATA_B R5
#define RES R5

set ADDR_A 53
set ADDR_B 57

SUBTRACT_MATRICES:
load DATA_A ADDR_A
load DATA_B ADDR_B
subt DATA_A DATA_B DATA_A
save ADDR_A DATA_A

subt ADDR_A ADDR_A ONE
subt ADDR_B ADDR_B ONE
mov1 TEMP 50
jz TEMP SUBTRACT_MATRICES

# Output Result
readm 50
readm 51
readm 52
readm 53

halt