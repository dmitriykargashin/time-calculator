/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.ui.calculator

import android.content.Context
import android.util.Log
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dmitriykargashin.cardamontimecalculator.data.repository.*
import com.dmitriykargashin.cardamontimecalculator.engine.calculator.CalculatorOfTime
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Token
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Tokens
import com.dmitriykargashin.cardamontimecalculator.data.resultFormat.ResultFormat
import com.dmitriykargashin.cardamontimecalculator.utilites.TimeConverter
import kotlinx.coroutines.*
import java.math.BigDecimal

class CalculatorViewModel(
    private val expressionRepository: ExpressionRepository,
    private val tokensRepository: TokensRepository,
    private val resultFormatsRepository: ResultFormatsRepository,
    private val perUnitsRepository: PerUnitsRepository,
    private val prefRepository: PrefRepository,
    private val utilityRepository: UtilityRepository,
    private val context: Context


) : ViewModel() {





    init {


    }

    ///utility repo
    fun getIsFormatsLayoutVisible() = utilityRepository.getIsFormatsLayoutVisible()

    fun getIsPerLayoutVisible() = utilityRepository.getIsPerLayoutVisible()

    fun getIsSupportAppLayoutVisible() = utilityRepository.getIsSupportAppLayoutVisible()

    fun getIsSettingsLayoutVisible() = utilityRepository.getIsSettingsLayoutVisible()

    fun setIsFormatsLayoutVisible(visible: Boolean) {
        utilityRepository.setIsFormatsLayoutVisible(visible)
    }

    fun setIsPerLayoutVisible(visible: Boolean) {
        utilityRepository.setIsPerLayoutVisible(visible)
    }

    fun setIsSupportAppLayoutVisible(visible: Boolean) {
        utilityRepository.setIsSupportAppLayoutVisible(visible)
    }

    fun setIsSettingsLayoutVisible(visible: Boolean) {
        utilityRepository.setIsSettingsLayoutVisible(visible)
    }


    fun getIsFormatsViewButtonDisabled() = utilityRepository.getIsFormatsViewButtonDisabled()

    fun getIsPerViewButtonDisabled() = utilityRepository.getIsPerViewButtonDisabled()

    fun setIsPerViewButtonDisabled(visible: Boolean) {
        utilityRepository.setIsPerViewButtonDisabled(visible)
    }

    fun setIsFormatsViewButtonDisabled(visible: Boolean) {
        utilityRepository.setIsFormatsViewButtonDisabled(visible)
    }


///utility repo end


    fun getResultTokens(): LiveData<Tokens> {
        utilityRepository.setIsPerViewButtonDisabled(isResultEmpty())
        utilityRepository.setIsFormatsViewButtonDisabled(isResultEmpty())
        return tokensRepository.getTokens()
    }


    //preferences
    fun getPrefThemeColor() = prefRepository.getPrefThemeColor()
    fun setPrefThemeColor(value: String) = prefRepository.setPrefThemeColor(value)
//end preferences


    fun getResultFormats() = resultFormatsRepository.getResultFormats()

    fun getPerUnits() = perUnitsRepository.getPerUnits()


    fun addToresultFormats(resultFormat: ResultFormat) =
        resultFormatsRepository.addResultFormat(resultFormat)

    fun addToken(token: Token) = tokensRepository.addToken(token)


    fun addToExpression(element: Token) {

        if (expressionRepository.addToExpression(element)) {
            viewModelScope.coroutineContext.cancelChildren()
            viewModelScope.launch { evaluateExpression() }
        }
        //   }
        //  }


    }

    fun getExpression() = expressionRepository.getExpression()


    fun isExpressionEmpty(): Boolean = expressionRepository.getExpression().value.isNullOrEmpty()

    fun isResultEmpty(): Boolean = tokensRepository.getTokens().value.isNullOrEmpty()


    private suspend fun evaluateExpression() {

        utilityRepository.setTempResultInMsec(withContext(Dispatchers.Default) {
            CalculatorOfTime.evaluate(getExpression().value!!/*.toString()*/)
        })


        val resultTokens = TimeConverter.convertTokensToTokensWithFormat(
            utilityRepository.getTempResultInMsec().value!!,
            resultFormatsRepository.getSelectedFormat().value!!.formatTokens
        )

        tokensRepository.setTokens(resultTokens)
        utilityRepository.setIsPerViewButtonDisabled(false)
        utilityRepository.setIsFormatsViewButtonDisabled(false)

    }


    fun clearAll() {
        tokensRepository.setTokens(Tokens())
        expressionRepository.setTokens(Tokens())
        utilityRepository.setIsPerViewButtonDisabled(true)
        utilityRepository.setIsFormatsViewButtonDisabled(true)
        //  expressionRepository.setExpression("")

    }

    fun clearOneLastSymbol(context: Context) {
        if (expressionRepository.deleteLastTokenOrSymbol()) {
            Log.i(
                "TAG",
                "AfterPress cleared ${
                    expressionRepository.getExpression().value?.toSpannableString(
                        context
                    )
                }"
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
            utilityRepository.setIsPerViewButtonDisabled(true)
            utilityRepository.setIsFormatsViewButtonDisabled(true)
        }
    }

    fun updateResultFormats() {
        resultFormatsRepository.updateFormatsWithPreview(utilityRepository.getTempResultInMsec().value!!)
    }


    fun updatePerUnits() {
        // updateSettingsForPerUnits(30.toBigDecimal(),"RUB")
        if (utilityRepository.getIsPerViewButtonDisabled().value == false)
            perUnitsRepository.updatePerUnitsWithPreview(utilityRepository.getTempResultInMsec().value!!)

    }


    fun updateSettingsForPerUnits(amount: BigDecimal, unitName: String) {

        if (utilityRepository.getIsPerViewButtonDisabled().value == false) {
            perUnitsRepository.setParams(amount, unitName, tokensRepository.getTokens().value!!)
            perUnitsRepository.updatePerUnitsWithPreview(utilityRepository.getTempResultInMsec().value!!)
        }
    }

    fun getSelectedFormat() = resultFormatsRepository.getSelectedFormat()


    fun setSelectedFormat(position: Int): LiveData<ResultFormat> {

        val selectedFormat = resultFormatsRepository.setSelectedFormat(position)

        // here we need to update result of expression to desired format

        val resultConvertedTokens = TimeConverter.convertTokensToTokensWithFormat(
            utilityRepository.getTempResultInMsec().value!!,
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
//}


}