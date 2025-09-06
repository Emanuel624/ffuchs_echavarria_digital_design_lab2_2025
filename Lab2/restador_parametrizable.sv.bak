module restador_parametrizable #(parameter int N = 4)(
    input  logic [N-1:0] A,
    input  logic [N-1:0] B,
    input  logic BORROW_IN,
    output logic [N-1:0] DIFF,
    output logic BORROW_OUT
);

    logic [N-1:0] B_comp; // B complementado

    // Complemento a 2 de B: invertimos y sumamos el borrow_in
    assign B_comp = B ^ {N{1'b1}}; // NOT de B

    // Usamos el sumador parametrizable para hacer A + (~B) + 1
    logic carry_internal;

    suma_parametrizable #(N) U1 (
        .A(A),
        .B(B_comp),
        .CIN(~BORROW_IN), // Para ajustar el borrow si es necesario
        .suma(DIFF),
        .cout(carry_internal)
    );

    // El borrow_out real es el inverso del carry final
    assign BORROW_OUT = ~carry_internal;

endmodule
