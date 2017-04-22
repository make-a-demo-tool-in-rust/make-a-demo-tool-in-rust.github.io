---
title: 1. Fish in a JIT
frontpage_toc: true
frontpage_toc_idx: 1
summary: Make a small thing with a JIT function that prints oneliner animated ASCII graphics.
summary_image: "/images/fish-jit-f100.jpg"
summary_image_alt: "fish in a jit"
---

{::comment}
## Tasks

TODO recommend gameprogrammingpatterns bytecode chapter

TODO recommend other JIT examples and tutorials, see jit.org

TODO windows and Mac

## Notes

- [jit.org](~/org/notes/jit.org)
- [assembly.org](~/org/notes/assembly.org)

{:/comment}

# 1. Fish in a JIT

![fish in a jit](/images/fish-jit.gif)

## Sections

- [1.1 dmo.rs - State and content](/1-1-dmo-rs.html)
- [1.2 ops.rs - Operators](/1-2-ops-rs.html)
- [1.3 jit.rs - A hand-made function](/1-3-jit-rs.html)
- [1.4 bytecode.rs - Blob](/1-4-bytecode-rs.html)
- [1.5 ASCII fish example](/1-5-ascii-fish-example.html)

Also check out the [Assembly Tutorial](/assembly-tutorial.html) for a quick start on that.

Follow along with the code in the [1-fish-in-a-jit][code] folder.

[code]: https://github.com/make-a-demo-tool-in-rust/make-a-demo-tool-in-rust-code/1-fish-in-a-jit/

The code here will be only snippets to help the reading, this whole thing will
make more sense if you have the sources open in a text editor or another browser
window.

## The JIT function

Let's start by getting familiar with the JIT function idea.

A function is an area of memory, where the bytes are CPU instructions. To design
graphics in real-time, while it is running real-time, we ask the OS for a piece
of memory, we put bytes there in hex like `48 83 EC 08` and tell the OS to
execute whatever it finds on that memory address.

The feedback is that it either works, or segfaults.

Insane cool stuff `:D`

Not so scary though, we will be using the `x86` code for simple things -- mostly
to call Rust functions where we write the complicated stuff.

(About the above byte sequence: In assembly, if you compile `sub rsp, 8`, and
load the binary file into a disassembler, you can discover that the asm code
corresponds to `48 83 EC 08`.)

We will build a small JIT (Just-in-Time compilation) lib which plays oneliner
ASCII animation, driven by some byte-code demo data in a file.

Later we will use the same logic with OpenGL graphics, but for now we just deal
with text to avoid the amount of boilerplate code which OpenGL would require.

For now, our screen will be one line in the terminal, we print and `\r` rewind.

This is the plan:

We keep our byte-code in a file. This is a custom (we invent it) serialized data
format which represents a list of `enum` types and the values they wrap, plus
the asset-type data to use as content.

The enums represent the operations which we want to execute one after the other,
so we take the list of enums and build the JIT function in memory accordingly.

This JIT function does all the drawing (printing).

Then we start a loop and call the JIT function in every iteration.

The loop runs until we call the operation which sets a break condition, if we
remembered to put one in.

## Compile and Run

We are going to be using Rust from the **nightly** channel.

[Install Rust nighly][rustup] if you haven't, on Linux and Mac it is simply:

[rustup]: https://www.rust-lang.org/en-US/other-installers.html

~~~
curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly
~~~

Clone, compile and run the example:

~~~
git clone https://github.com/make-a-demo-tool-in-rust/make-a-demo-tool-in-rust-code
cd make-a-demo-tool-in-rust-code
cd 1-fish-in-a-jit
cargo run --example fish-jit
~~~

**NOTE:** At the moment this is **only Linux x86_64** because the JIT is arch
specific. There is no reason why it shouldn't work on Windows and Mac though, so
I want to go over this again and extend it for Windows and Mac x86_64 as well.

