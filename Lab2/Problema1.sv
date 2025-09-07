module Problema1 #(
    parameter int WIDTH = 4,
    // 1: V = overflow con signo (estándar ALU)
    // 0: V = overflow sin signo (V refleja C en suma y ~borrow en resta)
    parameter bit SIGNED_OVF = 1
)(
    input  logic [WIDTH-1:0] A,
    input  logic [WIDTH-1:0] B,
    input  logic [3:0]       opcode,   // 0000=ADD, 0001=SUB, 0010=DIV, 0011=AND,
                                       // 0100=OR, 0101=XOR, 0110=MOD, 0111=SHL, 1000=SHR
    output logic [WIDTH-1:0] result,
    output logic             N, Z, C, V
);

    // --------- ADD (estructural)
    logic [WIDTH-1:0] addResult;
    logic             addCout;

    suma_parametrizable #(.N(WIDTH)) u_add (
        .A    (A),
        .B    (B),
        .CIN  (1'b0),
        .suma (addResult),
        .cout (addCout)
    );

    // --------- SUB (estructural): A - B
    logic [WIDTH-1:0] subResult;
    logic             subBorrow;

    restador_parametrizable #(.N(WIDTH)) u_sub (
        .A          (A),
        .B          (B),
        .BORROW_IN  (1'b0),
        .DIFF       (subResult),
        .BORROW_OUT (subBorrow)
    );
	 
	 // --------- MUL (estructural) N x N -> 2N
    logic [2*WIDTH-1:0] prod_full;
    multiplier #(.N(WIDTH)) u_mul (
        .a (A),
        .b (B),
        .product (prod_full)
    );


    // --------- DIV / MOD (protegidos B==0)
    logic [WIDTH-1:0] Q_div, Q_mod;
    logic             div0;

    always_comb begin
        if (B == '0) begin
            Q_div = '0;
            Q_mod = '0;
            div0  = 1'b1;
        end else begin
            Q_div = A / B;   // cociente
            Q_mod = A % B;   // residuo
            div0  = 1'b0;
        end
    end

    // --------- Lógica bit a bit
    logic [WIDTH-1:0] Q_and, Q_or, Q_xor;
    assign Q_and = A & B;
    assign Q_or  = A | B;
    assign Q_xor = A ^ B;

    // --------- Shifts por 1
    logic [WIDTH-1:0] Q_shl, Q_shr;
    assign Q_shl = A << 1;
    assign Q_shr = A >> 1;

	// --------- Selector de resultado
	always_comb begin
		 unique case (opcode)
			  4'b0000: result = addResult;             // ADD
			  4'b0001: result = subResult;             // SUB
			  4'b0010: result = prod_full[WIDTH-1:0];  // MUL (truncado a WIDTH)
			  4'b0011: result = Q_div;                 // DIV
			  4'b0100: result = Q_and;                 // AND
			  4'b0101: result = Q_or;                  // OR
			  4'b0110: result = Q_xor;                 // XOR
			  4'b0111: result = Q_mod;                 // MOD
			  4'b1000: result = Q_shl;                 // SHL
			  4'b1001: result = Q_shr;                 // SHR
			  default: result = '0;
		 endcase
	end


    // --------- Flags Z y N (sobre el resultado)
    assign Z = (result == '0);
    assign N = result[WIDTH-1];

	// --------- C: depende de la operación
	always_comb begin
		 C = 1'b0;
		 unique case (opcode)
			  4'b0000: C = addCout;                     // ADD
			  4'b0001: C = ~subBorrow;                  // SUB (carry = !borrow)
			  4'b0010: C = |prod_full[2*WIDTH-1:WIDTH]; // MUL: bits altos no nulos
			  4'b1000: C = A[WIDTH-1];                  // SHL (bit expulsado a la izq)
			  4'b1001: C = A[0];                        // SHR (bit expulsado a la der)
			  default: C = 1'b0;
		 endcase
	end


	// --------- V: seleccionable por parámetro
	localparam int MSB = WIDTH-1;
	wire V_add_signed = (A[MSB] == B[MSB]) && (addResult[MSB] != A[MSB]);
	wire V_sub_signed = (A[MSB] != B[MSB]) && (subResult[MSB] != A[MSB]);

	// Overflow de MUL
	wire upper_all_zero = ~|prod_full[2*WIDTH-1:WIDTH];
	wire upper_all_ones =  &prod_full[2*WIDTH-1:WIDTH];
	wire prod_sign      =  prod_full[2*WIDTH-1];
	wire V_mul_signed   = !( (prod_sign && upper_all_ones) || (!prod_sign && upper_all_zero) );
	wire V_mul_unsigned = !upper_all_zero;

	always_comb begin
		 V = 1'b0;
		 unique case (opcode)
			  4'b0000: V = SIGNED_OVF ? V_add_signed   : C;            // ADD
			  4'b0001: V = SIGNED_OVF ? V_sub_signed   : ~subBorrow;   // SUB
			  4'b0010: V = SIGNED_OVF ? V_mul_signed   : V_mul_unsigned; // MUL
			  4'b0011: V = div0;                                       // DIV (divide-by-zero)
			  default: V = 1'b0;
		 endcase
	end


endmodule




