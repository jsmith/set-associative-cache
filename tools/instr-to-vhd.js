(() => {
    let instructions = `
test1
test2
test3
test4
test5
`;

    return instructions.split('\n')
        .filter((line) => {
            // Filter empty lines
            return line;
        })
        .map(function (line, index) {
            return index + " => x\"" + line + "\"";
        }).join(",\n");
})();