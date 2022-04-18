# RailProject

Directly inspired from [a reply I made](https://devforum.roblox.com/t/rail-grinding-system/285666/9) on how to create a rail grinding system.

This is a module for calculating the position and velocity of an object traveling across a collection of attachment pairs. On its own, this does *not* implement how to actually move an object, as there are many ways to do so and can be expanded upon very easily.

## Getting started

This project is built using VS Code in tandem with [Rojo](https://github.com/rojo-rbx/rojo) 7.0.0.

From the root directory, run this in the command line:

```powershell
rojo build default.project.json -o RailPlace.rbxlx
rojo serve default.project.json
```

Next, open `RailPlace.rbxlx` in Roblox Studio and connect Studio's Rojo plugin.

In VS Code, build `default.project.json` and serve it with `RailPlace` open in Roblox Studio.

## Building

Building `package.project.json` in the command line will return the `RailGrinder` module as a model. Given it's just one file, however, downloading `src/init.lua` is sufficient.

```powershell
rojo build package.project.json -o RailGrinder.rbxmx
```
