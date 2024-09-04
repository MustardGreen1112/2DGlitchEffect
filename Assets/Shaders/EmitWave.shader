Shader "Custom/EmitWave"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo (RGB)", 2D) = "white" {}
    }
        SubShader
        {
            Cull Off ZWrite Off ZTest Always
            Blend One OneMinusSrcAlpha
            Tags
            {
                "RenderType" = "Transparent"
                "Queue" = "Transparent"
            }
            Pass
            {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 color: COLOR;
                float4 vertex : SV_POSITION;
            };
            sampler2D _MainTex;
            fixed4 _Color;
            float _GlobalController;
            float4 _MainTex_ST;

            v2f vert(appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.color = v.color;
                return o;
            }

            fixed4 frag(v2f i) :SV_Target{
                fixed4 tex = tex2D(_MainTex,i.uv);
                fixed4 color = i.color * tex;
                float2 center = float2(0.5, 0.5);
                float inflectionPt = 2*(1 - _GlobalController);
                //i.uv = TRANSFORM_TEX(i.uv, _MainTex);
                float x = 1.4142135623 * length(i.uv - center);
                float emit = x <= inflectionPt ? (x - inflectionPt) + 1 : -(x - inflectionPt) + 1;
                emit *= color.a;
                emit *= pow(emit, 3);
                return fixed4(color.r*emit, color.g*emit, color.b*emit, color.a*emit);
            }



            ENDCG
            }
        }
}