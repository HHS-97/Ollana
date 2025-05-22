package com.c104.ollana.presentation.screen

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.Alignment
import androidx.wear.compose.material.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color

@Composable
fun TestScreen(
    receivedMessage: String,
    onFastTestClick: () -> Unit,
    onSlowTestClick: () -> Unit,
    onReachClick: () -> Unit,
    onBadgeClick: () -> Unit
) {
    // Wear OS 전용 스크롤 가능한 컬럼
    ScalingLazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black), // 배경 어둡게
        horizontalAlignment = Alignment.CenterHorizontally,
        contentPadding = PaddingValues(vertical = 24.dp) // 상하 여백 확보
    ) {
        // 상태 메시지 표시
        item {
            Text(
                text = receivedMessage,
                fontSize = 14.sp,
                color = Color.White,
                modifier = Modifier.padding(bottom = 8.dp)
            )
        }

        // 각 테스트 버튼 항목
        item {
            Button(onClick = onFastTestClick) {
                Text("🐇 빠름 테스트", fontSize = 14.sp)
            }
        }

        item {
            Button(onClick = onSlowTestClick) {
                Text("🐢 느림 테스트", fontSize = 14.sp)
            }
        }

        item {
            Button(onClick = onReachClick) {
                Text("⛰ 정상 도착 테스트", fontSize = 14.sp)
            }
        }

        item {
            Button(onClick = onBadgeClick) {
                Text("🏅 뱃지 테스트", fontSize = 14.sp)
            }
        }
    }
}
