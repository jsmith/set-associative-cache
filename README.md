# set-associative-cache
Set associative cache project for ECE3242 

## Instruction Set:
- `mov1 REG[r1] <= MEM[IMM]`
- `mov2 MEM[IMM] <= REG[r1]`
- `mov3 MEM[REG[r1]] <= REG[r2]`
- `mov4 REG[r1] <= IMM`
- `add REG[r1] <= REG[r2] + REG[r3]`
- `subt REG[r1] <= REG[r2] - REG[r3]`
- `jz jz if REG[r1] == 0`
- `readm out <= MEM[IMM]`
- `halt`

## Instruction Format:
```
0011 0000 0000 0000
 OP  REG1 REG2 REG3
 OP  REG1    IMM
```
