package com.c104.ollana.presentation.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.Text
import coil.compose.AsyncImage
import com.c104.ollana.R
import androidx.compose.ui.text.style.TextAlign

@Composable
fun DefaultHomeScreen(){
    Box(
        modifier=Modifier
            .fillMaxSize()
            .background(Color.Black),
        contentAlignment  = Alignment.Center
    ){
        Column(horizontalAlignment = Alignment.CenterHorizontally){
            // GIF 이미지 출력 (GIF도 coil에서 가능!)
            AsyncImage(
                model = R.drawable.mount    , // drawable에 gif 넣기
                contentDescription = "Ollana Logo",
                modifier = Modifier.size(150.dp)
            )

        }

    }

}