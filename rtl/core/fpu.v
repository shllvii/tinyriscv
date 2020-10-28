//IEEE 754 Single Precision ALU
module adder(a, b, z);

	input [31:0] a, b;
	output [31:0] z;

	wire [31:0] z;
	wire [7:0] a_exponent;
	wire [23:0] a_mantissa;
	wire [7:0] b_exponent;
	wire [23:0] b_mantissa;

	reg        o_sign;
	reg [7:0]  o_exponent;
	reg [24:0] o_mantissa;


	reg [31:0] adder_a_in;
	reg [31:0] adder_b_in;
	wire [31:0] adder_out;

	assign z[31] = o_sign;
	assign z[30:23] = o_exponent;
	assign z[22:0] = o_mantissa[22:0];

	assign a_sign = a[31];
	assign a_exponent[7:0] = a[30:23];
	assign a_mantissa[23:0] = {1'b1, a[22:0]};

	assign b_sign = b[31];
	assign b_exponent[7:0] = b[30:23];
	assign b_mantissa[23:0] = {1'b1, b[22:0]};


	adder1 A1
	(
		.a(adder_a_in),
		.b(adder_b_in),
		.out(adder_out)
	);


	always @ (*) begin
		//If a is NaN or b is zero return a
		if ((a_exponent == 255 && a_mantissa != 0) || (b_exponent == 0) && (b_mantissa == 0)) begin
			o_sign = a_sign;
			o_exponent = a_exponent;
			o_mantissa = a_mantissa;
		//If b is NaN or a is zero return b
		end else if ((b_exponent == 255 && b_mantissa != 0) || (a_exponent == 0) && (a_mantissa == 0)) begin
			o_sign = b_sign;
			o_exponent = b_exponent;
			o_mantissa = b_mantissa;
		//if a or b is inf return inf
		end else if ((a_exponent == 255) && (b_exponent == 255)) begin
            if (a_sign == b_sign) begin
                o_sign = a_sign ;
                o_exponent = 255;
                o_mantissa = 0;
            end else begin
                o_sign = 0;
                o_exponent = 255;
                o_mantissa = 1;
            end
		end else if (a_exponent == 255) begin
            o_sign = a_sign;
            o_exponent = 255;
            o_mantissa = 0;
        end else if (b_exponent == 255) begin
            o_sign = b_sign;
            o_exponent = 255;
            o_mantissa = 0;
        end begin // Passed all corner cases
			adder_a_in = a;
			adder_b_in = b;
			o_sign = adder_out[31];
			o_exponent = adder_out[30:23];
			o_mantissa = adder_out[22:0];
		end
	end
endmodule


module adder1(a, b, out);
  input  [31:0] a, b;
  output [31:0] out;

  wire [31:0] out;
	reg a_sign;
	reg [7:0] a_exponent;
	reg [23:0] a_mantissa;
	reg b_sign;
	reg [7:0] b_exponent;
	reg [23:0] b_mantissa;

  reg o_sign;
  reg [7:0] o_exponent;
  reg [24:0] o_mantissa;

  reg [7:0] diff;
  reg [23:0] tmp_mantissa;
  reg [7:0] tmp_exponent;


  reg  [7:0] i_e;
  reg  [24:0] i_m;
  wire [7:0] o_e;
  wire [24:0] o_m;

  addition_normaliser norm1
  (
    .in_e(i_e),
    .in_m(i_m),
    .out_e(o_e),
    .out_m(o_m)
  );

  assign out[31] = o_sign;
  assign out[30:23] = o_exponent;
  assign out[22:0] = o_mantissa[22:0];

  always @ ( * ) begin
		a_sign = a[31];
		if(a[30:23] == 0) begin
			a_exponent = 8'b00000001;
			a_mantissa = {1'b0, a[22:0]};
		end else begin
			a_exponent = a[30:23];
			a_mantissa = {1'b1, a[22:0]};
		end
		b_sign = b[31];
		if(b[30:23] == 0) begin
			b_exponent = 8'b00000001;
			b_mantissa = {1'b0, b[22:0]};
		end else begin
			b_exponent = b[30:23];
			b_mantissa = {1'b1, b[22:0]};
		end
    if (a_exponent == b_exponent) begin // Equal exponents
      o_exponent = a_exponent;
      if (a_sign == b_sign) begin // Equal signs = add
        o_mantissa = a_mantissa + b_mantissa;
        //Signify to shift
        o_mantissa[24] = 1;
        o_sign = a_sign;
      end else begin // Opposite signs = subtract
        if(a_mantissa > b_mantissa) begin
          o_mantissa = a_mantissa - b_mantissa;
          o_sign = a_sign;
        end else begin
          o_mantissa = b_mantissa - a_mantissa;
          o_sign = b_sign;
        end
      end
    end else begin //Unequal exponents
      if (a_exponent > b_exponent) begin // a is bigger
        o_exponent = a_exponent;
        o_sign = a_sign;
        diff = a_exponent - b_exponent;
        tmp_mantissa = b_mantissa >> diff;
        if (a_sign == b_sign)
          o_mantissa = a_mantissa + tmp_mantissa;
        else
          	o_mantissa = a_mantissa - tmp_mantissa;
      end else if (a_exponent < b_exponent) begin // b is bigger
        o_exponent = b_exponent;
        o_sign = b_sign;
        diff = b_exponent - a_exponent;
        tmp_mantissa = a_mantissa >> diff;
        if (a_sign == b_sign) begin
          o_mantissa = b_mantissa + tmp_mantissa;
        end else begin
            o_mantissa = b_mantissa - tmp_mantissa;
        end
      end
    end
    if(o_mantissa[24] == 1) begin
      o_exponent = o_exponent + 1;
      o_mantissa = o_mantissa >> 1;
    end else if((o_mantissa[23] != 1) && (o_exponent != 0)) begin
      i_e = o_exponent;
      i_m = o_mantissa;
      o_exponent = o_e;
      o_mantissa = o_m;
    end
  end
endmodule

module addition_normaliser(in_e, in_m, out_e, out_m);
  input [7:0] in_e;
  input [24:0] in_m;
  output [7:0] out_e;
  output [24:0] out_m;

  wire [7:0] in_e;
  wire [24:0] in_m;
  reg [7:0] out_e;
  reg [24:0] out_m;

  always @ ( * ) begin
		if (in_m[23:3] == 21'b000000000000000000001) begin
			out_e = in_e - 20;
			out_m = in_m << 20;
		end else if (in_m[23:4] == 20'b00000000000000000001) begin
			out_e = in_e - 19;
			out_m = in_m << 19;
		end else if (in_m[23:5] == 19'b0000000000000000001) begin
			out_e = in_e - 18;
			out_m = in_m << 18;
		end else if (in_m[23:6] == 18'b000000000000000001) begin
			out_e = in_e - 17;
			out_m = in_m << 17;
		end else if (in_m[23:7] == 17'b00000000000000001) begin
			out_e = in_e - 16;
			out_m = in_m << 16;
		end else if (in_m[23:8] == 16'b0000000000000001) begin
			out_e = in_e - 15;
			out_m = in_m << 15;
		end else if (in_m[23:9] == 15'b000000000000001) begin
			out_e = in_e - 14;
			out_m = in_m << 14;
		end else if (in_m[23:10] == 14'b00000000000001) begin
			out_e = in_e - 13;
			out_m = in_m << 13;
		end else if (in_m[23:11] == 13'b0000000000001) begin
			out_e = in_e - 12;
			out_m = in_m << 12;
		end else if (in_m[23:12] == 12'b000000000001) begin
			out_e = in_e - 11;
			out_m = in_m << 11;
		end else if (in_m[23:13] == 11'b00000000001) begin
			out_e = in_e - 10;
			out_m = in_m << 10;
		end else if (in_m[23:14] == 10'b0000000001) begin
			out_e = in_e - 9;
			out_m = in_m << 9;
		end else if (in_m[23:15] == 9'b000000001) begin
			out_e = in_e - 8;
			out_m = in_m << 8;
		end else if (in_m[23:16] == 8'b00000001) begin
			out_e = in_e - 7;
			out_m = in_m << 7;
		end else if (in_m[23:17] == 7'b0000001) begin
			out_e = in_e - 6;
			out_m = in_m << 6;
		end else if (in_m[23:18] == 6'b000001) begin
			out_e = in_e - 5;
			out_m = in_m << 5;
		end else if (in_m[23:19] == 5'b00001) begin
			out_e = in_e - 4;
			out_m = in_m << 4;
		end else if (in_m[23:20] == 4'b0001) begin
			out_e = in_e - 3;
			out_m = in_m << 3;
		end else if (in_m[23:21] == 3'b001) begin
			out_e = in_e - 2;
			out_m = in_m << 2;
		end else if (in_m[23:22] == 2'b01) begin
			out_e = in_e - 1;
			out_m = in_m << 1;
		end
  end
endmodule

/*
module adder(
    input wire[31:0] a,
    input wire[31:0] b,
    output reg[31:0] z
);

reg [26:0] a_m, b_m;
reg [23:0] z_m;
wire [23:0] o_m;
reg [9:0] a_e, b_e, z_e;
wire [9:0] o_e;
reg a_s, b_s, z_s;
reg guard, round, sticky;
reg [27:0] sum;
reg [7:0] diff;
reg tmp_bit;
integer i;


adder_normaliser normaliser(
    .i_m(z_m),
    .i_e(z_e),
    .i_g(guard),
    .i_r(round),
    .i_s(sticky),
    .o_m(o_m),
    .o_e(o_e)
);

always @(*) begin
    a_m = {a[22:0], 3'd0};
    b_m = {b[22:0], 3'd0};
    a_e = a[30:23] - 127;
    b_e = b[30:23] - 127;
    a_s = a[31];
    b_s = b[31];

    if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m !=0)) begin
        z[31] = 1;
        z[30:23] = 255;
        z[22] = 1;
        z[21:0] = 0;
    end else if (a_e == 128) begin
        z[31] = a_s;
        z[30:23] = 255;
        z[22:0] = 0;
        if ((b_e == 128) && (a_s != b_s)) begin
            z[31] = b_s;
            z[30:23] = 255;
            z[22] = 1;
            z[21:0] = 0;
        end
    end else if (b_e == 128) begin
        z[31] = b_s;
        z[30:23] = 255;
        z[22:0] = 0;
    end else if (($signed(a_e) == -127) && (a_m == 0) && (($signed(b_e) == -127)&&(b_m==0))) begin
        z[31] = a_s & b_s;
        z[30:23] = b_e[7:0] + 127;
        z[22:0] = b_m[26:3];
    end else if (($signed(a_e) == -127) && (a_m == 0)) begin
        z[31] = b_s;
        z[30:23] = b_e[7:0] + 127;
        z[22:0] = b_m[26:3];
    end else if (($signed(b_e) == -127) && (b_m == 0)) begin
        z[31] = a_s;
        z[30:23] = a_e[7:0] + 127;
        z[22:0] = a_m[26:3];
    end begin
        if ($signed(a_e) == -127) begin
            a_e = -126;
        end else begin
            a_m[26] = 1;
        end
        if ($signed(b_e) == -127) begin
            b_e = -126;
        end else begin
            b_m[26] = 1;
        end

        if ($signed(a_e) > $signed(b_e)) begin
            diff = $signed(a_e) - $signed(b_e);
            if (diff > 27) begin
                diff = 27;
            end
            tmp_bit = 0;
            for (i=0; i<diff; i=i+1)
                tmp_bit = tmp_bit | b[i];
            b_m = b_m >> diff;
            b_m[0] = tmp_bit;
            b_e = b_e + diff;
        end else  if ($signed(b_e) > $signed(a_e)) begin
            diff = $signed(b_e) - $signed(a_e);
            if (diff > 27) begin
                diff = 27;
            end
            tmp_bit = 0;
            for (i=0; i<diff; i=i+1)
                tmp_bit = tmp_bit | a[i];
            a_m = a_m >> diff;
            a_m[0] = tmp_bit;
            a_e = a_e + diff;
        end 

        z_e = a_e;
        if (a_s == b_s) begin
            sum = a_m + b_m;
            z_s = a_s;
        end else begin
            if (a_m >= b_m) begin
                sum = a_m - b_m;
                z_s = a_s; 
            end else begin
                sum = b_m - a_m;
                z_s = b_s;
            end
        end

        if (sum[27]) begin
            z_m = sum[27:4];
            guard = sum[3];
            round = sum[2];
            sticky = sum[1] | sum[0];
            z_e = z_e + 1;
        end else begin
            z_m = sum[26:3];
            guard = sum[2];
            round = sum[1];
            sticky = sum[0];
        end

        z[22:0] = o_m[22:0];
        z[30:23] = o_e[7:0] + 127;
        z[31] = z_s;
        if ($signed(o_e) == -126 && o_m[23] == 0) begin
            z[30:23] = 0;
        end
        if ($signed(o_e) == -126 && o_m[23:0] == 0) begin
            z[31] = 0;
        end
        if ($signed(o_e) > 127) begin
            z[22:0] = 0;
            z[30:23] = 255;
            z[31] = z_s;
        end
    end
end 

endmodule

module adder_normaliser(
    input wire[23:0] i_m,
    input wire[9:0] i_e,
    input wire i_g,
    input wire i_r,
    input wire i_s,
    output reg[23:0] o_m,
    output reg[9:0] o_e
);
    reg[23:0] m;
    reg[9:0] e;
    reg g, r, s;
    reg[9:0] diff;
    integer i;

    always @(*) begin
        if ($signed(e) > -126) begin
            diff = e - (-126);
            
            m = i_m;
            e = i_e;
            g = i_g;
            r = i_r;
            s = i_s;

            if (m[23:0] == 24'b1) begin
                if (23 < diff) diff = 23;
            end else if (m[23:1] == 23'b1) begin
                if (22 < diff) diff = 22;
            end else if (m[23:2] == 22'b1) begin
                if (21 < diff) diff = 21;
            end else if (m[23:3] == 21'b1) begin
                if (20 < diff) diff = 20;
            end else if (m[23:4] == 20'b1) begin
                if (19 < diff) diff = 19;
            end else if (m[23:5] == 19'b1) begin
                if (18 < diff) diff = 18;
            end else if (m[23:6] == 18'b1) begin
                if (17 < diff) diff = 17;
            end else if (m[23:7] == 17'b1) begin
                if (16 < diff) diff = 16;
            end else if (m[23:8] == 16'b1) begin
                if (15 < diff) diff = 15;
            end else if (m[23:9] == 15'b1) begin
                if (14 < diff) diff = 14;
            end else if (m[23:10] == 14'b1) begin
                if (13 < diff) diff = 13;
            end else if (m[23:11] == 13'b1) begin
                if (12 < diff) diff = 12;
            end else if (m[23:12] == 12'b1) begin
                if (11 < diff) diff = 11;
            end else if (m[23:13] == 11'b1) begin
                if (10 < diff) diff = 10;
            end else if (m[23:14] == 10'b1) begin
                if (9 < diff) diff = 9;
            end else if (m[23:15] == 9'b1) begin
                if (8 < diff) diff = 8;
            end else if (m[23:16] == 8'b1) begin
                if (7 < diff) diff = 7;
            end else if (m[23:17] == 7'b1) begin
                if (6 < diff) diff = 6;
            end else if (m[23:18] == 6'b1) begin
                if (5 < diff) diff = 5;
            end else if (m[23:19] == 5'b1) begin
                if (4 < diff) diff = 4;
            end else if (m[23:20] == 4'b1) begin
                if (3 < diff) diff = 3;
            end else if (m[23:21] == 3'b1) begin
                if (2 < diff) diff = 2;
            end else if (m[23:22] == 2'b1) begin
                if (1 < diff) diff = 1;
            end else if (m[23] == 1'b1) begin
                if (0 < diff) diff = 0;
            end

            for (i=0; i<diff; i=i+1) begin
                e = e - 1;
                m = m << 1;
                m[0] = g;
                g = r; 
                r = 0;
            end 
        
        end

        if ($signed(e) < -126) begin
            diff = -126 - $signed(e);
            for (i = 0; i<diff; i=i+1) begin
                e = e + 1;
                s = s | r;
                r = g;
                g = m[0];
                m = m >> 1; 
            end
        end

        if (g && (r | s | m[0])) begin
            if (m == 24'hffffff) begin
                e = e + 1;
            end
            m = m + 1;
        end

        o_m = m;
        o_e = e;
    end
endmodule

*/
