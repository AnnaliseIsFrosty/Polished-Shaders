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
        _FlashColor("Flash Color", Color) = (1, 0, 0, 1)
        _FlashLength("Flash Length", Range(0, 1)) = 0.4
        _FlashStrength("Flash Strength", Range(0, 1)) = 0.5
        _CrackLength("Crack Length", Range(0, 1)) = 0.2
        _CrackStrength("Crack Strength", Range(0, 1)) = 0.5
        [HideInInspector] _CrackStart("Crack Start", Float) = 0
        [HideInInspector] _PreviousHealth("Previous Health", Float) = 1
        [HideInInspector] _LerpedHealth("Lerped Health", Float) = 1
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
            float4 _FlashColor;
            float _FlashLength, _FlashStrength;
            float _CrackLength, _CrackStrength, _CrackStart, _PreviousHealth, _LerpedHealth;

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
            
            // Code sourced from Inigo Quilez
            // https://iquilezles.org/articles/functions/
            float PolynomialImpulse(float falloff, float x)
            {
                return 2 * sqrt(falloff) * x / (1 + falloff * x * x);    
            }

            // Code based off pseudo-code by Inigo Quilez
            // https://www.youtube.com/watch?v=62-pRVZuS5c
            float RectangleSDF(float2 pos, float2 halfDimensions)
            {
                return length(max(abs(pos) - halfDimensions, 0));
            }

            // Code sourced from Inigo Quilez
            // https://www.shadertoy.com/view/4llXD7
            // b.x = half width
            // b.y = half height
            // r.x = roundness top-right  
            // r.y = roundness boottom-right
            // r.z = roundness top-left
            // r.w = roundness bottom-left
            float sdRoundBox( float2 p, float2 b, float4 r ) 
            {
                r.xy = (p.x>0.0)?r.xy : r.zw;
                r.x  = (p.y>0.0)?r.x  : r.y;
                float2 q = abs(p)-b+r.x;
                return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
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
                //lerpedColor *= 1 - CubicPulse(IN.uv.y, 0.0,0.6) * 0.5; // Creates shadow
                
                // Transparency
                // if (_Health != _PreviousHealth) 
                // {
                //     //_LerpedHealth = _PreviousHealth;
                //     if (abs(_LerpedHealth - _Health) >= 0.05 ) 
                //     {
                //         _LerpedHealth = clamp(lerp(_PreviousHealth, _Health, PolynomialImpulse(1, _Time.y)), _Health, _PreviousHealth);
                //     }
                // }

                if (_CrackStart > 0) 
                {
                    if (_Time.y - _CrackStart <= 1) 
                    {
                        _LerpedHealth = lerp(_PreviousHealth, _Health, PolynomialImpulse(1, frac(_Time.y - _CrackStart)));
                    }
                    else {_LerpedHealth = _Health;}
                }
                
                
                bool healthMask = (_LerpedHealth > IN.uv.x);
                lerpedColor.xyz *= healthMask;
                lerpedColor.a = clamp(healthMask + 0.5 * !healthMask, 0, 1);

                // Outline
                float2 sdfUVs = float2(IN.uv.x * 8, IN.uv.y) * 2 - float2(8, 1);
                float distanceFromRect = RectangleSDF(sdfUVs, float2(8 , 1) - _RoundingIntensity - _OutlineThickness);
                bool outlineMask = (distanceFromRect - _RoundingIntensity) <= 0.0;
                lerpedColor.xyz *= outlineMask;
                lerpedColor.a = clamp(lerpedColor.a + 0.5 * !outlineMask, 0, 1); // If a pixel is in the outline we make it opaque again

                // Clipping out the corners when rounded
                float distanceFromRounding = sdRoundBox(sdfUVs, float2(8 , 1) - _OutlineThickness, float4(_RoundingIntensity.xxxx));
                bool roundingMask = distanceFromRounding <= _OutlineThickness;
                if (_RoundingIntensity) {lerpedColor.a = clamp(lerpedColor.a - lerpedColor.a * !roundingMask, 0, 1);} // We only want the rounding to apply if rounding intensity is above 0
                
                // Flash when low health
                if (_Health <= _LowerThreshold) 
                {
                    float3 flash = lerp(lerpedColor.xyz, _FlashColor.xyz, CubicPulse(frac(_Time.y), 0.5, _FlashLength) * _FlashStrength); // Blends to flash color based off current intensity of the flash    
                    lerpedColor.xyz *= flash;
                    lerpedColor.xyz += clamp(flash.xyz, 0, 1);
                }

                // Flash when Damaged
                if (_CrackStart > 0) 
                {
                    if (_Time.y - _CrackStart < _CrackLength) 
                    {
                        float3 crack = lerp(lerpedColor.xyz, float3(1, 1, 1), CubicPulse(frac(_Time.y - _CrackStart), 0, _CrackLength) * _CrackStrength);
                        lerpedColor.xyz += crack * CubicPulse(frac(_Time.y - _CrackStart), 0, _CrackLength) * _CrackStrength; 
                    }
                }


                return lerpedColor;
                //return float4(CubicPulse(frac(_Time.y), 0.5, _FlashLength) * _FlashStrength.xxx, 1);
                // return float4(distanceFromRect.xxx, 1);
            }
            ENDHLSL
        }
    }
}
