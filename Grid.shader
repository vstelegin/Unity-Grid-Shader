Shader "Chase/Grid"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
        _GridScale ("Grid Scale", Range(1, 32)) = 2
        _Width ("Width", Range(0, 0.75)) = 0.1
        _Smoothness("Smoothness", Range(0, 1)) = 0.1
        _DistanceClose ("Distance Close", Range(0,10)) = 0.4
        _DistanceFar ("Distance Far", Range(0,10)) = 3.4
        _FillColor ("Fill Color", Color) = (1, 0.0, 0.0, 1.0) 

    }
    SubShader
    {
        Tags {"Queue"="Geometry-10" "RenderType"="Transparent" }
        LOD 100
        Pass {
            ZWrite On
            ColorMask 0
            
            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag

            struct v2f {
                float4 pos : SV_POSITION;
            };
     
            v2f vert (appdata_base v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }
     
            half4 frag (v2f i) : COLOR {
                return half4 (0,0,0,0);
            }
            ENDCG  
        }
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #include "UnityCG.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                half3 normal: NORMAL;
            };

            struct v2f
            {
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 worldPos : TEXCOORD2;
                half3 worldNormal: NORMAL; 
                fixed4 color : COLOR0;
            };


            fixed _GridScale;
            fixed4 _FillColor;
            half _Width;
            half _Smoothness;
            half _DistanceClose;
            half _DistanceFar;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                half l = min(1.0, max(0.0, (length(ObjSpaceViewDir(v.vertex)) - _DistanceClose) / (_DistanceFar - _DistanceClose)));
                o.color.a = lerp(1, 0.0, l);
                return o;
            }

            half4 fracSquare (float4 input)
            {
                float4 value = frac(input);
                value *= value;
                return value;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                
                half4 col = _GridScale * i.worldPos;
                col = max (fracSquare(col), fracSquare(-col));
                fixed high1 = 1 - _Width;
                fixed low1 = high1 - _Smoothness;
                col = (col - low1) / (high1 - low1);

                col = clamp(col, 0, 1);

                fixed3 normalFade = clamp(i.worldNormal*i.worldNormal,0.0,1.0);
                col.rgb *= (1 - normalFade);
                col.a = max (max(col.r, col.g), col.b);
                col.rgb = col.a;
                //col.a = col.r + col.g + col.b;
                //col.a = 0;
                col += _FillColor;
                if (col.a * i.color.a < 0.1)
                {
                    discard; // yes: discard this fragment
                }

                return col;
            }
            ENDCG
        }
    }
}
