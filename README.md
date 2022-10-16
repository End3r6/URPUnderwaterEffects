# URPUnderwaterEffects
An implementation of underwater effects that show under the water line.

# Instalation
Download the files by clicking the green Code button on the top right corner of this repo. Extract the zip file and drag the folder into your assets of your unity project.

# How to use
In your URP render settings, click add feature and choose Horizon Line Texture and 
any of the additional effects shown. Set the Horizon Line Texture render pass event to before post processing and set 
the additional effect's render pass events to after post processing. It should work after that.

If you are using hlsl (urp shader code), make sure your shader has the following snippet in the pass or subshader blocks.

```hlsl
Blend SrcAlpha OneMinusSrcAlpha
LOD 300

Tags
{
  "Queue" = "Transparent" 
  "RenderType" = "Transparent" 
  "RenderPipeline" = "UniversalRenderPipeline"
}
```

If you are using shader graph, make sure your graph settings look like this:
![Shader graph settings](https://github.com/End3r6/URPUnderwaterEffects/blob/master/Screenshots/ShaderGraphSettings.png)

# Extenstion
If you wish to add more effects on top of the basic fog, you need to sample the _HorizonLineTexture. This lets you seperate the waterline from the air above the water.

# Roadmap
* [x] Caustics
* [x] Distortion
* [ ] Sunrays
* [ ] Better Waterline Transition

# Cotributions
If you wish to contriubute to this repo, feel free to make a pull request.

# Demo
![Distortion](https://github.com/End3r6/URPUnderwaterEffects/blob/master/Screenshots/DistortionShowcase.png)
![Caustics](https://github.com/End3r6/URPUnderwaterEffects/blob/master/Screenshots/Showcase.png)
