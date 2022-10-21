# URPUnderwaterEffects
An implementation of underwater effects that show under the water line.

# How to use

Download the lates release or download from the green code button.

## Make sure that your water plane has the HorizonLineDraw layer (case sensitive).

In your URP render settings, click add feature and choose Horizon Line Texture and 
any of the additional effects shown. Make sure that the horizon texture pass is the first pass called. It should work after that.

# Extenstion
If you wish to add more effects on top of the existing ones, you need to sample the _HorizonLineTexture. This lets you seperate the waterline from the air above the water.

# Roadmap
* [x] Caustics
* [x] Distortion
* [x] Sunrays
* [x] Bubbles

# Cotributions
If you wish to contriubute to this repo, feel free to make a pull request.

# Demo
![Distortion](https://github.com/End3r6/URPUnderwaterEffects/blob/master/Screenshots/DistortionShowcase.png)
![Caustics](https://github.com/End3r6/URPUnderwaterEffects/blob/master/Screenshots/Showcase.png)
![Sunrays](https://github.com/End3r6/URPUnderwaterEffects/blob/master/Screenshots/Sunrays.png)
