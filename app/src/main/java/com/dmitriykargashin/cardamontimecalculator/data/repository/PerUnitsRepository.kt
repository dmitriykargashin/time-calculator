/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.data.repository

import android.util.Log
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.dmitriykargashin.cardamontimecalculator.data.perUnit.PerUnit
import com.dmitriykargashin.cardamontimecalculator.data.perUnit.PerUnits
import com.dmitriykargashin.cardamontimecalculator.data.resultFormat.ResultFormat
import com.dmitriykargashin.cardamontimecalculator.data.resultFormat.ResultFormats
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Tokens
import com.dmitriykargashin.cardamontimecalculator.internal.extension.toToken
import com.dmitriykargashin.cardamontimecalculator.internal.extension.toTokens
import com.dmitriykargashin.cardamontimecalculator.utilites.TimeConverter
import java.math.BigDecimal
import kotlin.math.log

class PerUnitsRepository {
    // default values
    private var perUnitsList = PerUnits(25.toBigDecimal(), "USD", "10 Hour".toTokens())
    private val perUnits = MutableLiveData<PerUnits>()


    init {
        perUnits.value = perUnitsList
        // selectedResultFormats.value = selectedResFormat
    }

    fun addPerUnit(perUnit: PerUnit): PerUnit {

        perUnitsList.add(perUnit)
        perUnits.value = perUnitsList
        return perUnit

    }

    fun setParams(amount: BigDecimal, unitName: String, timeInterval: Tokens) {
        perUnitsList.amount = amount
        perUnitsList.unitName = unitName
        perUnitsList.timeInterval = timeInterval

        perUnits.value = perUnitsList
    }

    fun length(): Int = perUnitsList.lastIndex + 1


    fun getPerUnits() = perUnits as LiveData<PerUnits>


    fun updatePerUnitsWithPreview(resultTokens: Tokens) {

        for (perUnitElement in perUnitsList) {


            val units = TimeConverter.convertTokensToTokensWithFormat(
                resultTokens,
                perUnitElement.timeUnit.toTokens()
            )

                    perUnitElement.unitsPer_Result =
                perUnitsList.amount * units[0].strRepresentation.toBigDecimal()

//
        }

        perUnits.value = perUnitsList
    }

//    fun setTokens(newResultFormats: ResultFormats) {
//
//        resultFormatsList = newResultFormats
//        //    Log.i("TAG", tokensList.toString())
//        resultFormats.postValue(resultFormatsList) // for executing in background thread
//
//        //     emit()
//        //  Log.i("TAG", tokensList.toString())
//    }

    private fun fillRepository() {
        setParams(25.toBigDecimal(), "USD", "10 Hour".toTokens())
        addPerUnit(PerUnit("Hour".toToken()))
        addPerUnit(PerUnit("Minute".toToken()))
        addPerUnit(PerUnit("Second".toToken()))
        addPerUnit(PerUnit("Day".toToken()))
        addPerUnit(PerUnit("Week".toToken()))
        addPerUnit(PerUnit("Month".toToken()))
        addPerUnit(PerUnit("Year".toToken()))
        addPerUnit(PerUnit("MSecond".toToken()))

    }

    companion object {
        // @Volatile - Writes to this property are immediately visible to other threads
        @Volatile
        private var instance: PerUnitsRepository? = null

        // The only way to get hold of the FakeDatabase object
        fun getInstance() =
        // Already instantiated? - return the instance
            // Otherwise instantiate in a thread-safe manner
            instance ?: synchronized(this) {
                // If it's still not instantiated, finally create an object
                // also set the "instance" property to be the currently created one
                instance
                    ?: PerUnitsRepository().also {
                        //fiil list only once
                        it.fillRepository()


                        instance = it
                    }
            }
    }
}