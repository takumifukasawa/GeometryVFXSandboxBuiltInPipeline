Shader "Custom/VoxelPhongLit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _PointLightPosition ("Point Light Position", Vector) = (1, 1, 1, 1)
        _PointLightPower ("Point Light Power", Range(0, 128)) = 10
        _PointLightAttenuation ("Point Light Attenuation", Range(0, 10)) = 1
        _DiffuseColor ("Diffuse Color", Color) = (1, 1, 1, 1)
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _SpecularPower ("Specular Power", Range(0, 128)) = 32
        _AmbientColor ("Ambient Color", Color) = (1, 1, 1, 1)
        _VoxelSize ("Voxel Size", Range(0, 0.1)) = 0.01
        _MovementAmplify ("Movement Amplify", Range(0, 1)) = 0.1
        _MovementSeed ("Movement Seed", Range(0, 100)) = 10
        _MovementSpeed ("Movement Speed", Range(0, 500)) = 10
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float3 _PointLightPosition;
            float _PointLightAttenuation;
            float _PointLightPower;
            half3 _DiffuseColor;
            half3 _SpecularColor;
            float _SpecularPower;
            half3 _AmbientColor;
            float _MovementAmplify;
            float _MovementSpeed;
            float _MovementSeed;
            float _VoxelSize;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct g2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 worldPosition : TEXCOORDS1;
                float3 normal : TEXCOORD2;
            };

            struct VertexAttributes
            {
                float4 vertex;
                float4 worldPosition;
                float2 uv;
                float3 normal;
            };

            float saturate(float x) {
                return clamp(0, 1, x);
            }

            float3 calcNormal(float3 v0, float3 v1, float3 v2) {
                return normalize(cross(v1 - v0, v2 - v0));
            }

            // world
            float4 GetVoxelPosition(float4 vertex, float size, int offsetIndex) {
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

                float3 offset = offsets[offsetIndex];

                return vertex + float4(offset.x, offset.y, offset.z, vertex.w) * size;
            }

            // VertexAttributes CreateVoxelVertex(float4 vertex, float size, int offsetIndex, int uvIndex, float3 v1, float3 v2) {
            VertexAttributes CreateVoxelVertex(float4 wp, float3 wn, int uvIndex) {
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

                VertexAttributes o;

                o.vertex = UnityWorldToClipPos(wp);
                o.worldPosition = wp;
                o.uv = uvs[uvIndex];
                o.normal = wn;

                return o;
            }

            appdata vert (appdata v)
            {
                v.vertex = mul(unity_ObjectToWorld, v.vertex);
                return v;
            }

            g2f PackVertex(VertexAttributes input) {
                g2f o;
                o.vertex = input.vertex;
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.uv = TRANSFORM_TEX(input.uv, _MainTex);
                o.worldPosition = input.worldPosition;
                o.normal = input.normal;
                return o;
            }

            [maxvertexcount(24)]
            void geom (triangle appdata inputs[3], uint id : SV_PrimitiveID, inout TriangleStream<g2f> outStream) {
                float4 centerLocalVertex = (inputs[0].vertex + inputs[1].vertex + inputs[2].vertex) / 3;
                float3 centerLocalNormal = (inputs[0].normal + inputs[1].normal + inputs[2].normal) / 3;
                float4 offset = float4(centerLocalNormal * sin(id * _MovementSeed + _Time.x * _MovementSpeed) * _MovementAmplify, 1);

                float4 wp0 = GetVoxelPosition(centerLocalVertex + offset, _VoxelSize, 0);
                float4 wp1 = GetVoxelPosition(centerLocalVertex + offset, _VoxelSize, 1);
                float4 wp2 = GetVoxelPosition(centerLocalVertex + offset, _VoxelSize, 2);
                float4 wp3 = GetVoxelPosition(centerLocalVertex + offset, _VoxelSize, 3);
                float4 wp4 = GetVoxelPosition(centerLocalVertex + offset, _VoxelSize, 4);
                float4 wp5 = GetVoxelPosition(centerLocalVertex + offset, _VoxelSize, 5);
                float4 wp6 = GetVoxelPosition(centerLocalVertex + offset, _VoxelSize, 6);
                float4 wp7 = GetVoxelPosition(centerLocalVertex + offset, _VoxelSize, 7);

                // front

                float3 nFront = calcNormal(wp0.xyz, wp1.xyz, wp2.xyz);
                outStream.Append(PackVertex(CreateVoxelVertex(wp0, nFront, 0)));
                outStream.Append(PackVertex(CreateVoxelVertex(wp1, nFront, 1)));
                outStream.Append(PackVertex(CreateVoxelVertex(wp2, nFront, 2)));
                outStream.Append(PackVertex(CreateVoxelVertex(wp3, nFront, 3)));
                outStream.RestartStrip();

                // left

                float3 nLeft = calcNormal(wp4.xyz, wp5.xyz, wp0.xyz);
                outStream.Append(PackVertex(CreateVoxelVertex(wp4, nLeft, 0)));
                outStream.Append(PackVertex(CreateVoxelVertex(wp5, nLeft, 1)));
                outStream.Append(PackVertex(CreateVoxelVertex(wp0, nLeft, 2)));
                outStream.Append(PackVertex(CreateVoxelVertex(wp1, nLeft, 3)));
                outStream.RestartStrip();

                // back

                float3 nBack = nFront * -1;
                outStream.Append(PackVertex(CreateVoxelVertex(wp6, nBack, 0)));
                outStream.Append(PackVertex(CreateVoxelVertex(wp7, nBack, 1)));
                outStream.Append(PackVertex(CreateVoxelVertex(wp4, nBack, 2)));
                outStream.Append(PackVertex(CreateVoxelVertex(wp5, nBack, 3)));
                outStream.RestartStrip();

                // right

                float3 nRight = nLeft * -1;
                outStream.Append(PackVertex(CreateVoxelVertex(wp2, nRight, 0)));
                outStream.Append(PackVertex(CreateVoxelVertex(wp3, nRight, 1)));
                outStream.Append(PackVertex(CreateVoxelVertex(wp6, nRight, 2)));
                outStream.Append(PackVertex(CreateVoxelVertex(wp7, nRight, 3)));
                outStream.RestartStrip();

                // top

                float3 nTop = calcNormal(wp1.xyz, wp5.xyz, wp3.xyz);
                outStream.Append(PackVertex(CreateVoxelVertex(wp1, nTop, 0)));
                outStream.Append(PackVertex(CreateVoxelVertex(wp5, nTop, 1)));
                outStream.Append(PackVertex(CreateVoxelVertex(wp3, nTop, 2)));
                outStream.Append(PackVertex(CreateVoxelVertex(wp7, nTop, 3)));
                outStream.RestartStrip();

                // bottom

                float3 nBottom = calcNormal(wp2.xyz, wp6.xyz, wp0.xyz);
                outStream.Append(PackVertex(CreateVoxelVertex(wp2, nBottom, 0)));
                outStream.Append(PackVertex(CreateVoxelVertex(wp6, nBottom, 1)));
                outStream.Append(PackVertex(CreateVoxelVertex(wp0, nBottom, 2)));
                outStream.Append(PackVertex(CreateVoxelVertex(wp4, nBottom, 3)));
                outStream.RestartStrip();
            }

            fixed4 frag (g2f i) : SV_Target
            {
                fixed4 col = fixed4(0, 0, 0, 1);

                fixed4 baseTexture = tex2D(_MainTex, i.uv);

                float3 lightDir = normalize(_PointLightPosition.xyz - i.worldPosition.xyz);
                float lightPower = _PointLightPower;
                float3 surfaceToCameraDir = normalize(_WorldSpaceCameraPos - i.worldPosition.xyz);
                float3 halfV = normalize((lightDir + surfaceToCameraDir) * 0.5);
                float distanceToLight = length(_PointLightPosition.xyz - i.worldPosition.xyz);

                float attenuation = 1 / (1 + _PointLightAttenuation * pow(distanceToLight, 2));

                float diffuse = saturate(dot(lightDir, i.normal));

                float3 specular = saturate(dot(halfV, i.normal));
                specular = pow(specular, _SpecularPower);

                col.xyz = (diffuse * _DiffuseColor * baseTexture + specular * _SpecularColor) * lightPower * attenuation + _AmbientColor;

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
