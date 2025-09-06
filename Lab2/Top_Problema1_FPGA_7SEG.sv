module Top_Problema1_FPGA_7SEG #(
    parameter int WIDTH = 4
)(
    input  logic        CLOCK_50,        // Reloj de placa
    input  logic [9:0]  SW,              // A=SW[4:1], B=SW[8:5]  (SW0 y SW9 libres)
    input  logic [3:0]  KEY,             // KEY[0]=LOAD (act. baja), KEY[1]=RESET (act. baja), KEY[2]=NEXT, KEY[3]=PREV
    output logic [9:0]  LEDR,            // LEDs
    output logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 // 7-seg activo-bajo
);

    // ----------------- Captura sincrónica de entradas -----------------
    logic [WIDTH-1:0] A_reg, B_reg;
    logic [3:0]       opcode_reg;

    // Sincronización simple de KEY0 (activo en bajo) para detectar flanco 1->0
    logic key0_sync, key0_sync_d;
    always_ff @(posedge CLOCK_50 or negedge KEY[1]) begin
        if (!KEY[1]) begin
            key0_sync   <= 1'b1;
            key0_sync_d <= 1'b1;
        end else begin
            key0_sync_d <= key0_sync;
            key0_sync   <= KEY[0];
        end
    end
    wire load_pulse = (key0_sync_d == 1'b1) && (key0_sync == 1'b0);

    // ---------- Selector de opcode con KEY2 (NEXT) / KEY3 (PREV) ----------
    // KEY[2] y KEY[3] activos en bajo: detectamos flanco 1->0
    logic k2_q, k2_d, k3_q, k3_d;
    always_ff @(posedge CLOCK_50 or negedge KEY[1]) begin
        if (!KEY[1]) begin
            k2_q <= 1'b1; k2_d <= 1'b1;
            k3_q <= 1'b1; k3_d <= 1'b1;
        end else begin
            k2_d <= k2_q; k2_q <= KEY[2];
            k3_d <= k3_q; k3_q <= KEY[3];
        end
    end
    wire k2_fall = (k2_d == 1'b1) && (k2_q == 1'b0); // NEXT
    wire k3_fall = (k3_d == 1'b1) && (k3_q == 1'b0); // PREV

    // Lista de opcodes válidos (0..8): 0=ADD,1=SUB,2=DIV,3=AND,4=OR,5=XOR,6=MOD,7=SHL,8=SHR
    localparam int OPC_MIN = 4'h0;
    localparam int OPC_MAX = 4'h8;

    // Avance/retroceso de opcode
    always_ff @(posedge CLOCK_50 or negedge KEY[1]) begin
        if (!KEY[1]) begin
            opcode_reg <= 4'h0; // ADD por defecto
        end else begin
            if (k2_fall) begin
                opcode_reg <= (opcode_reg == OPC_MAX) ? OPC_MIN : (opcode_reg + 4'd1);
            end else if (k3_fall) begin
                opcode_reg <= (opcode_reg == OPC_MIN) ? OPC_MAX : (opcode_reg - 4'd1);
            end
        end
    end

    // Latch A/B al presionar LOAD (KEY0)
    always_ff @(posedge CLOCK_50 or negedge KEY[1]) begin
        if (!KEY[1]) begin
            A_reg <= '0;
            B_reg <= '0;
        end else if (load_pulse) begin
            A_reg <= SW[4:1];   // A en SW1–SW4
            B_reg <= SW[8:5];   // B en SW5–SW8
        end
    end

    // ----------------- Instancia de la ALU/Calculadora -----------------
    logic [WIDTH-1:0] result_w;
    logic N_w, Z_w, C_w, V_w;

    Problema1 #(.WIDTH(WIDTH)) dut (
        .A      (A_reg),
        .B      (B_reg),
        .opcode (opcode_reg),
        .result (result_w),
        .N      (N_w),
        .Z      (Z_w),
        .C      (C_w),
        .V      (V_w)
    );

    // Registrar salidas para estabilidad visual en LEDs/7seg
    logic [WIDTH-1:0] result_r;
    logic N_r, Z_r, C_r, V_r;
    always_ff @(posedge CLOCK_50 or negedge KEY[1]) begin
        if (!KEY[1]) begin
            result_r <= '0;
            N_r <= 1'b0; Z_r <= 1'b0; C_r <= 1'b0; V_r <= 1'b0;
        end else begin
            result_r <= result_w;
            N_r <= N_w; Z_r <= Z_w; C_r <= C_w; V_r <= V_w;
        end
    end

    // ----------------- Encoder 7-seg (activo-bajo) -----------------
    function automatic logic [6:0] hex7seg_active_low(input logic [3:0] x);
        //  {g,f,e,d,c,b,a}  (1 = OFF, 0 = ON) en DE1-SoC
        case (x)
            4'h0: hex7seg_active_low = 7'b1000000;
            4'h1: hex7seg_active_low = 7'b1111001;
            4'h2: hex7seg_active_low = 7'b0100100;
            4'h3: hex7seg_active_low = 7'b0110000;
            4'h4: hex7seg_active_low = 7'b0011001;
            4'h5: hex7seg_active_low = 7'b0010010;
            4'h6: hex7seg_active_low = 7'b0000010;
            4'h7: hex7seg_active_low = 7'b1111000;
            4'h8: hex7seg_active_low = 7'b0000000;
            4'h9: hex7seg_active_low = 7'b0010000;
            4'hA: hex7seg_active_low = 7'b0001000; // A
            4'hB: hex7seg_active_low = 7'b0000011; // b
            4'hC: hex7seg_active_low = 7'b1000110; // C
            4'hD: hex7seg_active_low = 7'b0100001; // d
            4'hE: hex7seg_active_low = 7'b0000110; // E
            4'hF: hex7seg_active_low = 7'b0001110; // F
            default: hex7seg_active_low = 7'b1111111; // apagado
        endcase
    endfunction

    localparam logic [6:0] HEX_OFF = 7'b1111111;

    // ----------------- Salidas a 7-seg -----------------
    // HEX0 => RESULT (4 bits)
    // HEX3 => A_reg
    // HEX2 => B_reg
    // HEX4 => OPCODE
    // HEX1/HEX5 apagados
    always_comb begin
        HEX0 = hex7seg_active_low(result_r[3:0]);
        HEX1 = HEX_OFF;
        HEX2 = hex7seg_active_low(B_reg[3:0]);
        HEX3 = hex7seg_active_low(A_reg[3:0]);
        HEX4 = hex7seg_active_low(opcode_reg[3:0]);
        HEX5 = HEX_OFF;
    end

    // ----------------- Salidas a LEDs -----------------
    // LEDR[3:0]  = result
    // LEDR[9:6]  = {N,Z,C,V}
    // Resto apagado
    always_comb begin
        LEDR        = '0;
        LEDR[3:0]   = result_r;
        LEDR[9]     = N_r;
        LEDR[8]     = Z_r;
        LEDR[7]     = C_r;
        LEDR[6]     = V_r;
    end

endmodule
