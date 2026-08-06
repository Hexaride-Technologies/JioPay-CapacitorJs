package com.hexaride.plugins.jiopay_capacitorjs;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import androidx.activity.result.ActivityResult;
import androidx.browser.customtabs.CustomTabsIntent;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.ActivityCallback;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.jiopay.payment_library.config.JioPaySDK;
import org.json.JSONException;

@CapacitorPlugin(name = "JioPayCapacitorJs")
public class JioPayCapacitorJsPlugin extends Plugin {

    private final JioPayCapacitorJs implementation = new JioPayCapacitorJs();

    // JioPaySDK.Builder#build() itself throws IllegalStateException /
    // IllegalArgumentException with a specific message for whichever
    // required field is missing/invalid, so we surface that directly
    // instead of duplicating its validation here.
    @PluginMethod
    public void startPayment(PluginCall call) {
        try {
            Intent intent = implementation.buildPaymentIntent(getContext(), call);
            startActivityForResult(call, intent, "handlePaymentResult");
        } catch (JSONException e) {
            call.reject("Failed to read startPayment options: " + e.getMessage(), e);
        } catch (IllegalStateException | IllegalArgumentException e) {
            call.reject(e.getMessage(), e);
        }
    }

    // PaymentActivity always finishes with RESULT_OK (-1) and puts the real
    // outcome in the "STATUS"/"RESPONSE_JSON" string extras — including on
    // user-cancel (back press), which comes back as RESULT_OK with
    // status == "CANCELLED", not a non-OK result code. So cancellation has
    // to be detected from the status string, not the Activity result code.
    // JioPaySDK.clearInstance() is already called by PaymentActivity itself
    // before it finishes, so we don't need to call it again here.
    @ActivityCallback
    private void handlePaymentResult(PluginCall call, ActivityResult result) {
        if (call == null) {
            return;
        }

        Intent data = result.getData();
        if (result.getResultCode() != Activity.RESULT_OK || data == null) {
            call.reject("Payment cancelled or no response received");
            return;
        }

        String status = data.getStringExtra(JioPaySDK.ResponseKey.STATUS.toString());
        String responseJson = data.getStringExtra(JioPaySDK.ResponseKey.RESPONSE_JSON.toString());

        if (status == null) {
            call.reject("Payment response not available");
            return;
        }

        if (JioPaySDK.TransactionStatus.CANCELLED.name().equalsIgnoreCase(status)) {
            call.reject("Payment cancelled by user");
            return;
        }

        JSObject ret = new JSObject();
        ret.put("status", status);
        ret.put("rawJsonResponse", responseJson != null ? responseJson : "");
        call.resolve(ret);
    }

    @PluginMethod
    public void openHostedCheckout(PluginCall call) {
        String checkoutUrl = call.getString("checkoutUrl");
        if (checkoutUrl == null || checkoutUrl.isEmpty()) {
            call.reject("Missing required option: checkoutUrl");
            return;
        }

        Activity activity = getActivity();
        if (activity == null) {
            call.reject("No active Activity to open checkout in");
            return;
        }

        CustomTabsIntent customTabsIntent = new CustomTabsIntent.Builder().build();
        customTabsIntent.launchUrl(activity, Uri.parse(checkoutUrl));
        call.resolve();
    }
}
