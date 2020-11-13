---
layout: page
title:  "Factorio designs"
date:   2020-11-13 16:45 +0100
tags: factorio
show_sidebar: true
draft: false
permalink: /factorio
hero_image: /assets/img/factorio-banner.png
hero_darken: true

custom_emoji:
  zwj-merge: true
  sources:
   - prefix: factorio-
     assets: assets/img/factorio
   - prefix: factorio-
     assets: assets/img/factorio/signal
   - prefix: 
     assets: assets/img/help

---

This is a separate collection of factorio designs.


<ul>
{% for post in site.factorio %}
  <li><a href="{{post.url}}">{{ post.title }}</a></li>
{% endfor %}  
</ul>

