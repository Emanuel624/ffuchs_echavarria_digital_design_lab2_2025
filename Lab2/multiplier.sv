// Multiplicador parametrizable por suma de productos parciales
// - Sin usar operador '*'
// - Combinacional, sintetizable y escalable
module multiplier #(
    parameter int N = 4
)(
    input  logic [N-1:0]     a,
    input  logic [N-1:0]     b,
    output logic [2*N-1:0]   product
);
    // Etapas de acumulación (stage[0] = 0, stage[N] = product)
    logic [2*N-1:0] stage   [0:N];
    logic [2*N-1:0] partial [0:N-1];

    assign stage[0] = '0;

    // Productos parciales alineados (AND + shift)
    genvar i;
    generate
        for (i = 0; i < N; i++) begin : gen_pp
            // Extiende 'a' a 2N y desplaza i posiciones si b[i]=1
            assign partial[i] = b[i] ? ({{N{1'b0}}, a} << i) : '0;

            // stage[i+1] = stage[i] + partial[i] (sumador estructural de 2N bits)
            logic cout_unused;
            suma_parametrizable #(.N(2*N)) add_i (
                .A    (stage[i]),
                .B    (partial[i]),
                .CIN  (1'b0),
                .suma (stage[i+1]),
                .cout (cout_unused)
            );
        end
    endgenerate

    assign product = stage[N];

endmodule
