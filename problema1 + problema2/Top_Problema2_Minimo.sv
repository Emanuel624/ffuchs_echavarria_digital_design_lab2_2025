// Top_Problema2_Minimo.sv
module Top_Problema2_Minimo #(
    parameter int WIDTH = 32
)(
    input  logic       CLOCK_50,     // reloj placa
    input  logic [9:0] SW,           // A=SW[3:0], B=SW[7:4], OP={SW9,SW8,SW6,SW5}
    input  logic [3:0] KEY,          // KEY[1]=RESET (activa en bajo)
    output logic [9:0] LEDR          // salida registrada (solo mostramos hasta 10 LSBs)
);

    // ================= Reset =================
    logic rst_n;
    assign rst_n = KEY[1]; // activo-bajo

    // ================= Entradas a la ALU =================
    logic [WIDTH-1:0] A_sw, B_sw;
    logic [3:0]       OP_sw;

    // Zero-extend para WIDTH>4
    assign A_sw  = {{(WIDTH-4){1'b0}}, SW[3:0]};
    assign B_sw  = {{(WIDTH-4){1'b0}}, SW[7:4]};
    assign OP_sw = {SW[9], SW[8], SW[6], SW[5]}; // 4 bits de opcode

    // ================= Núcleo FF–ALU–FF =================
    logic [WIDTH-1:0] result_q;

    CriticalPathHarness #(.WIDTH(WIDTH)) u_harness (
        .clk    (CLOCK_50),
        .rst_n  (rst_n),
        .din_a  (A_sw),
        .din_b  (B_sw),
        .din_op (OP_sw),
        .dout_q (result_q)
    );

    // ================= LEDs (solo lo que cabe) =================
    localparam int LEDN  = 10;
    localparam int SHOWN = (WIDTH < LEDN) ? WIDTH : LEDN;

    always_comb begin
        LEDR               = '0;                 // apaga todos
        LEDR[SHOWN-1:0]    = result_q[SHOWN-1:0]; // muestra hasta 10 LSBs
    end

endmodule
