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

### `bram.v` module

The `bram.v` module infers a
4kb dual-ported RAM
as specified by the
iCE40-up5k Memory Usage Guide.
