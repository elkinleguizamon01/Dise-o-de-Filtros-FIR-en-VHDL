.PHONY: sim clean
sim:
	./sim/run_sim.sh
clean:
	rm -rf quartus/db quartus/incremental_db quartus/output_files
