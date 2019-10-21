/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.data.repository

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Token
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Tokens


class TokensRepository {


    private var tokensList = Tokens()
    private val tokens = MutableLiveData<Tokens>()

    init {
        tokens.value = tokensList
    }

    fun addToken(token: Token) {

        tokensList.add(token)
        tokens.value = tokensList

    }

    fun length(): Int = tokensList.lastIndex + 1

    fun getTokens()= tokens as LiveData<Tokens>

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
        private var instance: TokensRepository? = null

        // The only way to get hold of the FakeDatabase object
        fun getInstance() =
        // Already instantiated? - return the instance
            // Otherwise instantiate in a thread-safe manner
            instance ?: synchronized(this) {
                // If it's still not instantiated, finally create an object
                // also set the "instance" property to be the currently created one
                instance
                    ?: TokensRepository().also { instance = it }
            }
    }
}