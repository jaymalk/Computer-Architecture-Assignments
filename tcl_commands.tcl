# TCL commands for simulation on vivado

# Setting clock (10ns - 5ns)

# Setting go command
#add_force {/TestBench/go} -radix bin {0 0ns}
#add_force {/TestBench/go} -radix bin {1 0ns}

# Setting step command
# add_force {/TestBench/step} -radix bin {0 0ns}
# add_force {/TestBench/step} -radix bin {1 0ns}

# Setting instr command
add_force {/TestBench/instr} -radix bin {0 0ns}
add_force {/TestBench/instr} -radix bin {1 0ns}

# # Setting the reset command
# add_force {/TestBench/reset} -radix bin {0 0ns}
# add_force {/TestBench/reset} -radix bin {1 0ns}


# Program Select
# Enter the program no. in place
# add_force {/TestBench/Program_Select} -radix bin {000 0ns}
# add_force {/TestBench/reset} -radix bin {1 10ns}
# run 20ns
# add_force {/TestBench/reset} -radix bin {0 50ns}
# run 60ns

add_force {/TestBench/test_clock} -radix hex {1 0ns} {0 5000ps} -repeat_every 10000ps

# Complete Reset
add_force {/TestBench/step} -radix bin {0 0ns}
run 20ns
add_force {/TestBench/go} -radix bin {0 0ns}
run 20ns
add_force {/TestBench/instr} -radix bin {0 0ns}
run 20ns
# add_force {/TestBench/reset} -radix bin {1 0ns}
# run 10ns


#Run One instr
add_force {/TestBench/instr} -radix bin {1 0ns}
run 120ns
add_force {/TestBench/instr} -radix bin {0 0ns}
run 20ns

#Run One step
add_force {/TestBench/step} -radix bin {1 0ns}
run 60ns
add_force {/TestBench/step} -radix bin {0 0ns}
run 20ns

# For loop
for {set i 0} {$i < 15} {incr i} {
    add_force {/TestBench/instr} -radix bin {1 0ns}
    run 120ns
    add_force {/TestBench/instr} -radix bin {0 0ns}
    run 20ns
}