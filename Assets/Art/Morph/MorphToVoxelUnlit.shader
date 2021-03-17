Shader "Unlit/MorphToVoxelUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _VoxelSize ("Size", Range(0, 0.1)) = 0.01
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
            float _VoxelSize;
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

            VertexAttributes CreateVoxelVertex(float4 vertex, float size, int offsetIndex, int uvIndex) {
                // -------------------
                //     5 ----- 7
                //    /|      /|
                //   1 ----- 3 |
                //   | |     | |
                //   | 4 ----- 6
                //   |/      |/
                //   0 ----- 2
                // -------------------
                static float3 offsets[8] = {
                    float3(-1, -1, -1), // 0
                    float3(-1, 1, -1),  // 1
                    float3(1, -1, -1),  // 2
                    float3(1, 1, -1),   // 3
                    float3(-1, -1, 1),  // 4
                    float3(-1, 1, 1),   // 5
                    float3(1, -1, 1),   // 6
                    float3(1, 1, 1)     // 7
                };

                // -------------------
                //   1 ----- 3
                //   |       |
                //   |       |
                //   |       |
                //   0 ----- 2
                // -------------------
                static float2 uvs[4] = {
                    float2(0, 0),
                    float2(0, 1),
                    float2(1, 0),
                    float2(1, 1)
                };
            
                float3 offset = offsets[offsetIndex];

                VertexAttributes o;
                o.vertex = vertex + float4(offset.x, offset.y, offset.z, 0.) * size;
                o.uv = uvs[uvIndex];
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

                if(_MorphRate < 0.01) {
                    VertexAttributes a1;
                    VertexAttributes a2;
                    VertexAttributes a3;

                    a1.vertex = inputs[0].vertex;
                    a2.vertex = inputs[1].vertex;
                    a3.vertex = inputs[2].vertex;

                    a1.uv = inputs[0].uv;
                    a2.uv = inputs[1].uv;
                    a3.uv = inputs[2].uv;

                    outStream.Append(PackVertex(a1));
                    outStream.Append(PackVertex(a2));
                    outStream.Append(PackVertex(a3));
                    outStream.RestartStrip();

                    return;
                }

                // front

                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 0, 0)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 1, 1)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 2, 2)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 3, 3)));
                outStream.RestartStrip();

                // left

                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 4, 0)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 5, 1)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 0, 2)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 1, 3)));
                outStream.RestartStrip();

                // back

                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 6, 0)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 7, 1)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 4, 2)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 5, 3)));
                outStream.RestartStrip();

                // right

                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 2, 0)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 3, 1)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 6, 2)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 7, 3)));
                outStream.RestartStrip();

                // top

                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 1, 0)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 5, 1)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 3, 2)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 7, 3)));
                outStream.RestartStrip();

                // bottom

                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 2, 0)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 6, 1)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 0, 2)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, _VoxelSize, 4, 3)));
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
