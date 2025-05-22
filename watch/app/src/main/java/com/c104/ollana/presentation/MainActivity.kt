package com.c104.ollana.presentation

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.app.NotificationCompat
import androidx.wear.compose.material.MaterialTheme
import com.c104.ollana.presentation.data.MessageSender
import com.c104.ollana.presentation.screen.BadgeScreen
import com.c104.ollana.presentation.screen.ConfirmReachedScreen
import com.c104.ollana.presentation.screen.DefaultHomeScreen
import com.c104.ollana.presentation.screen.ETADistanceViewScreen
import com.c104.ollana.presentation.screen.HomeScreen
import com.c104.ollana.presentation.screen.PacemakerScreen
import com.c104.ollana.presentation.screen.ProgressComparisonScreen
import com.c104.ollana.presentation.screen.TestScreen
import com.c104.ollana.presentation.sensor.SensorCollector
import com.example.ollana.presentation.theme.OllanaTheme
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Wearable
import com.google.gson.Gson
import org.json.JSONObject
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.InvalidClassException
import java.io.ObjectInputStream
import java.io.ObjectOutputStream
import java.io.StreamCorruptedException
import java.nio.charset.StandardCharsets
import java.util.Arrays

class MainActivity : ComponentActivity(), MessageClient.OnMessageReceivedListener {

    private val TAG = "MainActivity"

    // Wear OS 메시지 전송/수신을 위한 클라이언트
    private lateinit var messageClient: MessageClient

    // 심박수/걸음수 센서를 수집하는 클래스
    private lateinit var sensorCollector: SensorCollector

    // Compose 상태 변수들 (UI 상태 저장용)
    private var messageState: MutableState<String>? = null
    private var isHomeState: MutableState<Boolean>? = null
    private var badgeUrlState: MutableState<String?>? = null
    private var showSaveDialogState: MutableState<Boolean>? = null

    private var trigger: String? = null
    private var progressMessage: String? = null

    private var eta: String = ""
    private var distance: Int = 0
    private var pacemakerInfo: Pair<String, String>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        trigger = intent.getStringExtra("trigger")
        Log.d(TAG, "📢 onCreate: trigger=$trigger")
        //런타임 권한 체크 추가
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (checkSelfPermission(android.Manifest.permission.BODY_SENSORS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                Log.w(TAG, "❌ BODY_SENSORS 권한 없음 → 요청 중")
                requestPermissions(arrayOf(android.Manifest.permission.BODY_SENSORS), 1001)
            } else {
                Log.d(TAG, "✅ BODY_SENSORS 권한 있음")
            }
        }

        // 메시지 통신 클라이언트 초기화
        messageClient = Wearable.getMessageClient(this)
        // 센서 수집 시작
        sensorCollector = SensorCollector(this)
        sensorCollector.start()

        // /PROGRESS 알림일 경우 초기 메시지 설정
        if (trigger == "progress") {
            Log.d(TAG, "progress 트리커 작용")
            val type = intent.getStringExtra("type") ?: ""
            val diff = intent.getIntExtra("difference", 0)
            val formatted = if (diff < 1000) {
                "${diff}m"
            } else {
                String.format("%.1fkm", diff.toDouble() / 1000)
            }
            progressMessage = when (type) {
                "FAST" -> "🐇 + $formatted"
                "SLOW" -> "🐢 - $formatted"
                else -> "🚶 이동 비교 결과: $formatted"
            }
            Log.d(TAG, "progressMessage :$progressMessage")

        } else if (trigger == "etaDistance") {
            Log.d(TAG, "etaDistance 트리커 작용")
            eta = intent.getStringExtra("eta") ?: "--:--"
            distance = intent.getIntExtra("distance", 0)
        } else if (trigger == "pacemaker") {
            Log.d(TAG, "pacemaker 트리커 작용")
            val level = intent.getStringExtra("level") ?: ""
            val message = intent.getStringExtra("message") ?: ""
            pacemakerInfo = Pair(level, message)
        }else if(trigger=="badge"){
            Log.d(TAG,"badge 트리커 작용")
            val badge = intent.getStringExtra("badge")
            badgeUrlState?.value = badge
        }

