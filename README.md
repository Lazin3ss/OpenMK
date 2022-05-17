# OpenMK
OpenMK is a software framework for Ikemen GO engine, based on Mortal Kombat gameplay. This framework intends to offer a set of tools, standards, resources and solutions for making fighting games with Mortal Kombat in mind.

We're following a modular design mindset, where features will have their own place separated from others, will not conflict with each other, and even are usually carried out by different developers. For example, batteplan will exist on the motif-side (coded via LUA), MK-unique lifebar features will be coded in fight.def when possible (and extended via lua when possible, too), and stage fatalities and transitions will belong to each stage and their behavior will be handled via AttachedChars.

# Installing
To use this framework, make sure you have a clean copy of the latest version available of Ikemen GO. After that, download all the tools you find necessary for your game (or the whole repository to create a full game based on it).
