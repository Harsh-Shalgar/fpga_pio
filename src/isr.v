// SPDX-FileCopyrightText: 2022 Lawrie Griffiths
// SPDX-License-Identifier: BSD-2-Clause

`default_nettype none
module isr #(
  parameter DATA_WIDTH = 16,
  parameter COUNT_WIDTH = 5
) (
  input                          clk,
  input                          penable,
  input                          reset,
  input                          stalled,
  input      [DATA_WIDTH-1:0]    din,
  input      [4:0]               shift,
  input                          dir,       // 0 = shift left, 1 = shift right
  input                          set,
  input                          do_shift,
  input      [COUNT_WIDTH-1:0]   bit_count,
  output     [DATA_WIDTH-1:0]    dout,
  output     [COUNT_WIDTH-1:0]   shift_count
);

  reg [DATA_WIDTH-1:0] shift_reg; // Stores the accumulated 16-bit ISR value.
  reg [COUNT_WIDTH-1:0] count; // Stores received bits; DATA_WIDTH means full.

  wire [4:0] shift_val = shift == 0 ? DATA_WIDTH : shift; // Encodes zero as a full-width shift.
  wire [DATA_WIDTH-1:0] source_mask = {DATA_WIDTH{1'b1}} >> (DATA_WIDTH-shift_val); // Creates a mask for the inserted input bits.
  wire [DATA_WIDTH-1:0] source_value = din & source_mask; // Keeps only the low N input bits.
  wire [DATA_WIDTH-1:0] shifted_left = (shift_reg << shift_val) | source_value; // Inserts data at the right for left shift.
  wire [DATA_WIDTH-1:0] shifted_right = (shift_reg >> shift_val) | (source_value << (DATA_WIDTH-shift_val)); // Inserts data at the left for right shift.
  wire [DATA_WIDTH-1:0] shifted_value = dir ? shifted_right : shifted_left; // Selects the configured ISR shift direction.
  wire [COUNT_WIDTH-1:0] next_count = (count + shift_val) >= DATA_WIDTH ? DATA_WIDTH : (count + shift_val); // Saturates the received-bit count at DATA_WIDTH.

  always @(posedge clk) begin // Updates ISR state only on enabled, non-stalled cycles.
    if (reset) begin // Clears the ISR and marks it empty.
      shift_reg <= {DATA_WIDTH{1'b0}}; // Clears all ISR data bits.
      count <= 0; // Marks the ISR as empty.
    end else if (penable && !stalled) begin // Accepts MOV or IN updates only when execution is enabled.
      if (set) begin // Loads ISR directly from MOV or OUT-ISR.
        shift_reg <= din; // Replaces the ISR contents.
        count <= bit_count; // Uses the explicitly supplied received-bit count.
      end else if (do_shift) begin // Applies IN source and bit-count data.
        shift_reg <= shifted_value; // Stores the shifted ISR result.
        count <= next_count; // Records the number of received bits.
      end
    end
  end

  assign dout = shift_reg; // Exposes ISR contents to PUSH and MOV operations.
  assign shift_count = count; // Exposes ISR status to threshold checks.

endmodule
 
