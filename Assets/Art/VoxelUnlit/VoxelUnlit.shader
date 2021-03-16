Shader "Unlit/VoxelUnlit"
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

            struct VertexAttributes
            {
                float4 vertex;
                float2 uv;
            };

            VertexAttributes CreateVoxelVertex(float4 vertex, float2 uv, float size, int index) {
                // -------------------
                //     5 ----- 7
                //    /|      /|
                //   1 ----- 3 |
                //   | |     | |
                //   | 4 ----- 6
                //   |/      |/
                //   0 ----- 2
                // -------------------
                float3 offsets[8] = {
                    float3(-1, -1, -1),
                    float3(-1, 1, -1),
                    float3(1, -1, -1),
                    float3(1, 1, -1),
                    float3(-1, -1, 1),
                    float3(-1, 1, 1),
                    float3(1, -1, 1),
                    float3(1, 1, 1)
                };
            
                float3 offset = offsets[index];

                VertexAttributes o;
                o.vertex = vertex + float4(offset.x, offset.y, offset.z, 0.) * size;
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

            [maxvertexcount(24)]
            void geom (triangle appdata inputs[3], inout TriangleStream<g2f> outStream) {
                float4 center = (inputs[0].vertex + inputs[1].vertex + inputs[2].vertex) / 3;
                float2 uv = (inputs[0].uv + inputs[1].uv + inputs[2].uv) / 3;
  
                outStream.Append(PackVertex(CreateVoxelVertex(center, uv, _Size, 0)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, uv, _Size, 1)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, uv, _Size, 2)));
                outStream.RestartStrip();

                outStream.Append(PackVertex(CreateVoxelVertex(center, uv, _Size, 2)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, uv, _Size, 1)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, uv, _Size, 3)));
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
