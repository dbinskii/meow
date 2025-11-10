package com.today.meowly.background

object CatBackgroundConfig {
    const val CHANNEL_NAME = "com.today.meowly/background"
    const val ACTION_CAT_REFRESHED = "com.today.meowly.action.CAT_REFRESHED"
    const val EXTRA_CREATED_AT = "createdAt"

    const val PREFS_NAME = "cat_background_config"
    private const val KEY_REFRESH_INTERVAL_MINUTES = "refresh_interval_minutes"

    const val DEFAULT_REFRESH_INTERVAL_MINUTES = 5

    fun saveIntervalMinutes(context: android.content.Context, minutes: Int) {
        context.getSharedPreferences(PREFS_NAME, android.content.Context.MODE_PRIVATE)
            .edit()
            .putInt(KEY_REFRESH_INTERVAL_MINUTES, minutes)
            .apply()
    }

    fun readIntervalMinutes(context: android.content.Context): Int {
        return context.getSharedPreferences(PREFS_NAME, android.content.Context.MODE_PRIVATE)
            .getInt(KEY_REFRESH_INTERVAL_MINUTES, DEFAULT_REFRESH_INTERVAL_MINUTES)
    }
}

