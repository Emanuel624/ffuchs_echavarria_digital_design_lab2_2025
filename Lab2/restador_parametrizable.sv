module restador_parametrizable #(
    parameter int N = 4
)(
    input  logic [N-1:0] A,
    input  logic [N-1:0] B,
    input  logic         BORROW_IN,
    output logic [N-1:0] DIFF,
    output logic         BORROW_OUT
);
    logic [N-1:0] B_comp;        // B complementado
    logic         carry_internal;

    // Complemento a 2 de B: invertimos y sumamos el borrow_in
    assign B_comp = ~B;

    // Usamos el sumador parametrizable para hacer A + (~B) + 1
    suma_parametrizable #(N) U1 (
        .A    (A),
        .B    (B_comp),
        .CIN  (~BORROW_IN),   // Ajusta según el borrow de entrada
        .suma (DIFF),
        .cout (carry_internal)
    );

    // El borrow_out real es el inverso del carry final
    assign BORROW_OUT = ~carry_internal;

endmodule
