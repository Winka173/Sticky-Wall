package com.winka.sticky_wall

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

/**
 * Home-screen widget. Shows a picture of the board when the app has exported
 * one to it ("Show on home-screen widget" in the board export), else the
 * current board's pinned notes as text. Data is pushed from Flutter via the
 * home_widget plugin (see lib/services/widget_service.dart).
 */
class StickyWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.sticky_widget)

            val wall = widgetData.getString("wall", null)?.let { loadScaled(it, 900) }
            if (wall != null) {
                views.setImageViewBitmap(R.id.widget_wall, wall)
                views.setViewVisibility(R.id.widget_wall, View.VISIBLE)
                views.setViewVisibility(R.id.widget_lines, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_wall, View.GONE)
                views.setViewVisibility(R.id.widget_lines, View.VISIBLE)
                bindLines(views, widgetData)
            }

            // Tapping the widget opens the app.
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun bindLines(views: RemoteViews, widgetData: SharedPreferences) {
        val title = widgetData.getString("title", "Sticky Wall") ?: "Sticky Wall"
        views.setTextViewText(R.id.widget_title, title)

        val lines = listOf(
            widgetData.getString("line1", "") ?: "",
            widgetData.getString("line2", "") ?: "",
            widgetData.getString("line3", "") ?: "",
        )
        val ids = intArrayOf(R.id.widget_line1, R.id.widget_line2, R.id.widget_line3)
        lines.forEachIndexed { i, text ->
            if (text.isBlank()) {
                views.setViewVisibility(ids[i], View.GONE)
            } else {
                views.setViewVisibility(ids[i], View.VISIBLE)
                views.setTextViewText(ids[i], "• $text")
            }
        }

        val empty = lines.all { it.isBlank() }
        views.setViewVisibility(
            R.id.widget_empty,
            if (empty) View.VISIBLE else View.GONE,
        )
    }

    /**
     * Decodes the exported picture no larger than [maxEdge] on its long side:
     * RemoteViews carries bitmaps through Binder, which caps their size, and
     * a widget is a few hundred dp across anyway.
     */
    private fun loadScaled(path: String, maxEdge: Int): Bitmap? {
        val file = File(path)
        if (!file.exists()) return null
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            var sample = 1
            while (maxOf(bounds.outWidth, bounds.outHeight) / sample > maxEdge) sample *= 2
            BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
        } catch (e: Exception) {
            null
        }
    }
}
