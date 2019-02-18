# set-associative-cache
Set associative cache project for ECE3242 

## Instruction Set:
- `0x0`: `mov1 REG[r1] <= MEM[IMM]`
- `0x1`: `mov2 MEM[IMM] <= REG[r1]`
- `0x2`: `mov3 MEM[REG[r1]] <= REG[r2]`
- `0x3`: `mov4 REG[r1] <= IMM`
- `0x4`: `add REG[r1] <= REG[r2] + REG[r3]`
- `0x5`: `subt REG[r1] <= REG[r2] - REG[r3]`
- `0x6`: `jz jz if REG[r1] == 0`
- `0x7`: `readm out <= MEM[IMM]`
- `0xA`: `load REG[r1] <= MEM[REG[r2]]`
- `0xF`: `halt`

## Instruction Format:
```
0011 0000 0000 0000
 OP  REG1 REG2 REG3
 OP  REG1    IMM
```
