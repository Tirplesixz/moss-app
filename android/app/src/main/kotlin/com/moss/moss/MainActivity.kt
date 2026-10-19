package com.moss.moss

import android.app.WallpaperManager
import android.Manifest
import android.content.ContentValues
import android.content.ContentUris
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.os.Build
import android.provider.CalendarContract
import android.provider.MediaStore
import android.provider.Settings
import android.net.Uri
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import java.util.TimeZone
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.moss.moss/lockscreen"
    private val calendarChannelName = "com.moss.moss/calendar"
    private val calendarPermissionRequest = 9042
    private var pendingCalendarPermission: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "applyLockScreen") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null) {
                    result.error("INVALID_IMAGE", "Wallpaper bytes are missing", null)
                    return@setMethodCallHandler
                }
                try {
                    val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                        ?: throw IllegalArgumentException("Invalid PNG image")
                    val manager = WallpaperManager.getInstance(applicationContext)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        manager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK)
                    } else {
                        manager.setBitmap(bitmap)
                    }
                    val shouldSave = call.argument<Boolean>("saveToGallery") ?: true
                    val location = if (shouldSave) saveToGallery(bytes) else null
                    bitmap.recycle()
                    result.success(mapOf("action" to "applied", "location" to location))
                } catch (error: Exception) {
                    result.error("WALLPAPER_FAILED", error.message, null)
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, calendarChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkAccess" -> {
                        val requested = getSharedPreferences("moss_permissions", MODE_PRIVATE)
                            .getBoolean("calendar_requested", false)
                        result.success(
                            if (hasCalendarAccess()) "granted"
                            else if (requested) "denied"
                            else "undetermined",
                        )
                    }
                    "requestAccess" -> requestCalendarAccess(result)
                    "fetchEvents" -> {
                        if (!hasCalendarReadAccess()) {
                            result.error("PERMISSION_DENIED", "Calendar permission is not granted", null)
                        } else {
                            val start = call.argument<Number>("start")?.toLong() ?: 0L
                            val end = call.argument<Number>("end")?.toLong() ?: 0L
                            result.success(fetchCalendarEvents(start, end))
                        }
                    }
                    "addCompletedTask" -> {
                        if (!hasCalendarWriteAccess()) {
                            result.success(null)
                        } else {
                            val title = call.argument<String>("title") ?: "Moss task"
                            val start = call.argument<Number>("start")?.toLong() ?: 0L
                            val end = call.argument<Number>("end")?.toLong() ?: start
                            result.success(addCompletedTask(title, start, end))
                        }
                    }
                    "upsertTaskEvent" -> {
                        if (!hasCalendarWriteAccess()) {
                            result.success(null)
                        } else {
                            try {
                                val eventId = call.argument<String>("eventId")
                                val title = call.argument<String>("title") ?: "Moss task"
                                val start = call.argument<Number>("start")?.toLong() ?: 0L
                                val end = call.argument<Number>("end")?.toLong() ?: start
                                val completed = call.argument<Boolean>("completed") ?: false
                                val notes = call.argument<String>("notes")
                                result.success(
                                    upsertTaskEvent(eventId, title, start, end, completed, notes),
                                )
                            } catch (error: Exception) {
                                result.error("CALENDAR_WRITE_FAILED", error.message, null)
                            }
                        }
                    }
                    "deleteEvent" -> {
                        val eventId = call.argument<String>("eventId")
                        result.success(eventId != null && deleteCalendarEvent(eventId))
                    }
                    "openAppSettings" -> {
                        val intent = Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:$packageName"),
                        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasCalendarReadAccess(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CALENDAR) ==
            PackageManager.PERMISSION_GRANTED

    private fun hasCalendarWriteAccess(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_CALENDAR) ==
            PackageManager.PERMISSION_GRANTED

    private fun hasCalendarAccess(): Boolean =
        hasCalendarReadAccess() && hasCalendarWriteAccess()

    private fun requestCalendarAccess(result: MethodChannel.Result) {
        getSharedPreferences("moss_permissions", MODE_PRIVATE)
            .edit()
            .putBoolean("calendar_requested", true)
            .apply()
        if (hasCalendarAccess()) {
            result.success("granted")
            return
        }
        pendingCalendarPermission?.success("denied")
        pendingCalendarPermission = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.READ_CALENDAR, Manifest.permission.WRITE_CALENDAR),
            calendarPermissionRequest,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == calendarPermissionRequest) {
            pendingCalendarPermission?.success(if (hasCalendarAccess()) "granted" else "denied")
            pendingCalendarPermission = null
        }
    }

    private fun fetchCalendarEvents(start: Long, end: Long): List<Map<String, Any?>> {
        val builder = CalendarContract.Instances.CONTENT_URI.buildUpon()
        ContentUris.appendId(builder, start)
        ContentUris.appendId(builder, end)
        val uri = builder.build()
        val projection = arrayOf(
            CalendarContract.Instances.EVENT_ID,
            CalendarContract.Instances.TITLE,
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.END,
            CalendarContract.Instances.ALL_DAY,
            CalendarContract.Instances.CALENDAR_DISPLAY_NAME,
            CalendarContract.Instances.EVENT_COLOR,
            CalendarContract.Instances.EVENT_LOCATION,
            CalendarContract.Instances.DESCRIPTION,
        )
        val events = mutableListOf<Map<String, Any?>>()
        contentResolver.query(uri, projection, null, null, "${CalendarContract.Instances.BEGIN} ASC")?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_ID)
            val titleIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.TITLE)
            val startIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.BEGIN)
            val endIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.END)
            val allDayIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.ALL_DAY)
            val calendarIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.CALENDAR_DISPLAY_NAME)
            val colorIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_COLOR)
            val locationIndex = cursor.getColumnIndex(CalendarContract.Instances.EVENT_LOCATION)
            val descIndex = cursor.getColumnIndex(CalendarContract.Instances.DESCRIPTION)
            while (cursor.moveToNext()) {
                val loc = if (locationIndex >= 0 && !cursor.isNull(locationIndex)) cursor.getString(locationIndex) else null
                val desc = if (descIndex >= 0 && !cursor.isNull(descIndex)) cursor.getString(descIndex) else null
                events.add(
                    mapOf(
                        "id" to cursor.getLong(idIndex).toString(),
                        "title" to (cursor.getString(titleIndex) ?: ""),
                        "start" to cursor.getLong(startIndex),
                        "end" to cursor.getLong(endIndex),
                        "allDay" to (cursor.getInt(allDayIndex) == 1),
                        "calendarName" to (cursor.getString(calendarIndex) ?: ""),
                        "color" to if (cursor.isNull(colorIndex)) null else
                            (cursor.getInt(colorIndex).toLong() and 0xFFFFFFFFL),
                        "location" to loc,
                        "description" to desc,
                    ),
                )
            }
        }
        return events
    }

    private fun addCompletedTask(title: String, start: Long, end: Long): String? =
        upsertTaskEvent(null, title, start, end, true, null)

    private fun upsertTaskEvent(
        eventId: String?,
        title: String,
        start: Long,
        end: Long,
        completed: Boolean,
        notes: String?,
    ): String? {
        val projection = arrayOf(CalendarContract.Calendars._ID)
        val selection =
            "${CalendarContract.Calendars.VISIBLE} = 1 AND " +
                "${CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL} >= ?"
        val args = arrayOf(CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR.toString())
        val calendarId = contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            selection,
            args,
            "${CalendarContract.Calendars.IS_PRIMARY} DESC, " +
                "${CalendarContract.Calendars.SYNC_EVENTS} DESC, " +
                "${CalendarContract.Calendars._ID} ASC",
        )?.use { cursor ->
            if (cursor.moveToFirst()) cursor.getLong(0) else null
        } ?: return null
        val values = ContentValues().apply {
            put(CalendarContract.Events.CALENDAR_ID, calendarId)
            put(CalendarContract.Events.TITLE, if (completed) "✓ $title" else title)
            put(
                CalendarContract.Events.DESCRIPTION,
                listOfNotNull(notes?.takeIf { it.isNotBlank() }, "ซิงก์จาก Moss").joinToString("\n\n"),
            )
            put(CalendarContract.Events.DTSTART, start)
            put(CalendarContract.Events.DTEND, end)
            put(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().id)
        }
        val existingUri = eventId?.let(::calendarEventUri)
        if (existingUri != null && contentResolver.update(existingUri, values, null, null) > 0) {
            return ContentUris.parseId(existingUri).toString()
        }
        return contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
            ?.let(ContentUris::parseId)
            ?.toString()
    }

    private fun calendarEventUri(eventId: String): Uri? =
        if (eventId.startsWith("content://")) {
            Uri.parse(eventId)
        } else {
            eventId.toLongOrNull()?.let {
                ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, it)
            }
        }

    private fun deleteCalendarEvent(eventId: String): Boolean {
        val uri = calendarEventUri(eventId) ?: return false
        return contentResolver.delete(uri, null, null) > 0
    }

    private fun saveToGallery(bytes: ByteArray): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, "moss-lockscreen-${System.currentTimeMillis()}.png")
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Moss")
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: return null
        contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
        values.clear()
        values.put(MediaStore.Images.Media.IS_PENDING, 0)
        contentResolver.update(uri, values, null, null)
        return uri.toString()
    }
}
