Shader "Unlit/TerrainWaveShader"
{
    Properties
    {
        _TerrainColor ("TerrainColor", Color) = (1,1,1,1)
        _WaterColor ("WaterColor", Color) = (1,1,1,1)
        _WaveColor ("WaveColor", Color) = (1,1,1,1)
        _Speed ("Speed", float) = 0.3
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            
            #pragma vertex vert
            #pragma fragment frag


            // Mesh data: vertex position, vertex normal, UVs, tangents, vertex colors
            struct VertexInput
            {
                float4 vertex : POSITION;
                float4 normal: NORMAL;
            };

            // Output of vertex shader that goes into the fragment shader
            struct VertexOutput
            {
                float4 clipSpacePos : SV_POSITION;
                float3 normal : TEXCOORD1;      // interpolator 1
                float3 localPos : TEXCOORD2;    // interpolator 2
            };

            float4 _TerrainColor;
            float4 _WaterColor;
            float4 _WaveColor;
            float _Speed;


            // Vertex Shader
            VertexOutput vert (VertexInput v)
            {

                // just passing the values through here, not really changing them
                VertexOutput o;
                o.normal = v.normal;
                o.localPos = v.vertex;
                o.clipSpacePos = UnityObjectToClipPos(v.vertex); // convert local mesh coordinate to clip space
                
                return o;
            }

            float4 frag(VertexOutput o) : SV_Target
            {
                // WAVE

                float terrainHeight = o.localPos.y;

                // Create speed offset that's slightly different for every fragment
                // by using the distance to (0,0,0)
                float offset = distance(o.localPos, float3(0,0,0)) * 0.003;
                float speed = _Speed + offset;
                
                // TimeComponent consists of two sine waves of different size
                // to create a wave that doesn't repeat itself as often.
                // Time in a sine function makes it go back and forth
                float4 timeComponent = (sin(_Time.y * 11 * speed) * 4 + sin(_Time * 9 * speed) * 4);

                // The sine of terrainHeight creates lines, the offset by the time makes them move
                float4 waveAmp = sin(terrainHeight * 64 + timeComponent);
                
                // Convert sin from (-1,1) to (0,1)
                waveAmp = (waveAmp + 1) * 0.5;    
                
                // Multiply with terrainheight to eliminate waveAmp were height is close to 0 or 1
                waveAmp *= terrainHeight;
                waveAmp *= 1-terrainHeight;
                
                // Adjust line size
                waveAmp *= 2.6;
                waveAmp = lerp(step(0.6, waveAmp), step(0.4, waveAmp), terrainHeight);
                
                // Colors
                float3 waterColor = lerp(_WaterColor, _TerrainColor, step(0.7, terrainHeight));
                float3 waterWithWaves = lerp(waterColor, _WaveColor, waveAmp);

                
                
                // LIGHTING

                float3 normal = normalize(o.normal); 
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 lightColor = _LightColor0.rgb;

                // Direct diffuse light
                float lightFalloff = max(0, dot(lightDir, normal));
                float3 directDiffuseLight = lightColor * lightFalloff;

                // Ambient light
                float3 ambientLight = float3(0.2, 0.2, 0.2);

                // Composite 
                float3 diffuseLight = ambientLight + directDiffuseLight;
                float3 finalSurfaceColor = diffuseLight * waterWithWaves;

                return float4(finalSurfaceColor, 0);
            }
            ENDCG          
        }
    }
}
