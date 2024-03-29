Shader "Hidden/UpperSide"
{
    Properties
    {
        _Color("Main Color", Color) = (1.0, 1.0, 1.0, 1.0)
    }

    SubShader
    {
        Pass 
        {
            Tags { "RenderType" = "Opaque" }
            Fog {Mode Off}
            Cull Back
            Color(1, 1, 1, 1)
        }
    }
}