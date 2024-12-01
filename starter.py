def preprocess_lines(lines):
    """
    Preprocesses a list of lines by removing comments, trimming whitespace,
    and excluding blank lines.

    Args:
        lines (list of str): The lines from the assembly file.

    Returns:
        list of str: The preprocessed list of instructions.
    """
    preprocessed_lines = []
    for line in lines:
        line = line.split('#')[0]
        line = line.strip()
        if line:
            preprocessed_lines.append(line)
    return preprocessed_lines

def build_data_table(lines):
    """
    Builds a data table by parsing the .data section of the program.
    This includes mapping labels to memory addresses, collecting data values,
    and removing the .data section from the program.

    Args:
        lines (list of str): The preprocessed list of lines representing the program.

    Returns:
        tuple: A tuple containing:
            - dict: A mapping of label -> memory address.
            - list: A list of each data value.
            - list: The remaining program instructions without the .data section.
    """
    data_table = {}
    data_list = []
    new_lines = []
    in_data_section = False
    memory_address = 0

    for line in lines:
        if line.startswith(".data"):
            in_data_section = True
            continue
        elif line.startswith(".text"):
            in_data_section = False
            continue

        if in_data_section:
            if ':' in line:
                label, value = map(str.strip, line.split(':'))
                data_table[label] = memory_address
                data_list.append(int(value))
                memory_address += 1
        else:
            new_lines.append(line)

    return data_table, data_list, new_lines

def create_label_table(lines):
    """
    Builds a label table by mapping labels to instruction numbers and removing
    labels from the source code.

    Args:
        lines (list of str): The preprocessed list of lines representing the program.

    Returns:
        tuple: A tuple containing:
            - dict: A mapping of label -> instruction number.
            - list: The remaining program instructions without the labels.
    """
    label_table = {}
    new_lines = []
    instruction_count = 0

    for line in lines:
        if ':' in line:
            label, rest_of_line = line.split(':', 1)
            label = label.strip()
            if label:
                label_table[label] = instruction_count
            line = rest_of_line.strip()

        if line:
            new_lines.append(line)
            instruction_count += 1

    return label_table, new_lines

def register_to_binary(register):
    """
    Converts a register (e.g., R1) to a 3-bit binary string.
    """
    if not register.startswith("R") or not register[1:].isdigit():
        raise ValueError(f"Invalid register: {register}")
    register_num = int(register[1:])
    if not (0 <= register_num <= 7):
        raise ValueError(f"Register out of range: {register}")
    return f"{register_num:03b}"

def dec_to_bin(value, bit_width):
    """
    Converts a decimal number to a binary string of the specified bit width,
    using two's complement for negative numbers.
    """
    if not (-2 ** (bit_width - 1) <= value < 2 ** (bit_width - 1)):
        raise ValueError(f"Value {value} out of range for {bit_width}-bit binary")
    return f"{(1 << bit_width) + value if value < 0 else value:0{bit_width}b}"

