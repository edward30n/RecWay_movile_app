# CodeViz Research Context

> **Note**: This file contains research context from CodeViz. Most recent contexts are at the bottom.

---

## Research Query

Investigate the "Services" component in detail. Focus your analysis on these key files:
1. native_sensor_service.dart (c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/native_sensor_service.dart)
2. database_service.dart (c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/database_service.dart)
3. background_service.dart (c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/background_service.dart)
4. sensor_diagnostic_service.dart (c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/sensor_diagnostic_service.dart)
5. permission_service.dart (c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/permission_service.dart)

Provide insights about the component's main responsibilities and functionality and how it integrates with other system components

*Session: 8f507cd1290bddb438c70cc42d8c8d31 | Generated: 7/16/2025, 2:10:44 PM*

### Analysis Summary

# Services Component Analysis

The **Services** component in this application is a critical layer responsible for abstracting and managing various core functionalities, including sensor data acquisition, persistent data storage, background processing, diagnostic checks, and permission handling. It acts as an intermediary between the UI/application logic and the underlying platform-specific APIs or system resources, ensuring a clean separation of concerns and robust operation.

## Core Responsibilities

The primary responsibilities of the Services component are:
*   **Sensor Data Management**: Interacting with native device sensors (accelerometer, gyroscope, GPS) to collect and process data.
*   **Data Persistence**: Storing collected sensor data efficiently and reliably in a local database.
*   **Background Execution**: Ensuring continuous data collection and processing even when the application is not in the foreground.
*   **System Diagnostics**: Providing tools to check the health and availability of sensors and other system components.
*   **Permission Handling**: Managing and requesting necessary runtime permissions from the user.

## Component Breakdown

### **Native Sensor Service** [native_sensor_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/native_sensor_service.dart)

