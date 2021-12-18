---
layout: post
title:  "Markdown in &lt;details&gt;"
date:   2020-03-22 03:10 +0100
tags: blog jekyll
show_sidebar: true
hero_height: is-small

---

Today I've polished the blog a bit and found out some stuff.

I learned about the HTML5 [&lt;details&gt; tag][Details] when I searched for a simple way to make collapsible code
 (which is great for illustrative purposes, but can get in the way of the main point you want to convey).
 
But I ran into some problems; The markdown inside the `<details>` tag didn't render.

Some people suggested to add

```yaml
markdown: kramdown
kramdown:
  parse_block_html: true
```

to the `_config.yml` file **but this was _bad_**!

This is to apply a [global solution to a local problem][global-state], which is never the solution you want to try first.

I did try it, and it still made a big mess of things!

A little extra digging and I found out that you can do

~~~none
{::nomarkdown}
<details>
<summary>This is an example</summary>
{:/nomarkdown}

```python
print("example yo")
```

{::nomarkdown}
</details>
<br>
{:/nomarkdown}
~~~

which just disables the markdown processor enough to let me add the raw html needed.

And hey, here is that exact demo!

{::nomarkdown}
<details>
<summary>This is an example</summary>
{:/nomarkdown}

```python
print("example yo")
```

{::nomarkdown}
</details>
<br>
{:/nomarkdown}

Pretty neat.

[Details]: https://www.w3schools.com/tags/tag_details.asp
[global-state]: https://devblogs.microsoft.com/oldnewthing/20081211-00/?p=19873