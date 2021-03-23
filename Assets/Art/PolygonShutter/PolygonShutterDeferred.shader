Shader "Custom/PolygonShutterDeferred"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MorphRate ("Morph Rate", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Forward" }
        LOD 100

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct VertexAttributes
            {
                float4 vertex;
                float2 uv;
                float morphRate;
            };

            struct g2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float morphRate : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _MorphRate;
            int _PolygonCount;

            float saturate(float x) {
                return clamp(0, 1, x);
            }

            // refs: https://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
            float rand(float2 co){
                return frac(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453);
            }

            float getMorphRate(uint id) {
                // return rand(float2(id, id));
                float i = rand(float2(id, id));
                return saturate((i - 1) + _MorphRate * 2);
                // return (float)id / (float)_PolygonCount;
                // return saturate(_MorphRate - ((float)id / (float)_PolygonCount));
            }

            appdata vert (appdata v)
            {
                return v;
            }

            VertexAttributes CreateVertex(float4 v, float2 uv, float morphRate) {
                VertexAttributes o;
                o.vertex = v;
                o.uv = uv;
                o.morphRate = morphRate;
                return o;
            }

            g2f PackVertex(VertexAttributes input) {
                g2f o;
                o.vertex = UnityObjectToClipPos(input.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.uv = TRANSFORM_TEX(input.uv, _MainTex);
                o.morphRate = input.morphRate;
                return o;
            }

            [maxvertexcount(9)]
            void geom (triangle appdata inputs[3], uint id : SV_PrimitiveID, inout TriangleStream<g2f> outStream) {
                appdata i0 = inputs[0];
                appdata i1 = inputs[1];
                appdata i2 = inputs[2];

                float4 v0 = i0.vertex;
                float4 v1 = i1.vertex;
                float4 v2 = i2.vertex;

                float2 uv0 = i0.uv;
                float2 uv1 = i1.uv;
                float2 uv2 = i2.uv;

                float4 centerV = (inputs[0].vertex + inputs[1].vertex + inputs[2].vertex) / 3;
                float2 centerUv = (inputs[0].uv + inputs[1].uv + inputs[2].uv) / 3;

                float morphRate = getMorphRate(id);

                if(morphRate < 0.001) {
                    return;
                }

                if(morphRate > 0.999) {
                    outStream.Append(PackVertex(CreateVertex(v0, uv0, morphRate)));
                    outStream.Append(PackVertex(CreateVertex(v1, uv1, morphRate)));
                    outStream.Append(PackVertex(CreateVertex(v2, uv2, morphRate)));
                    outStream.RestartStrip();
                    return;
                }

                float4 vc01 = (v0 + v1) * 0.5;
                float4 vc12 = (v1 + v2) * 0.5;
                float4 vc20 = (v2 + v0) * 0.5;

                float2 uvc01 = (i0.uv + i1.uv) * 0.5;
                float2 uvc12 = (i1.uv + i2.uv) * 0.5;
                float2 uvc20 = (i2.uv + i0.uv) * 0.5;

                // polygon 0

                outStream.Append(PackVertex(CreateVertex(lerp(vc01, centerV, morphRate), lerp(uvc01, centerUv, morphRate), morphRate)));
                outStream.Append(PackVertex(CreateVertex(v0, uv0, morphRate)));
                outStream.Append(PackVertex(CreateVertex(v1, uv1, morphRate)));
                outStream.RestartStrip();

                // polygon 1

                outStream.Append(PackVertex(CreateVertex(lerp(vc12, centerV, morphRate), lerp(uvc12, centerUv, morphRate), morphRate)));
                outStream.Append(PackVertex(CreateVertex(v1, uv1, morphRate)));
                outStream.Append(PackVertex(CreateVertex(v2, uv2, morphRate)));
                outStream.RestartStrip();

                // polygon 2

                outStream.Append(PackVertex(CreateVertex(lerp(vc20, centerV, morphRate), lerp(uvc20, centerUv, morphRate), morphRate)));
                outStream.Append(PackVertex(CreateVertex(v2, uv2, morphRate)));
                outStream.Append(PackVertex(CreateVertex(v0, uv0, morphRate)));
                outStream.RestartStrip();
            }

            fixed4 frag (g2f i) : SV_Target
            {
                if(i.morphRate < .001) {
                    discard;
                }
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
