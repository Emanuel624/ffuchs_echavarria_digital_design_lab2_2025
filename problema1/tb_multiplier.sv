`timescale 1ns/1ps

module tb_multiplier;

  // === Parámetros ===
  localparam int N = 4;

  // Modo de verificación:
  // 0 = verificar producto completo (2N bits)
  // 1 = verificar producto truncado a N bits (como ALU N-bit)
  localparam bit CHECK_TRUNCATED_N = 0;

  // === Señales DUT ===
  logic [N-1:0]     a, b;
  logic [2*N-1:0]   product;

  // Instancia del DUT (multiplicador por suma de productos parciales)
  multiplier #(.N(N)) dut (
    .a(a),
    .b(b),
    .product(product)
  );

  // === Referencias ===
  logic [2*N-1:0] ref_full;     // 2N bits
  logic [N-1:0]   ref_trunc;    // N bits

  // Función helper para máscara N bits
  function automatic logic [N-1:0] truncN(input logic [2*N-1:0] x);
    truncN = x[N-1:0];
  endfunction

  // === Check ===
  task automatic check_case(string tag="");
    ref_full  = a * b;
    ref_trunc = truncN(ref_full);

    if (!CHECK_TRUNCATED_N) begin
      // Verificación 2N bits
      if (product !== ref_full) begin
        $error("%s MISMATCH FULL: a=%0d(%b) b=%0d(%b) | DUT=%0d(%b) REF=%0d(%b)",
               tag, a,a, b,b, product,product, ref_full,ref_full);
      end else begin
        $display("%s OK FULL: a=%0d b=%0d | %0d", tag, a, b, product);
      end
    end else begin
      // Verificación truncada N bits (como ALU N-bit)
      if (product[N-1:0] !== ref_trunc) begin
        $error("%s MISMATCH TRUNC: a=%0d(%b) b=%0d(%b) | DUT=%0d(%b) REF_N=%0d(%b)",
               tag, a,a, b,b, product[N-1:0],product[N-1:0], ref_trunc,ref_trunc);
      end else begin
        $display("%s OK TRUNC: a=%0d b=%0d | %0d (N bits)", tag, a, b, product[N-1:0]);
      end
    end
  endtask

  initial begin
    $display("=== TB MULTIPLIER N=%0d | MODE=%s ===",
              N, CHECK_TRUNCATED_N ? "TRUNC(N)" : "FULL(2N)");

    // Dirigidos clave
    a=0;   b=9;   #1; check_case("D1 ");
    a=1;   b=11;  #1; check_case("D2 ");
    a=15;  b=1;   #1; check_case("D3 ");
    a=15;  b=15;  #1; check_case("D4 ");   // 225
    a=8;   b=8;   #1; check_case("D5 ");   // 64
    a=10;  b=11;  #1; check_case("D6 ");   // 110
    a=12;  b=7;   #1; check_case("D7 ");   // 84
    a=9;   b=6;   #1; check_case("D8 ");   // 54

    // Aleatorios
    repeat (8) begin
      a = $urandom_range(0, (1<<N)-1);
      b = $urandom_range(0, (1<<N)-1);
      #1; check_case("RND");
    end

    // Barrido opcional (actívalo si quieres exhaustivo; tarda más)
    // for (int A=0; A<(1<<N); A++) begin
    //   for (int B=0; B<(1<<N); B++) begin
    //     a=A; b=B; #1; check_case("ALL");
    //   end
    // end

    $display("=== FIN TB ===");
    $finish;
  end

endmodule

