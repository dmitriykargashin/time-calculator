/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator

import androidx.arch.core.executor.ArchTaskExecutor
import androidx.arch.core.executor.TaskExecutor
import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import android.text.SpannableString
import android.util.Log
import androidx.lifecycle.*
import com.dmitriykargashin.timecalculator.data.tokens.TokenType
import com.dmitriykargashin.timecalculator.data.tokens.Tokens
import com.dmitriykargashin.timecalculator.internal.extension.*
import com.dmitriykargashin.timecalculator.ui.calculator.CalculatorActivity
import com.dmitriykargashin.timecalculator.ui.calculator.CalculatorViewModel
import com.dmitriykargashin.timecalculator.ui.calculator.CalculatorViewModelFactory
import com.dmitriykargashin.timecalculator.utilites.InjectorUtils
import junit.framework.Assert.assertNotNull
import junit.framework.Assert.assertTrue
import kotlinx.coroutines.*
import kotlinx.coroutines.test.TestCoroutineDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runBlockingTest
import kotlinx.coroutines.test.setMain
import org.hamcrest.MatcherAssert.assertThat
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.rules.TestRule
import org.junit.Rule
import org.junit.rules.TestWatcher
import org.junit.runner.Description
import org.junit.runner.RunWith
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import org.mockito.Mockito.`when`
import org.mockito.Mockito.verify

class OneTimeObserver<T>(private val handler: (T) -> Unit) : Observer<T>, LifecycleOwner {
    private val lifecycle = LifecycleRegistry(this)

    init {
        lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_RESUME)
    }

    override fun getLifecycle(): Lifecycle = lifecycle

    override fun onChanged(t: T) {
        handler(t)
        lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_DESTROY)
    }
}

fun <T> LiveData<T>.observeOnce(onChangeHandler: (T) -> Unit) {
    val observer = OneTimeObserver(handler = onChangeHandler)
    observe(observer, observer)
}


class WhenViewModelCalculateExpression {
    // common function for calculate expression
    @get:Rule
    val rule = InstantTaskExecutorRule()

    private lateinit var factory: CalculatorViewModelFactory
    private lateinit var viewModel: CalculatorViewModel

    /*   @Mock
       lateinit var observer: Observer<Tokens>

      @Mock
       lateinit var observerExpression: Observer<String>*/
    private val mainThreadSurrogate = @UseExperimental newSingleThreadContext("UI thread")

    @Before
    fun initialize() {
        /*    MockitoAnnotations.initMocks(this)*/
        @UseExperimental Dispatchers.setMain(mainThreadSurrogate)

        factory = InjectorUtils.provideCalculatorViewModelFactory()

        viewModel = CalculatorViewModel(factory.expressionRepository, factory.tokensRepository)

        //   viewModel.getTokens().observeForever(observer)
//        viewModel.getExpression().observeForever(observerExpression)


    }

    @After
    fun tearDown() {
        mainThreadSurrogate.cancel()
        @UseExperimental Dispatchers.resetMain() // reset main dispatcher to the original Main dispatcher
        mainThreadSurrogate.close()

    }

    @Test
    fun testNull() {
        //   `when`(apiClient.fetchNews()).thenReturn(null)
        assertNotNull(viewModel.getTokens())
        assertTrue(viewModel.getTokens().hasObservers())
    }

    @Test
    fun Calculate_Expr_0_plus_10_Equals_10() = runBlockingTest {
        val listOfExpectedTokens = "0".toTokens()
        viewModel.addToExpression("0".toToken())
        advanceTimeBy(5_000)
        val listOfActualToken = viewModel.getTokens().value
        advanceTimeBy(5_000)
        assertThat(listOfActualToken, isEqualTo(listOfExpectedTokens))
    }
/*

        // result available immediately
        //  val expressionForCalculateTmp = ("0+10").addStartAndEndSpace()//.toHTMLWithColor()//.toHTMLWithColor()
        //      var expressionForCalculate =  SpannableString("rwefdg")// expressionForCalculateTmp.addStartAndEndSpace().toHTMLWithColor()


            //   viewModel.setExpression(expressionForCalculate)
               runBlockingTest {
            launch(Dispatchers.Main) {
                //    launch(Dispatchers.Main) {
                val listOfExpectedTokens = "0".toTokens()
                //    advanceTimeBy(5_000)

                viewModel.addToExpression("0")
                   advanceTimeBy(5_000)
                val listOfActualToken = viewModel.getTokens().value//.observeOnce {
                //     val listOfActualToken = it

                assertThat(listOfActualToken, isEqualTo(listOfExpectedTokens))
            }
        }

        //     runBlockingTest{
        //   viewModel.addToExpression("0")//}
        //    viewModel.addToExpression(TokenType.PLUS)
        //    viewModel.addToExpression("10")
        //  val listOfActualTokens =
        //       advanceTimeBy(1_000)
        //       delay(5000)


        //      val listOfActualToken = viewModel.getTokens().value
        //   if (!this.coroutineContext.isActive)
        //    println("dffdgdf")
        //        assertThat(listOfActualToken, isEqualTo(listOfExpectedTokens))
        //     }
        //   rslt.join()

        //   }
        //    }
        //   advanceTimeBy(3_000)
    }
*/

    //      val listOfActualTokens = viewModel.getTokens().value

    //   Log.i("TAG", listOfActualTokens?.value.toString())
    //     val actualTokens = listOfActualTokens
    //  verify(observer).onChanged(actualTokens)
    //    assertThat(listOfActualTokens, isEqualTo(listOfExpectedTokens))
    //       }
    //  assertThat(actualTokens, isEqualTo(listOfExpectedTokens))

    //  val listOfActualTokens = CalculateExpression(expressionForCalculate)

    //   assertThat(listOfActualTokens, isEqualTo(listOfExpectedTokens))
    // }


}