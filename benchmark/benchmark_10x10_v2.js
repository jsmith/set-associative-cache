# ECE3242 Computer Architecture
# 10x10 Matrix Subtraction Benchmark Program
#
# Authors: Jacob Smith, Brandon Richardson
# 

#define ONE R0
set ONE 1

#define BASE R1
#define COUNT R2
#define ADDR R3
#define TEMP R4

set BASE 50
set COUNT 200

# INIT_MATRICES:
# add ADDR BASE COUNT     # R3 <- R1 + R2
# save ADDR COUNT         # MEM[R3] <- R2
# subt COUNT COUNT ONE    # R2 <- R2 - 1
# mov1 TEMP 51            # TEMP <- MEM[51]
# jz TEMP INIT_MATRICES   # if R4 == 0, goto 3

# redefine variables for second loop :)
#define ADDR_A R1
#define ADDR_B R2
#define TEMP R3
#define DATA_A R4
#define DATA_B R5
#define RES R5

readm 0

set ADDR_A 150
set ADDR_B 250

load DATA_A ADDR_A
load DATA_B ADDR_B
subt DATA_A DATA_B DATA_A
save ADDR_A DATA_A

subt ADDR_A ADDR_A ONE
subt ADDR_B ADDR_B ONE
# Since we are getting MEM[50], subtraction will actually occur n*n + 1
# times. ie. 2x2 = 5, 10x10 = 101.
# This seemed like the easiest way to stop looping
mov1 TEMP 50
jz TEMP 11

# Debugging Output
readm 50
readm 51
readm 60
readm 70
readm 80

halt