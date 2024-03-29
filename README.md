<p align="center">
  <img width="200" height="200" src="https://github.com/End3r6/URPUnderwaterEffects/blob/master/UnderwaterLogo.png">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-orange">
</p>

<h1 align="center" style="bold">
  URP Underwater Effects
</h1>
<p align="center">
  An implementation of underwater effects that show under the water line. 
</p>

<h1 align="center">
  Demo
</h1>

<p align="center">
  <img src="https://github.com/End3r6/URPUnderwaterEffects/blob/master/GIF/Shot_02.gif">
  <img src="https://github.com/End3r6/URPUnderwaterEffects/blob/master/GIF/Showcase_WaterLine.gif">
</p>

<h1 align="center">
  Also
</h1>

I'd love to see what you are using this for. If you submit an issue with a couple of screenshots or something I will try to make a section devoted to cool projects using this.

<h1 align="center">
  How to use
</h1>

Download the latest release or download from the green code button. The difference is that the releases are the latest stable versions of the tool while  downloading the source gives you the most updated version which is often buggy and experimental.

All effects are render features, so add the ones you want. The Horizon Line Feature needs to be the first one called. In order for the effects to be drawn under the water, set a layer on the object that you want to be the horizon line and use that layer in the horizon pass.

Thanks to [Tom Weiland](https://github.com/tom-weiland) for ideas with the original concept. I just took it way too far lol.

# Current Effects
- Volumetric Light Rays
- Caustics
- Fog
- Refraction
- Blurred Water line
- Color Changes With the Main Light and Ambient Color.

# Note
If you have the game view resolution set too low, it is possible there might be a gap between the water and the effects. This is fixed if you just set low res off in the game view settings.

# Other Effects
Bubbles are included as a particle prefab.

# Known Issues
- The fog doesn't draw transparent objects. (I would love help on this one if you know a solution)

# Extenstion
If you wish to add more effects on top of the existing ones, you need to sample the _HorizonLineTexture. This lets you separate the waterline from the air above the water. I do this many times in the source so check there if you need help.

# Cotributions
If you wish to contribute to this repo, feel free to make a pull request.
