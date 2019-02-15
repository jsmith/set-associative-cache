instructions = `
test1
test2
test3
test4
test5
`;

s = "";
instructions.split('\n')
    .filter((line) => {
        // Filter empty lines
        return line;
    })
    .forEach(function(line, index) {
        s += index + " => x\"" + line + "\",\n";
    });

console.log(s);