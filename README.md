# set-associative-cache
Set associative cache project for ECE3242.

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

## Test Files
- [Reading scripts](https://jacobsmith.me/assembly/#/?text=mov1%20R0%203%20%23%20miss,%20set%200,%20line%200%0Amov1%20R0%202%20%23%20hit%0Amov1%20R0%201%20%23%20hit%0Amov1%20R0%200%20%23%20hit%0Amov1%20R0%204%20%23%20miss,%20set%201,%20line%200%0Amov1%20R0%208%20%23%20miss,%20set%202,%20line%200%20because%20line%201%20mru%0Ahalt%0A%0A%23%200000000100020003%0A%23%200000F00000080004%0A%23%20It%20worked%20as%20expected.%20This%20isn%27t%20the%20benchmark%20I%20wanted%20to%20run%20though%20since%20I%20though%20mov1%20R0%204%20and%20mov1%20R0%208%20where%20still%20in%20set%200%0A)

## Memory Mapper Script
Chunks the memory into blocks of 4 16 bit words and then reverses them. Appends `0x0000` before reversing if the length of the chunk is less than 4.
```javascript
`
0003
0002
0001
0000
0004
0008
F000
`
  .split('\n')
  .map(line => line.trim())
  .filter(line => line)
  .reduce((chunks, line) =>{
    if (!chunks.length || chunks[chunks.length - 1].length === 4) {
    	chunks.push([])
	}

	chunks[chunks.length - 1].push(line)
	return chunks
  }, [])
  .map(chunk => {
	while (chunk.length < 4) {
	  chunk.push("0000")
    }
  	return chunk.reverse();
  })
  .map(chunk => chunk.join(''))
```

## Instruction Format:
```
0011 0000 0000 0000
 OP  REG1 REG2 REG3
 OP  REG1    IMM
```
