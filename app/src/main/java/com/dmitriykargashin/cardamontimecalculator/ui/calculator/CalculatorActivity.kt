/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.ui.calculator


import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.text.method.ScrollingMovementMethod
import android.util.Log
import android.view.MotionEvent
import android.view.View
import android.view.ViewAnimationUtils
import android.view.animation.AccelerateDecelerateInterpolator
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.RadioButton
import android.widget.RadioGroup
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.app.AppCompatDelegate
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
import com.dmitriykargashin.cardamontimecalculator.utilites.InjectorUtils
import com.google.android.material.snackbar.Snackbar
import com.suddenh4x.ratingdialog.AppRating
import com.suddenh4x.ratingdialog.preferences.MailSettings
import com.suddenh4x.ratingdialog.preferences.RatingThreshold
import hotchemi.android.rate.AppRate
import hotchemi.android.rate.StoreType
import kotlinx.android.synthetic.main.activity_main.*
import kotlinx.android.synthetic.main.view_formats.*
import kotlinx.android.synthetic.main.view_per.*
import kotlinx.android.synthetic.main.view_settings.*
import kotlinx.android.synthetic.main.view_support_app.*
import kotlin.math.hypot


class CalculatorActivity : AppCompatActivity(), PurchasesUpdatedListener {


    private lateinit var factory: CalculatorViewModelFactory
    lateinit var viewModel: CalculatorViewModel
    private val TAG = "CalculatorActivity"

    // private var isRemoveAdsPurchased = false

    private lateinit var billingClient: BillingClient
    private val skuList = listOf(
        "support_1",
        "support_3",
        "support_5",
        "support_9",
//        "support_15",
//        "support_29",
        "remove_ads"
    )


    // Called when leaving the activity
    public override fun onPause() {

        super.onPause()


    }

    // Called when returning to the activity
    public override fun onResume() {
        super.onResume()
        checkPurchases()

//        if (!isPaidVersion() && !isRemoveAdsPurchased) {
//            //adView.resume()
//        }
    }

    // Called before the activity is destroyed
    public override fun onDestroy() {
//        if (!isPaidVersion() && !isRemoveAdsPurchased) {
//            //   adView.destroy()
//        }
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
        logger("purchase isPaidVersion ${isPaidVersion()}")
        if (!isPaidVersion()) {

            setupBillingClient()
            logger("end Setup Billing")

            /* MobileAds.initialize(this)
              val adRequest =
                  AdRequest.Builder().addTestDevice("C38113ED0332D64C52D625B7ED43DDED").build()
              adView.loadAd(adRequest)*/


        } //else adView.visibility = View.GONE

        initUI()

        if (savedInstanceState == null) {
            rateBuilder()
                .showRateNeverButtonAfterNTimes(
                    R.string.never_show_ratetheapp,
                    null,
                    3
                ) // by default the button is hidden
                .showIfMeetsConditions()
        }
        // setupRateMe()

    }

    private fun rateBuilder(): AppRating.Builder {

        return AppRating.Builder(this)
            .setMinimumLaunchTimes(5)
            .setMinimumDays(7)
            .setMinimumLaunchTimesToShowAgain(5)
            .setMinimumDaysToShowAgain(10)
            // .setCustomTheme(R.style.RateTheme)
            .setRatingThreshold(RatingThreshold.FOUR)
            .setShowOnlyFullStars(true)

            .setTitleTextId(R.string.rate_main_text)
            .setMessageTextId(R.string.rate_second_text) // by default no message is shown

//                .setStoreRatingTitleTextId(storeRatingTitleTextId: Int)
            .setStoreRatingMessageTextId(R.string.rate_store_second_text)
            .setMailFeedbackMessageTextId(R.string.rate_feedback_main_text)

            .setMailSettingsForFeedbackDialog(
                MailSettings(
                    mailAddress = "support@cardamon.org",
                    subject = "Feedback Time Calculator Cardamon v.${BuildConfig.VERSION_CODE}"
                )
            )
    }

//    private fun setupRateMe() {
//        AppRate.with(this)
//            .setStoreType(StoreType.GOOGLEPLAY) //default is Google, other option is Amazon
//            .setInstallDays(10) // default 10, 0 means install day.
//            .setLaunchTimes(10) // default 10 times.
//            .setRemindInterval(2) // default 1 day.
//            .setShowLaterButton(true) // default true.
//            .setDebug(false) // default false.
//            .setCancelable(false) // default false.
//            .setOnClickButtonListener {
//                if (it == 0) rateMeOnGooglePlay() // 0 index of rate me button
//            }
//
//            .setMessage(R.string.new_rate_dialog_message)
//
//            .monitor()
//
//        AppRate.showRateDialogIfMeetsConditions(this)
//
//    }

//
//    private fun rateMeOnGooglePlay() {
//        try {
//            startActivity(
//                Intent(
//                    Intent.ACTION_VIEW,
//                    Uri.parse("market://details?id=$packageName")
//                )
//            )
//        } catch (e: ActivityNotFoundException) {
//            startActivity(
//                Intent(
//                    Intent.ACTION_VIEW,
//                    Uri.parse("http://play.google.com/store/apps/details?id=$packageName")
//                )
//            )
//        }
//
//    }

