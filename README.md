# URPUnderwaterEffects
An implementation of underwater effects that show under the water line.

# Demo
![Showcase Gif](https://github.com/End3r6/URPUnderwaterEffects/blob/master/GIF/Shot_02.gif)

# How to use
Download the latest release or download from the green code button. The difference is that the releases are the latest stable versions of the tool while downloading the source gives you the most updated version which is often buggy and experimental.

All effects are render features, so just add the one you want. The Horizon Line Feature needs to be the first one called. In order for the effects to be drawn under the water, set a layer on the object that you want to be the horizon line and use that layer in the horizon pass.

# Note
If you have the game view resolution set to low, it is possible there might be a gap between the water and the effects. This is fixed if you just set low res off in the game view settings.

# Other Effects
Bubbles are included, they are a particle prefab.

# Extenstion
If you wish to add more effects on top of the existing ones, you need to sample the _HorizonLineTexture. This lets you seperate the waterline from the air above the water.

# Cotributions
If you wish to contriubute to this repo, feel free to make a pull request.
