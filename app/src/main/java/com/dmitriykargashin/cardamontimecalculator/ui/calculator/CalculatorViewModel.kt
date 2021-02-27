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
import com.dmitriykargashin.cardamontimecalculator.data.repository.PerUnitsRepository
import com.dmitriykargashin.cardamontimecalculator.data.repository.ResultFormatsRepository
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Token
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Tokens
import com.dmitriykargashin.cardamontimecalculator.data.repository.TokensRepository
import com.dmitriykargashin.cardamontimecalculator.data.resultFormat.ResultFormat
import com.dmitriykargashin.cardamontimecalculator.utilites.TimeConverter
import kotlinx.coroutines.*
import java.math.BigDecimal

class CalculatorViewModel(
    private val expressionRepository: ExpressionRepository,
    private val tokensRepository: TokensRepository,
    private val resultFormatsRepository: ResultFormatsRepository,
    private val perUnitsRepository: PerUnitsRepository

) : ViewModel() {


    private var isInFormatsChooseModeRepository: Boolean =
        false // for controlling whenever opened format chooser view or not

    private val isInFormatsChooseMode = MutableLiveData<Boolean>()

    private var isInPerViewModeRepository: Boolean =
        false // for controlling whenever opened per view or not

    private val isInPerViewMode = MutableLiveData<Boolean>()



    private var isInSupportAppViewModeRepository: Boolean =
        false // for controlling whenever opened Support app view or not
    private val isInSupportAppViewMode = MutableLiveData<Boolean>()



    private var tempResultInMsec = Tokens()

    private var isPerViewButtonDisabledRepository: Boolean =
        true
    private val isPerViewButtonDisabled = MutableLiveData<Boolean>()


    init {
        isInFormatsChooseMode.value = isInFormatsChooseModeRepository
        isInPerViewMode.value = isInPerViewModeRepository
        isPerViewButtonDisabled.value = isPerViewButtonDisabledRepository
        isInSupportAppViewMode.value = isInSupportAppViewModeRepository
    }


    fun getResultTokens() = tokensRepository.getTokens()


    fun getResultFormats() = resultFormatsRepository.getResultFormats()

    fun getPerUnits() = perUnitsRepository.getPerUnits()


    fun addToresultFormats(resultFormat: ResultFormat) =
        resultFormatsRepository.addResultFormat(resultFormat)

    fun addToken(token: Token) = tokensRepository.addToken(token)

    fun getIsFormatsLayoutVisible() = isInFormatsChooseMode as LiveData<Boolean>

    fun getIsPerLayoutVisible() = isInPerViewMode as LiveData<Boolean>

    fun getIsSupportAppLayoutVisible() = isInSupportAppViewMode as LiveData<Boolean>

    fun setIsFormatsLayoutVisible(visible: Boolean) {
        isInFormatsChooseModeRepository = visible
        isInFormatsChooseMode.value = isInFormatsChooseModeRepository
    }


    fun setIsPerLayoutVisible(visible: Boolean) {
        isInPerViewModeRepository = visible
        isInPerViewMode.value = isInPerViewModeRepository
    }

    fun setIsSupportAppLayoutVisible(visible: Boolean) {
        isInSupportAppViewModeRepository = visible
        isInSupportAppViewMode.value = isInSupportAppViewModeRepository
    }


    fun getIsPerViewButtonDisabled() = isPerViewButtonDisabled as LiveData<Boolean>

    fun setIsPerViewButtonDisabled(visible: Boolean) {
        isPerViewButtonDisabledRepository = visible
        isPerViewButtonDisabled.value = isPerViewButtonDisabledRepository
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
        setIsPerViewButtonDisabled(false)

    }


    fun clearAll() {
        tokensRepository.setTokens(Tokens())
        expressionRepository.setTokens(Tokens())
        setIsPerViewButtonDisabled(true)
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
            setIsPerViewButtonDisabled(true)
        }
    }

    fun updateResultFormats() {
        resultFormatsRepository.updateFormatsWithPreview(tempResultInMsec)
    }


    fun updatePerUnits() {
        // updateSettingsForPerUnits(30.toBigDecimal(),"RUB")
        if (!isPerViewButtonDisabledRepository)
            perUnitsRepository.updatePerUnitsWithPreview(tempResultInMsec)

    }


    fun updateSettingsForPerUnits(amount: BigDecimal, unitName: String) {

        if (!isPerViewButtonDisabledRepository) {
            perUnitsRepository.setParams(amount, unitName, tokensRepository.getTokens().value!!)
            perUnitsRepository.updatePerUnitsWithPreview(tempResultInMsec)
        }
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