    private fun isPaidVersion() = BuildConfig.PRO_VERSION


    override fun onBackPressed() {
        when {
            viewModel.getIsFormatsLayoutVisible().value!! -> closeFormatsLayout(10, 10)
            viewModel.getIsPerLayoutVisible().value!! -> closePerLayout(10, 10)
            viewModel.getIsSupportAppLayoutVisible().value!! -> closeSupport_appLayout(10, 10)
            viewModel.getIsSettingsLayoutVisible().value!! -> closeSettingsLayout(10, 10)
            else -> moveTaskToBack(true)
        }
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

        logger("loadAllSKUs")
        billingClient.querySkuDetailsAsync(params) { billingResult, skuDetailsList ->
            // Process the result.
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && skuDetailsList?.isNotEmpty()!!) {
                for (skuDetails in skuDetailsList) {
                    if (skuDetails.sku == "remove_ads" || skuDetails.sku == "support_3")
                        btnSupport3.setOnClickListener {
                            //  logger("press button to buy")
                            val billingFlowParams = BillingFlowParams
                                .newBuilder()
                                .setSkuDetails(skuDetails)
                                .build()
                            billingClient.launchBillingFlow(this, billingFlowParams)
                        }

                    if (skuDetails.sku == "support_1")
                        btnSupport1.setOnClickListener {
                            //  logger("press button to buy")
                            val billingFlowParams = BillingFlowParams
                                .newBuilder()
                                .setSkuDetails(skuDetails)
                                .build()
                            billingClient.launchBillingFlow(this, billingFlowParams)
                        }

                    if (skuDetails.sku == "support_5")
                        btnSupport5.setOnClickListener {
                            //  logger("press button to buy")
                            val billingFlowParams = BillingFlowParams
                                .newBuilder()
                                .setSkuDetails(skuDetails)
                                .build()
                            billingClient.launchBillingFlow(this, billingFlowParams)
                        }


                    if (skuDetails.sku == "support_9")
                        btnSupport9.setOnClickListener {
                            //  logger("press button to buy")
                            val billingFlowParams = BillingFlowParams
                                .newBuilder()
                                .setSkuDetails(skuDetails)
                                .build()
                            billingClient.launchBillingFlow(this, billingFlowParams)
                        }

//                    if (skuDetails.sku == "support_15")
//                        btnSupport.setOnClickListener {
//                            //  logger("press button to buy")
//                            val billingFlowParams = BillingFlowParams
//                                .newBuilder()
//                                .setSkuDetails(skuDetails)
//                                .build()
//                            billingClient.launchBillingFlow(this, billingFlowParams)
//                        }


//                    if (skuDetails.sku == "support_29")
//                        btnSupport29.setOnClickListener {
//                            //  logger("press button to buy")
//                            val billingFlowParams = BillingFlowParams
//                                .newBuilder()
//                                .setSkuDetails(skuDetails)
//                                .build()
//                            billingClient.launchBillingFlow(this, billingFlowParams)
//                        }

                    logger("details " + skuDetails.description)
                }
            }
            logger("details " + skuDetailsList.toString())
            //    logger("details "+skuDetails.description)

        }

    } else {
        logger("Billing Client not ready")
    }


    override fun onPurchasesUpdated(p0: BillingResult, purchases: MutableList<Purchase>?) {
        if (p0?.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
            for (purchase in purchases) {
                acknowledgePurchase(purchase.purchaseToken)
                handlePurchase(purchase)

            }
        } else if (p0?.responseCode == BillingClient.BillingResponseCode.USER_CANCELED) {
            // Handle an error caused by a user cancelling the purchase flow.
            logger("User Cancelled")
            logger(p0.debugMessage.toString())


        } else {
            logger("other error")
            logger(p0?.debugMessage.toString())

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
// user has any purchase
            buttonFood.setImageResource(R.drawable.ic_food);

        } else {// user dont have any purchase
            buttonFood.setImageResource(R.drawable.ic_food_checked);

//            MobileAds.initialize(this)
//            val adRequest =
//                AdRequest.Builder().addTestDevice("C38113ED0332D64C52D625B7ED43DDED").build()
//            adView.loadAd(adRequest)

            /////    removeAds()

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
            if (purchase.sku == "remove_ads" || purchase.sku == "support_3") {
                //    removeAds()
// Grant the item to the user, and then acknowledge the purchase
                imageStar3.visibility = View.VISIBLE
                btnSupport3.isEnabled = false
                btnSupport3.alpha = 0.5f

            }

            if (purchase.sku == "support_1") {
                //    removeAds()
// Grant the item to the user, and then acknowledge the purchase
                imageStar1.visibility = View.VISIBLE
                btnSupport1.isEnabled = false
                btnSupport1.alpha = 0.5f

            }

            if (purchase.sku == "support_5") {
                //    removeAds()
// Grant the item to the user, and then acknowledge the purchase
                imageStar5.visibility = View.VISIBLE
                btnSupport5.isEnabled = false
                btnSupport5.alpha = 0.5f

            }

            if (purchase.sku == "support_9") {
                //    removeAds()
// Grant the item to the user, and then acknowledge the purchase
                imageStar9.visibility = View.VISIBLE
                btnSupport9.isEnabled = false
                btnSupport9.alpha = 0.5f

            }


//            if (purchase.sku == "support_15") {
//                //    removeAds()
//// Grant the item to the user, and then acknowledge the purchase
//                imageStar15.visibility = View.VISIBLE
//                btnSupport15.isEnabled = false
//                btnSupport15.alpha = 0.5f
//
//            }
//
//
//            if (purchase.sku == "support_29") {
//                //    removeAds()
//// Grant the item to the user, and then acknowledge the purchase
//                imageStar29.visibility = View.VISIBLE
//                btnSupport29.isEnabled = false
//                btnSupport29.alpha = 0.5f
//
//            }
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


    private fun initUI() {
        setSupportActionBar(toolbarSupport_app)
        setSupportActionBar(toolbarPer)
        setSupportActionBar(toolbar)
        factory = InjectorUtils.provideCalculatorViewModelFactory(baseContext)
        viewModel = ViewModelProviders.of(this, factory)
            .get(CalculatorViewModel::class.java)


        val linearLayoutManager = LinearLayoutManager(
            this, RecyclerView.VERTICAL, false
        )

        val linearLayoutManager2 = LinearLayoutManager(
            this, RecyclerView.VERTICAL, false
        )
        rvFormatsToChoose.layoutManager = linearLayoutManager
        rvPer.layoutManager = linearLayoutManager2


        // Observe the model
        viewModel.getResultFormats().observe(this, Observer {
            rvFormatsToChoose.adapter = RvAdapterResultFormats(viewModel, baseContext)
            Log.d("TAG", "changeFormat")
        })


        viewModel.getPerUnits().observe(this, Observer {
            rvPer.adapter = RvAdapterPer(viewModel)

//            etUnit.text.append   (it?.unitName)
//            etUnitAmount.text.append (it?.amount?.stripTrailingZeros().toString())

//            etUnit.setText(it?.unitName)
//            etUnitAmount.setText(it?.amount?.stripTrailingZeros().toString())

            //Log.d("TAG", "changeFormat")
        })

        viewModel.getIsFormatsLayoutVisible().observe(this, Observer {
            logger("savestate IsFormatsLayout $it")
            if (it)
                formatsLayout.visibility = View.VISIBLE
            else
                formatsLayout.visibility = View.GONE
        })


        viewModel.getIsPerViewButtonDisabled().observe(this, Observer {
            if (it) {
                buttonPer.isEnabled = false
                buttonPer.isClickable = false
                buttonPer.alpha = 0.2f


            } else {
                buttonPer.isEnabled = true
                buttonPer.isClickable = true
                buttonPer.alpha = 1.0f
            }
        })


        viewModel.getIsFormatsViewButtonDisabled().observe(this, Observer {
            if (it) {
                buttonFormats.isEnabled = false
                buttonFormats.isClickable = false
                buttonFormats.alpha = 0.2f


            } else {
                buttonFormats.isEnabled = true
                buttonFormats.isClickable = true
                buttonFormats.alpha = 1.0f
            }
        })

        viewModel.getIsPerLayoutVisible().observe(this, Observer {
            if (it)
                perLayout.visibility = View.VISIBLE
            else
                perLayout.visibility = View.GONE
        })

        viewModel.getIsSupportAppLayoutVisible().observe(this, Observer {
            if (it)
                support_appLayout.visibility = View.VISIBLE
            else
                support_appLayout.visibility = View.GONE
        })


        viewModel.getIsSettingsLayoutVisible().observe(this, Observer {
            if (it)
                settingsLayout.visibility = View.VISIBLE
            else
                settingsLayout.visibility = View.GONE
        })



        viewModel.getSelectedFormat().observe(this, Observer {

            Log.d("TAG", "changeFormat click")

            tvFormats.text = (it.textPresentationOfTokens)//.toHTMLBlackColor()

            val touchPointX = commonConstraintLayout.width / 2
            val touchPointY = commonConstraintLayout.height / 2

            if (formatsLayout.isAttachedToWindow && viewModel.getIsFormatsLayoutVisible().value!!) {
                // Log.d("TAG", "changeFormat click ${formatsLayout.visibility == View.VISIBLE}")
                closeFormatsLayout(
                    touchPointX,
                    touchPointY
                )
            }

        })

        viewModel.getResultTokens().observe(
            this,
            Observer {

                tvOnlineResult.text = it?.toLightSpannableString(baseContext)
                rvPer.adapter = RvAdapterPer(viewModel)

                // add result to ViewPer view
                labelTimeIntervalAmount.text = it?.toSpannableString(baseContext)


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
                tvExpressionField.text = it.toSpannableString(baseContext)
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

        btnSupportRate.setOnClickListener {
            //  logger("press button to buy")
            rateBuilder()
                .dontCountThisAsAppLaunch()
                .showNow();
        }


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
            viewModel.clearOneLastSymbol(baseContext)
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
//                    anim.addListener(object : AnimatorListenerAdapter() {
//
//                        override fun onAnimationEnd(animation: Animator) {
//                            super.onAnimationEnd(animation)
//                            window.statusBarColor = ContextCompat.getColor(applicationContext, R.color.colorSecondaryBackground)
//                            //           mainConstraintLayout.visibility = View.GONE
//
//                            // viewModel.clearAll()
//                        }
//                    })
                viewModel.setIsFormatsLayoutVisible(true)
                formatsLayout.visibility = View.VISIBLE

                anim.start()


            } else {
                viewModel.setIsFormatsLayoutVisible(true)
                formatsLayout.visibility = View.VISIBLE

            }
        }


        buttonPer.setOnClickListener {
            viewModel.updatePerUnits()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {


                //  forceRippleAnimation(tvOnlineResult)

                val location = IntArray(2)
                buttonPer.getLocationOnScreen(location)

                val x = location[0] + buttonPer.width / 2
                val y = location[1] + buttonPer.height / 2

                val startRadius = 0
                val endRadius =
                    hypot(
                        commonConstraintLayout.width.toDouble(),
                        commonConstraintLayout.height.toDouble()
                    )
                        .toInt()

                val anim =
                    ViewAnimationUtils.createCircularReveal(
                        perLayout,
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
                viewModel.setIsPerLayoutVisible(true)
                perLayout.visibility = View.VISIBLE

                anim.start()


            } else {
                viewModel.setIsPerLayoutVisible(true)
                perLayout.visibility = View.VISIBLE

            }
        }



        buttonFood.setOnClickListener {
            //   viewModel.updateResultFormats()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {


                //  forceRippleAnimation(tvOnlineResult)

                val location = IntArray(2)
                buttonFood.getLocationOnScreen(location)

                val x = location[0] + buttonFood.width / 2
                val y = location[1] + buttonFood.height / 2

                val startRadius = 0
                val endRadius =
                    hypot(
                        commonConstraintLayout.width.toDouble(),
                        commonConstraintLayout.height.toDouble()
                    )
                        .toInt()

                val anim =
                    ViewAnimationUtils.createCircularReveal(
                        support_appLayout,
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
                viewModel.setIsSupportAppLayoutVisible(true)
                support_appLayout.visibility = View.VISIBLE

                anim.start()


            } else {
                viewModel.setIsSupportAppLayoutVisible(true)
                support_appLayout.visibility = View.VISIBLE

            }
        }



        buttonSettings.setOnClickListener {
            //   viewModel.updateResultFormats()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {


                //  forceRippleAnimation(tvOnlineResult)

                val location = IntArray(2)
                buttonSettings.getLocationOnScreen(location)

                val x = location[0] + buttonSettings.width / 2
                val y = location[1] + buttonSettings.height / 2

                val startRadius = 0
                val endRadius =
                    hypot(
                        commonConstraintLayout.width.toDouble(),
                        commonConstraintLayout.height.toDouble()
                    )
                        .toInt()

                val anim =
                    ViewAnimationUtils.createCircularReveal(
                        settingsLayout,
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
                viewModel.setIsSettingsLayoutVisible(true)
                settingsLayout.visibility = View.VISIBLE

                anim.start()


            } else {
                viewModel.setIsSettingsLayoutVisible(true)
                settingsLayout.visibility = View.VISIBLE

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
                            tvExpressionField.height.toDouble() + tvOnlineResult.height.toDouble()
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


        buttonFeedback_Sendfeedback.setOnClickListener {
            sendFeedback()
        }


        etUnitAmount.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_DONE) {
                // Call your code here
                //   viewModel.updateSettingsForPerUnits(etUnitAmount.text.toString().toBigDecimal(),etUnit.text.toString())
                hideKeyboard()
                true
            }
            false
        }

        etUnit.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_DONE) {
                // Call your code here
                //viewModel.updateSettingsForPerUnits(etUnitAmount.text.toString().toBigDecimal(),etUnit.text.toString())
                hideKeyboard()


                true
            }
            false
        }

//        viewModel.getPerUnits().observe(
//            this,
//            Observer {
//                rvPer.refreshDrawableState()
//
//            }
//        )


        toolbarInitalize()


        etUnitAmount.addTextChangedListener(object : TextWatcher {

            override fun afterTextChanged(s: Editable) {
                //  viewModel.updateSettingsForPerUnits(s.toString().toBigDecimal(),etUnit.text.toString())
            }

            override fun beforeTextChanged(
                s: CharSequence, start: Int,
                count: Int, after: Int
            ) {
            }

            override fun onTextChanged(
                s: CharSequence, start: Int,
                before: Int, count: Int
            ) {
                if (s.length > 0 && !etUnit.text.isEmpty()) {
                    viewModel.updateSettingsForPerUnits(
                        s.toString().toBigDecimal(),
                        etUnit.text.toString()
                    )
                    rvPer.visibility = View.VISIBLE
                } else rvPer.visibility = View.INVISIBLE
            }
        })

        etUnit.addTextChangedListener(object : TextWatcher {

            override fun afterTextChanged(s: Editable) {
                //    viewModel.updateSettingsForPerUnits(etUnitAmount.text.toString().toBigDecimal(),s.toString())

            }

            override fun beforeTextChanged(
                s: CharSequence, start: Int,
                count: Int, after: Int
            ) {
            }

            override fun onTextChanged(
                s: CharSequence, start: Int,
                before: Int, count: Int
            ) {
                if (s.length > 0 && !etUnitAmount.text.isEmpty()) {
                    viewModel.updateSettingsForPerUnits(
                        etUnitAmount.text.toString().toBigDecimal(), s.toString()
                    )

                    // if (!etUnitAmount.text.isEmpty())
                    rvPer.visibility = View.VISIBLE

                } else
                    rvPer.visibility = View.INVISIBLE
            }
        })






        viewModel.getPrefThemeColor().observe(
            this,
            {

                when (it) {
                    "0" -> {
                        AppCompatDelegate.setDefaultNightMode(
                            AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM
                        )
                        if (!rbTheme_SystemDefault.isChecked) rbTheme_SystemDefault.isChecked = true
                    }
                    "1" -> {
                        AppCompatDelegate.setDefaultNightMode(
                            AppCompatDelegate.MODE_NIGHT_NO
                        )

                        if (!rbTheme_Light.isChecked) rbTheme_Light.isChecked = true
                    }

                    "2" -> {
                        AppCompatDelegate.setDefaultNightMode(
                            AppCompatDelegate.MODE_NIGHT_YES
                        )
                        if (!rbTheme_Dark.isChecked) rbTheme_Dark.isChecked = true
                    }
                    else -> {
                        AppCompatDelegate.setDefaultNightMode(
                            AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM
                        )
                        if (!rbTheme_SystemDefault.isChecked) rbTheme_SystemDefault.isChecked = true
                    }

                }

                logger("theme -  $it")
            }
        )


    }


    fun onRadioButtonClicked(view: View) {
        if (view is RadioButton) {
            // Is the button now checked?
            val checked = view.isChecked

            // Check which radio button was clicked
            when (view.getId()) {
                R.id.rbTheme_SystemDefault ->
                    if (checked) {
                        viewModel.setPrefThemeColor("0")

                    }
                R.id.rbTheme_Light ->
                    if (checked) {
                        viewModel.setPrefThemeColor("1")
                    }

                R.id.rbTheme_Dark ->
                    if (checked) {
                        viewModel.setPrefThemeColor("2")
                    }
            }
        }
    }


    private fun sendFeedback() {

        logger("theme - sendFeedback")
        val intent = Intent(Intent.ACTION_SENDTO).apply {
            data = Uri.parse("mailto:") // only email apps should handle this
            putExtra(Intent.EXTRA_EMAIL, arrayOf("support@cardamon.org"))
            //intent.setData(Uri.parse("mailto:dmitrii.kargashin@cardamon.org"))
            putExtra(
                Intent.EXTRA_SUBJECT,
                "Feedback Time Calculator Cardamon ${BuildConfig.VERSION_CODE}"
            )
        }
        if (intent.resolveActivity(packageManager) != null) {
            startActivity(intent)
        }


    }


    private fun init(v: View) {
        v.visibility = View.INVISIBLE
        //v.translationY = -v.height.toFloat()
        //  v.alpha = 0f
    }


    private fun toolbarInitalize() {
        //   buttonPer.text = buttonPer.text.toString().toHTMLWithLightGreenColor()


        toolbar.setNavigationOnClickListener {
            closeFormatsLayout(10, 10)
            // back button pressed

        }
        toolbarPer.setNavigationOnClickListener {
            closePerLayout(10, 10)
            // back button pressed
        }

        toolbarSupport_app.setNavigationOnClickListener {
            closeSupport_appLayout(10, 10)
            // back button pressed
        }

        toolbarSettings.setNavigationOnClickListener {
            closeSettingsLayout(10, 10)
            // back button pressed
        }

    }


    override fun dispatchTouchEvent(ev: MotionEvent?): Boolean {
        hideKeyboard()
        return super.dispatchTouchEvent(ev)
    }

    private fun hideKeyboard() {
        if (currentFocus != null) {
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
            imm.hideSoftInputFromWindow(currentFocus!!.windowToken, 0)
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


    private fun closePerLayout(x: Int, y: Int) {
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
                    perLayout,
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
                    viewModel.setIsPerLayoutVisible(false)
                    perLayout.visibility = View.GONE

                    //  viewModel.clearAll()
                }
            })
            //       formatsLayout = View.GONE


            anim.start()

        } else {
            viewModel.setIsPerLayoutVisible(false)
            perLayout.visibility = View.GONE

        }
    }


    private fun closeSupport_appLayout(x: Int, y: Int) {
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
                    support_appLayout,
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
                    viewModel.setIsSupportAppLayoutVisible(false)
                    support_appLayout.visibility = View.GONE

                    //  viewModel.clearAll()
                }
            })
            //       formatsLayout = View.GONE


            anim.start()

        } else {
            viewModel.setIsSupportAppLayoutVisible(false)
            support_appLayout.visibility = View.GONE

        }
    }


    private fun closeSettingsLayout(x: Int, y: Int) {
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
                    settingsLayout,
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
                    viewModel.setIsSettingsLayoutVisible(false)
                    settingsLayout.visibility = View.GONE

                    //  viewModel.clearAll()
                }
            })
            //       formatsLayout = View.GONE


            anim.start()

        } else {
            viewModel.setIsSettingsLayoutVisible(false)
            settingsLayout.visibility = View.GONE

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


