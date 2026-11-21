# NI Multisim Workbench Build Guide

## Before you start

This guide describes a reproducible schematic architecture using Multisim-compatible digital primitives/TTL parts. The delivered package does **not** contain a native `.msXX` file and the circuit has not been opened or simulated in Multisim here. Build it in the Multisim version installed on your computer, then save the actual native design there.

Choose one consistent logic family (e.g. 74LS TTL) and use its matching supply/power conventions. In Multisim, digital primitives are convenient for the first functional build; then, if the course requires gate-level ICs, replace each primitive block with the listed 74LS devices and check pinouts against the exact library model/datasheet. The equations below are authoritative.

## 1. Inputs / controls

Create eight interactive logic-state inputs: A3..A0, B3..B0, M, S1, S0. Arrange A3/A0 and B3/B0 in MSB-to-LSB order and label every net. For demonstrations, use digital interactive switches or logic-state sources, not floating inputs.

## 2. Logic unit

For each i=0..3 create:

- `AND_i = A_i AND B_i`
- `XOR_i = A_i XOR B_i`
- `NAND_i = NOT(AND_i)`
- `XNOR_i = NOT(XOR_i)`

Select one vector with a 4-way, 4-bit mux controlled by `{S1,S0}` in that mapping order (00 AND, 01 XOR, 10 NAND, 11 XNOR). Gate its output with `NOT(M)` to produce L[3:0]. Thus arithmetic mode forces L=0000. If mux components are unavailable, use four 4:1 muxes or sum-of-products: each bit is `~M & ((~S1&~S0&AND_i) | (~S1&S0&XOR_i) | (S1&~S0&NAND_i) | (S1&S0&XNOR_i))`.

Gate quantities for a primitive/gate-level implementation: 4 AND, 4 XOR, 4 NOT (for NAND/XNOR), one 4-bit 4:1 mux (or equivalent 16 product terms plus OR tree), and four AND gates for the mode mask. TTL alternative: 74LS08 AND, 74LS86 XOR, 74LS04 inverter, plus mux or gates. Account for package fanout and unused gates.

## 3. Arithmetic unit: derive four candidate 5-bit values

Use zero-extended operands `A5={0,A}`, `B5={0,B}`.

- ADD: `ADD5=A5+B5` (5-bit result, carry retained).
- ADD1: `ADD1_5=A5+B5+1`.
- SUB magnitudes: form a 5-bit unsigned comparator `LT=(A<B)`, then `SUB5=LT ? (B-A) : (A-B)`. `SUB_NEG=LT`. Both differences are zero-extended to five bits. This implements the required absolute difference, not two's-complement wraparound.
- SHIFT: `SHIFT5={A,1'b0}` (2A); do not connect B to this operation's data path.

A reusable 4-bit ripple adder uses one full-adder stage per bit; carry-in is 0 for ADD, 1 for ADD1. For subtraction, use a comparator plus two's complement subtractor, or use two independent magnitude subtractors selected by LT. For a 74LS implementation, 74LS283 provides a 4-bit adder; expand to five-bit carry-aware results and use separate/controlled stages as needed. A 74LS85 comparator can produce A<B. Validate exact library pin numbering and active-levels before wiring; do not assume pin order from this guide.

An alternative single-adder architecture for arithmetic is possible but must preserve a 5-bit carry and must correctly handle absolute subtraction. The separate candidates above are the clearer student implementation.

## 4. Arithmetic operation selection and output gating

Select `RAW5` from ADD5, SUB5, ADD1_5, SHIFT5 using a 4:1, 5-bit mux controlled by `{S1,S0}`. Then `R = M ? RAW5 : 5'b00000`. Negative LED equation: `N=M & ~S1 & S0 & SUB_NEG`; therefore N is zero except subtraction with A<B. L is already suppressed when M=1.

Check that signal width is 5 bits at every candidate and mux. A frequent error is dropping the carry bit from addition (e.g., 15+15=30=`11110`).

## 5. Binary-to-decimal and displays

Use a combinational binary-to-BCD converter for R[4:0], range 0–31. One straightforward implementation is a magnitude-range network:

- if R≥30: tens=3, ones=R−30
- else if R≥20: tens=2, ones=R−20
- else if R≥10: tens=1, ones=R−10
- else: tens=0, ones=R

The supplied HDL implements this exact behavior. In a gate-level Multisim build, implement threshold comparators and subtractors or a double-dabble converter. Connect BCD tens and ones to two BCD-to-seven-segment decoders (e.g. 74LS47 for common-anode displays, subject to the simulator's model and display type). Use current-limiting resistors if the selected physical/display model requires them. For a common-anode 7-segment display, segment outputs are active-low. Check the particular Multisim display component's polarity and segment naming; if using common-cathode, use a matching active-high decoder/inversion arrangement.

If you use the seven-segment display component with an integrated decoder, still connect the four BCD bits in correct weight order (D,C,B,A or the component's documented order). Confirm display shows `00` for R=0, `09` for 9, `10` for 10, `29` for 29, `30` for 30, and `31` for 31.

## 6. Output indicators / organization

Place four LEDs on L3..L0, five logic probes or LEDs on R4..R0 (optional but useful for debugging), two decimal seven-segment displays for R, and LED N. Label blocks `INPUTS`, `LOGIC UNIT`, `ARITHMETIC UNIT`, `OPERATION SELECT`, `BCD CONVERTER`, and `OUTPUTS`. Use buses or net labels to reduce crossings. Never leave inputs/selects floating.

## 7. Recommended Multisim validation sequence

1. Test logic blocks individually with A=1010, B=1100: AND=1000, XOR=0110, NAND=0111, XNOR=1001.
2. Test ADD on 15+15: R=30, display `30`; test ADD1 on 15+15: R=31, display `31`.
3. Test subtract both orderings: (3,11)→R=8,N=1; (11,3)→R=8,N=0; equality (7,7)→R=0,N=0.
4. Test 2A at A=15, B arbitrary (e.g. 9): R=30, display `30`; vary B and confirm no change.
5. Test mode suppression: M=0 gives R=0,N=0, selected logic L; M=1 gives L=0000.
6. Test decimal boundaries 9,10,19,20,29,30,31 through suitable ALU inputs, checking tens carry and leading zero.
7. Record actual simulator version, date, and observed values in the report only after running Multisim. Keep screenshots as evidence if requested.

## 8. Expected control wiring summary

| Signal | Definition |
|---|---|
| L[3:0] | `~M & selected_logic[3:0]` |
| R[4:0] | `M ? selected_arithmetic[4:0] : 0` |
| N | `M & ~S1 & S0 & (A<B)` |
| BCD_TENS/ONES | unsigned R (0..31) converted to decimal |
| display segments | decode each BCD digit; polarity per selected component |
