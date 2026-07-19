Shader "Custom/HealthbarShader"
{
    Properties
    {
        [MainColor] _FullColor("Full Color", Color) = (0, 1, 0, 1)
        [MainColor] _EmptyColor("Empty Color", Color) = (1, 0, 0, 1)
        _LowerThreshold("Lower Threshold", Range(0, 1)) = 0.2
        _UpperThreshold("Upper Threshold", Range(0, 1)) = 0.8
        _Health("Health", Range(0,1)) = 1
        _OutlineThickness("Outline Thickness", Range(0, 1)) = 0.2
        _RoundingIntensity("Rounding Intensity", Range(0, 10)) = 0
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
            float _OutlineThickness, _RoundingIntensity;

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

            // Code based off pseudo-code by Inigo Quilez
            // https://www.youtube.com/watch?v=62-pRVZuS5c
            float RectangleSDF(float2 pos, float2 halfDimensions)
            {
                return length(max(abs(pos) - halfDimensions, 0));
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
                //lerpedColor *= 1 - CubicPulse(IN.uv.y, 0.0,0.6) * 1.1; // Creates shadow
                
                // Transparency
                bool healthMask = (_Health > IN.uv.x);
                lerpedColor.xyz *= healthMask;
                lerpedColor.a = healthMask + 0.5 * !healthMask;

                // Outline
                float2 sdfUVs = float2(IN.uv.x * 8, IN.uv.y) * 2 - float2(8, 1);
                float distanceFromRect = RectangleSDF(sdfUVs, float2(8 - _OutlineThickness * _RoundingIntensity - _OutlineThickness, 1 - _OutlineThickness * _RoundingIntensity - _OutlineThickness));
                float outlineMask = (distanceFromRect - _OutlineThickness * _RoundingIntensity) <= 0.0;
                lerpedColor.xyz *= outlineMask;
                lerpedColor.a += 0.5 * !outlineMask;

                float distanceFromRounding = RectangleSDF(sdfUVs, float2(8 - _OutlineThickness * _RoundingIntensity, 1 - _OutlineThickness * _RoundingIntensity));
                float roundingMask = (distanceFromRounding - _OutlineThickness * _RoundingIntensity) <= 0.0;
                lerpedColor.a -= lerpedColor.a * !roundingMask;
                
                return lerpedColor;
                return float4(outlineMask.xxx, 1) + float4(!roundingMask.x, 0, 0, 1);
            }
            ENDHLSL
        }
    }
}
