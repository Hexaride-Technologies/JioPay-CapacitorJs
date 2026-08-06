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

        String returnUrlPrefix = call.getString("returnUrlPrefix");
        if (returnUrlPrefix == null || returnUrlPrefix.isEmpty()) {
            call.reject("Missing required option: returnUrlPrefix");
            return;
        }

        Intent intent = new Intent(getContext(), HostedCheckoutActivity.class);
        intent.putExtra(HostedCheckoutActivity.EXTRA_CHECKOUT_URL, checkoutUrl);
        intent.putExtra(HostedCheckoutActivity.EXTRA_RETURN_URL_PREFIX, returnUrlPrefix);
        startActivityForResult(call, intent, "handleCheckoutResult");
    }

    @ActivityCallback
    private void handleCheckoutResult(PluginCall call, ActivityResult result) {
        if (call == null) {
            return;
        }

        Intent data = result.getData();
        if (result.getResultCode() != Activity.RESULT_OK || data == null) {
            call.reject("Checkout closed before reaching the return URL");
            return;
        }

        String landedUrl = data.getStringExtra(HostedCheckoutActivity.EXTRA_LANDED_URL);
        Uri uri = Uri.parse(landedUrl);

        JSObject params = new JSObject();
        Set<String> keys = uri.getQueryParameterNames();
        for (String key : keys) {
            params.put(key, uri.getQueryParameter(key));
        }

        JSObject ret = new JSObject();
        ret.put("url", landedUrl);
        ret.put("params", params);
        call.resolve(ret);
    }
}