The **NativeSensorService** is responsible for direct communication with platform-specific native sensor APIs (likely via Flutter's `MethodChannel`). It provides a high-level interface for starting, stopping, and polling native sensor data.

*   **Purpose**: To bridge the gap between Flutter and native (Android/iOS) sensor functionalities, allowing the application to access raw sensor data and manage native sensor states.
*   **Internal Parts**:
    *   `_channel`: A `MethodChannel` [native_sensor_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/native_sensor_service.dart:10) used for invoking native methods.
    *   `startNativeSensors(int samplingRate)`: Initiates native sensor data collection at a specified frequency [native_sensor_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/native_sensor_service.dart:16).
    *   `stopNativeSensors()`: Halts native sensor data collection [native_sensor_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/native_sensor_service.dart:31).
    *   `getCurrentSensorData()`: Retrieves the latest sensor data from the native side [native_sensor_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/native_sensor_service.dart:46).
    *   `startPolling(...)` and `stopPolling()`: Manages a `Timer` [native_sensor_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/native_sensor_service.dart:57) for periodically fetching sensor data.
    *   `requestBatteryOptimization()`: Requests the system to ignore battery optimizations for the app [native_sensor_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/native_sensor_service.dart:83).
    *   `isAvailable()` and `getStatus()`: Checks the availability and current status of native sensors [native_sensor_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/native_sensor_service.dart:94).
*   **External Relationships**: It is primarily used by the **BackgroundService** [background_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/background_service.dart:10) to initiate and manage native sensor data collection in the background.

### **Database Service** [database_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/database_service.dart)

The **DatabaseService** provides a singleton interface for interacting with the local SQLite database using the `sqflite` package. It manages database initialization, table creation, and CRUD operations for sensor data.

*   **Purpose**: To provide a robust and efficient mechanism for storing, retrieving, and managing sensor data collected by the application.
*   **Internal Parts**:
    *   `_database`: A static `Database` instance [database_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/database_service.dart:5) ensuring a single database connection.
    *   `database`: Getter for the database instance, initializing it if necessary [database_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/database_service.dart:7).
    *   `_initDatabase()`: Handles the opening and creation of the SQLite database file [database_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/database_service.dart:12).
    *   `_createTables(Database db)`: Defines the schema for the `sensor_data` table, including columns for accelerometer, gyroscope, GPS data, and session information [database_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/database_service.dart:25).
    *   `insertData(Map<String, dynamic> data)`: Inserts a new record of sensor data into the database [database_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/database_service.dart:50).
    *   `getData(...)`, `getDataCount(...)`, `clearOldData(...)`, `clearAllData()`: Methods for querying, counting, and clearing data [database_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/database_service.dart:55).
    *   `getUniqueSessions()` and `getSessionStats(String sessionId)`: Provides methods for managing and retrieving statistics about data collection sessions [database_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/database_service.dart:110).
    *   `isDatabaseHealthy()` and `cleanupOpenSessions()`: Utility methods for database maintenance and integrity checks [database_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/database_service.dart:150).
*   **External Relationships**: Heavily utilized by the **BackgroundService** [background_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/background_service.dart:10) to persist collected sensor data.

### **Background Service** [background_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/background_service.dart)

The **BackgroundService** is the central orchestrator for continuous sensor data collection, even when the application is not actively in use. It leverages `flutter_background_service` to run tasks in the background and manages the lifecycle of sensor data streams and data saving.

*   **Purpose**: To enable persistent and robust sensor data collection in the background, ensuring that data is not lost when the app is closed or minimized. It also handles the coordination of sensor data acquisition and storage.
*   **Internal Parts**:
    *   `initializeService()`: Configures and starts the background service, setting up Android and iOS specific configurations (e.g., foreground mode, notifications) [background_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/background_service.dart:12).
    *   `onStart(ServiceInstance service)`: The entry point for the background service, executed when the service starts. It sets up foreground service, enables `WakelockPlus` [background_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/background_service.dart:47), and listens for commands from the main application.
    *   `startRecording` and `stopRecording` listeners: Handle commands from the main app to start and stop data collection sessions [background_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/background_service.dart:90).
    *   Sensor Streams (`accelerometerEventStream`, `gyroscopeEventStream`, `getPositionStream`): Subscribes to sensor data streams from `sensors_plus` and `geolocator` [background_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/background_service.dart:190).
    *   `_saveDataPoint(...)`: A helper function to format and save collected sensor data to the database [background_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/background_service.dart:260).
    *   Timers (`samplingTimer`, `sensorForceTimer`): Manages the frequency of data sampling and ensures sensors remain active [background_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/background_service.dart:139).
*   **External Relationships**:
    *   Communicates with the main application via `service.on()` listeners for `startRecording` and `stopRecording` events.
    *   Relies on **NativeSensorService** [background_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/background_service.dart:10) for native sensor access.
    *   Utilizes **DatabaseService** [background_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/background_service.dart:260) to store collected data.
    *   Integrates with `geolocator` and `sensors_plus` packages for GPS and device sensor data.
    *   Uses `wakelock_plus` [background_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/background_service.dart:9) to keep the CPU active during recording.

### **Sensor Diagnostic Service** [sensor_diagnostic_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/sensor_diagnostic_service.dart)

The **SensorDiagnosticService** is designed to provide insights into the operational status and availability of various sensors and system components crucial for the application's functionality.

*   **Purpose**: To help diagnose issues related to sensor availability, permissions, and background service status, providing a health check for the data collection system.
*   **Internal Parts**:
    *   `checkAllSensors()`: A comprehensive method that checks the status of accelerometer, gyroscope, GPS, and the background service [sensor_diagnostic_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/sensor_diagnostic_service.dart:10).
    *   `_checkAccelerometer()` and `_checkGyroscope()`: Verify the availability of these sensors [sensor_diagnostic_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/sensor_diagnostic_service.dart:30).
    *   `_checkGps()`: Checks GPS service status and permissions [sensor_diagnostic_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/sensor_diagnostic_service.dart:40).
    *   `_checkBackgroundService()`: Verifies if the background service is running [sensor_diagnostic_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/sensor_diagnostic_service.dart:58).
    *   `_checkBatteryOptimization()`: Checks if battery optimization is ignored [sensor_diagnostic_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/sensor_diagnostic_service.dart:68).
    *   `_checkDatabaseHealth()`: Assesses the health of the local database [sensor_diagnostic_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/sensor_diagnostic_service.dart:78).
*   **External Relationships**:
    *   Relies on **NativeSensorService** [sensor_diagnostic_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/sensor_diagnostic_service.dart:10) for native sensor status.
    *   Uses **DatabaseService** [sensor_diagnostic_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/sensor_diagnostic_service.dart:11) to check database health.
    *   Interacts with `geolocator` for GPS status and `flutter_background_service` for background service status.
    *   Likely consumed by UI components (e.g., a diagnostic screen) to display system health.

### **Permission Service** [permission_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/permission_service.dart)

The **PermissionService** centralizes the logic for requesting and checking various runtime permissions required by the application, such as location, activity recognition, and notification permissions.

*   **Purpose**: To streamline the process of managing user permissions, ensuring the application has the necessary access to device features for data collection.
*   **Internal Parts**:
    *   `requestAllPermissions()`: Requests all necessary permissions in a structured manner [permission_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/permission_service.dart:10).
    *   `_requestLocationPermission()`: Handles requesting location permissions (both `locationWhenInUse` and `locationAlways`) [permission_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/permission_service.dart:20).
    *   `_requestActivityRecognitionPermission()`: Requests permission for physical activity recognition [permission_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/permission_service.dart:48).
    *   `_requestNotificationPermission()`: Requests permission for notifications (for foreground service) [permission_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/permission_service.dart:58).
    *   `checkAllPermissions()`: Checks the current status of all required permissions [permission_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/permission_service.dart:70).
    *   `openAppSettings()`: Provides a utility to open the application's settings page for manual permission granting [permission_service.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/services/permission_service.dart:88).
*   **External Relationships**:
    *   Uses the `permission_handler` package to interact with the operating system's permission system.
    *   Likely called from the application's startup flow or a dedicated permission request screen (e.g., [permission_loading_screen.dart](c:/Users/NICOLAS/Desktop/RecWay/beforeMerch/lib/screens/permission_loading_screen.dart)).

