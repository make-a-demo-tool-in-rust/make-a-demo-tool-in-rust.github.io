---
title: 1.5 ASCII fish example
---

# 1.5 ASCII fish example

![fish in a jit](/images/fish-jit.gif)

This is the [examples/fish-jit.rs][example] example using our custom little JIT lib.

[example]: https://github.com/make-a-demo-tool-in-rust/make-a-demo-tool-in-rust-code/1-fish-in-a-jit/examples/fish-jit.rs

1. This takes the `YAML` file below,
2. deserializes it into a `Dmo` struct,
3. allocates the JIT memory and fills it with instructions,
4. starts a `while` loop
5. calls the JIT function at every iteration
6. sleeps a bit and increments time.

~~~ yaml
# examples/fish-demo.yml

operators:
  - Clear: 32
  - Draw: [ 3, 0, 0.3 ]
  - Draw: [ 1, 5, 8.0 ]
  - Draw: [ 0, 2, 1.5 ]
  - Draw: [ 1, 30, 4.0 ]
  - Draw: [ 2, 15, 6.0 ]
  - Print
  - Exit: 30.0

context:
  sprites:
    - " ><(([°> "
    - " ><> "
    - " }-<ø> "
    - "¸¸,,¸¸,¸¸,,¸¸,¸¸,,¸¸,¸¸,,¸¸,¸¸,,¸¸,¸¸,,¸¸,¸¸,,¸¸,,"
~~~

Clone, compile and run:

~~~
git clone https://github.com/make-a-demo-tool-in-rust/make-a-demo-tool-in-rust-code
cd make-a-demo-tool-in-rust-code
cd 1-fish-in-a-jit
cargo run --example fish-jit
~~~

**NOTE:** only Linux x86_64 at the moment. Windows and Mac x86_64 happening later.
