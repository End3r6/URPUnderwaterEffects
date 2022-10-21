# URPUnderwaterEffects
An implementation of underwater effects that show under the water line.

# Demo
![Showcase Gif](https://github.com/End3r6/URPUnderwaterEffects/blob/master/GIF/Shot_02.gif)

# How to use

Download the lates release or download from the green code button.

## Make sure that your water plane has the HorizonLineDraw layer (case sensitive). Will change to layer tag selection in the near future.

In your URP render settings, click add feature and choose Horizon Line Texture and 
any of the additional effects shown. Make sure that the horizon texture pass is the first pass called. Next, enjoy pretty underwater graphics.

# Other Effects
Bubbles are included, they are a particle prefab.

# Extenstion
If you wish to add more effects on top of the existing ones, you need to sample the _HorizonLineTexture. This lets you seperate the waterline from the air above the water.

# Cotributions
If you wish to contriubute to this repo, feel free to make a pull request.
