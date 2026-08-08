package com.winka.sticky_wall

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget showing the current board's pinned notes. Data is pushed
 * from Flutter via the home_widget plugin (see lib/services/widget_service.dart).
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
                    views.setViewVisibility(ids[i], android.view.View.GONE)
                } else {
                    views.setViewVisibility(ids[i], android.view.View.VISIBLE)
                    views.setTextViewText(ids[i], "• $text")
                }
            }

            val empty = lines.all { it.isBlank() }
            views.setViewVisibility(
                R.id.widget_empty,
                if (empty) android.view.View.VISIBLE else android.view.View.GONE,
            )

            // Tapping the widget opens the app.
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
