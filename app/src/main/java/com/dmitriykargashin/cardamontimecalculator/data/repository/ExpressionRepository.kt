/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.data.repository

import android.util.Log
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.dmitriykargashin.cardamontimecalculator.engine.expression.isErrorsInExpression
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Token
import com.dmitriykargashin.cardamontimecalculator.data.tokens.TokenType
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Tokens

class ExpressionRepository {

    private var tokensList = Tokens()
    private val tokens = MutableLiveData<Tokens>()


    init {
        tokens.value = tokensList

    }

    fun addToExpression(tokenForAdd: Token): Boolean {

        when (tokenForAdd.type) {
            TokenType.PLUS, TokenType.MINUS, TokenType.DIVIDE, TokenType.MULTIPLY -> {
                tryToAddToExpression(tokenForAdd) // when we add operators dont need to evaluate
                return false
            }


        }

        // if was enter DOT then we add the DOT to previous NUMBER if it exists
        // return the function means we need to evaluate expression

        var lastToken: Token? = null //it can be null

        if (tokensList.isNotEmpty()) lastToken = tokensList.last()

        val lastOperator = tokensList.findLastNearestOperatorToken()
        val tokenBeforeLastOperator = tokensList.findTokenBeforeLastNearestOperatorToken()
        val lastTokenBeforeTokenBeforeLastOperator =
            tokensList.findTokenBeforeTokenBeforeLastNearestOperatorToken()


        if (tokenForAdd.type == TokenType.DOT || tokenForAdd.type == TokenType.NUMBER) {
            return if (lastToken != null && lastToken.type == TokenType.NUMBER) {
                if (tokenForAdd.type == TokenType.DOT) {
                    tokensList.last().addDotToNumber()
                    tokens.value = tokensList
                    false
                } else {
                    tokensList.last().mergeNumberToNumber(tokenForAdd)
                    tokens.value = tokensList

                    //return result. if it's only number, then we dont need to evaluate

                    tokensList.isLastExpressionBlockHasTimeKeyword() &&
                            ((lastOperator != null && (lastOperator.type == TokenType.DIVIDE || lastOperator.type == TokenType.MULTIPLY)
                                    && tokenBeforeLastOperator != null && tokenBeforeLastOperator.type != TokenType.NUMBER)
                                    ||
                                    (lastOperator != null && (lastOperator.type == TokenType.DIVIDE || lastOperator.type == TokenType.MULTIPLY)
                                            && tokenBeforeLastOperator != null && tokenBeforeLastOperator.type == TokenType.NUMBER
                                            && lastTokenBeforeTokenBeforeLastOperator != null && (lastTokenBeforeTokenBeforeLastOperator.type == TokenType.DIVIDE || lastTokenBeforeTokenBeforeLastOperator.type == TokenType.MULTIPLY))
                                    )

                }

            } else {

                tryToAddToExpression(tokenForAdd)
                return tokensList.isLastExpressionBlockHasTimeKeyword() &&
                        (

                                (lastOperator != null && (lastOperator.type == TokenType.DIVIDE || lastOperator.type == TokenType.MULTIPLY)
                                        && tokenBeforeLastOperator != null && tokenBeforeLastOperator.type != TokenType.NUMBER)
                                        ||
                                        (lastOperator != null && (lastOperator.type == TokenType.DIVIDE || lastOperator.type == TokenType.MULTIPLY)
                                                && tokenBeforeLastOperator != null && tokenBeforeLastOperator.type == TokenType.NUMBER
                                                && lastTokenBeforeTokenBeforeLastOperator != null && (lastTokenBeforeTokenBeforeLastOperator.type == TokenType.DIVIDE || lastTokenBeforeTokenBeforeLastOperator.type == TokenType.MULTIPLY))
                                )

            }
        } else {
            return tryToAddToExpression(tokenForAdd)
        }

        //  return true
    }

    private fun tryToAddToExpression(tokenForAdd: Token): Boolean {

        return if (!isErrorsInExpression(
                tokenForAdd,
                tokensList
            )
        )// if error we wont add it to expression
        {
            tokensList.add(tokenForAdd)
            tokens.value = tokensList
            true
        } else {
            //  if (expressionString == ".") expression.value = expression.value + expressionString

            false

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

    fun deleteLastTokenOrSymbol(): Boolean {
      //  Log.i("TAG", "Expression Before delete ${tokensList.toSpannableString()}")
//        Log.i("TAG", "Entered for delete ${tokensList.last().strRepresentation}")

        var lastOperator = tokensList.findLastNearestOperatorToken()
        var tokenBeforeLastOperator = tokensList.findTokenBeforeLastNearestOperatorToken()

        var lastToken: Token? = null //it can be null

        if (tokensList.isNotEmpty()) lastToken = tokensList.last()


        return if (lastToken != null) {
            //  var lastToken = tokensList.last()
            if (lastToken.type != TokenType.NUMBER) {
                //       Log.i("TAG", "Entered for delete TOKEN ${lastToken.strRepresentation}")
                tokensList.removeLastToken()

            } else {
                //       Log.i("TAG", "Entered for delete symbol in NUMBER ${lastToken.strRepresentation}")
                lastToken.deleteOneLastSymbolInNumber()
                if (lastToken.strRepresentation == "") tokensList.removeLastToken()

            }
            //  tokens.postValue(tokensList)
            //     Log.i("TAG", "Result After delete ${tokensList.toSpannableString()}")
            tokens.value = tokensList

            var newLastToken: Token? = null

            if (tokensList.isNotEmpty()) newLastToken = tokensList.last()

                 tokensList.isLastExpressionBlockHasTimeKeyword()
                    || (newLastToken!=null && newLastToken.type != TokenType.NUMBER)

        } else false
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
