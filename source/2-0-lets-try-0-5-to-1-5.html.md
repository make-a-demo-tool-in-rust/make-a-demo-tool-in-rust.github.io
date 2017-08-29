---
title: 2. Let's try 0.5 to 1.5
frontpage_toc: true
frontpage_toc_idx: 2
summary: Implementing a client for the GNU Rocket Editor to control variable values over time. Doing sync-track in other words.
summary_image: "/images/rocket-example-start_crop.jpg"
summary_image_alt: "rocket example"
diagram_image: "/images/rocket-to-demo-diagram_crop.jpg"
diagram_image_alt: "rocket to demo diagram"
---

# 2. Let's try 0.5 to 1.5

![rocket example](/images/rocket-example-demo.gif)

![rocket to demo diagram](/images/rocket-to-demo-diagram_w780.jpg)

## Sections

- [2.1 rocket_client lib - Connecting to a Rocket Editor](/2-1-rocket-client-lib.html)
- [2.2 rocket_sync lib - Variable values at a given time](/2-2-rocket-sync-lib.html)
- [2.3 rocket_example - An example project](/2-3-rocket-example.html)

## Overview

To see this working, download and compile the [Rocket Editor].

It is used to edit a file format which allows scheduling how variable values
changes over time. These values then can become uniform values for shaders or
the demo can use them in other ways to animate objects.

The variable values don't come from Rocket, the editor only edits the data. The
editor tells the demo tool over `localhost:1338` what the user has changed (for
example adding a key value to a track) and the demo tool makes the same changes
in its own data structures.

The variable values are calculated by the demo (using the sync library), but the
since the sync lib implements the same interpolations, the values will
correspond to the values shown in Rocket.

The values don't come from Rocket because when the final demo executable is
running, it will be standalone, and the editor instance will not be there.
Instead, the demo loads the data (the tracks and keys) and calculates the
interpolated variable values at a given time.

[Rocket Editor]: https://github.com/emoon/rocket
