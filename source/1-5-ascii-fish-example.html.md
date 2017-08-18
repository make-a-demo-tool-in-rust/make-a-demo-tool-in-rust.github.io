---
title: 1.5 ASCII fish example
---

# 1.5 ASCII fish example

![fish in a jit](/images/fish-jit.gif)

This is the [examples/fish-jit.rs][example] example using our custom little JIT lib.

[example]: https://github.com/make-a-demo-tool-in-rust/fish-in-a-jit/blob/master/examples/fish-jit.rs

1. Take the `YAML` file below,
2. deserialize it into a `Dmo` struct,
3. from that, build the JIT function for drawing (printing)
4. start a `while` loop
5. call the JIT function at every iteration
6. sleep a bit and increment time.

~~~ rust
// examples/fish-jit.rs

pub fn main() {
    // Read in at runtime, include path is relative to current directory, which
    // is the crate root if running this example with "cargo run --example fish-jit".
    let text = file_to_string(&PathBuf::from("./examples/fish-demo.yml")).unwrap();
    let d = Dmo::new_from_yml_str(&text).unwrap();
    let bytecode = d.to_bytecode();

    // Write the bytecode blob while we are at it, for the standalone example to
    // use with include_bytes!()
    d.write_to_blob(&PathBuf::from("./examples/fish-demo.dmo")).unwrap();

    // A Dmo from the bytecode directly, for testing that.
    let mut dmo = Dmo::from_bytecode(bytecode);
    dmo.build_jit_fn();

    print!("\n");

    while dmo.get_is_running() {
        dmo.run_jit_fn();
        sleep(Duration::from_millis(10));
        dmo.add_to_time(0.01);
    }

    print!("\n");
}
~~~

And the YAML:

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
git clone https://github.com/make-a-demo-tool-in-rust/fish-in-a-jit
cd fish-in-a-jit
cargo run --example fish-jit
~~~

