---
title: 1. Fish in a JIT
frontpage_toc: true
frontpage_toc_idx: 1
summary: Writing a small Just-In-Time (JIT) compilation library and using it to print oneliner animated ASCII graphics.
summary_image: "/images/fish-jit-f100.jpg"
summary_image_alt: "fish in a jit"
diagram_image: "/images/fish-in-a-jit-diagram_crop.jpg"
diagram_image_alt: "fish in a jit diagram"
---

{::comment}
## Tasks

## Notes

- [jit.org](~/org/notes/jit.org)
- [assembly.org](~/org/notes/assembly.org)

{:/comment}

# 1. Fish in a JIT

![fish in a jit](/images/fish-jit.gif)

![fish in a jit diagram](/images/fish-in-a-jit-diagram_w780.jpg)

{::comment}
TODO add hand drawn diagram
{:/comment}

## Sections

- [1.1 dmo.rs - State and content](/1-1-dmo-rs.html)
- [1.2 ops.rs - Operators](/1-2-ops-rs.html)
- [1.3 JIT - A hand-made function](/1-3-jit.html)
- [1.4 bytecode.rs - Blob](/1-4-bytecode-rs.html)
- [1.5 ASCII fish example](/1-5-ascii-fish-example.html)

Also check out the [Assembly Tutorial](/assembly-tutorial.html) for a quick start on that.

Follow along with the code in the [fish-in-a-jit/src][code] folder.

[code]: https://github.com/make-a-demo-tool-in-rust/fish-in-a-jit/tree/master/src

The code here will be only snippets to help the reading, this whole thing will
make more sense if you have the sources open in a text editor or another browser
window.

Allow me to mention two excellent tutorials without which I wouldn't have gotten
anywhere:

- [A Basic Just-In-Time Compiler - Chris Wellons](http://nullprogram.com/blog/2015/03/19/)
- [Building a simple JIT in Rust - Jonathan Turner](https://www.jonathanturner.org/2015/12/building-a-simple-jit-in-rust.html)

## The JIT function

Let's start by getting familiar with the JIT function idea.

A function is an area of memory, where the bytes are CPU instructions. To design
graphics in real-time, while it is running real-time, we ask the OS for a piece
of memory, we put bytes there in hex like `48 83 EC 08` (which is `sub rsp, 8`
in asm) and tell the OS to execute whatever it finds on that memory address.

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

This requires **nightly** Rust, last time I checked `7ac979d8c 2017-08-16`
worked.

[Install Rust nighly][rustup] if you haven't, on Linux and Mac it is simply:

[rustup]: https://www.rust-lang.org/en-US/other-installers.html

~~~ bash
curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly
~~~

On Windows, find the link on the above page for **rustup-init.exe**, download,
run, and in the text dialog select the **nightly** channel to install.

At that point you are ready to clone, compile and run the code for the first
chapter:

~~~ bach
git clone https://github.com/make-a-demo-tool-in-rust/fish-in-a-jit
cd fish-in-a-jit
cargo run --example fish-jit
~~~

This is a simple enough project to compile in the future too, but if you have to
compile it on a particular Rust version:

~~~ bash
rustup install nightly-2017-08-16
rustup default nightly-2017-08-16-x86_64-unknown-linux-gnu
~~~

Then run the examples:

~~~ bash
cargo run --example fish-jit
~~~
