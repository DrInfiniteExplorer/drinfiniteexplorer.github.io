---
layout: post
title:  "HDL synthezis notes"
date:   2020-03-21 16:30 +0100
tags: hdl-synthezis vhdl
show_sidebar: true
hero_height: is-small

---

Many years ago, I thought that circuit diagrams was the only way to reason about electronics and logic.

In fact I only lived in the analog world at the time, with transistors and resistors.

Then I started studying at [LiTH][LiTH] and learned more about analog electronics, and really got introduced to digital electronics.
That shit was rad! Just connect pins of standard circuits to create advanced shit like counters and serial buffers and things that is straight up overwhelming to design as analog circuits!

Then the courses slowly transitioned into how to compose more even advanced functionality, and finally into composing those functions into simple CPU architectures!

At this point we still drew schematics for things and used this as the perspective to reason around.
Then we got introduced to [VHDL][VHDL] and things started taking off for real!
Within a few weeks we had to design and implement functioning CPU architectures on [CPLD][CPLD]s.

It wasn't a game-changer at the time.
But now it seems like the simplest thing to project the idea of what you want into [VHDL][VHDL].
Schematics and diagrams are still of help of course, but any single subcircuit is easy to express.

## For the uninitiated

[VHDL][VHDL] is one of two major [HDL][HDL] (Hardware Description Language) available, the other being [Verilog][crap].
Verilog is similar in syntax to C, while [VHDL][VHDL] is similar in syntax to [Ada][Ada].
I personally prefer the explicit and verbose syntax of [VHDL][VHDL].
Verilog to me looks like someone made an ugly hack and everybody just rolled with it.

Anyway, what the languages boil down to is to be able to say that

* We are designing a chip! (Called _Magic_)
* It has inputs `i1`, `i2`
* It has outputs `o1`
* Internall in our chips, we have two other chips A and B.
* A is a two-input AND-gate. Inputs `Ai1`, `Ai2`. Output `Ao1`.
* B is a NOT-gate. Input `Bi1`. Output `Bi2`.
* Connect `i1` to `Ai1`
* Connect `i2` to `Ai2`
* Connect `Ao1` to `Bi1`
* Connect `Bo1` to `o1`.

That's what it is in simple terms.

{::nomarkdown}
<details>

<summary>
Click here to view the corresponding VHDL
</summary>
{:/nomarkdown}

```vhdl
-- this is the entity
entity Magic is
  port ( 
    i1 : in std_logic;
    i2 : in std_logic;
    o1  : out std_logic);
end entity Magic;

-- this is the architecture
architecture RTL of Magic is
  component AND
    port ( Ai1 : in std_logic; 
           Ai2 : in std_logic; 
           Ao1 : out std_logic ); 
  end component;
  
  component NOT
    port ( Bi1 : in std_logic; 
           Bo1 : out std_logic ); 
  end component;
begin
  -- Here we say that we have a signal called `wire1`.
  signal wire1 : std_logic;
  
  -- Create an AND-gate called A, and connect input from Magic to it.
  -- Output is into the signal `wire`
  A : AND port map (
    Ai1 <= i1,
    Ai2 <= i2,
    Ao1 <= wire1
  ); 
  -- Create NOT-circuit called B.
  -- Input is the signal `wire` which is connected to the output of A
  -- Output is connected to the output of Magic
  B : NOT port map (
    Bi1 <= wire,
    Bo1 <= o1
  ); 
end architecture RTL;
```

{::nomarkdown}
</details>
<br>
{:/nomarkdown}

Now, as basic logic like AND, OR, NOT, etc is very common building blocks, we there is language support for being able to express that without expicitly declaring all internal" chips and connections they require. A functional equivalent would be 

* We are designing a chip!
* It has inputs `i1`, `i2`
* It has outputs `o1`
* Connect `NOT(AND(i1, i2))` to `o1`

This is a lot easier and a lot more concise to express than the earlier version, and thus easier to work with.

{::nomarkdown}
<details>

