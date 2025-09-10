# Reloj base (50 MHz nominal de la placa)
create_clock -name clk_50 -period 20.000 [get_ports {CLOCK_50}]

# El reset asíncrono no debe limitar fmax
set_false_path -from [get_ports {KEY[*]}]
