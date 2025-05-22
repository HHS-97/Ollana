package com.c104.ollana.presentation.sensor

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import com.c104.ollana.presentation.data.MessageSender
import java.io.ByteArrayOutputStream
import java.io.ObjectOutputStream

class SensorCollector(private val context : Context) : SensorEventListener{

    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager

    //사용자 센서 정의(심박수, 걸음수)
    private val heartRateSensor : Sensor?=sensorManager.getDefaultSensor(Sensor.TYPE_HEART_RATE)
    private val stepSensor : Sensor?=sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)

    //최근 수집된 센서 값 저장
    private var lastHeartRate : Int?=null
    private var lastStepCount : Int=0

    //마지막 전송 시간(3초마다 한번만 전송하기위한 체크용)
    private var lastSensorTime=0L

    val TAG="SensorCollector"

    //센서 수집
    fun start(){
        Log.d(TAG, "📦 센서 존재 여부 - HR: ${heartRateSensor != null}, Step: ${stepSensor != null}")
        // 센서 목록 확인 로그
        sensorManager.getSensorList(Sensor.TYPE_ALL).forEach {
            Log.d(TAG, "📦 사용 가능한 센서: ${it.name} (type: ${it.type})")
        }

        heartRateSensor?.let {
            val result = sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
            Log.d(TAG, "✅ 심박수 리스너 등록 성공 여부: $result")
        }
        stepSensor?.let{
            val result = sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
            Log.d(TAG, "✅ 걸음수 리스너 등록 성공 여부: $result")
        }
        Log.d(TAG,"센서수집 시작")
        Log.d(TAG, "심박수 센서: ${heartRateSensor?.name}, 걸음 수 센서: ${stepSensor?.name}")
    }

    //센서 수집 중단
    fun stop(){
        sensorManager.unregisterListener(this)
        Log.d(TAG,"센서 수집 중단")
    }

    //센서 데이터가 들어왔을때 호출
    override fun onSensorChanged(event: SensorEvent?) {
        Log.d(TAG, "onSensorChanged 호출됨")
        if(event ==null) return

        when(event.sensor.type){

            Sensor.TYPE_HEART_RATE->{
                lastHeartRate=event.values[0].toInt()
                Log.d(TAG, "심박수 수신됨: ${lastHeartRate}")
            }
            Sensor.TYPE_STEP_COUNTER->{
                lastStepCount=event.values[0].toInt()
                Log.d(TAG, "👣 걸음 수 수신됨: ${lastStepCount}")
            }
        }
        
        //5초마다 전송
        val currentTime = System.currentTimeMillis()
        val shouldSend =currentTime-lastSensorTime >=5000

        if (currentTime - lastSensorTime >= 5000 && lastHeartRate != null && lastStepCount != null) {
            sendSensorData()
            lastSensorTime = currentTime
        }
    }
    //센서 데이터를 앱에 전송
    private fun sendSensorData() {

        val sensorMap = mapOf(
            "path" to "/SENSOR_DATA",
            "heartRate" to lastHeartRate,
            "steps" to lastStepCount
        )
        try{
            val baos = ByteArrayOutputStream()
            val oos = ObjectOutputStream(baos)
            oos.writeObject(sensorMap)
            oos.flush()
            val byteArray = baos.toByteArray()

            //전송
            MessageSender.send(
                path="/SENSOR_DATA",
                message = byteArray,
                context=context
            )
            Log.d("SensorCollector","센서 데이터 전송:${sensorMap}")
        }catch (e : Exception){
            Log.e(TAG, "❌ 센서 데이터 직렬화 실패", e)
        }


    }

    fun sendTestDataManually() {
        val testMap = mapOf(
            "path" to "/SENSOR_DATA",
            "data" to mapOf(
                "heartRate" to 72,
                "steps" to 100
            )
        )

        try {
            val baos = ByteArrayOutputStream()
            val oos = ObjectOutputStream(baos)
            oos.writeObject(testMap)
            oos.flush()
            val byteArray = baos.toByteArray()

            MessageSender.send(
                path = "/SENSOR_DATA",
                message = byteArray,
                context = context
            )
            Log.d(TAG, "✅ 테스트 센서 데이터 전송: $testMap")
        } catch (e: Exception) {
            Log.e(TAG, "❌ 테스트 데이터 직렬화 실패", e)
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        Log.d(TAG, "🎯 onAccuracyChanged: sensor=${sensor?.name}, accuracy=$accuracy")
    }

}