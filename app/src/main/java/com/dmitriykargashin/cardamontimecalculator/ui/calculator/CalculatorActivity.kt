/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.ui.calculator


import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.os.Build
import android.os.Bundle
import android.text.method.ScrollingMovementMethod
import android.util.Log
import android.view.View
import android.view.ViewAnimationUtils
import android.view.animation.AccelerateDecelerateInterpolator
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.Observer
import androidx.lifecycle.ViewModelProviders
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.android.billingclient.api.*
import com.dmitriykargashin.cardamontimecalculator.BuildConfig
import com.dmitriykargashin.cardamontimecalculator.R
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Token
import com.dmitriykargashin.cardamontimecalculator.data.tokens.TokenType
import com.dmitriykargashin.cardamontimecalculator.internal.extension.logger
import com.dmitriykargashin.cardamontimecalculator.internal.extension.toHTMLWithLightGreenColor
import com.dmitriykargashin.cardamontimecalculator.utilites.InjectorUtils
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.MobileAds
import hotchemi.android.rate.AppRate
import kotlinx.android.synthetic.main.activity_main.*
import kotlinx.android.synthetic.main.view_formats.*
import kotlin.math.hypot

import hotchemi.android.rate.StoreType
import android.content.Intent
import android.content.ActivityNotFoundException
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.util.Base64
import com.google.android.material.snackbar.Snackbar
import com.facebook.FacebookSdk
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException


class CalculatorActivity : AppCompatActivity(), PurchasesUpdatedListener {


    private lateinit var factory: CalculatorViewModelFactory
    lateinit var viewModel: CalculatorViewModel
    private val TAG = "CalculatorActivity"

    private var isRemoveAdsPurchased = false

    private lateinit var billingClient: BillingClient
    private val skuList = listOf("remove_ads")


    // Called when leaving the activity
    public override fun onPause() {

        super.onPause()
        if (!isPaidVersion() && !isRemoveAdsPurchased) {
            adView.pause()
        }

    }

    // Called when returning to the activity
    public override fun onResume() {
        super.onResume()
        checkPurchases()

        if (!isPaidVersion() && !isRemoveAdsPurchased) {
            adView.resume()
        }
    }

    // Called before the activity is destroyed
    public override fun onDestroy() {
        if (!isPaidVersion() && !isRemoveAdsPurchased) {
            adView.destroy()
        }
        super.onDestroy()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)


     /*   try {
            val info = getPackageManager().getPackageInfo(
                getPackageName(),
                PackageManager.GET_SIGNATURES
            );
            for (signature in info.signatures) {
                var messageDigest = MessageDigest.getInstance ("SHA")
                messageDigest.update(signature.toByteArray())
                Log.d("KeyHash:", Base64.encodeToString(messageDigest.digest(), Base64.DEFAULT))
            }
        } catch (e:PackageManager.NameNotFoundException) {

        }
        catch(e:NoSuchAlgorithmException) {

        }



        logger("Start Setup Billing")*/


        //   checkPurchases()

        if (!isPaidVersion()) {

            setupBillingClient()
            logger("end Setup Billing")

            /* MobileAds.initialize(this)
              val adRequest =
                  AdRequest.Builder().addTestDevice("C38113ED0332D64C52D625B7ED43DDED").build()
              adView.loadAd(adRequest)*/


        } else adView.visibility = View.GONE

