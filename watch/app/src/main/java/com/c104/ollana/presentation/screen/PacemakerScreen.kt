package com.c104.ollana.presentation.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.*
import androidx.wear.compose.material.MaterialTheme.typography

@Composable
fun PacemakerScreen(level : String, message:String){

    val (color, emoji) = when (level) {
        "저강도" -> Color(0xFF81D4FA) to "🐢"
        "중강도" -> Color(0xFFFFD54F) to "🚶"
        "고강도" -> Color(0xFFE57373) to "🔥"
        else -> Color.Gray to "❓"
    }

    Box(
        modifier=Modifier
            .fillMaxSize()
            .background(Color.Black),
        contentAlignment = Alignment.Center
    ){
        Column(horizontalAlignment = Alignment.CenterHorizontally){
            Text(emoji, fontSize = 36.sp)
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "💪 현재 강도: $level",
                fontSize = 16.sp,
                style = typography.title1,
                color = color
            )
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text=message,
                style = typography.body1,
                fontSize = 14.sp,
                color = Color.White,
                modifier = Modifier.padding(horizontal = 8.dp),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
        }
    }
}