package com.c104.ollana.presentation.screen

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.wear.compose.material.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.MaterialTheme.typography
import com.c104.ollana.R

//실시간 비교 결과를 표시하는 화면
@Composable
fun ProgressComparisonScreen(progressMessage : String){
    val isFast = progressMessage.contains("🐇")
    val isSlow = progressMessage.contains("🐢")

    val distanceInfo = progressMessage.substringAfter(" ").trim()

    Box(
        modifier=Modifier
            .fillMaxSize()
            .background(Color.Black),
        contentAlignment  = Alignment.Center
    ){
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ){
            if(isFast){
                Image(
                    painter= painterResource(id=R.drawable.rabbit2),
                    contentDescription = "토끼",
                    modifier = Modifier.size(100.dp),
                    contentScale = ContentScale.Fit
                )
            }else if(isSlow){
                Image(
                    painter = painterResource(id = R.drawable.turtle2), // 🐢 이미지
                    contentDescription = "거북이",
                    modifier = Modifier.size(100.dp),
                    contentScale = ContentScale.Fit
                )
            }
            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text=distanceInfo,
                style     = typography.title1,
                fontSize = 20.sp,
                color=Color.White,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(16.dp)
            )
        }

    }

}

