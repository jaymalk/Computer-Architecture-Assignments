# TCL commands for simulation on vivado

# Setting clock (10ns - 5ns)
add_force {/TestBench/test_clock} -radix hex {1 0ns} {0 5000ps} -repeat_every 10000ps

# Setting go command
add_force {/TestBench/go} -radix bin {0 0ns}
add_force {/TestBench/go} -radix bin {1 0ns}

# Setting step command
add_force {/TestBench/step} -radix bin {0 0ns}
add_force {/TestBench/step} -radix bin {1 0ns}

# Setting instr command
add_force {/TestBench/instr} -radix bin {0 0ns}
add_force {/TestBench/instr} -radix bin {1 0ns}

# Setting the reset command
add_force {/TestBench/reset} -radix bin {0 0ns}
add_force {/TestBench/reset} -radix bin {1 0ns}

# Complete Reset
add_force {/TestBench/step} -radix bin {0 0ns}
run 10ns
add_force {/TestBench/go} -radix bin {0 0ns}
run 10ns
add_force {/TestBench/instr} -radix bin {0 0ns}
run 10ns
add_force {/TestBench/reset} -radix bin {1 0ns}
run 10ns

# Program Select
# Enter the program no. in place
add_force {/TestBench/Program_Select} -radix bin {011 0ns}
add_force {/TestBench/reset} -radix bin {1 10ns}
run 20ns
add_force {/TestBench/reset} -radix bin {0 50ns}
run 60ns

#Run One instr
add_force {/TestBench/instr} -radix bin {1 0ns}
run 60ns
add_force {/TestBench/instr} -radix bin {0 0ns}
run 10ns

#Run One step
add_force {/TestBench/step} -radix bin {1 0ns}
run 30ns
add_force {/TestBench/step} -radix bin {0 0ns}
run 10ns