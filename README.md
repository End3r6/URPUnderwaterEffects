# URP Underwater Effects

An implementation of underwater effects that render below the water line.

This started as a simple underwater fog effect and slowly turned into a full underwater rendering framework for URP. What began as a small experiment grew into a complete collection of underwater rendering effects, and at this point I have definitely taken it way too far lol.

---

## Demo

<p align="center">
  <img src="https://github.com/End3r6/URPUnderwaterEffects/blob/master/GIF/Shot_02.gif">
  <img src="https://github.com/End3r6/URPUnderwaterEffects/blob/master/GIF/Showcase_WaterLine.gif">
</p>

---

## Features

Current Effects:

- Volumetric Sun Shafts
- Caustics
- Fog
- Refraction
- Water Line Refraction
- Color Changes Based On Main Light and Ambient Color

Also Included:

- Bubble particle prefab

---

## How To Use

Download the latest release or clone the repository.

The difference is:

- **Releases** contain the latest stable version.
- **Source** contains the latest development version which may include experimental features, unfinished work, or bugs.

### Setup

1. Add the **Underwater Effects** renderer feature to your URP Renderer Asset.
2. Create a Volume in your scene.
3. Add the underwater volume overrides you want to use.
4. Assign the water surface layer in the Water Line Mask effect.

Version 4.0.0 completely changed the workflow.

Older versions required multiple renderer features. The current version only requires a single renderer feature and all configuration is done through Volumes.

---

## Performance

A lot of work has gone into performance during the RenderGraph rewrite.

Current effects make use of:

- RenderGraph
- Shared rendering resources
- Downsampling
- Blue noise sampling
- Bilateral blurs
- Shared underwater masks

The goal is to keep the full underwater stack as inexpensive as possible while maintaining visual quality.

---

## Creating Additional Effects

The package now uses a shared underwater framework.

Effects generate and use shared resources such as:

- `_WaterLineMask`

If you want to create additional underwater effects, sample `_WaterLineMask` inside your shader to separate underwater pixels from the air above the surface.

Many of the included effects use this workflow, so the source code is a good place to start if you're looking to build your own extensions.

---

## Also

I'd love to see what you're using this for.

If you create something cool with the package, submit an issue with a few screenshots or details about the project. I'd like to eventually create a section dedicated to projects using URP Underwater Effects.

---

## Known Issues

- Fog currently does not affect transparent objects.

I am actively working on this one and it should be supported shortly.

---

## Contributions

Pull requests are welcome.

If you have improvements, fixes, optimizations, or new effects you'd like to contribute, feel free to submit a PR.

---

## Thanks

Thanks to [Tom Weiland](https://github.com/tom-weiland) for ideas behind the original concept.

I just took it way too far lol.