        initUI()
        setupRateMe()

    }

    private fun setupRateMe() {
        AppRate.with(this)
            .setStoreType(StoreType.GOOGLEPLAY) //default is Google, other option is Amazon
            .setInstallDays(10) // default 10, 0 means install day.
            .setLaunchTimes(10) // default 10 times.
            .setRemindInterval(2) // default 1 day.
            .setShowLaterButton(true) // default true.
            .setDebug(false) // default false.
            .setCancelable(false) // default false.
            .setOnClickButtonListener {
                if (it == 0) rateMeOnGooglePlay() // 0 index of rate me button
            }

            .setMessage(R.string.new_rate_dialog_message)

            .monitor()

        AppRate.showRateDialogIfMeetsConditions(this)

    }


    fun rateMeOnGooglePlay() {
        try {
            startActivity(
                Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("market://details?id=$packageName")
                )
            )
        } catch (e: ActivityNotFoundException) {
            startActivity(
                Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("http://play.google.com/store/apps/details?id=$packageName")
                )
            )
        }

    }

    private fun isPaidVersion() = BuildConfig.PRO_VERSION


    override fun onBackPressed() {
        if (viewModel.getIsFormatsLayoutVisible().value!!) closeFormatsLayout(10, 10)
        else moveTaskToBack(true)
    }


    private fun setupBillingClient() {
        logger("Start Setup Billing")
        billingClient = BillingClient.newBuilder(this)
            .enablePendingPurchases()
            .setListener(this)
            .build()
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    // The BillingClient is ready. You can query purchases here.
                    logger("Setup Billing Done")
                    loadAllSKUs()
                    checkPurchases()
                }
            }

            override fun onBillingServiceDisconnected() {
                // Try to restart the connection on the next request to
                // Google Play by calling the startConnection() method.
                logger("Failed")

            }
        })

    }


    private fun loadAllSKUs() = if (billingClient.isReady) {
        val params = SkuDetailsParams
            .newBuilder()
            .setSkusList(skuList)
            .setType(BillingClient.SkuType.INAPP)
            .build()
        billingClient.querySkuDetailsAsync(params) { billingResult, skuDetailsList ->
            // Process the result.
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && skuDetailsList.isNotEmpty()) {
                for (skuDetails in skuDetailsList) {
                    if (skuDetails.sku == "remove_ads")

                        removeads.setOnClickListener {
                            logger("press button to buy")
                            fadeOutFABs()
                            val billingFlowParams = BillingFlowParams
                                .newBuilder()
                                .setSkuDetails(skuDetails)
                                .build()
                            billingClient.launchBillingFlow(this, billingFlowParams)
                        }
                }
            }
            //  logger(skuDetailsList.get(0).description)

        }

    } else {
        logger("Billing Client not ready")
    }


    override fun onPurchasesUpdated(
        billingResult: BillingResult?,
        purchases: MutableList<Purchase>?
    ) {
        if (billingResult?.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
            for (purchase in purchases) {
                acknowledgePurchase(purchase.purchaseToken)
                handlePurchase(purchase)

            }
        } else if (billingResult?.responseCode == BillingClient.BillingResponseCode.USER_CANCELED) {
            // Handle an error caused by a user cancelling the purchase flow.
            logger("User Cancelled")
            logger(billingResult.debugMessage.toString())


        } else {
            logger("other error")
            logger(billingResult?.debugMessage.toString())

            Snackbar.make(
                commonConstraintLayout,
                "Purchase is pending. Please wait",
                Snackbar.LENGTH_SHORT
            )
                .show()
            // Handle any other error codes.*/
        }
    }


    private fun acknowledgePurchase(purchaseToken: String) {
        val params = AcknowledgePurchaseParams.newBuilder()
            .setPurchaseToken(purchaseToken)
            .build()
        billingClient.acknowledgePurchase(params) { billingResult ->
            val responseCode = billingResult.responseCode
            val debugMessage = billingResult.debugMessage
            logger(debugMessage)
            logger(responseCode)


        }
    }


    private fun checkPurchases() {
        val purchasesResult: Purchase.PurchasesResult =
            billingClient.queryPurchases(BillingClient.SkuType.INAPP)
        val purchasesList = purchasesResult.purchasesList

        if (!purchasesList.isNullOrEmpty()) {
            for (purchase in purchasesList) {
                handlePurchase(purchase)
            }


        } else {// user dont have any purchase


            MobileAds.initialize(this)
            val adRequest =
                AdRequest.Builder().addTestDevice("C38113ED0332D64C52D625B7ED43DDED").build()
            adView.loadAd(adRequest)


        }

        logger("Purchases checked")
    }

    private fun handlePurchase(purchase: Purchase) {
        //test case use only! removes test purchase
        /*  val consumeParams =
              ConsumeParams.newBuilder()
                  .setPurchaseToken(purchase.purchaseToken)
                  .setDeveloperPayload(purchase.developerPayload)
                  .build()

          billingClient.consumeAsync(consumeParams) { billingResult, outToken ->
              if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                  // Handle the success of the consume operation.
                  // For example, increase the number of coins inside the user's basket.
              }
          }
          return*/
        if (purchase.purchaseState == Purchase.PurchaseState.PURCHASED) {
            if (purchase.sku == "remove_ads") {
                removeAds()
// Grant the item to the user, and then acknowledge the purchase
            }


        } else {
// here i start show ads, if not purchased.


            if (purchase.purchaseState == Purchase.PurchaseState.PENDING) {
                // Here you can confirm to the user that they've started the pending
                // purchase, and to complete it, they should follow instructions that
                // are given to them. You can also choose to remind the user in the
                // future to complete the purchase if you detect that it is still
                // pending.


                logger("Purchase pending")


                //test case use only! removes test purchase
                /*   val consumeParams =
                       ConsumeParams.newBuilder()
                           .setPurchaseToken(purchase.purchaseToken)
                           .setDeveloperPayload(purchase.developerPayload)
                           .build()

                   billingClient.consumeAsync(consumeParams) { billingResult, outToken ->
                       if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                           // Handle the success of the consume operation.
                           // For example, increase the number of coins inside the user's basket.
                       }
                   }
       */
            }
        }
    }

    private fun removeAds() {
        isRemoveAdsPurchased = true
        adView.visibility = View.GONE
        removeads.visibility = View.GONE
        tvRemoveAds.visibility = View.GONE

        logger("Purchase applied. ads removed")
    }


    private fun initUI() {


        factory = InjectorUtils.provideCalculatorViewModelFactory()
        viewModel = ViewModelProviders.of(this, factory)
            .get(CalculatorViewModel::class.java)


        val linearLayoutManager = LinearLayoutManager(
            this, RecyclerView.VERTICAL, false
        )
        rvFormatsToChoose.layoutManager = linearLayoutManager


        // Observe the model
        viewModel.getResultFormats().observe(this, Observer {
            rvFormatsToChoose.adapter = RvAdapterResultFormats(viewModel)
            Log.d("TAG", "changeFormat")
        })

        viewModel.getIsFormatsLayoutVisible().observe(this, Observer {
            if (it)
                formatsLayout.visibility = View.VISIBLE
            else
                formatsLayout.visibility = View.GONE
        })


        viewModel.getSelectedFormat().observe(this, Observer {

            Log.d("TAG", "changeFormat click")

            buttonFormats.text = it.textPresentationOfTokens.toHTMLWithLightGreenColor()

            val touchPointX = commonConstraintLayout.width / 2
            val touchPointY = commonConstraintLayout.height / 2

            if (formatsLayout.isAttachedToWindow && viewModel.getIsFormatsLayoutVisible().value!!) {
                Log.d("TAG", "changeFormat click ${formatsLayout.visibility == View.VISIBLE}")
                closeFormatsLayout(
                    touchPointX,
                    touchPointY
                )
            }

        })

        viewModel.getResultTokens().observe(
            this,
            Observer {

                tvOnlineResult.text = it?.toLightSpannableString()

                /*tokens ->
                               val stringBuilder = StringBuilder()
                               tokens. forEach{ quote ->
                                   stringBuilder.append("$quote\n\n")
                               }
                               textView_quotes.text = stringBuilder.toString()
               */
                // calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
            }
        )

        viewModel.getExpression().observe(
            this,
            Observer {
                tvExpressionField.text = it.toSpannableString()
                tvExpressionField.movementMethod = ScrollingMovementMethod()
                // tvExpressionField.setTextIsSelectable(true)

                /*val layout = tvExpressionField.getLayout()
                if (layout != null) {
                    val scrollDelta = (layout!!.getLineBottom(tvExpressionField.getLineCount() - 1)
                            - tvExpressionField.getScrollY() - tvExpressionField.getHeight())
                    if (scrollDelta > 0)
                        tvExpressionField.scrollBy(0, scrollDelta)
                }*/

                // tvExpressionField.scroll
            }
        )


        toolbarInitalize()
        fabInitalize()


        //nums
        buttonNum1.setOnClickListener {

            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "1"))
        }
        buttonNum2.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "2"))

        }
        buttonNum3.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "3"))

        }
        buttonNum4.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "4"))

        }
        buttonNum5.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "5"))

        }
        buttonNum6.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "6"))
        }
        buttonNum7.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "7"))
        }
        buttonNum8.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "8"))
        }
        buttonNum9.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "9"))
        }
        buttonNum0.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "0"))

        }
        buttonComma.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.DOT))

        }

        /// times
        buttonYear.setOnClickListener {

            viewModel.addToExpression(Token(type = TokenType.YEAR))
        }
        buttonMonth.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.MONTH))

        }
        buttonWeek.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.WEEK))

        }
        buttonDay.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.DAY))
        }
        buttonHour.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.HOUR))
        }
        buttonMinute.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.MINUTE))
        }
        buttonSecond.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.SECOND))
        }
        buttonMsec.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.MSECOND))
        }

        ///operations
        buttonMultiply.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.MULTIPLY))

        }
        buttonDivide.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.DIVIDE))

        }
        buttonSubstraction.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.MINUS))

        }
        buttonAddition.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.PLUS))

        }

        buttonDelete.setOnClickListener {
            viewModel.clearOneLastSymbol()
            //      Log.i("TAG","pressed delete")
        }

        buttonFormats.setOnClickListener {
            viewModel.updateResultFormats()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {


                //  forceRippleAnimation(tvOnlineResult)

                val location = IntArray(2)
                buttonFormats.getLocationOnScreen(location)

                val x = location[0] + buttonFormats.width / 2
                val y = location[1] + buttonFormats.height / 2

                val startRadius = 0
                val endRadius =
                    hypot(
                        commonConstraintLayout.width.toDouble(),
                        commonConstraintLayout.height.toDouble()
                    )
                        .toInt()

                val anim =
                    ViewAnimationUtils.createCircularReveal(
                        formatsLayout,
                        x,
                        y,
                        startRadius.toFloat(),
                        endRadius.toFloat()
                    ).apply {
                        interpolator = AccelerateDecelerateInterpolator()
                        duration = 600
                    }
                // make the view invisible when the animation is done
                /*    anim.addListener(object : AnimatorListenerAdapter() {

                        override fun onAnimationEnd(animation: Animator) {
                            super.onAnimationEnd(animation)
                            //           mainConstraintLayout.visibility = View.GONE

                            // viewModel.clearAll()
                        }
                    })*/
                viewModel.setIsFormatsLayoutVisible(true)
                formatsLayout.visibility = View.VISIBLE

                anim.start()


            } else {
                viewModel.setIsFormatsLayoutVisible(true)
                formatsLayout.visibility = View.VISIBLE

            }
        }

        buttonDelete.setOnLongClickListener {

            if (!viewModel.isExpressionEmpty()) {


                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {


                    //  forceRippleAnimation(tvOnlineResult)

                    val location = IntArray(2)
                    buttonDelete.getLocationOnScreen(location)

                    val x = location[0] + buttonDelete.width / 2
                    val y = tvOnlineResult.bottom

                    val startRadius = 0
                    val endRadius =
                        hypot(
                            tvExpressionField.width.toDouble(),
                            tvExpressionField.height.toDouble() + tvOnlineResult.height.toDouble() + buttonFormats.height.toDouble()
                        )
                            .toInt()

                    val anim =
                        ViewAnimationUtils.createCircularReveal(
                            tvFakeForClear,
                            x,
                            y,
                            startRadius.toFloat(),
                            endRadius.toFloat()
                        ).apply {
                            interpolator = AccelerateDecelerateInterpolator()
                            duration = 400
                        }
                    // make the view invisible when the animation is done
                    anim.addListener(object : AnimatorListenerAdapter() {

                        override fun onAnimationEnd(animation: Animator) {
                            super.onAnimationEnd(animation)
                            tvFakeForClear.visibility = View.GONE
                            viewModel.clearAll()
                        }
                    })
                    tvFakeForClear.visibility = View.VISIBLE
                    anim.start()

                } else
                    viewModel.clearAll()
            }
            true
        }


        buttonEqual.setOnClickListener {
            viewModel.sendResultToExpression()
            // calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())

        }


    }

    private fun fabInitalize() {
        if (!isRemoveAdsPurchased) {
            init(removeads)
            init(tvRemoveAds)


        }
        init(rateApp)
        init(tvRateApp)

        init(feedback)
        init(tvFeedback)



        fab.setOnClickListener {

            if (!fab.isExpanded) {
                fadeInFABs()
            } else {
                fadeOutFABs()
            }


            //  dimmedBackground.visibility = View.VISIBLE
            /*if (fab.isExpanded()) {//make the background visible

            } else {//make the background invisible
                dimmedBackground.visibility = View.GONE
            }*/

        }



        dimmedBackground.setOnClickListener {
            fadeOutFABs()
        }


        rateApp.setOnClickListener {
            fadeOutFABs()
            rateMeOnGooglePlay()

        }

        feedback.setOnClickListener {
            fadeOutFABs()
            sendFeedback()

        }


    }

    private fun sendFeedback() {


        val intent = Intent(Intent.ACTION_SENDTO).apply {
            data = Uri.parse("mailto:") // only email apps should handle this
            putExtra(Intent.EXTRA_EMAIL, arrayOf("dmitrii.kargashin@cardamon.org"))
            //intent.setData(Uri.parse("mailto:dmitrii.kargashin@cardamon.org"))
            putExtra(Intent.EXTRA_SUBJECT, "Feedback Time Calculator Cardamon ${BuildConfig.VERSION_CODE}")
        }
        if (intent.resolveActivity(packageManager) != null) {
            startActivity(intent)
        }



    }


    private fun fadeInFABs() {
        fadeIn()
        if (!isRemoveAdsPurchased) {
            showIn(removeads, -removeads.height.toFloat())
            showIn(tvRemoveAds, -removeads.height.toFloat())
        }
        showIn(rateApp, -rateApp.height.toFloat())
        showIn(tvRateApp, -rateApp.height.toFloat())
        showIn(feedback, -feedback.height.toFloat())
        showIn(tvFeedback, -feedback.height.toFloat())


        fab.isExpanded = true
        fab.setImageResource(R.drawable.ic_close_white_24dp)
    }


    private fun fadeOutFABs() {

        fadeOut()
        if (!isRemoveAdsPurchased) {
            showOut(removeads, -removeads.height.toFloat())
            showOut(tvRemoveAds, -removeads.height.toFloat())
        }
        showOut(rateApp, -rateApp.height.toFloat())
        showOut(tvRateApp, -rateApp.height.toFloat())
        showOut(feedback, -feedback.height.toFloat())
        showOut(tvFeedback, -feedback.height.toFloat())


        fab.isExpanded = false
        fab.setImageResource(R.drawable.ic_menu_white_24dp)
    }


    //crossfade animation for background
    private fun fadeIn() {
        dimmedBackground.apply {
            // Set the content view to 0% opacity but visible, so that it is visible
            // (but fully transparent) during the animation.
            alpha = 0f
            visibility = View.VISIBLE

            // Animate the content view to 100% opacity, and clear any animation
            // listener set on the view.
            animate()
                .alpha(1f)
                .setDuration(100)
                .setListener(null)
        }
        // Animate the loading view to 0% opacity. After the animation ends,
        // set its visibility to GONE as an optimization step (it won't
        /*     // participate in layout passes, etc.)
         dimmedBackground.animate()
                 .alpha(0f)
                 .setDuration(1)
                 .setListener(object : AnimatorListenerAdapter() {
                     override fun onAnimationEnd(animation: Animator) {
                         dimmedBackground.visibility = View.VISIBLE
                     }
                 })*/
    }


    private fun fadeOut() {
        dimmedBackground.apply {
            // Set the content view to 0% opacity but visible, so that it is visible
            // (but fully transparent) during the animation.
            //   alpha = 0f
            // visibility = View.VISIBLE

            // Animate the content view to 100% opacity, and clear any animation
            // listener set on the view.
            animate()
                .alpha(0f)
                .setDuration(100)
                .setListener(object : AnimatorListenerAdapter() {
                    override fun onAnimationEnd(animation: Animator) {
                        dimmedBackground.visibility = View.GONE
                    }
                })
        }
        // Animate the loading view to 0% opacity. After the animation ends,
        // set its visibility to GONE as an optimization step (it won't
        /*     // participate in layout passes, etc.)
         dimmedBackground.animate()
                 .alpha(0f)
                 .setDuration(1)
                 .setListener(object : AnimatorListenerAdapter() {
                     override fun onAnimationEnd(animation: Animator) {
                         dimmedBackground.visibility = View.VISIBLE
                     }
                 })*/
    }


    private fun showIn(v: View, startPosition: Float) {
        v.visibility = View.VISIBLE
        v.alpha = 0f
        v.translationY = startPosition
        v.animate()
            .setDuration(200)
            .translationY(0f)
            .setListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    super.onAnimationEnd(animation)
                }
            })
            .alpha(1f)
            .start()
    }

    private fun showOut(v: View, endPosition: Float) {
        v.visibility = View.VISIBLE
        v.alpha = 1f
        v.translationY = 0f
        v.animate()
            .setDuration(200)
            .translationY(endPosition)
            .setListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    v.visibility = View.GONE
                    super.onAnimationEnd(animation)
                }
            }).alpha(0f)
            .start()
    }

    private fun init(v: View) {
        v.visibility = View.INVISIBLE
        //v.translationY = -v.height.toFloat()
        //  v.alpha = 0f
    }


    private fun toolbarInitalize() {
        toolbar.setNavigationOnClickListener {

            closeFormatsLayout(10, 10)


            // back button pressed

        }


    }

    private fun closeFormatsLayout(x: Int, y: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {


            /*  val x = 10
              val y = 10*/

            val endRadius = 0
            val startRadius =
                hypot(
                    commonConstraintLayout.width.toDouble(),
                    commonConstraintLayout.height.toDouble()
                )
                    .toInt()

            val anim =
                ViewAnimationUtils.createCircularReveal(
                    formatsLayout,
                    x,
                    y,
                    startRadius.toFloat(),
                    endRadius.toFloat()
                ).apply {
                    interpolator = AccelerateDecelerateInterpolator()
                    duration = 450
                }
            // make the view invisible when the animation is done
            anim.addListener(object : AnimatorListenerAdapter() {

                override fun onAnimationEnd(animation: Animator) {
                    super.onAnimationEnd(animation)
                    viewModel.setIsFormatsLayoutVisible(false)
                    formatsLayout.visibility = View.GONE

                    //  viewModel.clearAll()
                }
            })
            //       formatsLayout = View.GONE


            anim.start()

        } else {
            viewModel.setIsFormatsLayoutVisible(false)
            formatsLayout.visibility = View.GONE

        }
    }

/*  override fun onTouchEvent(event: MotionEvent?): Boolean {
      if (event?.actionMasked == MotionEvent.ACTION_UP) {
          lastTouchDownXY[0] = event.x.toInt()
          lastTouchDownXY[1] = event.y.toInt()
          Log.i("TAG", "onLongClick: x = {$event.x}, y = {$event.y}")

      }
      return super.onTouchEvent(event)
  }*/


/*  var clickListener: View.OnClickListener = View.OnClickListener {
      // retrieve the stored coordinates
      val x = lastTouchDownXY[0]
      val y = lastTouchDownXY[1]

      // use the coordinates for whatever

      Log.i("TAG", "onLongClick: x = $x, y = $y")
  }*/

/*
    protected fun forceRippleAnimation(view: View) {
        val background = view.getBackground()

        if (Build.VERSION.SDK_INT >= 21 && background is RippleDrawable) {
            val rippleDrawable = background as RippleDrawable

            rippleDrawable.state = intArrayOf(android.R.attr.state_pressed, android.R.attr.state_enabled)

            val handler = Handler()

            handler.postDelayed(Runnable { rippleDrawable.state = intArrayOf() }, 0)
        }
    }*/
}


