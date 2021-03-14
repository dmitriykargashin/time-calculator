/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.utilites

import android.content.Context
import com.dmitriykargashin.cardamontimecalculator.data.repository.*
import com.dmitriykargashin.cardamontimecalculator.ui.calculator.CalculatorViewModelFactory

object InjectorUtils {

    fun provideCalculatorViewModelFactory(context: Context): CalculatorViewModelFactory {
        // ViewModelFactory needs a repository, which in turn needs a DAO from a database
        // The whole dependency tree is constructed right here, in one place
        val tokensRepository = TokensRepository.getInstance()
        val expressionRepository = ExpressionRepository.getInstance()
        val resultFormatsRepository = ResultFormatsRepository.getInstance()
        val perUnitsRepository = PerUnitsRepository.getInstance()
        val prefRepository = PrefRepository.getInstance(context)
        val utilityRepository = UtilityRepository.getInstance()

        return CalculatorViewModelFactory(expressionRepository, tokensRepository,resultFormatsRepository,perUnitsRepository,prefRepository,utilityRepository,context)
    }
}