def encode_instruction(line_num, instruction, label_table, data_table):
    """
    Encodes a single assembly instruction into a 16-bit binary string.

    Args:
        line_num (int): Line number of the instruction in the source code.
        instruction (str): The instruction to encode (e.g., "addi R1, R2, 10").
        label_table (dict): Mapping of labels to instruction numbers.
        data_table (dict): Mapping of data labels to memory addresses.

    Returns:
        str: The 16-bit binary encoding of the instruction.
    """
    try:
        parts = instruction.replace(",", " ").split()
        op = parts[0]
        binary = ""

        # R-Format Instructions
        if op in {"add", "sub", "and", "or", "slt"}:
            if len(parts) != 4:
                raise ValueError(f"Invalid syntax for R-format instruction: {instruction}")

            rs = register_to_binary(parts[2])
            if parts[3] in data_table:
                rt = "000"
                immediate = dec_to_bin(data_table[parts[3]], 6)
            else:
                rt = register_to_binary(parts[3])
                immediate = "000000"
            rd = register_to_binary(parts[1])

            func = {
                "add": "010",
                "sub": "110",
                "and": "000",
                "or": "001",
                "slt": "111",
            }[op]

            if parts[3] in data_table:
                binary = f"0001{rs}{rd}{immediate}"
            else:
                binary = f"0000{rs}{rt}{rd}{func}"

            formatted_binary = (
                f"{binary[:4]} {binary[4:7]} {binary[7:10]} {binary[10:13]} {binary[13:]}"
            )
            return formatted_binary

        # I-Format Instructions
        elif op in {"addi", "beq", "bne", "lw", "sw"}:
            if len(parts) < 4 and op not in {"lw", "sw"}:
                raise ValueError(f"Invalid syntax for I-format instruction: {instruction}")
            rt = register_to_binary(parts[1])
            if op == "addi":
                rs = register_to_binary(parts[2])
                immediate = dec_to_bin(int(parts[3]), 6)
            elif op in {"beq", "bne"}:
                rs = register_to_binary(parts[2])
                if parts[3] not in label_table:
                    raise ValueError(f"Undefined label: {parts[3]}")
                offset = label_table[parts[3]] - (line_num + 1)
                immediate = dec_to_bin(offset, 6)
            elif op in {"lw", "sw"}:
                if "(" in parts[2]:
                    offset, base = parts[2].split("(")
                    offset = offset.strip()
                    base = base.strip(")")
                    rs = register_to_binary(base)
                    immediate = dec_to_bin(int(offset), 6)
                else:
                    if parts[2] not in data_table:
                        raise ValueError(f"Undefined label in data section: {parts[2]}")
                    rs = "000"
                    immediate = dec_to_bin(data_table[parts[2]], 6)
            opcode = {
                "addi": "0101",
                "beq": "0011",
                "bne": "0110",
                "lw": "0001",
                "sw": "0010",
            }[op]
            binary = f"{opcode}{rs}{rt}{immediate}"

            formatted_binary = f"{binary[:4]} {binary[4:7]} {binary[7:10]} {binary[10:]}"
            return formatted_binary

        # J-Format Instructions
        elif op in {"j", "jal"}:
            if len(parts) != 2:
                raise ValueError(f"Invalid syntax for J-format instruction: {instruction}")
            if parts[1] not in label_table:
                raise ValueError(f"Undefined label: {parts[1]}")
            address = dec_to_bin(label_table[parts[1]], 12)
            opcode = "0100" if op == "j" else "1000"
            binary = f"{opcode}{address}"

            formatted_binary = f"{binary[:4]} {binary[4:]}"
            return formatted_binary

        # JR Instruction (special)
        elif op == "jr":
            if len(parts) != 2:
                raise ValueError(f"Invalid syntax for jr instruction: {instruction}")
            rs = register_to_binary(parts[1])
            binary = f"0111{rs}000000000"

            formatted_binary = f"{binary[:4]} {binary[4:7]} {binary[7:10]} {binary[10:13]} {binary[13:]}"
            return formatted_binary

        elif op == "display":
            binary = "1111000000000000"

            formatted_binary = f"{binary[:4]} {binary[4:7]} {binary[7:]}"
            return formatted_binary

        else:
            raise ValueError(f"Unknown instruction: {op}")

    except ValueError as e:
        raise ValueError(f"Error encoding instruction at line {line_num}: '{instruction}' -> {e}")

def encode_program(lines, label_table, data_table):
    """
    Encodes an entire program into a list of 16-bit binary instructions.

    Args:
        lines (list of str): List of assembly instructions.
        label_table (dict): Mapping of labels to instruction numbers.
        data_table (dict): Mapping of data labels to memory addresses.

    Returns:
        list of str: List of binary encoded instructions.
    """
    binary_instructions = []
    for line_num, line in enumerate(lines):
        binary_instructions.append(encode_instruction(line_num, line, label_table, data_table))
    return binary_instructions

def post_process(lines):
    """
    Converts binary instructions into hexadecimal format suitable for Logisim.

    Args:
        lines (list of str): List of binary strings obtained from the prior steps.

    Returns:
        list of str: List of hexadecimal strings.
    """
    hex_instructions = [f"{int(line.replace(' ', ''), 2):04x}" for line in lines]

    formatted_hex = " ".join(hex_instructions)

    return [formatted_hex]

def main():
    # Defining the assembly file to read from
    filename = "assembly_file.asm"

    # Read all lines from the assembly file, and store them in a list
    with open(filename, "r") as infile:
        lines = infile.readlines()

    # Step 1: Preprocess the lines to remove comments and whitespace
    lines = preprocess_lines(lines)

    # Step 2: Use the preprocessed program to build data table
    data_table, data_list, lines = build_data_table(lines)

    # Step 3: Build a label table and strip out the labels from the code
    label_table, lines = create_label_table(lines)

    # Step 4: Encode the program into a list of binary strings
    encoded_program = encode_program(lines, label_table, data_table)

    # Step 5: Convert the strings to hexadecimal and write them to a file
    hex_program = post_process(encoded_program)
    with open("program.hex", "w") as outfile:
        outfile.write("v3.0 hex words addressed\n00: ")
        outfile.writelines(hex_program)

    # Step 6: Convert the data list to hexadecimal and write it to a file
    with open("data.hex", "w") as outfile:
        outfile.write("v3.0 hex words addressed\n00: ")
        outfile.writelines([f"{d:04x} " for d in data_list])

if __name__ == "__main__":
    main()