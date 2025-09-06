
module mult_parametrizable #(
    parameter int N = 4
)(
    input  logic [N-1:0]   A,
    input  logic [N-1:0]   B,
    output logic [2*N-1:0] P_full,   // producto completo 2N bits
    output logic [N-1:0]   P_trunc
);
    // ------------------------------------------------------------
    // 0) Parametro local para ancho del sumador
    // ------------------------------------------------------------
    localparam int M = 2*N;

    // ------------------------------------------------------------
    // 1) Productos parciales (N vectores de N bits)
    // ------------------------------------------------------------
    logic [N-1:0] pp [0:N-1];
    genvar g0;
    generate
        for (g0 = 0; g0 < N; g0++) begin : gen_pp
            assign pp[g0] = A & {N{B[g0]}};
        end
    endgenerate

    // ------------------------------------------------------------
    // 2) Extiende a M y desplaza g1 posiciones
    // ------------------------------------------------------------
    logic [M-1:0] pp_ext [0:N-1];
    genvar g1;
    generate
        for (g1 = 0; g1 < N; g1++) begin : gen_pp_ext
            // { ceros[N], pp[g1] } tiene M bits; luego << g1
            assign pp_ext[g1] = ({ {N{1'b0}}, pp[g1] }) << g1;
        end
    endgenerate

    // ------------------------------------------------------------
    // 3) Acumulación con sumadores M-bit (sin '+')
    // acc[0] = 0; acc[k+1] = acc[k] + pp_ext[k]
    // ------------------------------------------------------------
    logic [M-1:0] acc [0:N];
    assign acc[0] = '0;

    genvar g2;
    generate
        for (g2 = 0; g2 < N; g2++) begin : gen_acc
            logic [M-1:0] sum_i;
            logic         cout_i, cin_msb_i;

            // ¡OJO! Puertos coinciden con tu suma_parametrizable (SUM/COUT/CARRY_INTO_MSB)
            suma_parametrizable #(.N(M)) U_ADD (
                .A               (acc[g2]),
                .B               (pp_ext[g2]),
                .CIN             (1'b0),
                .SUM             (sum_i),
                .COUT            (cout_i),
                .CARRY_INTO_MSB  (cin_msb_i)
            );
            assign acc[g2+1] = sum_i;
        end
    endgenerate

    // ------------------------------------------------------------
    // 4) Salidas
    // ------------------------------------------------------------
    assign P_full  = acc[N];
    assign P_trunc = acc[N][N-1:0];

endmodule

