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
            4'b0000: result = addResult; // ADD
            4'b0001: result = subResult; // SUB
            4'b0010: result = Q_div;     // DIV
            4'b0011: result = Q_and;     // AND
            4'b0100: result = Q_or;      // OR
            4'b0101: result = Q_xor;     // XOR
            4'b0110: result = Q_mod;     // MOD
            4'b0111: result = Q_shl;     // SHL
            4'b1000: result = Q_shr;     // SHR
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
            4'b0000: C = addCout;     // ADD
            4'b0001: C = ~subBorrow;  // SUB (carry = !borrow)
            4'b0111: C = A[WIDTH-1];  // SHL: bit expulsado por la izquierda
            4'b1000: C = A[0];        // SHR: bit expulsado por la derecha
            default: C = 1'b0;
        endcase
    end

    // --------- V: seleccionable por parámetro
    // Overflow con signo (estándar):
    //  ADD: (A_msb==B_msb) && (sum_msb != A_msb)
    //  SUB: (A_msb!=B_msb) && (diff_msb != A_msb)
    // Overflow sin signo:
    //  ADD: V = C ;  SUB: V = ~borrow ; otros: 0
    localparam int MSB = WIDTH-1;
    wire V_add_signed = (A[MSB] == B[MSB]) && (addResult[MSB] != A[MSB]);
    wire V_sub_signed = (A[MSB] != B[MSB]) && (subResult[MSB] != A[MSB]);

    always_comb begin
        V = 1'b0;
        unique case (opcode)
            4'b0000: V = SIGNED_OVF ? V_add_signed : C;          // ADD
            4'b0001: V = SIGNED_OVF ? V_sub_signed : ~subBorrow; // SUB
            4'b0010: V = div0;                                    // DIV (error/overflow)
            default: V = 1'b0;                                    // AND/OR/XOR/MOD/SHL/SHR
        endcase
    end

endmodule




