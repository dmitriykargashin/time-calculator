/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.data.repository

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.dmitriykargashin.timecalculator.data.expression.isErrorsInExpression
import com.dmitriykargashin.timecalculator.data.tokens.Token
import com.dmitriykargashin.timecalculator.data.tokens.TokenType
import com.dmitriykargashin.timecalculator.data.tokens.Tokens

class ExpressionRepository {

    private var tokensList = Tokens()
    private val tokens = MutableLiveData<Tokens>()

    init {
        tokens.value = tokensList
    }

    fun addToExpression(tokenForAdd: Token): Boolean {
        // if was entered DOT then we add the DOT to previous NUMBER if it exists
        // return the function means we need to evaluate expression
        if (tokenForAdd.type == TokenType.DOT || tokenForAdd.type == TokenType.NUMBER) {
            if (tokensList.isNotEmpty() && tokensList.last().type == TokenType.NUMBER) {
                if (tokenForAdd.type == TokenType.DOT) {
                    tokensList.last().addDotToNumber()
                    tokens.value = tokensList
                    return false
                } else {
                    tokensList.last().mergeNumberToNumber(tokenForAdd)
                    tokens.value = tokensList
                    return true
                }

            } else {
               return tryToAddToExpression(tokenForAdd)

            }
        } else {
            return tryToAddToExpression(tokenForAdd)
        }

      //  return true
    }

    private fun tryToAddToExpression (tokenForAdd: Token): Boolean {

        if (!isErrorsInExpression(tokenForAdd, tokensList))// if error we wont add it to expression
        {
            tokensList.add(tokenForAdd)
            tokens.value = tokensList
            return true
        } else {
            //  if (expressionString == ".") expression.value = expression.value + expressionString

            return false

        }


    }

    fun getExpression() = tokens as LiveData<Tokens>

    fun setTokens(newTokens: Tokens) {

        tokensList = newTokens
        //    Log.i("TAG", tokensList.toString())
        tokens.postValue(tokensList) // for executing in background thread
        //  tokens.setValue(tokensList) // for immediately set
        //     emit()
        //  Log.i("TAG", tokensList.toString())
    }


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
                instance
                    ?: ExpressionRepository().also { instance = it }
            }
    }
}
