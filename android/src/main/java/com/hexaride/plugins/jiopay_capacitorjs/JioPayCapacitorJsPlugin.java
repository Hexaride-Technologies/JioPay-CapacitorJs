package com.hexaride.plugins.jiopay_capacitorjs;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import androidx.activity.result.ActivityResult;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.ActivityCallback;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.util.Set;

@CapacitorPlugin(name = "JioPayCapacitorJs")
public class JioPayCapacitorJsPlugin extends Plugin {

    @PluginMethod
    public void openHostedCheckout(PluginCall call) {
        String checkoutUrl = call.getString("checkoutUrl");
        if (checkoutUrl == null || checkoutUrl.isEmpty()) {
            call.reject("Missing required option: checkoutUrl");
            return;
        }
        if (!checkoutUrl.startsWith("http://") && !checkoutUrl.startsWith("https://")) {
            call.reject("Invalid checkoutUrl: must be an http(s) URL");
            return;
        }

        String returnUrlPrefix = call.getString("returnUrlPrefix");
        if (returnUrlPrefix == null || returnUrlPrefix.isEmpty()) {
            call.reject("Missing required option: returnUrlPrefix");
            return;
        }

        boolean showAppBar = Boolean.TRUE.equals(call.getBoolean("showAppBar", false));
        String headerColor = call.getString("headerColor");

        Intent intent = new Intent(getContext(), HostedCheckoutActivity.class);
        intent.putExtra(HostedCheckoutActivity.EXTRA_CHECKOUT_URL, checkoutUrl);
        intent.putExtra(HostedCheckoutActivity.EXTRA_RETURN_URL_PREFIX, returnUrlPrefix);
        intent.putExtra(HostedCheckoutActivity.EXTRA_SHOW_APP_BAR, showAppBar);
        intent.putExtra(HostedCheckoutActivity.EXTRA_HEADER_COLOR, headerColor);
        startActivityForResult(call, intent, "handleCheckoutResult");
    }

    @ActivityCallback
    private void handleCheckoutResult(PluginCall call, ActivityResult result) {
        if (call == null) {
            return;
        }

        Intent data = result.getData();
        if (result.getResultCode() != Activity.RESULT_OK || data == null) {
            JSObject eventData = new JSObject();
            eventData.put("status", "cancelled");
            notifyListeners("cancelled", eventData);
            notifyListeners("complete", eventData);
            call.reject("Checkout closed before reaching the return URL");
            return;
        }

        String landedUrl = data.getStringExtra(HostedCheckoutActivity.EXTRA_LANDED_URL);
        if (landedUrl == null) {
            call.reject("Checkout closed without a landed URL");
            return;
        }
        Uri uri = Uri.parse(landedUrl);

        JSObject params = new JSObject();
        Set<String> keys = uri.getQueryParameterNames();
        for (String key : keys) {
            params.put(key, uri.getQueryParameter(key));
        }

        // JioPay's B2B callback uses responseCode "0000" for a successful
        // transaction (matches the S2S webhook payload shape); anything else
        // is a failure. This is UX-only, same caveat as the rest of this flow.
        boolean isSuccess = "0000".equals(uri.getQueryParameter("responseCode"));
        String status = isSuccess ? "success" : "fail";

        JSObject eventData = new JSObject();
        eventData.put("status", status);
        eventData.put("url", landedUrl);
        eventData.put("params", params);
        notifyListeners(status, eventData);
        notifyListeners("complete", eventData);

        JSObject ret = new JSObject();
        ret.put("url", landedUrl);
        ret.put("params", params);
        call.resolve(ret);
    }
}