<summary>
Click here to view the corresponding VHDL
</summary>
{:/nomarkdown}

```vhdl
-- this is the entity
entity Magic is
  port ( 
    i1 : in std_logic;
    i2 : in std_logic;
    o1  : out std_logic);
end entity Magic;

architecture RTL of Magic is
begin
  -- This is a lot more compact and concise. You could even do `o1 <= i1 nand i2;` directly!
  o1 <= not (i1 and i2);
end architecture RTL;
```

{::nomarkdown}
</details>
<br>
{:/nomarkdown}


These are both two versions of what is called a _[netlist][Netlist]_.

A netlist is a.. list, that describes the interconnectivity network of circuits.

The process of synthesizing [VHDL][VHDL](or any [HDL][HDL]) is the process of refining the netlists into less concise versions of themselves.
After the netlist has been detailed all the way to only consist of individual AND, OR, NOT cells, it is said to be a _logic-level netlist_.
Of course, depending on the target of the synthetization there might be higher-level gates available for common functions, like adders or memories.

We perform further synthetization from _logic-level_ to _gate-level_, and during this we might map some logic to the existing adder-circuits available.

Regardless of the level where it is done, the term is _technology mapping_ when mapping a netlist to existing building blocks.
Technically mapping basic logic like AND is also _technology mapping_.

Logic networks can be transformed into multiple equivalent circuits.
Sometimes an _And-Inverter Graph_ is a good representation, where optimizations can be performed.
But it could as well be that the logic is turned into a _Loop-Up Table_ (LUT), which can be realized with MUXes or ROM.

For [FPGA][FPGA]s, technology mapping is often to rewrite logic circuits into fixed-sized LUTs.

For [CPLD][CPLD]s, it could be to turn logic into ORs of ANDs ([sum of products][SOP]).

After a gate-level netlist has been produced, it is _[placed and routed][PlaceAndRoute]_.
This corresponds to giving physical locations to the cells(placing) and making sure the right inputs/outputs can be connected (routing).
This is kind of like solving a sudoku-puzzle; position the numbers(place) and make sure the constraints are fullfilled (routing is possible).
Like in sudoku, something that is badly placed prevents you from solving the entire puzzle. If that happens, you try again until you make it.

Now there are a few common ways to synthezise to hardware

* Map to [FPGA][FPGA] / [CPLD][CPLD]. There are known grids where a unit can perform simple logic, usually with a D-style flipflop at the end, and a connectivity grid that can be configured to connect units to each other. The hardware is reconfigurable multiple times and easily aquired at a low cost.
* Map to a _Standard Cell_ architecture. Like and [FPGA][FPGA] there are units with simple logic available, but there is larger flexibility in interconnect and special functions. This is done if you want a physical chip built with your logic that you can sell / build bigger systems with. This is a rather expensive process, and once the chip has been manufactured it is impossible to change or update. But it is absolutely cheap in large numbers, and doesn't require bootstrapping.
* Map all the way to individual analog/digital electronic blocks. This is pretty hardcore, but offers some potential that is lost when you constrain yourself to be able to fit into a pre-designed grid. For example, for some circuits you might be able to drastically decrease the chip-area needed to implement a function.

[LiTH]: https://www.lith.liu.se/?l=en
[FPGA]: https://en.wikipedia.org/wiki/Field-programmable_gate_array
[CPLD]: https://en.wikipedia.org/wiki/Complex_programmable_logic_device
[SOP]: https://en.wikipedia.org/wiki/Disjunctive_normal_form
[VHDL]: https://en.wikipedia.org/wiki/VHDL
[HDL]: https://en.wikipedia.org/wiki/Hardware_description_language
[crap]: https://en.wikipedia.org/wiki/Verilog
[Ada]: https://en.wikipedia.org/wiki/Ada_(programming_language)
[Netlist]: https://en.wikipedia.org/wiki/Netlist
[PlaceAndRoute]: https://en.wikipedia.org/wiki/Place_and_route