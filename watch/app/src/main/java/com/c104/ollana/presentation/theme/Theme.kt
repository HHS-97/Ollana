package com.example.ollana.presentation.theme

import androidx.compose.runtime.Composable
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Typography
import com.c104.ollana.R

// 1) Light(300), Medium(500), Bold(700) 등록
private val GmarketSans = FontFamily(
    Font(R.font.gmarketsansttf_light,  weight = FontWeight.Light),   // 300
    Font(R.font.gmarketsansttf_medium, weight = FontWeight.Medium),  // 500
    Font(R.font.gmarketsansttf_bold,   weight = FontWeight.Bold)     // 700
)

private val AppTypography = Typography(
    defaultFontFamily = GmarketSans,

    // 질문용 텍스트 (가벼운 느낌—Light 300)
    body1 = TextStyle(
        fontFamily = GmarketSans,
        fontWeight  = FontWeight.Normal,
        fontSize    = 16.sp,
        lineHeight  = 20.sp,
        letterSpacing = 0.18.sp
    ),
    body2 = TextStyle(
        fontFamily = GmarketSans,
        fontWeight  = FontWeight.Light,
        fontSize    = 14.sp,
        lineHeight  = 20.sp,
        letterSpacing = 0.18.sp
    ),

    // 버튼 텍스트 (강조할 때—Bold 700)
    button = TextStyle(
        fontFamily = GmarketSans,
        fontWeight  = FontWeight.Bold,
        fontSize    = 15.sp,
        lineHeight  = 19.sp,
        letterSpacing = 0.38.sp
    ),
    title1 = TextStyle(
        fontFamily = GmarketSans,
        fontWeight  = FontWeight.Bold
    ),
    // 나머지 스타일은 defaultFontFamily + 기본 weight/size 그대로
)

@Composable
fun OllanaTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        typography = AppTypography,
        content    = content
    )
}
