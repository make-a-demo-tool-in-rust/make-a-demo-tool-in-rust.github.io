---
title: 1.1 dmo.rs - State and content
---

# 1.1 dmo.rs - State and content

`Dmo` holds the application state and data content we need to access when
running the code.

The `Vec<Operator>` will be used to build the JIT fn. When calling it, the JIT
fn will have access to `Context`, so this needs the data which we operate on --
text sprites, print buffer and so on.

We expect the text sprites in Unicode (more fun characters), so we use
`Vec<char>` instead of a `Vec<u8>`. A `char` is 4-bytes to represent UTF-32
encoding.

The `Context` and `Vec<Operator>` are private to make them only accessible
through API calls which should remember to rebuild the `JitFn` as well.

~~~ rust
// src/dmo.rs

pub struct Dmo {
    context: Context,
    operators: Vec<Operator>,
    jit_fn: JitFn,
}

pub struct Context {
    pub sprites: Vec<String>,
    pub buffer: Vec<char>,
    pub is_running: bool,
    pub time: f32,
}

pub enum Operator {
    /// No operation
    NOOP,
    /// Exit the main loop if time is greater than this value
    Exit(f32),
    /// Print the text buffer
    Print,
    /// Draw a sprite into the buffer: sprite idx, offset, time speed
    Draw(u8, u8, f32),
    /// Clear the text buffer with a character code, expect UTF-32 unicode
    Clear(u32),
}
~~~

The `Dmo` data could come from a GUI. Here we will just design our demo by
writing a `YAML` file and deserializing it with `serde`.

Such as this for the earlier ASCII example:

~~~ yaml
# examples/fish-demo.yml

operators:
  - Clear: 32
  - Draw: [ 3, 0, 0.3 ]
  - Draw: [ 1, 5, 8.0 ]
  - Draw: [ 0, 2, 1.5 ]
  - Draw: [ 1, 0, 4.0 ]
  - Draw: [ 2, 3, 6.0 ]
  - Print
  - Exit: 30.0

context:
  sprites:
    - " ><(([°> "
    - " ><> "
    - " }-<ø> "
    - "¸¸,,¸¸,¸¸,,¸¸,¸¸,,¸¸,¸¸,,¸¸,¸¸,,¸¸,¸¸,,¸¸,¸¸,,¸¸,,"
~~~

This directly deserializes into our `Dmo` struct.

From the `YAML` we get the `Dmo`, then we will implement a `Dmo::to_bytecode()`
which encodes it as a `Vec<u8>`.

~~~ rust
// src/dmo.rs

impl Dmo {
    pub fn new_from_yml_str(text: &str) -> Result<Dmo, Box<Error>> {
        let dmo: Dmo = try!(serde_yaml::from_str(text));
        Ok(dmo)
    }

    pub fn write_to_blob(&self, path: &PathBuf) -> Result<(), Box<Error>> {
        let mut f: File = try!(File::create(&path));
        let bytecode = self.to_bytecode();
        f.write_all(bytecode.as_slice()).unwrap();
        Ok(())
    }
}
~~~

Two steps are necessary: First, the `Dmo` has to be assigned to a variable, then
the JIT function is assembled.

After assignment, the `Context` and `Operators` have a memory address which the
JIT function will be able to use.

~~~ rust
let mut dmo = Dmo::from_bytecode(bytecode);
dmo.build_jit_fn();
~~~

The bytecode is a `Vec<u8>` which represents the whole demo and can be replayed
by a small utility. We write the bytecode to disk, but the standalone replay
doesn't even need to read files, it is enough to `include_bytes!()` at compile
time, reconstruct the `Dmo` and it's ready to go.

~~~ rust
// examples/fish-standalone.rs

pub fn main() {
    // Read in at compile time, include path is relative to the .rs file.
    let bytecode = include_bytes!("./fish-demo.dmo").to_vec();

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

