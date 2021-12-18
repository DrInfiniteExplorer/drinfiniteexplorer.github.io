---
layout: post
title:  "Github pages"
date:   2020-03-20 23:15:01 +0100
tags: blog github-pages
show_sidebar: true
hero_height: is-small

---

Ok, so [Github Pages][gh-pages] are cool. But unfortunately not as straightforward to get going as one might like.

At least not when you just want to host some files and let github do the [Jekyll][gh-jekyll]-lifting for you.
Preferably you'd just clone/fork an existing repository and BAM you'd have everything set up, ready to edit.

But _noooooo_, you need to install a lot of crap locally just in order to run a `jekyll init` command to generate some boilerplate files.
And the instructions for doing that is spread out all over the place. You need to collect them and figure out the missing crap,
 because god help you if you happen to get the wrong version of a dependency installed!

For the convenience of myself and others, I'm writing this blog post and linking a version of my own crap that is ready to be cloned.

[This][bare-jekyll] is my repo and the specific git commit you'd want to start from.
Easiest is probably to just [download a copy][bare-export] of the files and put into your own repo.

If you want to run Jekyll locally you still need to install crap.
These are the instructions I compiled through some experimentation.
I'm running Ubuntu-18.04

```bash
# Install things we need
sudo apt update
sudo apt install ruby-full make gcc build-essential zlib1g-dev

# Add configuration of where to store ruby gems into .bashrc
#  Probably better to make a local environment for just the Jekyll instance tho.
echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc
echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc
echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Install bundler tool
gem install bundler

mkdir blog
cd blog

# This is an important first step as otherwise you might end up with crappy version problems
echo "source 'https://rubygems.org'" > Gemfile
echo "gem 'github-pages'" >> Gemfile
bundle install

# --force to overwrite the existing Gemfile
bundle exec jekyll new . --force

# Open the `Gemfile`, comment out `gem "Jekyll"` and comment in `gem "github-pages"` as is instructed in the gemfile.
bundle update

```

There you have it, that's a lot to do to create a handful of boring files.

# Edit 2020-03-21

I have since yesterday abandoned letting github build the site.
It is now built with jekyll by myself. Github is just the host.
My main reason for doing it so quickly is because apparently the `github-pages`-gem disables the plugin-functionality of Jekyll.

[gh-pages]: https://pages.github.com/
[gh-jekyll]: https://help.github.com/en/github/working-with-github-pages/setting-up-a-github-pages-site-with-jekyll

[bare-jekyll]: https://github.com/DrInfiniteExplorer/drinfiniteexplorer.github.io/tree/7b9d50b3f4fc6f51042776edb96079e3985e1715
[bare-export]: https://github.com/DrInfiniteExplorer/drinfiniteexplorer.github.io/archive/7b9d50b3f4fc6f51042776edb96079e3985e1715.zip
