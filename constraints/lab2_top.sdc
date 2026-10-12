# Restricciones de temporizacion - DE1, reloj de 50 MHz
create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
derive_clock_uncertainty
