# An-Najah National University
## Department of Computer Engineering
### Digital Circuits Design I — Assignment 1

# 4-Bit Arithmetic Logic Unit (ALU) Design

**Student name:** يامن عبد الكريم توبه  
**Student ID:** 12428060  
**Section:** ____________________  
**Submission date:** ____________________

---

## Abstract

This project specifies and implements a combinational 4-bit unsigned ALU for two inputs A and B, each ranging from 0 to 15. A mode bit M selects logic or arithmetic behavior, while S1 and S0 select one of four operations in the active mode. The logic operations are bitwise AND, XOR, NAND, and XNOR. Arithmetic operations are addition, absolute-magnitude subtraction with a negative-result indicator, addition with carry-in one, and doubling A. The arithmetic result is a 5-bit unsigned magnitude, sufficient for results through 31. The design also converts that value to two decimal digits and decodes both digits for seven-segment displays. The provided Verilog implementation is supported by a self-checking exhaustive testbench covering all 2,048 combinations of eight control encodings and 16×16 input pairs. The report distinguishes HDL testbench verification from Multisim validation: a native Multisim file and Multisim run are not claimed or included.

## 1. Problem specification

The assignment requires a combinational circuit with A[3:0], B[3:0], M, S1, S0; logic output L[3:0]; 5-bit arithmetic magnitude R[4:0]; and negative-result indicator N. For M=0, the selected bitwise logic operation appears on L while R=0 and N=0. For M=1, L=0000 and the selected arithmetic result appears on R. Subtraction displays |A−B| and sets N exactly when A<B. In the 2A operation, B is unused. R is displayed as decimal 00–31 using two seven-segment digits.

## 2. Operation table

| M | S1 | S0 | Operation | L | R | N |
|---:|---:|---:|---|---|---|---|
| 0 | 0 | 0 | A AND B | A&B | 0 | 0 |
| 0 | 0 | 1 | A XOR B | A^B | 0 | 0 |
| 0 | 1 | 0 | A NAND B | ~(A&B) bitwise | 0 | 0 |
| 0 | 1 | 1 | A XNOR B | ~(A^B) bitwise | 0 | 0 |
| 1 | 0 | 0 | A+B | 0 | A+B | 0 |
| 1 | 0 | 1 | A−B magnitude | 0 | |A−B| | 1 iff A<B |
| 1 | 1 | 0 | A+B+1 | 0 | A+B+1 | 0 |
| 1 | 1 | 1 | 2A | 0 | 2A | 0 |

## 3. Functional design and equations

Let `sel={S1,S0}`. Per bit i, form `AND_i=A_iB_i`, `XOR_i=A_i⊕B_i`, `NAND_i=¬(A_iB_i)`, and `XNOR_i=¬(A_i⊕B_i)`. Select by sel and mask with logic mode:

`L_i = ¬M · [(¬S1¬S0 AND_i) + (¬S1S0 XOR_i) + (S1¬S0 NAND_i) + (S1S0 XNOR_i)]`.

All terms here are Boolean products/sums. Arithmetic candidates are zero-extended to five bits:

- `ADD5 = {0,A}+{0,B}`.
- `ADD1_5 = {0,A}+{0,B}+1`.
- `LT = (A<B)`. `SUB5 = LT ? {0,(B−A)} : {0,(A−B)}`.
- `SHIFT5 = {A,0}`.

The arithmetic selection follows sel, and `R = M ? selected_arithmetic : 0`. The sign indicator is `N = M·¬S1·S0·LT`. These equations retain addition carry and produce nonnegative magnitude for subtraction.

For decimal conversion, the binary value R in 0..31 is split by thresholds: R≥30 gives tens=3, ones=R−30; else R≥20 gives tens=2, ones=R−20; else R≥10 gives tens=1, ones=R−10; otherwise tens=0, ones=R. Each BCD digit is decoded to a seven-segment pattern. The RTL uses active-low segment patterns ordered `{a,b,c,d,e,f,g}` for common-anode convention; adapt polarity if the selected Multisim display is common-cathode.

## 4. Architecture

The design is partitioned into input interface, four parallel bitwise logic functions, arithmetic candidate generators, mode/operation multiplexers, subtraction magnitude/sign logic, output control, binary-to-BCD converter, two digit decoders, and indicators. The source diagram is `ALU_Block_Diagram.mmd` with a rendered `ALU_Block_Diagram.png`. Detailed construction instructions are in `Multisim_Build_Guide.md`.

## 5. HDL implementation

`src/alu4.v` implements the specified behavior as combinational Verilog-2001. Outputs are assigned defaults in the combinational process and all operation cases are explicitly selected. Addition uses 5-bit operands. Subtraction compares operands, computes the positive difference, and asserts N only in the A<B case. The 2A case wires `{A,1'b0}` and does not use B. The BCD and segment logic are combinational.

## 6. Verification plan and results

The self-checking testbench in `tb/tb_alu4.v` iterates every selector encoding and every pair A,B∈[0,15], yielding 8×16×16=2,048 test vectors. Independently computed reference results are compared against L, R, N, BCD_TENS, BCD_ONES, and both segment outputs. Failure lines report the operation and input pair. Run with Icarus Verilog using the commands in README.md.

Representative required cases and expected decimal outputs are tabulated in `results/expected_test_cases.csv`. The table includes two or more cases per operation and covers zero/max inputs, equality, both subtraction orderings, carry, carry-in, maximum arithmetic result, ignored B for 2A, logic correctness, display boundaries, and inactive-mode suppression.

**Verification status:** The supplied files are a reference implementation and test method. An HDL simulation status is recorded in `results/simulation_log.txt` only if the simulator was available and the run completed. No claim of NI Multisim execution is made in this package. Before submission, build and run the schematic in the installed Multisim Workbench and record actual version, observations, and evidence. Expected values in the test table are theoretical results, not Multisim measurements.

## 7. Expected test discussion

For A=B, subtraction must produce zero with N=0. For A<B, R must be B−A, not a 5-bit two's-complement wraparound, and N=1. For A>B, R=A−B and N=0. Addition must retain the fifth bit (15+15=30). Addition with carry-in reaches 31 (15+15+1). Doubling 15 yields 30. Logic operations apply to corresponding bit positions. Inactive outputs are held at zero by mode control.

## 8. Multisim construction

Follow `Multisim_Build_Guide.md` to build the modular design with logic primitives or TTL equivalents, label all nets, use an appropriate binary-to-BCD network and two BCD decoders, and test display polarity and pin mapping against the installed component models. The assignment explicitly asks for a Multisim design; this delivery provides exact logic, a reference model, diagram, guide, and tests, but it is not a fabricated `.msXX` project.

## 9. Conclusion

The architecture satisfies the stated operation map and output rules. The RTL and exhaustive testbench provide a precise functional reference for implementation. The key design risks are dropped carry bits, incorrectly signed subtraction, wrong mux selector ordering, accidental use of B in doubling, and seven-segment polarity mismatch. The supplied tests target these cases. Complete final academic submission by filling cover details, building/simulating the actual Multisim schematic, and adding actual screenshots/results without describing theoretical values as measured results.

## References

1. An-Najah National University, Department of Computer Engineering, *Digital Circuits Design I — Assignment 1: 4 bit ALU Design*, supplied assignment image, deadline shown as 20/11/2026.
2. Verilog HDL source and testbench included with this submission package.
