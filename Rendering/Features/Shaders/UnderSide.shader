Shader "Hidden/UnderSide"
{
    Properties {}

    SubShader
    {
        Pass 
        {
            Tags { "RenderType" = "Opaque" }
            Fog {Mode Off}
            Cull Front
            Color(0, 0, 0, 0)
        }
    }
}