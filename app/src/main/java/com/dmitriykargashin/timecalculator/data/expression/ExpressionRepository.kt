/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.data.expression

import android.arch.lifecycle.LiveData
import android.arch.lifecycle.MutableLiveData
import android.text.SpannableString
import android.text.TextUtils


class ExpressionRepository {


    private val expression = MutableLiveData<String>()

    init {
        expression.value = ""
    }

    fun setExpression(expressionString: String) {

        expression.value = expressionString
    }

    fun addToExpression(expressionString: String) {
        if (noErrorsInExpression(expressionString)) expression.value =
            expression.value + expressionString
    }


/*
    fun addToExpression(expressionString: String) {

        if (noErrorsInExpression(expressionString)) expression.value =
            SpannableString(TextUtils.concat(expression.value, expressionString))
    }
*/


    private fun noErrorsInExpression(expressionToAdd: String): Boolean {
//here we should check all future errors when we will add the new expression to existing expression

        return true
    }

    fun getExpression() = expression as LiveData<String>


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
