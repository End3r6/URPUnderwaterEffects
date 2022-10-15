Shader "Hidden/BlackUnder"
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
            Cull Front
            Color(0, 0, 0, 0)
        }
    }
}