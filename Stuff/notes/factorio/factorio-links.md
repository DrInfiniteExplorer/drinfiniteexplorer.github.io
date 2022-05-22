---
layout: post
title:  "Factorio-related links"
date:   2022-03-27 23:56 +0100

category: notes

---


Factorio fuck yea!

* [Blueprint Visualizer](https://github.com/piebro/factorio-blueprint-visualizer)

* [verilog2factorio](https://github.com/redcrafter/verilog2factorio)
    This is kinda what I wanted to do long ago.
    It [generates a netlist], then [maps] to classes that implement the same logic.
    Essentially, technology mapping is done in JS after a netlist is produced.
    Stuff is connected and then BP is generated. There's also routing with annealing or matrix placement.

    Why was it that I abandoned my own attempt?
    I wanted to go the full yosys-route with doing tech mapping in yosys, then either doing P&R in python or building standard cells and layouts in factorio.
    Only to realize that VHDL/Verilog isn't a good match for factorio, as the circuit system in factorio is a lot richer than what VHDL/Verilog can do. ¯\\_(ツ)\_/¯

* Bot queues: The scheduling of tasks does at most X schedules per tick.
    However, if a thing is lacking materials right now, it can't be scheduled.
    If there are Y such failed attempts in a tick, queueing is abandoned for the tick.
    Increase these limits in the console (`/c <command>`)

    ```
    game.player.force.max_successful_attempts_per_tick_per_construction_queue = 20
    game.player.force.max_failed_attempts_per_tick_per_construction_queue = 20
    ```



[generates a netlist]: https://github.com/Redcrafter/verilog2factorio/blob/5a7e842c00137a4127eb977f39d20d740818557b/src/main.ts#L70
[maps]: https://github.com/Redcrafter/verilog2factorio/blob/e755b6ad58b82bc3c13655de31fe3c64c7b24270/src/parser.ts#L49