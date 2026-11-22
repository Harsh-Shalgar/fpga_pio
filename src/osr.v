// SPDX-FileCopyrightText: 2022 Lawrie Griffiths
// SPDX-License-Identifier: BSD-2-Clause

`default_nettype none
module osr #(
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
  output     [DATA_WIDTH-1:0]    dout,
  output     [COUNT_WIDTH-1:0]   shift_count
);

  reg [DATA_WIDTH-1:0] shift_reg; // Stores the 16-bit OSR value.
  reg [COUNT_WIDTH-1:0] count; // Stores shifted-out bits; DATA_WIDTH means empty.

  wire [COUNT_WIDTH-1:0] shift_val = shift == 0 ? DATA_WIDTH : shift; // Encodes zero as a full-width shift.
  wire [DATA_WIDTH-1:0] source_mask = {DATA_WIDTH{1'b1}} >> (DATA_WIDTH-shift_val); // Creates a mask for the low N OSR bits.
  wire [DATA_WIDTH-1:0] shifted_out = dir ? (shift_reg & source_mask) : (shift_reg >> (DATA_WIDTH-shift_val)); // Extracts the bits removed from the OSR.
  wire [DATA_WIDTH-1:0] shifted_value = dir ? (shift_reg >> shift_val) : (shift_reg << shift_val); // Calculates the OSR value remaining after a shift.
  wire [COUNT_WIDTH-1:0] next_count = (count + shift_val) >= DATA_WIDTH ? DATA_WIDTH : (count + shift_val); // Saturates the shifted-out count at DATA_WIDTH.

  always @(posedge clk) begin // Updates OSR state only on enabled, non-stalled cycles.
    if (reset) begin // Clears the OSR and marks it empty.
      shift_reg <= {DATA_WIDTH{1'b0}}; // Clears all OSR data bits.
      count <= DATA_WIDTH; // Marks the OSR as empty.
    end else if (penable && !stalled) begin // Accepts PULL or OUT updates only when execution is enabled.
      if (set) begin // Loads a newly pulled or MOV-written word.
        shift_reg <= din; // Replaces the OSR contents.
        count <= 0; // Marks a newly loaded word as full.
      end else if (do_shift) begin // Applies OUT's shift amount.
        shift_reg <= shifted_value; // Stores the remaining OSR bits.
        count <= next_count; // Records the number of shifted-out bits.
      end
    end
  end

  assign dout = do_shift ? shifted_out : shift_reg; // Sends shifted-out bits for OUT or the full OSR for MOV.
  assign shift_count = count; // Exposes OSR status to threshold and JMP checks.

endmodule
