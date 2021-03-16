Shader "Unlit/PointToPolygonUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Size ("Size", Range(0, 0.1)) = 0.01
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

            struct v2g
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
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

            appdata vert (appdata v)
            {
                return v;
            }

            [maxvertexcount(4)]
            void geom (triangle appdata inputs[3], inout TriangleStream<g2f> outStream) {
                float4 center = (inputs[0].vertex + inputs[1].vertex + inputs[2].vertex) / 3;
                float2 uv = (inputs[0].uv + inputs[1].uv + inputs[2].uv) / 3;

                // -------------------
                //   [1]-----[3]
                //    |\      |
                //    | \     |
                //    |  \    |
                //    |   \   |
                //    |    \  |
                //    |     \ |
                //   [0]-----[2]
                // -------------------
                float2 offsets[4] = {
                    float2(-1, -1),
                    float2(-1, 1),
                    float2(1, -1),
                    float2(1, 1)
                };
  
                [unroll]
                for(int i = 0; i < 4; i++) {
                    g2f o;
                    o.vertex = UnityObjectToClipPos(center + float4(offsets[i].x, offsets[i].y, 0., 0.) * _Size);
                    UNITY_TRANSFER_FOG(o,o.vertex);
                    o.uv = TRANSFORM_TEX(uv, _MainTex);
                    outStream.Append(o);
                }
                outStream.RestartStrip();
            }

            fixed4 frag (g2f i) : SV_Target
            {
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
