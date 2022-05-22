---
layout: post
title:  "Toolbars in UE4"
date:   2022-05-21 17:12 +0100
tags: ue4 notes

category: ue4

markdown:
  +extensions:
    - admonition

---

I have figured out that extending/customizing the editor toolbar in UE4 sucks.

Why does it suck?

* Limited and undocumented API for working with the toolbars
* Lots of shit is hardcoded c++ and can't be extended without recompiles.
* The straightforward method to _add_ things work, but...
* There are extension hooks that can insert things
* There are dynamic entries which insert things
* The model is convoluted and can't be controlled

### Ok, so what is the model?
-------------------------

There are

* _Menus_ - These can contain entries of sorts
* _Sections_ - A grouping within a menu
* _Entries_ - Like a button or menu-entry

A simplified model would be

```yaml
-
  name: File
  sections:
    -
      name: Saves and stuff
      entries:
        - New
        - Save
        - Load
    -
      name: Quit
      entries:
        - Restart
        - Quit
```

This is the 'source' model, which is copied and extended as it is turned into UI elements.

### Extensions and turning into UI
----------------------------------

An extension or hook can be triggered with information like `File.New` and decide to add it's own entry `File.NewFromTemplate`.

!!! Note ""
    This makes it impossible to adjust the original model to remove such extensions without removing `File.New`.

There are also dynamic sections (or entries?) which are invoked during UI-model-preparation.
I kind of understand these, since one might want to hide buttons or entries depending on the environment (available compilers, etc etc).

Though this seems like a redundant feature and system, when one could instead extend the entries themselves with callbacks to determine whether they should be visible or enabled instead. 🤔

### UE4 menu customization
--------------------------

In 4.26 it seems that an experimental menu editing feature was added. The _only_ documentation is some bloke mentioning it [in a twitter thread](https://twitter.com/milkyengineer/status/1379644279480446982?lang=en).
It works by doing a post-process of the assembled model (after dynamics, but before hooks?). It can do visibility overrides, and even reorder entries.

It can still not deal with entries added by hooks, which severly limits the usability.

The feature is incomplete, in 4.26.2 at least. There is an embryo of implementing a save to the per-project-user-settings, but it has no effect.

### Overall verdict?
--------------------

There _are_ some methods which are clearly implemented to extend the system a tiny bit for BPs and python. But what good is that when the overall toolbars can't be controlled and there is limited pixel real estate?

The effect is exacerbated by the UI design in the editor itself, as one can only choose between ridiculously large toolbar buttons, or tiny buttons without help.

You know what's an easier solution?

* Make a [dockable widget](https://docs.unrealengine.com/4.27/en-US/InteractiveExperiences/UMG/UserGuide/EditorUtilityWidgets/)
* Add buttons to it
* Dock it
* Hide the tab
* Boom! 💣💥 (haha) - Now you've got a better toolbar that is easier to work with and extend than the toolbar from Epic 😒



#### References
---------------

* Emperor of Wisdom - [ToolMenuEntryScript](https://blog-l0v0-com.translate.goog/posts/fe336621.html?_x_tr_sl=auto&_x_tr_tl=en&_x_tr_hl=en-US&_x_tr_pto=wapp)