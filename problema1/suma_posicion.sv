module suma_posicion (
    input  logic A,
    input  logic B,
    input  logic Carry,
    output logic suma,
    output logic Cout
);
    assign suma = A ^ B ^ Carry;
    assign Cout = (A & B) | (A & Carry) | (B & Carry);
endmodule
