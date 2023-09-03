import 'package:highlight/highlight.dart';
import 'package:highlight/src/common_modes.dart';

const MATCH_NOTHING = r"^$";

Mode msp430_lang() {
  return Mode(
    refs: {
      "~symbol": Mode(
          className: "symbol",
          begin: "([A-z\$_][A-z0-9\$_]*)"
      ),
      "~built_in": Mode(
          className: "built_in",
          begin: "pc sp sr cg r0 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12 r13 r14 r15 r1".replaceAll(" ", "|")
      ),
      "~number": Mode(
        className: "number",
        variants: [
          Mode(begin: "#?[-+]?0x[0-9a-f]{1,4}"),
          Mode(begin: "#?[-+]?\\d+")
        ],
        relevance: 0
      ),
      "~number-ref": Mode(
        variants: [
          Mode(begin: "#?[-+]?0x[0-9a-f]{1,4}"),
          Mode(begin: "#?[-+]?\\d+")
        ],
        relevance: 0
      ),
      "~register": Mode(
        variants: [
          Mode(begin: "r1[0-5](?![0-9])"),
          Mode(begin: "r[0-9](?![0-9])"),
        ]
      )
    },
    case_insensitive: true,
    keywords: {
      "built_in":
          "pc sp sr cg r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12 r13 r14 r15"
    },
    contains: [
      Mode(
        className: "formula",
        begin:
          r"^\s*\b(rrc|swpb|rra|sxt|push|call|reti|jne|jnz|jeq|jz|jnc|jlo|jc|jhs|jn|jge|jl|jmp|mov|add|addc|subc|sub|cmp|dadd|bit|bic|bis|xor|and|adc|br|clr|clrc|clrn|clrz|dadc|dec|decd|dint|enit|inc|incd|inv|nop|pop|ret|rla|rlc|sbc|setc|setn|setz|tst)\b"
      ),
      Mode(
          className: "comment",
          begin: ";",
          end: "\$",
          contains: [
            PHRASAL_WORDS_MODE,
            Mode(
              className: "doctag",
              begin: "(?:TODO|FIXME|NOTE|BUG|XXX):",
              relevance: 0
            ),
            Mode(
              className: "name",
              begin: r"<(?!.*\s.*>)",
              end: ">",
              relevance: 0
            ),
            Mode(
              className: "attribute",
              begin: r"@(arg|ret)\s+",
              contains: [
                Mode(
                  className: "strong",
                  variants: [
                    Mode(begin: r"r1[0-5](?![0-9])\s*"),
                    Mode(begin: r"r[0-9](?![0-9])\s*"),
                  ],
                  contains: [
                    Mode(
                      className: "normal_weight",
                      begin: r"\w"
                    )
                  ]
                ),
              ]
            ),
            Mode(
              ref: "~built_in",
              className: "built_in",
              variants: [
                Mode(begin: r"r1[0-5](?![0-9])"),
                Mode(begin: r"r[0-9](?![0-9])"),
              ],
            ),
          ],
          relevance: 0),
      Mode(ref: "~built_in"), // needed because otherwise number matches part of registers
      Mode(
        className: "literal",
        begin: r"\.(b|w)"
      ),
      Mode(
        className: "variable",
        begin: r"\[[A-z$_][A-z0-9$_]*\]", //r"\[[A-z$_][A-z0-9$_]*\]"
      ),
      Mode(
        className: "function",
        begin: "^([A-z\$_][A-z0-9\$_]*):"
      ),
      Mode(ref: "~symbol"),
      Mode(
        className: "variable",
        begin: "\\.define \"(.*)\",? *([A-z\$_][A-z0-9\$_]*)"
      ),
      Mode(
        className: "operator",
        begin: "@",
        contains: [
          Mode(
            className: "built_in",
            variants: [
              Mode(begin: "r1[0-5](?![0-9])"),
              Mode(begin: "r[0-9](?![0-9])"),
              Mode(begin: "pc|sp|sr|cg")
            ],
            endsWithParent: true,
            contains: [
              Mode(
                className: "operator",
                begin: r"\+",
                endsParent: true
              )
            ]
          ),
        ]
      ),
      Mode(
        className: "operator",
        begin: "#|&",
        contains: [
          Mode(ref: "~number"),
          Mode(ref: "~symbol")
        ]
      ),
      Mode(ref: "~number")
      /*
      Mode(
          className: "symbol",
          variants: [
            Mode(begin: "^[a-z_\\.\\\$][a-z0-9_\\.\\\$]+"),
            Mode(begin: "^\\s*[a-z_\\.\\\$][a-z0-9_\\.\\\$]+:"),
            Mode(begin: "[=#]\\w+")
          ],
          relevance: 0)*/
    ]
  );
}