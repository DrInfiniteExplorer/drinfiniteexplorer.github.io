---
layout: post
title:  "Windows Container notes"
date:   2020-05-11 00:50 +0100
tags: notes
show_sidebar: true

---

Today was the day during which I was going to get going with [ghdl](https://github.com/ghdl/ghdl-yosys-plugin).

Or so I thought.

Initially I was reading up on the updates, and was going to start by running a simple example in their docker.

I haven't dealt much with docker so far; I know the concept(s) and that has been enough.

So I thought I'd read up a little on what the normal workflows are, etc.
But I got sidetracked by vaugely worded comments on the docker page about the difference between Linux and Windows docker images.

I've heard _a lot_ of people say that _Windows-based docker-images is impossible!_ but what do I find, it's been supported for 4 years already.

Linux images can be hosted with process-isolation in a Linux-VM, or be hosted more separated where each image gets its own small VM.

But what about windows images?

Apparently they are built on top of Microsoft-provided base-images which contain container-adapted DLLs(?).
 By default images built on those just soft-link to the base image, but this can be overridden as mentioned in the [Windows Container FAQ][win-container-faq] on MSDN.

After an hour of fruitless digging on Docker and various Microsoft-sites I found this [reverse-engineering post][bloke] site where some bloke summarized
 that virtualization works with _Jobs_ and _Silos_. A Job loosely corresponds to the Linux mechanism _control group_ (cgroup).
The namespacing mechanism in Linux is loosely the same as a _silo_ which can change the root namespace object in windows,
 through which filesystem, registry, and other things is accessed.

With these new search terms in hand I found book about [Windows Internals][book] with details about how to create and operate jobs and silos.

It is likely that [MSIX][MSIX] (which I stumbled over when looking for container APIs) uses these mechanisms to achieve their containerized structure.
MSIX replaces the old [AppV][appv] which did virtualization by filter drivers and similar redirection.


[win-container-faq]: https://docs.microsoft.com/en-us/virtualization/windowscontainers/about/faq
[bloke]: https://unit42.paloaltonetworks.com/what-i-learned-from-reverse-engineering-windows-containers/
[book]: https://books.google.se/books?id=y83LDgAAQBAJ&lpg=PT299&ots=kHeyLyLsgE&dq=create%20silo%20application%20win32&pg=PT310#v=onepage&q=create%20silo%20application%20win32&f=false
[MSIX]: https://docs.microsoft.com/en-us//windows/msix/overview?view=winrt-18362
[appv]: https://www.tmurgent.com/TmBlog/?p=2489