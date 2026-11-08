package com.apps.winka.stickywall

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.text.SpannableString
import android.text.Spanned
import android.text.style.ForegroundColorSpan
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

/**
 * Home-screen widget. Shows a picture of the board when the app has exported
 * one to it and "Board picture" is chosen, else a board's pinned or newest
 * notes as text, in the colours and text size chosen in the app (Customize →
 * Home-screen widget). Each line opens its note (stickywall://note/<guid>),
 * the + button a new note on the board shown (stickywall://new?board=<id>);
 * the app reads both in lib/services/widget_service.dart (WidgetTap). Data is pushed from Flutter via the home_widget plugin
 * (see lib/services/widget_service.dart; the colours match widgetColors in
 * lib/widgets/widget_settings_sheet.dart).
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

            // Before the app wrote a mode, a sent picture was always shown.
            val mode = widgetData.getString("mode", null)
            val wall = if (mode == null || mode == "picture") {
                widgetData.getString("wall", null)?.let { loadScaled(it, 900) }
            } else {
                null
            }
            var addTint = CHALK
            if (wall != null) {
                views.setImageViewBitmap(R.id.widget_wall, wall)
                views.setViewVisibility(R.id.widget_wall, View.VISIBLE)
                views.setViewVisibility(R.id.widget_lines, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_wall, View.GONE)
                views.setViewVisibility(R.id.widget_lines, View.VISIBLE)
                addTint = bindLines(context, views, widgetData)
            }

            // Tapping the widget opens the app; a line opens its note.
            views.setOnClickPendingIntent(R.id.widget_root, launch(context, null))

            // + starts a new note on the board the widget shows.
            val board = widgetData.getString("boardId", "") ?: ""
            views.setInt(R.id.widget_add, "setColorFilter", addTint)
            views.setOnClickPendingIntent(
                R.id.widget_add,
                launch(context, Uri.parse("stickywall://new?board=${Uri.encode(board)}")),
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun launch(context: Context, uri: Uri?) =
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri)

    /** Fills the text lines; returns the text colour for the + button. */
    private fun bindLines(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
    ): Int {
        val look = widgetData.getString("look", "wall")
        val (background, text, faded) = when (look) {
            "paper" -> Triple(R.drawable.widget_bg_paper, INK, INK_FADED)
            "ink" -> Triple(R.drawable.widget_bg_ink, CHALK, CHALK_FADED)
            else -> Triple(R.drawable.widget_bg, CHALK, CHALK_FADED)
        }
        val (titleSize, lineSize) = when (widgetData.getString("textSize", "normal")) {
            "small" -> 14f to 12f
            "large" -> 19f to 17f
            else -> 16f to 14f
        }
        views.setInt(R.id.widget_root, "setBackgroundResource", background)

        val title = widgetData.getString("title", null)
            ?: context.getString(R.string.widget_title_default)
        views.setTextViewText(R.id.widget_title, title)
        views.setTextColor(R.id.widget_title, text)
        views.setTextViewTextSize(R.id.widget_title, TypedValue.COMPLEX_UNIT_SP, titleSize)

        val ids = intArrayOf(
            R.id.widget_line1, R.id.widget_line2, R.id.widget_line3,
            R.id.widget_line4, R.id.widget_line5, R.id.widget_line6,
        )
        val lines = ids.indices.map { widgetData.getString("line${it + 1}", "") ?: "" }
        lines.forEachIndexed { i, line ->
            if (line.isBlank()) {
                views.setViewVisibility(ids[i], View.GONE)
            } else {
                views.setViewVisibility(ids[i], View.VISIBLE)
                // A dot of the note's paper colour leads the line.
                val dot = widgetData.getString("color${i + 1}", "")?.toLongOrNull()?.toInt()
                val shown = SpannableString("● $line")
                if (dot != null) {
                    shown.setSpan(ForegroundColorSpan(dot), 0, 1, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
                }
                views.setTextViewText(ids[i], shown)
                views.setTextColor(ids[i], text)
                views.setTextViewTextSize(ids[i], TypedValue.COMPLEX_UNIT_SP, lineSize)
                val id = widgetData.getString("id${i + 1}", "") ?: ""
                if (id.isNotEmpty()) {
                    views.setOnClickPendingIntent(
                        ids[i],
                        launch(context, Uri.parse("stickywall://note/${Uri.encode(id)}")),
                    )
                }
            }
        }

        val empty = lines.all { it.isBlank() }
        views.setViewVisibility(
            R.id.widget_empty,
            if (empty) View.VISIBLE else View.GONE,
        )
        views.setTextViewText(
            R.id.widget_empty,
            widgetData.getString("empty", null)
                ?: context.getString(R.string.widget_empty_default),
        )
        views.setTextColor(R.id.widget_empty, faded)
        views.setTextViewTextSize(R.id.widget_empty, TypedValue.COMPLEX_UNIT_SP, lineSize)
        return text
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

    private companion object {
        const val CHALK = 0xFFFDFBF3.toInt()
        const val CHALK_FADED = 0xCCFDFBF3.toInt()
        const val INK = 0xFF3B372F.toInt()
        const val INK_FADED = 0xCC3B372F.toInt()
    }
}
