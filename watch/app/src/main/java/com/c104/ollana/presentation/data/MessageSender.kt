package com.c104.ollana.presentation.data

import android.content.Context
import android.util.Log
import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.DataMap
import com.google.android.gms.wearable.Wearable
import java.io.ByteArrayOutputStream
import java.io.ObjectOutputStream


//워치에서 폰 메시지 전송 함수
object MessageSender {
    private const val TAG = "MessageSender"

    // path: 메시지 종류를 구분하는 경로
    // message: 실제 보낼 메시지 내용
    // context: 현재 화면의 context (앱 연결 상태 등 사용)
    fun send(path: String, message: ByteArray, context: Context) {
        Thread {
            try {
                // 현재 연결된 기기를 가져온다
                val nodes = Tasks.await(Wearable.getNodeClient(context).connectedNodes)

                // 연결된 모든 기기에 메시지 전송
                for (node in nodes) {
                    val task = Wearable.getMessageClient(context)
                        .sendMessage(node.id, path, message)

                    // 성공했을 때
                    task.addOnSuccessListener {
                        Log.d(TAG, "메시지 전송 성공: ${node.displayName}")
                    }
                    // 실패했을 때
                    task.addOnFailureListener {
                        Log.e(TAG, "메시지 전송 실패", it)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "예외 발생", e)
            }
        }.start() // 백그라운드 스레드에서 실행 (앱 멈추지 않게 하기 위함)
    }
}