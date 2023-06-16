



float4 kawaseBlur(sampler2D blurTexture, float2 uv, float width, float height, float2 res)
{    
    int loopX = width / 3, loopY = height / 3;

    float4 sum = 0;
    float4 col = tex2D(blurTexture, saturate(uv));
    for(int x = 0; x < loopX; x++)
    {
        for(int y = 0; y < loopY; y++)
        {
            int sampleX = min(width - 1, max(0, x));
			int sampleY = min(height - 1, max(0, y));

            sum += tex2D(blurTexture, saturate(uv + float2(sampleX, sampleY) * res));
        }
    }
    
    float4 blurredCol = sum / (loopX * loopY);

    blurredCol = col + blurredCol;
    
    return blurredCol;
}
