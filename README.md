# URPUnderwaterEffects
An implementation of underwater effects that show under the water line.

# Instalation
Download the files by clicking the green Code button on the top right corner of this repo. Extract the zip file and drag the folder into your assets of your unity project.

#How to use
In your URP render settings, clikc add feature and choose both Horizon Line Texture and 
Underwater Fog. Set the Horizon Line Texture render pass event to before pos processing and set 
the Underwater Fog's render pass event to after post processing. It should work after that.

Make sure your water shader is transparent or the effect won't work.

# Extenstion
If you wish to add more effects on top of the basic fog, you need to sample the _HorizonLineTexture. This lets you put it under the waterline.

# Roadmap
* [ ] Caustics
* [ ] Distortion
* [ ] Sunrays

# Cotributions
If you wish to contriubute to this effect, feel free to make a pull request.

# Demo
![Demo](https://github.com/End3r6/URPUnderwaterEffects/blob/master/Screenshots/Showcase.png)
