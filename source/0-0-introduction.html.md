---
title: Introduction
frontpage_toc: true
frontpage_toc_idx: 0
summary: Origins of this tutorial and the general motivation for a demo tool.
---

# Introduction

The inspiration for the tech comes from the demo tool of the [Logicoma group],
*Demotivation*. [Ferris] did excellent streams on how the tool works
([Ep.002 stream][stream-ep002] and [notes][notes-ep002]), and breaking down the
64k demo [Elysian] produced in the tool ([Ep.003 stream][stream-ep003]
and [notes][notes-ep003]).

[Logicoma group]: http://www.pouet.net/groups.php?which=12638
[Ferris]: https://github.com/yupferris
[stream-ep002]: https://www.youtube.com/watch?v=p9Obe-Xg35o
[notes-ep002]: https://github.com/yupferris/ferris-makes-demos-notes/blob/master/ep-002-demotivation.md
[Elysian]: http://www.pouet.net/prod.php?which=68375
[stream-ep003]: https://www.youtube.com/watch?v=DcsesTY6AxI
[notes-ep003]: https://github.com/yupferris/ferris-makes-demos-notes/blob/master/ep-003-elysian-breakdown.md

## Motivation for a Tool

A large number of steps are involved in producing even simple graphics:
typically you load or generate content, move a camera around while calculating
matrices and variables for the scene, render the scene to a framebuffer, use
that framebuffer as a texture for post-processing and so on.

This is organized in the CPU code, and if you know what is going to happen
already, you can design and code these steps, then compile and run.

Demoscene graphics is very inventive though, you just make it up as you go
along, and that's more fun too -- not to mention that you will probably change
between rendering pipelines from one scene to the next in the same demo.

Compiling just the see the result...

![Waiting for the build](/images/waiting-for-the-build.jpg)

(“Waiting for the build”, Juan Manuel Blanes, 1875 / 78, [classicprogrammerpaintings.com][waiting])

[waiting]: http://classicprogrammerpaintings.com/post/142841291544/waiting-for-the-build-also-known-as-scala

Instead of hard-coding the sequence of these operations, it is better to
generate some code which will produce the graphics in real-time, and tune the
code while you are looking at the result as the code is running.

Just-In-Time compilation (JIT) is one way to do this.

There is one function which we call at every frame, this does all the
drawing. This function is assembled in the memory at runtime from a custom
byte-code sequence which describes the operations to execute. This way, as soon
as we change the byte-code, the function can be re-built in the memory and at
the very next frame it can draw something completely different.
