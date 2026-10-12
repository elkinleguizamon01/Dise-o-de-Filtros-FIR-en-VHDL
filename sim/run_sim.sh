#!/usr/bin/env bash
# Compila y ejecuta los testbenches con GHDL.  Uso: ./sim/run_sim.sh  (desde la raíz del repo)
set -euo pipefail
cd "$(dirname "$0")/.."
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
STD=08
ghdl -a --std=$STD --workdir="$WORK" src/gen_muestreo.vhd src/adc0808_ctrl.vhd src/fir_filter.vhd sim/tb_*.vhd
fail=0
for tb in tb_gen_muestreo tb_adc0808 tb_fir; do
  echo "▶ $tb"
  out=$(ghdl -r --std=$STD --workdir="$WORK" "$tb" --assert-level=error --stop-time=3ms 2>&1) || { echo "$out"; echo "✘ $tb FALLÓ"; fail=1; continue; }
  echo "$out" | tail -1; echo "✔ $tb OK"
done
exit $fail
