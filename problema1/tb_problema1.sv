`timescale 1ns/1ps

module tb_problema1;
    localparam int WIDTH = 4;
    localparam int MASK  = (1<<WIDTH)-1;

    // DUT I/O
    logic [WIDTH-1:0] A, B;
    logic [3:0]       opcode;
    wire  [WIDTH-1:0] result;

    // Instancia del DUT
    Problema1 #(.WIDTH(WIDTH)) dut (
        .A(A), .B(B), .opcode(opcode), .result(result)
    );

    // Contadores
    int total_tests = 0;
    int total_errors = 0;

    // Opcodes (mismo mapeo que en tu diseño)
	localparam logic [3:0]
		 OP_ADD = 4'b0000,
		 OP_SUB = 4'b0001,
		 OP_MUL = 4'b0010, // NUEVO AQUÍ
		 OP_DIV = 4'b0011,
		 OP_AND = 4'b0100,
		 OP_OR  = 4'b0101,
		 OP_XOR = 4'b0110,
		 OP_MOD = 4'b0111,
		 OP_SHL = 4'b1000, // <<1
		 OP_SHR = 4'b1001; // >>1


    // Modelo de referencia
	function automatic logic [WIDTH-1:0] model_result(
		 input logic [3:0]       op,
		 input logic [WIDTH-1:0] a,
		 input logic [WIDTH-1:0] b
	);
		 logic [WIDTH-1:0] y;
		 case (op)
			  OP_ADD: y = (a + b);
			  OP_SUB: y = (a - b);
			  OP_MUL: y = (a * b);                 // <-- agregado (se truncará con MASK)
			  OP_DIV: y = (b == '0) ? '0 : (a / b);
			  OP_AND: y = a & b;
			  OP_OR : y = a | b;
			  OP_XOR: y = a ^ b;
			  OP_MOD: y = (b == '0) ? '0 : (a % b);
			  OP_SHL: y = (a << 1);
			  OP_SHR: y = (a >> 1);
			  default: y = '0;
		 endcase
		 return y & MASK; // mantiene WIDTH bits (truncado)
	endfunction

    // Tarea de chequeo
    task automatic check_case(input logic [3:0] op, input int ai, bi);
        logic [WIDTH-1:0] a4 = logic'(ai[WIDTH-1:0]);
        logic [WIDTH-1:0] b4 = logic'(bi[WIDTH-1:0]);
        logic [WIDTH-1:0] exp;
        begin
            A = a4; B = b4; opcode = op;
            #1;
            exp = model_result(op, a4, b4);
            total_tests++;
            if (result !== exp) begin
                $error("OP=%b A=%0d(0x%0h) B=%0d(0x%0h) -> DUT=0x%0h  EXP=0x%0h",
                       op, a4, a4, b4, b4, result, exp);
                total_errors++;
            end
        end
    endtask

    initial begin
    `ifndef SYNTHESIS
        $dumpfile("tb_problema1.vcd");
        $dumpvars(0, tb_problema1);
    `endif

        // Pruebas dirigidas
        A='0; B='0; opcode=OP_ADD; #1;

        $display("=== Pruebas dirigidas ===");
        check_case(OP_ADD,  3,  5);
        check_case(OP_ADD, 15,  1);
        check_case(OP_SUB,  7,  2);
        check_case(OP_SUB,  2,  7);
		  check_case(OP_MUL,  3,  5);  // 3*5 = 15 -> 0xF
		  check_case(OP_MUL,  7,  7);  // 49 -> 0x31, truncado a 4 bits = 0x1
		  check_case(OP_MUL, 10,  0);  // 0
		  check_case(OP_MUL, 15, 15); // 225 -> 0xE1, en 4 bits queda 0x1
        check_case(OP_DIV, 15,  3);
        check_case(OP_DIV,  9,  4);
        check_case(OP_DIV,  9,  0);
        check_case(OP_MOD, 15,  4);
        check_case(OP_MOD,  7,  2);
        check_case(OP_MOD, 10,  0);
        check_case(OP_AND, 'hA, 'h3);
        check_case(OP_OR , 'hA, 'h3);
        check_case(OP_XOR, 'hA, 'h3);
        check_case(OP_SHL, 'h9,  0);
        check_case(OP_SHR, 'h9,  0);

        // Barrido exhaustivo (A,B=0..15) para todos los opcodes
			$display("=== Barrido exhaustivo ===");
			for (int opi = 0; opi <= 9; opi++) begin   // <--- antes era <= 8
				 logic [3:0] op;
				 op = opi[3:0];
				 for (int ai = 0; ai < (1<<WIDTH); ai++) begin
					  for (int bi = 0; bi < (1<<WIDTH); bi++) begin
							check_case(op, ai, bi);
					  end
				 end
			end

        if (total_errors == 0)
            $display("✅ TODOS LOS TESTS PASARON. Total casos: %0d", total_tests);
        else
            $display("❌ %0d errores de %0d casos.", total_errors, total_tests);

        $finish;
    end
endmodule

