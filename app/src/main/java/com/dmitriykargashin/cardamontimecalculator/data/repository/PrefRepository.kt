/*
 * Copyright (c) 2021. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.data.repository

import android.content.Context
import android.content.SharedPreferences
import androidx.lifecycle.MutableLiveData




const val PREFERENCE_NAME = "MY_APP_PREF"

const val PREF_THEME_COLOR = "PREF_THEME_COLOR"

class PrefRepository(val context: Context) {

    private val pref: SharedPreferences =
        context.getSharedPreferences(PREFERENCE_NAME, Context.MODE_PRIVATE)

    private val editor = pref.edit()

    private var prefThemeColorRep = "0"
    private val prefThemeColor = MutableLiveData<String>()


    init {
        //fist run
        getPrefThemeColor()
        if (prefThemeColorRep.isBlank()) setPrefThemeColor("0")

    }

    // private val gson = Gson()

    private fun putString(parameterName: String, value: String) {
        editor.putString(parameterName, value)
        editor.commit()
    }

    private fun getString(parameterName: String) = pref.getString(parameterName, "")!!


    fun getPrefThemeColor() = run {
        prefThemeColorRep = getString(PREF_THEME_COLOR)
        prefThemeColor.value = prefThemeColorRep
        prefThemeColor //as LiveData<String>
    }


    fun setPrefThemeColor(value: String) {

        prefThemeColorRep = value
        putString(PREF_THEME_COLOR, value)

        prefThemeColor.postValue(prefThemeColorRep) // for executing in background thread

    }


    companion object {
        // @Volatile - Writes to this property are immediately visible to other threads
        @Volatile
        private var instance: PrefRepository? = null

        // The only way to get hold of the FakeDatabase object
        fun getInstance(context: Context) =
        // Already instantiated? - return the instance
            // Otherwise instantiate in a thread-safe manner
            instance ?: synchronized(this) {
                // If it's still not instantiated, finally create an object
                // also set the "instance" property to be the currently created one
                instance
                    ?: PrefRepository(context).also {
                      //  it.getPrefThemeColor()
                        instance = it }
            }
    }
}