        renderScreen()
    }

    private fun renderScreen() {
        Log.d(TAG, "🎯 renderScreen: trigger=$trigger")

        // UI 렌더링
        setContent {
            OllanaTheme {
                val message = remember { mutableStateOf("") }
                val isHome = remember { mutableStateOf(false) }
                val badgeUrl = remember { mutableStateOf<String?>(null) }
                val showSaveDialog = remember { mutableStateOf(false) }

                // 상태 변수를 외부에서도 접근 가능하게 저장
                messageState = message
                isHomeState = isHome
                badgeUrlState = badgeUrl
                showSaveDialogState = showSaveDialog

                Box(modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black)) {

                    when (trigger) {
                        "reached" -> ConfirmReachedScreen(
                            onStopTracking = {
                                //sendStopTrackingToApp()
                                showSaveDialog.value = true
                            }
                        )

                        "progress" -> ProgressComparisonScreen(progressMessage ?: "")
                        "etaDistance" -> ETADistanceViewScreen(eta = eta, distance = distance)
                        "pacemaker" -> PacemakerScreen(
                            level = pacemakerInfo?.first ?: "",
                            message = pacemakerInfo?.second ?: ""
                        )
                        "badge" -> BadgeScreen(badgeUrl.value)
                        else -> if (isHome.value) {
                            HomeScreen(
                                receivedMessage = message.value,
                                badgeImageUrl = badgeUrl.value,
                                onStopTracking = {
                                    //앱에 트래킹 종료 및 알림 전송
                                    //sendStopTrackingToApp()
                                    showSaveDialog.value = true // 종료 시 확인 다이얼로그 표시
                                }
                            )
                        } else DefaultHomeScreen()
//                            TestScreen(
//                                receivedMessage = message.value,
//                                onFastTestClick = {
//                                    val fakeEvent = MessageEventFake(
//                                        "/watch_connectivity",
//                                        """{
//                                    "path":"/PROGRESS",
//                                     "data":"{\"type\":\"FAST\",\"difference\":300}"}""".trimIndent()
//                                    )
//                                    handleIncomingMessage(String(fakeEvent.data))
//                                    isHome.value = true
//                                },
//                                onSlowTestClick = {
//                                    val fakeEvent = MessageEventFake(
//                                        "/watch_connectivity",
//                                        """{"path":"/PROGRESS",
//                                    "data":"{\"type\":\"SLOW\",\"difference\":300}"}""".trimIndent()
//                                    )
//                                    handleIncomingMessage(String(fakeEvent.data))
//                                    isHome.value = true
//                                },
//                                onReachClick = {
//                                    val fakeEvent = MessageEventFake(
//                                        "/watch_connectivity",
//                                        """{"path":"/REACHED","data":""}"""
//                                    )
//                                    handleIncomingMessage(String(fakeEvent.data))
//                                    isHome.value = true
//                                },
//                                onBadgeClick = {
//                                    val fakeEvent = MessageEventFake(
//                                        "/watch_connectivity",
//                                        """{"path":"/PACEMAKER",
//                                  "data":"{\"level\":\"저강도\",\"message\":\"템포를 좀 더 올려도 괜찮습니다!\"}"}""".trimIndent()
//                                    )
//                                    handleIncomingMessage(String(fakeEvent.data))
//                                    isHome.value = true
//                                }
//                            )
                    }
                    // 실제 트래킹 홈 화면 or 테스트 화면 선택
//                FloatingActionButton(
//                    onClick = {
//                        sensorCollector.sendTestDataManually()
//                    },
//                    containerColor = Color(0xFF2196F3),
//                    modifier = Modifier
//                        .align(Alignment.BottomEnd)
//                        .padding(16.dp)
//                ) {
//                    Text("TEST", color = Color.White)
//                }


                    // 기록 저장 여부 다이얼로그
                    if (showSaveDialog.value) {
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .background(Color.Black),
                            contentAlignment = Alignment.Center
                        ) {
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.Center,
                                modifier = Modifier.padding(12.dp)
                            ) {
                                Text(
                                    text = "기록을 저장하시겠습니까?",
                                    style= MaterialTheme.typography.body1,
                                    color = Color.White,
                                    fontSize = 15.sp,
                                    modifier = Modifier.padding(bottom = 12.dp)
                                )

                                // 버튼 나란히 정렬
                                Row(
                                    horizontalArrangement = Arrangement.spacedBy(24.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    // ✔ 확인 버튼
                                    Button(
                                        onClick = {
                                            showSaveDialog.value = false
                                            message.value = "종료"
                                            trigger = null
                                            sendRecordDecisionToApp(true)

                                        },
                                        colors = ButtonDefaults.buttonColors(
                                            containerColor = Color(
                                                0xFF4CAF50
                                            )
                                        ),
                                        shape = CircleShape,
                                        modifier = Modifier.size(60.dp)
                                    ) {
                                        Box(
                                            modifier = Modifier.fillMaxSize(),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Text("✔",style= MaterialTheme.typography.button, fontSize = 20.sp, color = Color.White)
                                        }
                                    }

                                    // ✖ 취소 버튼
                                    Button(
                                        onClick = {
                                            showSaveDialog.value = false
                                            message.value = "종료"
                                            trigger = null
                                            sendRecordDecisionToApp(false)
                                        },
                                        colors = ButtonDefaults.buttonColors(containerColor = Color.Red),
                                        shape = CircleShape,
                                        modifier = Modifier.size(60.dp)
                                    ) {
                                        Box(
                                            modifier = Modifier.fillMaxSize(),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Text("✖", style= MaterialTheme.typography.button, fontSize = 20.sp, color = Color.White)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }


    override fun onResume() {
        super.onResume()
        messageClient.addListener(this)
        Log.d(TAG, "리스너 등록")
    }

    override fun onPause() {
        super.onPause()
        messageClient.removeListener(this)
    }

    // 워치로부터 메시지 수신
    override fun onMessageReceived(event: MessageEvent) {
        val gson = Gson()
        val path = event.path                     // event.getPath()
        val senderNode = event.sourceNodeId       // event.getSourceNodeId()
        try {
            val bais = ByteArrayInputStream(event.data)
            val ois = ObjectInputStream(bais)

            val map = ois.readObject() as HashMap<*, *>
            ois.close()

            val jsonString = gson.toJson(map)
            Log.d(TAG, "path=$path, from=$senderNode, data=$jsonString")
            handleIncomingMessage(jsonString)
        } catch (e: InvalidClassException) {
            Log.e(TAG, "직렬화 버전 불일치", e)
        } catch (e: StreamCorruptedException) {
            Log.e(TAG, "스트림 손상", e)
        } catch (e: Exception) {
            Log.e(TAG, "역직렬화 실패", e)
        }

    }

    // 시스템 진동 및 알림 호출
    private fun vibrateAndNotify(title: String, content: String, id: Int = 1) {
        val vibrator = getSystemService(VIBRATOR_SERVICE) as Vibrator
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(1000, 255))
        } else {
            vibrator.vibrate(1000)
        }

        val channelId = "ollana_alert_channel"
        val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel =
                NotificationChannel(channelId, "Ollana 알림", NotificationManager.IMPORTANCE_HIGH)
            notificationManager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(content)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(id, notification)
    }

    // 메시지 타입에 따라 처리
    private fun handleIncomingMessage(jsonStr: String) {
        try {
            val obj = JSONObject(jsonStr)
            val path = obj.optString("path", "")
            val payload = obj.optString("data", "")
            Log.d(TAG, "잘가니?${path}")
            when (path) {
                "/REACHED" -> {
                    runOnUiThread {
                        messageState?.value = "도착"
                        vibrateAndNotify("정상 도착", "트래킹 종료를 눌러 기록을 저장하세요")
                    }
                }

                "/PROGRESS" -> {

                    val data = JSONObject(payload)
                    val type = data.getString("type")
                    val diffMeters = data.getDouble("difference")
                    val formatted = if (diffMeters < 1000) {
                        "${diffMeters.toInt()}m"
                    } else {
                        String.format("%.1fkm", diffMeters / 1000)
                    }

                    val result = when (type) {
                        "FAST" -> "🐇 + $formatted"
                        "SLOW" -> "🐢 - $formatted"
                        else -> "🚶 이동 비교 결과: $formatted"
                    }
                    runOnUiThread {
                        messageState?.value = result
                        val title = if (type == "FAST") "더 빨라요" else "천천히 가고 있어요"
                        vibrateAndNotify(title, "이전 기록보다 $formatted 차이납니다.")
                    }

                }

//                "/BADGE" -> {
//                    val badgeUrl = JSONObject(payload).getString("url")
//                    runOnUiThread {
//                        messageState?.value = "종료"
//                        badgeUrlState?.value = badgeUrl
//                    }
//
//                }
                "/STOP_TRACKING_CONFIRM" -> {
                    val data = JSONObject(payload)
                    val badge = data.optString("badge", null)
                    val intent = Intent(this, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        putExtra("trigger", "badge")
                        putExtra("badge", badge)
                    }
                    startActivity(intent)
                }

                "/ETA_DISTANCE" -> {
                    val data = JSONObject(payload)
                    val etaStr = data.optString("eta", "--:--")
                    val distance = data.optInt("distance", 0)
                    val intent = Intent(this, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        putExtra("trigger", "etaDistance")
                        putExtra("eta", etaStr)
                        putExtra("distance", distance)
                    }
                    startActivity(intent)
                }

                "/PACEMAKER" -> {
                    val data = JSONObject(payload)
                    val level = data.getString("level")
                    val message = data.getString("message")
                    runOnUiThread {
                        trigger = "pacemaker"
                        pacemakerInfo = Pair(level, message)
                        renderScreen()
                    }
                }

                else -> runOnUiThread {
                    messageState?.value = "알수없는 경로: $path"
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "메시지 파싱 오류", e)
        }

    }

    // 테스트용 가짜 메시지 클래스
    class MessageEventFake(
        private val fakePath: String,
        private val dataStr: String
    ) : MessageEvent {
        override fun getSourceNodeId(): String = "testNode"
        override fun getRequestId(): Int = 0
        override fun getPath(): String = fakePath
        override fun getData(): ByteArray = dataStr.toByteArray()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        this.trigger = intent?.getStringExtra("trigger")
        Log.d(TAG, "🔥 onNewIntent: trigger=$trigger")

        if (trigger == "progress") {
            val type = intent.getStringExtra("type") ?: ""
            val diff = intent.getIntExtra("difference", 0)
            //Log.d(TAG,"이동 비교 diff=${diff}")
            val formatted = if (diff < 1000) {
                "${diff}m"
            } else {
                String.format("%.1fkm", diff.toDouble() / 1000)
            }
            progressMessage = when (type) {
                "FAST" -> "🐇 + $formatted"
                "SLOW" -> "🐢 - $formatted"
                else -> "🚶 이동 비교 결과: $formatted"
            }
            Log.d(TAG, "progressMessage : $progressMessage")
            isHomeState?.value = true
            messageState?.value = progressMessage ?: ""

        } else if (trigger == "etaDistance") {
            eta = intent.getStringExtra("eta") ?: "--:--"
            distance = intent.getIntExtra("distance", 0)
        } else if (trigger == "pacemaker") {
            val level = intent.getStringExtra("level") ?: ""
            val message = intent.getStringExtra("message") ?: ""
            pacemakerInfo = Pair(level, message)
        }else if(trigger=="badge"){
            val badge = intent.getStringExtra("badge") // <- 여기만 사용
            badgeUrlState?.value = badge
        }
        renderScreen()
    }

    //앱에 기록 저장 여부 전송
    private fun sendRecordDecisionToApp(shouldSave: Boolean) {

        val path = if (shouldSave) "/STOP_TRACKING_CONFIRM" else "/STOP_TRACKING_CANCEL"

        val recordMap = mapOf(
            "path" to path
        )
        try {
            val baos = ByteArrayOutputStream()
            val oos = ObjectOutputStream(baos)
            oos.writeObject(recordMap)
            oos.flush()
            val byteArray = baos.toByteArray()

            MessageSender.send(
                path = "/RECORD",
                message = byteArray,
                context = this
            )
            Log.d(TAG, "📤 기록 저장 여부 전송 완료: $recordMap")
        } catch (e: Exception) {
            Log.e(TAG, "❌ RECORD 메시지 직렬화 실패", e)
        }
    }

    //트래킹 종료 버튼 누를시 트래킹 종료되었다는 데이터 앱에게 전송
//    private fun sendStopTrackingToApp() {
//
//        val endTrackingMap = mapOf(
//            "path" to "/STOP_TRACKING_CONFIRM"
//        )
//        try {
//            val baos = ByteArrayOutputStream()
//            val oos = ObjectOutputStream(baos)
//            oos.writeObject(endTrackingMap)
//            oos.flush()
//            val byteArray = baos.toByteArray()
//
//            MessageSender.send(
//                path = "/STOP_TRACKING",
//                message = byteArray,
//                context = this
//            )
//            Log.d("MainActivity", "📤 트래킹 종료 메시지 전송 완료")
//        } catch (e: Exception) {
//            Log.e("MainActivity", "❌ 트래킹 종료 메시지 전송 실패", e)
//        }
//
//    }
}
