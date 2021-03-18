Shader "Unlit/PolygonShutterUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Size ("Size", Range(0, 0.1)) = 0.01
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

            struct g2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Size;
            float _MorphRate;

            appdata vert (appdata v)
            {
                return v;
            }

            struct VertexAttributes
            {
                float4 vertex;
                float2 uv;
            };

            VertexAttributes CreateVertex(float4 v, float2 uv) {
                VertexAttributes o;
                o.vertex = v;
                o.uv = uv;
                return o;
            }

            g2f PackVertex(VertexAttributes input) {
                g2f o;
                o.vertex = UnityObjectToClipPos(input.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.uv = TRANSFORM_TEX(input.uv, _MainTex);
                return o;
            }

            [maxvertexcount(9)]
            void geom (triangle appdata inputs[3], inout TriangleStream<g2f> outStream) {
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

                if(_MorphRate < 0.001) {
                    return;
                }

                if(_MorphRate > 0.999) {
                    VertexAttributes o0;
                    o0.vertex = v0;
                    o0.uv = uv0;
                    outStream.Append(PackVertex(o0));

                    VertexAttributes o1;
                    o1.vertex = v1;
                    o1.uv = uv1;
                    outStream.Append(PackVertex(o1));

                    VertexAttributes o2;
                    o2.vertex = v2;
                    o2.uv = uv2;
                    outStream.Append(PackVertex(o2));

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

                outStream.Append(PackVertex(CreateVertex(lerp(vc01, centerV, _MorphRate), lerp(uvc01, centerUv, _MorphRate))));
                outStream.Append(PackVertex(CreateVertex(v0, uv0)));
                outStream.Append(PackVertex(CreateVertex(v1, uv1)));
                outStream.RestartStrip();

                // polygon 1

                outStream.Append(PackVertex(CreateVertex(lerp(vc12, centerV, _MorphRate), lerp(uvc12, centerUv, _MorphRate))));
                outStream.Append(PackVertex(CreateVertex(v1, uv1)));
                outStream.Append(PackVertex(CreateVertex(v2, uv2)));
                outStream.RestartStrip();

                // polygon 2

                outStream.Append(PackVertex(CreateVertex(lerp(vc20, centerV, _MorphRate), lerp(uvc20, centerUv, _MorphRate))));
                outStream.Append(PackVertex(CreateVertex(v2, uv2)));
                outStream.Append(PackVertex(CreateVertex(v0, uv0)));
                outStream.RestartStrip();
            }

            fixed4 frag (g2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                col.rg = i.uv;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
