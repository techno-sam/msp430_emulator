/*
 *     MSP430 emulator and assembler
 *     Copyright (C) 2023  Sam Wagenaar
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:msp430_dart/msp430_dart_assembler.dart';
const Map<int, String> namedRegisters = {
  0: "pc",
  1: "sp",
  2: "sr",
  3: "cg"
};

const List<int> specialImmediates = [4, 8, 0, 1, 2, -1];

String? describeOperand(Operand operand, bool bw) {
  final String registerDesc = "r${operand.src}${namedRegisters.containsKey(operand.src) ? " (aka ${namedRegisters[operand.src]!})" : ""}";
  if (operand is OperandRegisterDirect) {
    return "Direct. Value in register $registerDesc";
  } else if (operand is OperandIndexed) {
    return "Indexed. Memory at the address ${operand.val} + the value of $registerDesc";
  } else if (operand is OperandRegisterIndirect) {
    int increment = 2;
    if (bw && operand.reg != 0 && operand.reg != 1) {
      increment = 1;
    }
    String ret = "Indirect. Memory at the address in $registerDesc";
    if (operand.autoincrement) {
      ret += ", register += $increment afterwards";
    }
    return ret;
  } else if (operand is OperandSymbolic) {
    return "Symbolic. Memory at the address ${operand.val}, stored as PC+offset";
  } else if (operand is OperandImmediate) {
    if (operand.val.hasValue && specialImmediates.contains(operand.val.value)) {
      return "Constant. Operand is the constant ${operand.val}";
    }
    return "Immediate. Next word in the instruction stream (${operand.val}), equivalent to @PC+";
  } else if (operand is OperandAbsolute) {
    return "Absolute. Memory at the address ${operand.val}, stored without an offset";
  }
  return null;
}

Map<String, String> get mnemonicTutors {
  final tutors = {
    "adc": "dst + C -> dst",
    "add": "src + dst -> dst",
    "addc": "src + dst + C -> dst",
    "and": "src .AND. dst -> dst",
    "bic": ".NOT.src .AND. dst -> dst",
    "bis": "src .OR. dst -> dst",
    "bit": "src .AND. dst -> dst",
    "br": "dst -> PC",
    "call": "call function at dst, storing PC on the stack",
    "clr": "0 -> dst",
    "clrc": "0 -> C",
    "clrn": "0 -> N",
    "clrz": "0 -> Z",
    "cmp": "dst - src -> Flags", // todo make additional info system (specifying which flags are set or how a conditional jump can be used)
    "dadc": "A cursed instruction I don't understand, and therefore is not implemented",
    "dadd": "A cursed instruction I don't understand, and therefore is not implemented",
    "dec": "dst - 1 -> dst",
    "decd": "dst - 2 -> dst",
    "dint": "Disable general interrupts (0 -> GIE)",
    "eint": "Enable general interrupts (1 -> GIE)",
    "inc": "dst + 1 -> dst",
    "incd": "dst + 2 -> dst",
    "inv": ".NOT.dst -> dst",
    "jc": "Jump if C = 1",
    "jeq": "Jump if Z = 1",
    "jge": "Jump if (N .XOR. V) = 0",
    "jl": "Jump if (N .XOR. V) = 1",
    "jmp": "Jump unconditionally",
    "jn": "Jump if N = 1",
    "jnc": "Jump if C = 0",
    "jne": "Jump if Z = 0",
    "mov": "src -> dst",
    "nop": "Do nothing",
    "pop": "Pop from stack to dst (@SP -> tmp, SP + 2 -> SP, tmp -> dst)",
    "push": "Push src onto stack (SP - 2 -> SP, src -> @SP)",
    "ret": "Return from subroutine (@SP -> PC, SP + 2 -> SP)",
    "reti": "Return from interrupt (restores SR and PC)",
    "rla": "Rotate left arithmetically [s*2] (C <- MSB <- MSB-1 ... LSB+1 <- LSB <- 0)",
    "rlc": "Rotate left through carry [s*2] (C <- MSB <- MSB-1 ... LSB+1 <- LSB <- C)",
    "rra": "Rotate right arithmetically [s/2] (MSB -> MSB, MSB -> MSB-1, ... LSB+1 -> LSB, LSB -> C)",
    "rrc": "Rotate right through carry [s/2] (C -> MSB -> MSB-1 ... LSB+1 -> LSB -> C)",
    "sbc": "dst + 0xffff + C -> dst (Subtract source and .NOT. Carry from dst)",
    "setc": "1 -> C",
    "setn": "1 -> N",
    "setz": "1 -> Z",
    "sub": "dst + .NOT.src + 1 -> dst (effectively dst - src -> dst)",
    "subc": "dst + .NOT.src + C -> dst (effectively dst - src - 1 + C -> dst",
    "swpb": "Swap bytes in dst (Bits 15 to 8 <-> bits 7 to 0)",
    "sxt": "Sign extend (converts s8 -> s16 by Bit 7 -> Bit 8 ... Bit 15)",
    "tst": "dst + 0xffff + 1 -> N and Z flags",
    "xor": "src .XOR. dst -> dst",
  };
  final aliases = [
    "jc jhs",
    "jeq jz",
    "jnc jlo",
    "jne jnz",
    "subc sbb"
  ];
  for (final alias in aliases) {
    final split = alias.split(" ");
    final a = split[0];
    final b = split[1];
    if (tutors.containsKey(a)) {
      tutors[b] = tutors[a]!;
    } else if (tutors.containsKey(b)) {
      tutors[a] = tutors[b]!;
    } else {
      assert(false, "Alias not found");
    }
  }
  return tutors;
}