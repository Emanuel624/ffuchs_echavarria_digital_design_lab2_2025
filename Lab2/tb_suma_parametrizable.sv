`timescale 1ns/1ps

module tb_suma_parametrizable;

    // Parámetro del tamaño
    parameter int N = 4;

    // Señales de prueba
    logic [N-1:0] A;
    logic [N-1:0] B;
    logic CIN;
    logic [N-1:0] suma;
    logic cout;

    // Instancia del módulo bajo prueba
    suma_parametrizable #(N) UUT (
        .A(A),
        .B(B),
        .CIN(CIN),
        .suma(suma),
        .cout(cout)
    );

    // Variables para bucles
    integer i, j;

    initial begin
        $display("=== Testbench Suma Parametrizable ===");
        $display("A\tB\tCIN\tsuma\tcout");

        // Probar todas las combinaciones de A y B con CIN = 0 y 1
        for (i = 0; i < 2**N; i = i + 1) begin
            for (j = 0; j < 2**N; j = j + 1) begin
                // CIN = 0
                A = i;
                B = j;
                CIN = 1'b0;
                #5; // esperar 5 ns
                $display("%b\t%b\t%b\t%b\t%b", A, B, CIN, suma, cout);

                // CIN = 1
                CIN = 1'b1;
                #5;
                $display("%b\t%b\t%b\t%b\t%b", A, B, CIN, suma, cout);
            end
        end

        $display("=== Fin de la simulación ===");
        $stop;
    end

endmodule
