---
title: 2.3 rocket_example - An example project
---

# 2.3 rocket_example - An example project

The code is in the [rocket_example] repo.

[rocket_example]: https://github.com/make-a-demo-tool-in-rust/rocket_example

![rocket example demo](/images/rocket-example-demo.gif)

In brief it does the following:

- open a window with a Quad (two triangles) to draw on
- compile the shaders to a program
- connect to Rocket and send the track names
- start a draw loop. In every iteration:
  - see if Rocket has data to send
  - send the shader uniform variables with values calculated by the sync lib
  - draw
  - sleep

To get this going on your machine, clone the example repo and compile. Enable
the `env_logger` messages, it can be useful.

~~~ bash
git clone https://github.com/make-a-demo-tool-in-rust/rocket_example
cd rocket_example
RUST_LOG=rocket_example,rocket_sync cargo run
~~~

At this point the Rocket editor is not running, and we are not parsing the
`tracks.rocket` in standalone, so shader variable values will be 0.

But that already shows something to see:

![rocket example start](/images/rocket-example-start.png)

After installing [Rocket], let's suppose you copied the compiled binary to
`~/lib/rocket/rocket_editor`.

[Rocket]: https://github.com/emoon/rocket

Start it, then press `Ctrl + O` to open a file. It will not show a dialog, but
waits for the input in the terminal.

~~~ bash
# current folder is ./rocket_example
# start Rocket
~/lib/rocket/rocket_editor
# press Ctrl + O in Rocket
# enter the path to open and press RET:
./data/tracks.rocket
~~~

Now the track data should be loaded. Rocket keeps a recent file list in
`.rocket-recents.txt`, so next time we only need to press `Ctrl + 1` to open the
same file.

In Rocket, the `SPC` key is play / pause, this should start the animation as
above.
