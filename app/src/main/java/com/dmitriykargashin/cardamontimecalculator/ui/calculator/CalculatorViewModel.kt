/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.ui.calculator

import android.util.Log
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dmitriykargashin.cardamontimecalculator.engine.calculator.CalculatorOfTime
import com.dmitriykargashin.cardamontimecalculator.data.repository.ExpressionRepository
import com.dmitriykargashin.cardamontimecalculator.data.repository.ResultFormatsRepository
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Token
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Tokens
import com.dmitriykargashin.cardamontimecalculator.data.repository.TokensRepository
import com.dmitriykargashin.cardamontimecalculator.data.resultFormat.ResultFormat
import com.dmitriykargashin.cardamontimecalculator.utilites.TimeConverter
import kotlinx.coroutines.*

class CalculatorViewModel(
    private val expressionRepository: ExpressionRepository,
    private val tokensRepository: TokensRepository,
    private val resultFormatsRepository: ResultFormatsRepository


) : ViewModel() {


    private var isInFormatsChooseModeRepository: Boolean =
        false // for controlling whenever opened format chooser view or not

    private val isInFormatsChooseMode = MutableLiveData<Boolean>()

    private var tempResultInMsec=Tokens()


    init {
        isInFormatsChooseMode.value = isInFormatsChooseModeRepository


    }

    fun getResultTokens() = tokensRepository.getTokens()


    fun getResultFormats() = resultFormatsRepository.getResultFormats()


    fun addToresultFormats(resultFormat: ResultFormat) =
        resultFormatsRepository.addResultFormat(resultFormat)

    fun addToken(token: Token) = tokensRepository.addToken(token)

    fun getIsFormatsLayoutVisible() = isInFormatsChooseMode as LiveData<Boolean>

    fun setIsFormatsLayoutVisible(visible: Boolean) {
        isInFormatsChooseModeRepository = visible
        isInFormatsChooseMode.value = isInFormatsChooseModeRepository
    }


    fun addToExpression(element: Token) {

        if (expressionRepository.addToExpression(element)) {
            viewModelScope.coroutineContext.cancelChildren()
            viewModelScope.launch { evaluateExpression() }
        }
        //   }
        //  }


    }

    fun getExpression() = expressionRepository.getExpression()


    fun isExpressionEmpty(): Boolean {
        return expressionRepository.getExpression().value.isNullOrEmpty()
    }

    private suspend fun evaluateExpression() {

        tempResultInMsec = withContext(Dispatchers.Default) {
            CalculatorOfTime.evaluate(getExpression().value!!/*.toString()*/)

        }
        val resultTokens = TimeConverter.convertTokensToTokensWithFormat(
            tempResultInMsec, resultFormatsRepository.getSelectedFormat().value!!.formatTokens
        )

        tokensRepository.setTokens(resultTokens)


    }


    fun clearAll() {
        tokensRepository.setTokens(Tokens())
        expressionRepository.setTokens(Tokens())
        //  expressionRepository.setExpression("")

    }

    fun clearOneLastSymbol() {
        if (expressionRepository.deleteLastTokenOrSymbol()) {
            Log.i(
                "TAG",
                "AfterPress cleared ${expressionRepository.getExpression().value?.toSpannableString()}"
            )
            //if true then recalculate
            viewModelScope.coroutineContext.cancelChildren()
            viewModelScope.launch { evaluateExpression() }
        }
    }

    fun sendResultToExpression() {
        if (tokensRepository.length() > 0) {
            expressionRepository.setTokens(tokensRepository.getTokens().value!!)
            tokensRepository.setTokens(Tokens())
        }
    }

    fun updateResultFormats() {
        resultFormatsRepository.updateFormatsWithPreview(tempResultInMsec)
    }

    fun getSelectedFormat() = resultFormatsRepository.getSelectedFormat()


    fun setSelectedFormat(position: Int): LiveData<ResultFormat> {

        val selectedFormat = resultFormatsRepository.setSelectedFormat(position)

        // here we need to update result of expression to desired format

        val resultConvertedTokens = TimeConverter.convertTokensToTokensWithFormat(
            tempResultInMsec,
            resultFormatsRepository.getSelectedFormat().value!!.formatTokens
        )
        tokensRepository.setTokens(resultConvertedTokens)

        return selectedFormat


    }

/* private fun convertEvaluatedTokensToSpannedString(textView: TextView, listOfResultTokens: Tokens) {


     for (token in listOfResultTokens) {
         when (token.type) {
             TokenType.NUMBER ->
                 textView.append(token.strRepresentation)

             TokenType.SECOND, TokenType.MSECOND, TokenType.YEAR, TokenType.MONTH, TokenType.WEEK, TokenType.DAY, TokenType.HOUR, TokenType.MINUTE ->
                 textView.append(token.strRepresentation.addStartAndEndSpace().toHTMLWithColor())
         }
     }
     //      Log.i("TAG", textView.text.toString())

 }*/


}