package com.c104.ollana.presentation.screen

import androidx.compose.foundation.background
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.wear.compose.material.*
import androidx.compose.foundation.layout.*
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.MaterialTheme.typography

@Composable
fun ETADistanceViewScreen(eta : String, distance : Int ){

    val formatted = if (distance < 1000) {
        "${distance}m"
    } else {
        String.format("%.1fkm", distance.toDouble() / 1000)
    }

    Box(
        modifier =Modifier
            .fillMaxSize()
            .background(Color.Black),
        contentAlignment = Alignment.Center
    ){
        Column (horizontalAlignment = Alignment.CenterHorizontally){
            Text("⏱ 예상 도착 시간",
                style = typography.body1,
                color = Color.White
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                eta,
                style = typography.title1,
                color = Color.Cyan)

            Spacer(modifier = Modifier.height(12.dp))

            Text("🥾 남은 거리",
               style= typography.body1,
                color = Color.White
            )
            Spacer(modifier = Modifier.height(4.dp))        // 레이블↔값 간격
            Text(formatted,
              style = typography.title1,
                color = Color.Yellow)
        }
    }
}