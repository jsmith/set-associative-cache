mov4 R0 1

mov4 R1 50
mov4 R2 200
add R3 R1 R2
mov3 R3 R2
sub R2 R2 R0
jz R2 1

mov4 R1 50 # countA
mov4 R2 150 # countB
mov4 R3 100 # count

load R4 R1 # dataA = MEM[countA]
load R5 R2 # dataB = MEM[countB]
sub R4 R5 R4 # dataA = dataB - dataA
mov3 R1 R4 # MEM[countA] = dataA

add R1 R1 R0
add R2 R2 R0
sub R3 R3 R0
jz R3 10

readm 50
readm 51
readm 60
readm 70
readm 80

halt
