`timescale 1ns/1ps

module tb_restador_parametrizable;

    parameter N = 4;

    logic [N-1:0] A, B;
    logic BORROW_IN;
    logic [N-1:0] DIFF;
    logic BORROW_OUT;

    // Instanciamos el DUT
    restador_parametrizable #(N) dut (
        .A(A),
        .B(B),
        .BORROW_IN(BORROW_IN),
        .DIFF(DIFF),
        .BORROW_OUT(BORROW_OUT)
    );

    // Generamos estímulos automáticos
    initial begin
        BORROW_IN = 0;

        for (int i = 0; i < 16; i++) begin
            for (int j = 0; j < 16; j++) begin
                A = i;
                B = j;
                #5; // pequeño delay
                $display("A=%0d B=%0d -> DIFF=%0d BORROW_OUT=%b", A, B, DIFF, BORROW_OUT);
            end
        end

        $finish;
    end

endmodule
