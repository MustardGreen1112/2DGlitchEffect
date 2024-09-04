Shader "Custom/Glitch2D"
{
	Properties
	{
		[PerRendererData]_MainTex("Texture", 2D) = "white" {}
		_ChromAberrAmountX("Chromatic aberration amount X", float) = 0
		_ChromAberrAmountY("Chromatic aberration amount Y", float) = 0
		_RightStripesAmount("Right stripes amount", float) = 1
		_RightStripesFill("Right stripes fill", range(0, 1)) = 0.7
		_LeftStripesAmount("Left stripes amount", float) = 1
		_LeftStripesFill("Left stripes fill", range(0, 1)) = 0.7
		_DisplacementAmount("Displacement amount", vector) = (0, 0, 0, 0)
		_WavyDisplFreq("Wavy displacement frequency", float) = 10
		_Speed("Speed", float) = 100
		_MaskedAmount("Masked Amount", float) = 0.2
		_MaskedFill("Masked Fill", float) = 0.3

		_Color ("Tint", Color) = (1,1,1,1)

		_StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

		_ColorMask ("Color Mask", Float) = 15

		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
	} 
		SubShader
		{
			// No culling or depth
			Cull Off 
			Lighting Off
			ZWrite Off 
			ZTest Always
			Blend SrcAlpha OneMinusSrcAlpha
			ColorMask [_ColorMask]
		Tags
		{
			"RenderType" = "Transparent"
			"Queue" = "Transparent"
			"IgnoreProjector"="True"
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}
		Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }
			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma target 2.0

				#include "UnityCG.cginc"
				#include "UnityUI.cginc"

				#pragma multi_compile_local _ UNITY_UI_CLIP_RECT
				#pragma multi_compile_local _ UNITY_UI_ALPHACLIP

				struct appdata
				{
					float4 vertex : POSITION;
					float4 color    : COLOR;
					float2 uv : TEXCOORD0;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct v2f
				{
					float2 uv : TEXCOORD0;
					float4 vertex : SV_POSITION;
					float4 worldPosition : TEXCOORD1;
					fixed4 color    : COLOR;
					UNITY_VERTEX_OUTPUT_STEREO
				};


				sampler2D _MainTex;
				float _ChromAberrAmountX;
				float _ChromAberrAmountY;
				fixed4 _DisplacementAmount;
				float _DesaturationAmount;
				float _RightStripesAmount;
				float _RightStripesFill;
				float _LeftStripesAmount;
				float _LeftStripesFill;
				float _WavyDisplFreq;
				float _Speed;
				float _Page;
				float _Page2;
				float _MaskedAmount;
				float _MaskedFill;
				float _GlobalController;

				float4 _ClipRect;
				float4 _MainTex_ST;
				fixed4 _Color;
				fixed4 _TextureSampleAdd;

				float rand(float2 co) {
					return frac(sin(dot(co ,float2(12.9898,78.233))) * 43758.5453);
				}
				v2f vert(appdata v)
				{
					v2f OUT;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

					OUT.worldPosition = v.vertex;
					OUT.vertex = UnityObjectToClipPos(v.vertex);
					OUT.uv = TRANSFORM_TEX(v.uv, _MainTex);
					OUT.color = v.color * _Color;
					
					return OUT;
				}
				fixed4 frag(v2f i) : SV_Target {

				fixed2 _ChromAberrAmount = fixed2(_ChromAberrAmountX, _ChromAberrAmountY) * _GlobalController;
				_Speed *= _GlobalController;
				//Time.
				_Page = floor((unity_DeltaTime.x * 15.0 * _Speed));
				_Page2 = floor((_Time.y * 16));

				//Stripes section
				float stripesRight = floor(i.uv.y * _RightStripesAmount);
				stripesRight = step(_RightStripesFill, rand(float2(stripesRight + _Page, stripesRight - _Page))) * _GlobalController;

				float stripesLeft = floor(i.uv.y * _LeftStripesAmount);
				stripesLeft = step(_LeftStripesFill, rand(float2(stripesLeft + _Page, stripesLeft - _Page))) * _GlobalController;
				//Stripes section

				fixed4 wavyDispl = lerp(fixed4(1,0,0,1), fixed4(0,1,0,1), (sin(i.uv.y * _WavyDisplFreq + _Time.w) + 1) / 2) * _GlobalController;

				//Displacement section
				fixed2 displUV = -(_DisplacementAmount.xy * stripesRight) + (_DisplacementAmount.xy * stripesLeft);
				displUV += (_DisplacementAmount.zw * wavyDispl.r) - (_DisplacementAmount.zw * wavyDispl.g);
				//Displacement section

				//Masked section
				float alpha = max(tex2D(_MainTex, i.uv + displUV + _ChromAberrAmount).a,
					max(tex2D(_MainTex, i.uv + displUV).a, tex2D(_MainTex, i.uv + displUV - _ChromAberrAmount).a));
				float2 masked = floor(i.uv.xy * float2(1,3) * _MaskedAmount);
				masked = step(_MaskedFill * _GlobalController, rand(float2(masked.x + 10*_Page, masked.y -3* _Page)));
				//--Flicker effect--//
					float interval = 1;
					if (_GlobalController >= 0.25) { interval = (min(1, _Page2 % 15) / _GlobalController); }
					else { interval = 12 * _GlobalController + 1; }
					masked *= interval;
				//--End Flicker Effect--//
				alpha *= masked;
				//Masked section
				
				//Chromatic aberration section
				float chromR = tex2D(_MainTex, i.uv + displUV + _ChromAberrAmount+_TextureSampleAdd).r;
				float chromG = tex2D(_MainTex, i.uv + displUV+_TextureSampleAdd).g;
				float chromB = tex2D(_MainTex, i.uv + displUV - _ChromAberrAmount+_TextureSampleAdd).b;
				fixed4 color = fixed4(chromR, chromG, chromB, alpha);

				#ifdef UNITY_UI_CLIP_RECT
                color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip (color.a - 0.001);
                #endif

				return color;
			}
			ENDCG
				}
		}
}