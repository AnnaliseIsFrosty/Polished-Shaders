Shader "Custom/HealthbarShader"
{
    Properties
    {
        [MainColor] _FullColor("Full Color", Color) = (0, 1, 0, 1)
        [MainColor] _EmptyColor("Empty Color", Color) = (1, 0, 0, 1)
        _LowerThreshold("Lower Threshold", Range(0, 1)) = 0.2
        _UpperThreshold("Upper Threshold", Range(0, 1)) = 0.8
        _Health("Health", Range(0,1)) = 1
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent"}

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            float4 _FullColor, _EmptyColor;
            float _Health;
            float _UpperThreshold, _LowerThreshold;

            // Code sourced from Freya Holmer
            //https://www.youtube.com/watch?v=kfM-yu0iQBk&t=6927s
            float InverseLerp(float floor, float ceiling, float input) 
            {
                return (input - floor) / (ceiling - floor);
            }
            
            // Code sourced from Inigo Quilez
            // https://iquilezles.org/articles/functions/
            float CubicPulse(float x, float flashLocation, float flashLength) 
            {
                x = abs(x - flashLocation); // distance from current x to the flash location
                float output = x / flashLength;
                output = 1 - output * output * (3 - 2 * output);
                return output * (x <= flashLength);
            }

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END



            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                // Colour
                float range = InverseLerp(_LowerThreshold, _UpperThreshold, _Health);
                float4 lerpedColor = clamp(lerp(_EmptyColor, _FullColor, range), 0, 1);
                lerpedColor = lerp(lerpedColor, float4(lerpedColor + 0.8.xxxx), CubicPulse(IN.uv.y, 0.65, 0.25) * 0.5); // Creates highlight
                lerpedColor *= 1 - CubicPulse(IN.uv.y, 0.0,0.6) * 0.8; // Creates shadow
                
                // Transparency
                bool healthMask = (_Health > IN.uv.x);
                lerpedColor.xyz *= healthMask;
                lerpedColor.a = healthMask + 0.5 * !healthMask;

                return lerpedColor;
            }
            ENDHLSL
        }
    }
}
