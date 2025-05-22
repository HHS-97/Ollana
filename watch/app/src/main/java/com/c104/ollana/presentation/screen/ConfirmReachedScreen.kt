package com.c104.ollana.presentation.screen


import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.MaterialTheme.typography


/**
 * 정상 도착 시 사용자에게 트래킹 종료 여부를 물어보는 UI 화면
 * MainActivity에서 trigger == "reached"일 때 이 컴포저블을 단독 표시
 */
@Composable
fun ConfirmReachedScreen(
    onStopTracking: () -> Unit // 트래킹 종료 버튼 클릭 시 실행할 콜백
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .padding(20.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {

        // 안내 메시지 텍스트
        Text(
            text = "정상 도착!\n트래킹을 종료할까요?",
            style = typography.body1,
            color = Color.White,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(bottom = 20.dp)
        )

        Spacer(modifier = Modifier.height(20.dp))

        // 종료 버튼 (적색)
        Button(
            onClick = onStopTracking,
            colors = ButtonDefaults.buttonColors(containerColor = Color.Red),
            shape = CircleShape,
            modifier = Modifier.size(width = 140.dp, height = 60.dp)
        ) {
            Text("트래킹 종료", style =typography.button,
                color = Color.White)
        }
    }
}
