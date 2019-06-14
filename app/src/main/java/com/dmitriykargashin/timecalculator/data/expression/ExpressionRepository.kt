/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.data.expression

import android.arch.lifecycle.LiveData
import android.arch.lifecycle.MutableLiveData
import android.text.SpannableString
import android.text.TextUtils


class ExpressionRepository {


    private val expression = MutableLiveData<SpannableString>()

    init {
        expression.value= SpannableString("")
    }

    fun setExpression(expressionString: SpannableString) {

        expression.value = expressionString
    }

    fun addToExpression(expressionString: SpannableString) {

        expression.value =  SpannableString(TextUtils.concat(expression.value, expressionString))
    }

    fun addToExpression(expressionString: String) {

        expression.value =  SpannableString(TextUtils.concat(expression.value, expressionString))
    }

    fun getExpression() = expression as LiveData<SpannableString>


    companion object {
        // @Volatile - Writes to this property are immediately visible to other threads
        @Volatile
        private var instance: ExpressionRepository? = null

        // The only way to get hold of the FakeDatabase object
        fun getInstance() =
        // Already instantiated? - return the instance
            // Otherwise instantiate in a thread-safe manner
            instance ?: synchronized(this) {
                // If it's still not instantiated, finally create an object
                // also set the "instance" property to be the currently created one
                instance ?: ExpressionRepository().also { instance = it }
            }
    }
}
