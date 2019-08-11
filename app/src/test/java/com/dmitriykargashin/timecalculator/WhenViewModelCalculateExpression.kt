/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator

import androidx.arch.core.executor.ArchTaskExecutor
import androidx.arch.core.executor.TaskExecutor
import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.Observer
import androidx.lifecycle.ViewModelProviders
import android.text.SpannableString
import android.util.Log
import com.dmitriykargashin.timecalculator.data.tokens.TokenType
import com.dmitriykargashin.timecalculator.data.tokens.Tokens
import com.dmitriykargashin.timecalculator.internal.extension.addStartAndEndSpace
import com.dmitriykargashin.timecalculator.internal.extension.spannable
import com.dmitriykargashin.timecalculator.internal.extension.toHTMLWithColor
import com.dmitriykargashin.timecalculator.ui.calculator.CalculatorActivity
import com.dmitriykargashin.timecalculator.ui.calculator.CalculatorViewModel
import com.dmitriykargashin.timecalculator.ui.calculator.CalculatorViewModelFactory
import com.dmitriykargashin.timecalculator.utilites.InjectorUtils
import junit.framework.Assert.assertNotNull
import junit.framework.Assert.assertTrue
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.newSingleThreadContext
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runBlockingTest
import kotlinx.coroutines.test.setMain
import org.hamcrest.MatcherAssert.assertThat
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.rules.TestRule
import org.junit.Rule
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import org.mockito.Mockito.`when`
import org.mockito.Mockito.verify


class WhenViewModelCalculateExpression {
    // common function for calculate expression
    @get:Rule
    val rule = InstantTaskExecutorRule()

    private lateinit var factory: CalculatorViewModelFactory
    private lateinit var viewModel: CalculatorViewModel

    @Mock
    lateinit var observer: Observer<Tokens>

    @Mock
    lateinit var observerExpression: Observer<String>
    private val mainThreadSurrogate = @UseExperimental newSingleThreadContext("UI thread")

    @Before
    fun initialize() {
        MockitoAnnotations.initMocks(this)
        @UseExperimental Dispatchers.setMain(mainThreadSurrogate)

        factory = InjectorUtils.provideCalculatorViewModelFactory()

        viewModel = CalculatorViewModel(factory.expressionRepository, factory.tokensRepository)

        viewModel.getTokens().observeForever(observer)
        viewModel.getExpression().observeForever(observerExpression)




    }

    @After
    fun tearDown() {
        @UseExperimental  Dispatchers.resetMain() // reset main dispatcher to the original Main dispatcher
        mainThreadSurrogate.close()

    }
    @Test
    fun testNull() {
     //   `when`(apiClient.fetchNews()).thenReturn(null)
        assertNotNull(viewModel.getTokens())
        assertTrue(viewModel.getTokens().hasObservers())
    }

    @Test
    fun Calculate_Expr_0_plus_10_Equals_10() {

        //  val expressionForCalculateTmp = ("0+10").addStartAndEndSpace()//.toHTMLWithColor()//.toHTMLWithColor()
        //      var expressionForCalculate =  SpannableString("rwefdg")// expressionForCalculateTmp.addStartAndEndSpace().toHTMLWithColor()
        val listOfExpectedTokens = "0".toTokens()
        //     runBlockingTest{
        //   viewModel.setExpression(expressionForCalculate)
        runBlockingTest {
            launch(Dispatchers.Main) {
                viewModel.addToExpression("0")
            //    viewModel.addToExpression(TokenType.PLUS)
            //    viewModel.addToExpression("10")
                val listOfActualTokens = viewModel.getTokens().value
                assertThat(listOfActualTokens, isEqualTo(listOfExpectedTokens))
            }

            //      val listOfActualTokens = viewModel.getTokens().value

            //   Log.i("TAG", listOfActualTokens?.value.toString())
            //     val actualTokens = listOfActualTokens
            //  verify(observer).onChanged(actualTokens)
            //    assertThat(listOfActualTokens, isEqualTo(listOfExpectedTokens))
            //       }
            //  assertThat(actualTokens, isEqualTo(listOfExpectedTokens))

            //  val listOfActualTokens = CalculateExpression(expressionForCalculate)

            //   assertThat(listOfActualTokens, isEqualTo(listOfExpectedTokens))
        }
    }


}