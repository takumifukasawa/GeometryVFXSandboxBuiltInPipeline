Shader "Unlit/MorphToVoxelUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _VoxelSize ("Size", Range(0, 0.1)) = 0.01
        _MorphRate ("Morph Rate", Range(0, 1)) = 0
        [MaterialToggle] _ShowUV ("Show UV", Float) = 0
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
            float _ShowUV;

            appdata vert (appdata v)
            {
                return v;
            }

            struct VertexAttributes
            {
                float4 vertex;
                float2 uv;
            };

            VertexAttributes CreateVoxelVertex(float4 vertex, int offsetIndex, int uvIndex, float4 morphOrigin) {
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
                o.vertex = lerp(
                    morphOrigin,
                    vertex + float4(offset.x, offset.y, offset.z, 0.) * _VoxelSize,
                    _MorphRate
                );
                // o.vertex = vertex + float4(offset.x, offset.y, offset.z, 0.) * _VoxelSize * _MorphRate;
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
                appdata i0 = inputs[0];
                appdata i1 = inputs[1];
                appdata i2 = inputs[2];

                float4 center = (inputs[0].vertex + inputs[1].vertex + inputs[2].vertex) / 3;
                float2 uv = (inputs[0].uv + inputs[1].uv + inputs[2].uv) / 3;

                if(_MorphRate < 0.01) {

                    VertexAttributes a0;
                    VertexAttributes a1;
                    VertexAttributes a2;

                    a0.vertex = i0.vertex;
                    a1.vertex = i1.vertex;
                    a2.vertex = i2.vertex;
                    // a0.vertex = lerp(i0.vertex, center, _MorphRate);
                    // a1.vertex = lerp(i1.vertex, center, _MorphRate);
                    // a2.vertex = lerp(i2.vertex, center, _MorphRate);

                    a0.uv = i0.uv;
                    a1.uv = i1.uv;
                    a2.uv = i2.uv;

                    outStream.Append(PackVertex(a0));
                    outStream.Append(PackVertex(a1));
                    outStream.Append(PackVertex(a2));
                    outStream.RestartStrip();

                    return;
                }

                // front

                outStream.Append(PackVertex(CreateVoxelVertex(center, 0, 0, i0.vertex)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, 1, 1, i1.vertex)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, 2, 2, i2.vertex)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, 3, 3, i0.vertex)));
                outStream.RestartStrip();

                // left

                outStream.Append(PackVertex(CreateVoxelVertex(center, 4, 0, i0.vertex)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, 5, 1, i1.vertex)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, 0, 2, i2.vertex)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, 1, 3, i0.vertex)));
                outStream.RestartStrip();

                // back

                outStream.Append(PackVertex(CreateVoxelVertex(center, 6, 0, i0.vertex)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, 7, 1, i1.vertex)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, 4, 2, i2.vertex)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, 5, 3, i0.vertex)));
                outStream.RestartStrip();

                // right

                outStream.Append(PackVertex(CreateVoxelVertex(center,  2, 0, i0.vertex)));
                outStream.Append(PackVertex(CreateVoxelVertex(center,  3, 1, i1.vertex)));
                outStream.Append(PackVertex(CreateVoxelVertex(center,  6, 2, i2.vertex)));
                outStream.Append(PackVertex(CreateVoxelVertex(center,  7, 3, i0.vertex)));
                outStream.RestartStrip();

                // top

                outStream.Append(PackVertex(CreateVoxelVertex(center, 1, 0, i0.vertex)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, 5, 1, i1.vertex)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, 3, 2, i2.vertex)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, 7, 3, i0.vertex)));
                outStream.RestartStrip();

                // bottom

                outStream.Append(PackVertex(CreateVoxelVertex(center, 2, 0, i0.vertex)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, 6, 1, i1.vertex)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, 0, 2, i2.vertex)));
                outStream.Append(PackVertex(CreateVoxelVertex(center, 4, 3, i0.vertex)));
                outStream.RestartStrip();
            }

            fixed4 frag (g2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = lerp(
                    tex2D(_MainTex, i.uv),
                    float4(i.uv.x, i.uv.y, 1., 1.),
                    step(0.5, _ShowUV)
                );
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
