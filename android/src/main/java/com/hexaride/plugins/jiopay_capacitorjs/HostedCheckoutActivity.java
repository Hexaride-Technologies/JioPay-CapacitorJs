package com.hexaride.plugins.jiopay_capacitorjs;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.graphics.Bitmap;
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
import androidx.appcompat.app.AppCompatActivity;

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
    static final String EXTRA_LANDED_URL = "landedUrl";

    private WebView webView;
    private ProgressBar progressBar;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        String checkoutUrl = getIntent().getStringExtra(EXTRA_CHECKOUT_URL);
        String returnUrlPrefix = getIntent().getStringExtra(EXTRA_RETURN_URL_PREFIX);
        if (checkoutUrl == null) {
            setResult(Activity.RESULT_CANCELED);
            finish();
            return;
        }

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

        setContentView(root);
        webView.loadUrl(checkoutUrl);

        getOnBackPressedDispatcher()
            .addCallback(
                this,
                new OnBackPressedCallback(true) {
                    @Override
                    public void handleOnBackPressed() {
                        if (webView.canGoBack()) {
                            webView.goBack();
                        } else {
                            setEnabled(false);
                            getOnBackPressedDispatcher().onBackPressed();
                        }
                    }
                }
            );
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
