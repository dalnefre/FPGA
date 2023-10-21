## Physical Test Bench

The project is for testing
the physical realization of a module.
Simulation cannot tell us
how many resources will be used or
how the gates will be laid out.
So we provide a test-bench "top"
and fully synthesize the design.

### `alloc.v` module

The `alloc.v` module is a
Linked-Memory Allocator.
It manages group of memory locations,
implementing a dynamic memory API.

#### Function Table

This table describes the functional effect
of different input-signal combinations.

 Input Signals       | mem read  | mem write | o_data    | o_addr    |
---------------------|-----------|-----------|-----------|-----------|
~alloc ~free ~rd ~wr |           |           |           |           |
~alloc ~free ~rd  wr |           | i_addr    |           |           |
~alloc ~free  rd ~wr |           |           |           |           |
~alloc ~free  rd  wr |           |           |           |           |
~alloc  free ~rd ~wr |           | i_addr    |           | `#?`      |
~alloc  free ~rd  wr |           |           |           |           |
~alloc  free  rd ~wr |           |           |           |           |
~alloc  free  rd  wr |           |           |           |           |
 alloc ~free ~rd ~wr |           | top/next  |           | top/next  |
 alloc ~free ~rd  wr |           |           |           |           |
 alloc ~free  rd ~wr |           |           |           |           |
 alloc ~free  rd  wr |           |           |           |           |
 alloc  free ~rd ~wr |           | i_addr    |           | i_addr    |
 alloc  free ~rd  wr |           |           |           |           |
 alloc  free  rd ~wr |           |           |           |           |
 alloc  free  rd  wr |           |           |           |           |
