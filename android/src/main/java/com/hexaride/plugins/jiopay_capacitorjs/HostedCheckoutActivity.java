package com.hexaride.plugins.jiopay_capacitorjs;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebResourceRequest;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.ProgressBar;
import androidx.activity.OnBackPressedCallback;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;

/**
 * Hosts JioPay's checkout page in an embedded WebView so navigation can be
 * intercepted: landing on a URL starting with returnUrlPrefix means the
 * gateway flow is done, and any non-http(s) URL (upi://, gpay://, etc.) is
 * handed off via ACTION_VIEW so installed UPI apps still get invoked the way
 * they would in a real browser.
 */
public class HostedCheckoutActivity extends AppCompatActivity {

    static final String EXTRA_CHECKOUT_URL = "checkoutUrl";
    static final String EXTRA_RETURN_URL_PREFIX = "returnUrlPrefix";
    static final String EXTRA_SHOW_APP_BAR = "showAppBar";
    static final String EXTRA_HEADER_COLOR = "headerColor";
    static final String EXTRA_LANDED_URL = "landedUrl";
    private static final String DEFAULT_HEADER_COLOR = "#F9A000";

    private WebView webView;
    private ProgressBar progressBar;

    @SuppressLint("SetJavaScriptEnabled")
    @SuppressWarnings("deprecation") // setStatusBarColor: still the correct way to tint the bar on pre-edge-to-edge Android
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        String checkoutUrl = getIntent().getStringExtra(EXTRA_CHECKOUT_URL);
        String returnUrlPrefix = getIntent().getStringExtra(EXTRA_RETURN_URL_PREFIX);
        boolean showAppBar = getIntent().getBooleanExtra(EXTRA_SHOW_APP_BAR, false);
        String headerColorHex = getIntent().getStringExtra(EXTRA_HEADER_COLOR);
        if (checkoutUrl == null) {
            setResult(Activity.RESULT_CANCELED);
            finish();
            return;
        }

        int headerColor;
        try {
            headerColor = Color.parseColor(headerColorHex != null ? headerColorHex : DEFAULT_HEADER_COLOR);
        } catch (IllegalArgumentException e) {
            headerColor = Color.parseColor(DEFAULT_HEADER_COLOR);
        }

        // AppCompatActivity shows the app's default ActionBar unless told
        // otherwise — we only extend it for getOnBackPressedDispatcher() and
        // (optionally) this bar, so hide it entirely unless showAppBar asked
        // for it, and wire its Up button to the same back/close logic as the
        // system back button.
        if (getSupportActionBar() != null) {
            if (showAppBar) {
                getSupportActionBar().setDisplayHomeAsUpEnabled(true);
                getSupportActionBar().setBackgroundDrawable(new ColorDrawable(headerColor));
            } else {
                getSupportActionBar().hide();
            }
        }

        getWindow().setStatusBarColor(headerColor);
        WindowInsetsControllerCompat insetsController = WindowCompat.getInsetsController(getWindow(), getWindow().getDecorView());
        insetsController.setAppearanceLightStatusBars(isColorLight(headerColor));

        webView = new WebView(this);
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setDomStorageEnabled(true);
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                String url = request.getUrl().toString();

                if (returnUrlPrefix != null && url.startsWith(returnUrlPrefix)) {
                    finishWithResult(url);
                    return true;
                }

                if (!url.startsWith("http://") && !url.startsWith("https://")) {
                    try {
                        startActivity(new Intent(Intent.ACTION_VIEW, request.getUrl()));
                    } catch (ActivityNotFoundException e) {
                        // No app installed to handle this URI (e.g. that UPI
                        // app isn't installed) — nothing more we can do.
                    }
                    return true;
                }

                return false;
            }

            @Override
            public void onPageStarted(WebView view, String url, Bitmap favicon) {
                // shouldOverrideUrlLoading is never called for POST navigations
                // (e.g. bank/ACS pages that auto-submit a form back to the
                // return URL), so the prefix check is duplicated here since
                // onPageStarted fires regardless of GET/POST.
                if (returnUrlPrefix != null && url.startsWith(returnUrlPrefix)) {
                    finishWithResult(url);
                    return;
                }
                progressBar.setVisibility(View.VISIBLE);
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                progressBar.setVisibility(View.GONE);
            }
        });

        FrameLayout root = new FrameLayout(this);
        root.addView(webView, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

        progressBar = new ProgressBar(this);
        FrameLayout.LayoutParams progressParams = new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        );
        progressParams.gravity = Gravity.CENTER;
        root.addView(progressBar, progressParams);

        // Apps targeting SDK 35+ draw edge-to-edge by default, so with the
        // ActionBar hidden nothing else reserves space for the status/nav
        // bars — pad the root view by the system bar insets ourselves
        // (mirrors what JioPay's own PaymentActivity does for the same
        // reason).
        ViewCompat.setOnApplyWindowInsetsListener(root, (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        setContentView(root);
        webView.loadUrl(checkoutUrl);

        getOnBackPressedDispatcher()
            .addCallback(
                this,
                new OnBackPressedCallback(true) {
                    @Override
                    public void handleOnBackPressed() {
                        handleBackOrClose();
                    }
                }
            );
    }

    private static boolean isColorLight(int color) {
        double luminance = (0.299 * Color.red(color) + 0.587 * Color.green(color) + 0.114 * Color.blue(color)) / 255;
        return luminance > 0.5;
    }

    @Override
    public boolean onSupportNavigateUp() {
        handleBackOrClose();
        return true;
    }

    private void handleBackOrClose() {
        if (webView.canGoBack()) {
            webView.goBack();
        } else {
            confirmClose();
        }
    }

    private void confirmClose() {
        new AlertDialog.Builder(this)
            .setTitle("Cancel payment?")
            .setMessage("Are you sure you want to leave? Your payment will not be completed.")
            .setPositiveButton("Leave", (dialog, which) -> {
                setResult(Activity.RESULT_CANCELED);
                finish();
            })
            .setNegativeButton("Stay", null)
            .show();
    }

    private void finishWithResult(String landedUrl) {
        Intent result = new Intent();
        result.putExtra(EXTRA_LANDED_URL, landedUrl);
        setResult(Activity.RESULT_OK, result);
        finish();
    }

    @Override
    protected void onDestroy() {
        webView.destroy();
        super.onDestroy();
    }
}
