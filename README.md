<p align="center">
  <img width="200" height="200" src="https://github.com/End3r6/URPUnderwaterEffects/blob/master/UnderwaterLogo.png">
</p>

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

Framework Features:

- Shared underwater rendering framework
- Custom underwater effect support
- Effect ordering system
- Shared underwater resources
- Transparent depth support
- Per-object transparent fog participation
- Volume driven workflow
- RenderGraph implementation

Also Included:

- Bubble particle prefab

---

## How To Use

See the [Set Up Guide](https://github.com/End3r6/URPUnderwaterEffects/wiki/Setup-Guide) for information about how to get started!

---

## Transparent Depth Support

Transparent objects can participate in underwater fog.

Add a `TransparentDepthSettings` component to any renderer that should contribute to the transparent depth system.

Per-object settings currently include:

- Thickness
- Opacity

The transparent depth system generates a global texture \_TransparentDepthTexture which can be sampled by custom underwater effects.
This allows objects such as:

- Glass
- Observation domes
- Force fields
- Portals
- Shields

to integrate with underwater fog and attenuation.

---

## Performance

Version 4.0 introduced a full RenderGraph rewrite and a shared underwater rendering framework.

Current features include:

- RenderGraph
- Shared rendering resources
- Shared underwater masks
- Downsampling
- Blue noise sampling
- Bilateral blurs
- Effect ordering
- Resource reuse between effects

The goal is to keep the underwater stack modular, extensible, and as inexpensive as possible while maintaining visual quality.

---

## Creating Additional Effects

The package now uses a shared underwater framework which enables easy creation of custom effects.

Go to the [wiki](https://github.com/End3r6/URPUnderwaterEffects/wiki/Creating-Custom-Effects) to learn how to make custom effects.

---

## Also

I'd love to see what you're using this for.

If you create something cool with the package, submit an issue with a few screenshots or details about the project. I'd like to eventually create a section dedicated to projects using URP Underwater Effects.

---

## Known Issues

- The transparent depth optical model is still being refined and may continue to evolve in future releases.

If you encounter issues or have suggestions, please open an issue on GitHub.

---

## Contributions

Pull requests are welcome.

If you have improvements, fixes, optimizations, or new effects you'd like to contribute, feel free to submit a PR.

---

## Thanks

Thanks to [Tom Weiland](https://github.com/tom-weiland) for ideas behind the original concept.

I just took it way too far lol.
