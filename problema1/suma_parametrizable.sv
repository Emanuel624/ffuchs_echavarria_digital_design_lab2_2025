module suma_parametrizable #(
    parameter int N = 4
)(
    input  logic [N-1:0] A,
    input  logic [N-1:0] B,
    input  logic         CIN,
    output logic [N-1:0] suma,
    output logic         cout
);
    logic [N-1:0] carry; // Vector de acarreos internos

    genvar i;
    generate
        for (i = 0; i < N; i++) begin : sum_loop
            if (i == 0) begin
                // Primer bit: entrada de acarreo es CIN
                suma_posicion fa (
                    .A     (A[i]),
                    .B     (B[i]),
                    .Carry (CIN),
                    .suma  (suma[i]),
                    .Cout  (carry[i])
                );
            end else begin
                // Los demás bits: entrada de acarreo es el Cout del bit anterior
                suma_posicion fa (
                    .A     (A[i]),
                    .B     (B[i]),
                    .Carry (carry[i-1]),
                    .suma  (suma[i]),
                    .Cout  (carry[i])
                );
            end
        end
    endgenerate

    // Último acarreo
    assign cout = carry[N-1];

endmodule
