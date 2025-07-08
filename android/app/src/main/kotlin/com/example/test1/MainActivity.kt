package com.example.test1

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.PowerManager
import android.os.Build
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.test1/native_sensors"
    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private var gyroscope: Sensor? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var isListening = false
    private var executor: ScheduledExecutorService? = null
    
    // Datos actuales de sensores
    private var currentAccelX = 0.0f
    private var currentAccelY = 0.0f
    private var currentAccelZ = 0.0f
    private var currentGyroX = 0.0f
    private var currentGyroY = 0.0f
    private var currentGyroZ = 0.0f
    private var lastUpdateTime = 0L

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        gyroscope = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE)
        
        // Configurar WakeLock permanente
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ON_AFTER_RELEASE,
            "SensorCollector::SensorWakeLock"
        )
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startNativeSensors" -> {
                    val samplingRate = call.argument<Int>("samplingRate") ?: 50
                    startNativeSensors(samplingRate)
                    result.success("Native sensors started")
                }
                "stopNativeSensors" -> {
                    stopNativeSensors()
                    result.success("Native sensors stopped")
                }
                "getSensorData" -> {
                    val data = getCurrentSensorData()
                    result.success(data)
                }
                "requestBatteryOptimization" -> {
                    requestIgnoreBatteryOptimizations()
                    result.success("Battery optimization requested")
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startNativeSensors(samplingRate: Int) {
        if (isListening) return
        
        isListening = true
        
        // Adquirir WakeLock
        if (!wakeLock?.isHeld!!) {
            wakeLock?.acquire()
        }
        
        // Configurar sensores con máxima frecuencia
        val delay = when {
            samplingRate >= 100 -> SensorManager.SENSOR_DELAY_FASTEST // ~200Hz
            samplingRate >= 50 -> SensorManager.SENSOR_DELAY_GAME     // ~50Hz
            samplingRate >= 20 -> SensorManager.SENSOR_DELAY_UI       // ~16Hz
            else -> SensorManager.SENSOR_DELAY_NORMAL                 // ~5Hz
        }
        
        accelerometer?.let {
            sensorManager.registerListener(accelerometerListener, it, delay)
        }
        
        gyroscope?.let {
            sensorManager.registerListener(gyroscopeListener, it, delay)
        }
        
        // Forzar lectura periódica para mantener activos los sensores
        executor = Executors.newSingleThreadScheduledExecutor()
        executor?.scheduleAtFixedRate({
            // Mantener despiertos los sensores
            lastUpdateTime = System.currentTimeMillis()
        }, 0, 100, TimeUnit.MILLISECONDS)
        
        println("🔋 Native sensors started with wake lock")
    }

    private fun stopNativeSensors() {
        if (!isListening) return
        
        isListening = false
        sensorManager.unregisterListener(accelerometerListener)
        sensorManager.unregisterListener(gyroscopeListener)
        
        executor?.shutdown()
        executor = null
        
        // Liberar WakeLock
        if (wakeLock?.isHeld!!) {
            wakeLock?.release()
        }
        
        println("🔋 Native sensors stopped")
    }

    private val accelerometerListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent) {
            currentAccelX = event.values[0]
            currentAccelY = event.values[1]
            currentAccelZ = event.values[2]
            lastUpdateTime = System.currentTimeMillis()
        }
        
        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    }

    private val gyroscopeListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent) {
            currentGyroX = event.values[0]
            currentGyroY = event.values[1]
            currentGyroZ = event.values[2]
        }
        
        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    }

    private fun getCurrentSensorData(): Map<String, Any> {
        return mapOf(
            "accelerometer" to mapOf(
                "x" to currentAccelX.toDouble(),
                "y" to currentAccelY.toDouble(),
                "z" to currentAccelZ.toDouble()
            ),
            "gyroscope" to mapOf(
                "x" to currentGyroX.toDouble(),
                "y" to currentGyroY.toDouble(),
                "z" to currentGyroZ.toDouble()
            ),
            "timestamp" to lastUpdateTime,
            "isActive" to isListening
        )
    }
    
    private fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent()
            intent.action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        }
    }
    
    override fun onDestroy() {
        stopNativeSensors()
        super.onDestroy()
    }
}
