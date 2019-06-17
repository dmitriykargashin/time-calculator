/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.data.tokens

import android.arch.lifecycle.LiveData
import android.arch.lifecycle.MutableLiveData
import android.util.Log


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

    fun getTokens() = tokens as LiveData<Tokens>

    fun setTokens(newTokens: Tokens) {

        tokensList = newTokens
    //    Log.i("TAG", tokensList.toString())
        tokens.postValue(tokensList) // for executing in background thread
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
                instance ?: TokensRepository().also { instance = it }
            }
    }
}