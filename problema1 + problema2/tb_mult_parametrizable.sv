`timescale 1ns/1ps

module tb_mult_parametrizable;
    // ----------------------------------------------------------------
    // Parámetros del DUT
    // ----------------------------------------------------------------
    localparam int N = 4;

    // ----------------------------------------------------------------
    // Señales
    // ----------------------------------------------------------------
    logic [N-1:0]   A, B;
    wire  [2*N-1:0] P_full;
    wire  [N-1:0]   P_trunc;

    // ----------------------------------------------------------------
    // DUT
    // Asegúrate de compilar también tu suma_parametrizable #(2*N)
    // y mult_parametrizable #(N) antes de este TB.
    // ----------------------------------------------------------------
    mult_parametrizable #(.N(N)) dut (
        .A      (A),
        .B      (B),
        .P_full (P_full),
        .P_trunc(P_trunc)
    );

    // ----------------------------------------------------------------
    // Contadores y utilidades
    // ----------------------------------------------------------------
    int total_tests = 0;
    int total_errors = 0;

    // Tarea de chequeo de un caso
    task automatic check_case(input int ai, bi);
        logic [2*N-1:0] exp_full;
        logic [N-1:0]   exp_trunc;
        begin
            A = logic'(ai[N-1:0]);
            B = logic'(bi[N-1:0]);
            #1; // combinacional, dar tiempo a que propague

            exp_full  = ai * bi;                 // referencia
            exp_trunc = exp_full[N-1:0];         // truncado esperado

            total_tests++;

            if (P_full !== exp_full) begin
                $error("P_full mismatch: A=%0d (0x%0h), B=%0d (0x%0h) => DUT=%0d (0x%0h), EXP=%0d (0x%0h)",
                       ai, ai[N-1:0], bi, bi[N-1:0], P_full, P_full, exp_full, exp_full);
                total_errors++;
            end

            if (P_trunc !== exp_trunc) begin
                $error("P_trunc mismatch: A=%0d (0x%0h), B=%0d (0x%0h) => DUT=%0d (0x%0h), EXP=%0d (0x%0h)",
                       ai, ai[N-1:0], bi, bi[N-1:0], P_trunc, P_trunc, exp_trunc, exp_trunc);
                total_errors++;
            end
        end
    endtask

    // ----------------------------------------------------------------
    // Pruebas
    // ----------------------------------------------------------------
    initial begin
        // Dump para GTKWave
        $dumpfile("tb_mult_parametrizable.vcd");
        $dumpvars(0, tb_mult_parametrizable);

        // Reset "lógico" de entradas
        A = '0; B = '0;
        #1;

        $display("=== Pruebas dirigidas (casos borde) ===");
        check_case(0, 0);     // 0*0
        check_case(0, 7);     // 0*7
        check_case(1, 1);     // 1*1
        check_case(1, 15);    // 1*15
        check_case(2, 8);     // 2*8 = 16 (ver overflow/trunc)
        check_case(3, 5);     // 3*5 = 15
        check_case(7, 7);     // 7*7 = 49
        check_case(15, 15);   // 15*15 = 225
        check_case(9, 3);     // 9*3 = 27
        check_case(12, 4);    // 12*4 = 48

        $display("=== Barrido exhaustivo 16x16 ===");
        for (int ai = 0; ai < (1<<N); ai++) begin
            for (int bi = 0; bi < (1<<N); bi++) begin
                check_case(ai, bi);
            end
        end

        // Resumen
        if (total_errors == 0) begin
            $display("✅ TODOS LOS TESTS PASARON. Total casos: %0d", total_tests);
        end else begin
            $display("❌ Se encontraron %0d errores de %0d casos.", total_errors, total_tests);
        end

        $finish;
    end

endmodule
