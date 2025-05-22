package com.c104.ollana.presentation.sensor

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.ActivityCompat.requestPermissions
import androidx.core.app.NotificationCompat
import com.c104.ollana.R

class SensorCollectorService : Service(){

    private val TAG="SensorCollectorService"
    private lateinit var sensorCollector: SensorCollector

    override fun onCreate() {
        super.onCreate()
        Log.d("SensorCollectorService", "🔥 서비스 생성됨")

        try {
            val notification = createMinimalNotification()
            Log.d(TAG, "🔧 Notification 객체 생성됨")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                if (checkSelfPermission(android.Manifest.permission.FOREGROUND_SERVICE_HEALTH) == PackageManager.PERMISSION_GRANTED) {
                    startForeground(1, createMinimalNotification())
                } else {
                    Log.e(TAG, "❌ FOREGROUND_SERVICE_HEALTH 권한 없음 - startForeground 실패")
                }
            } else {
                startForeground(1, createMinimalNotification())
            }
            Log.d(TAG, "📌 startForeground 호출 완료")

            sensorCollector = SensorCollector(this)
            sensorCollector.start()
            Log.d(TAG, "✅ 센서 수집 시작됨")
        } catch (e: Exception) {
            Log.e(TAG, "❌ 예외 발생: ${e.message}", e)
        }
    }

    private fun requestPermissions(arrayOf: Array<String>, i: Int) {

    }

    override fun onDestroy() {
        super.onDestroy()

        //서비스가 종료될때 센서 수집도 중단
        sensorCollector.stop()
        stopForeground(true) // ← 알림까지 제거
        Log.d(TAG,"센서 수집 서비스 종료")
    }

    override fun onBind(intent : Intent?) : IBinder?=null

    private fun createMinimalNotification() : Notification{
        val channelId = "sensor_channel"
        val channelName = "센서 수집 알림"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val chan = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_LOW)
            chan.description = "센서 수집을 위한 포그라운드 알림"
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(chan)
        }
        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("센서 수집 중")
            .setContentText("심박수/걸음 수 데이터를 수집합니다.")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation) // ← 이거 없으면 안됨
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

}