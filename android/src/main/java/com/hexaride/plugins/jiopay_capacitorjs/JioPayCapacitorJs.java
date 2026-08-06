package com.hexaride.plugins.jiopay_capacitorjs;

import android.content.Context;
import android.content.Intent;
import com.getcapacitor.JSArray;
import com.getcapacitor.PluginCall;
import com.jiopay.payment_library.PaymentActivity;
import com.jiopay.payment_library.config.JioPaySDK;
import org.json.JSONException;

public class JioPayCapacitorJs {

    // JioPaySDK.Builder#build() only validates params and stores a config
    // singleton (read back via JioPaySDK.getInstance()) — it does not launch
    // anything itself. PaymentActivity reads everything it needs from that
    // singleton (merchant image, amount, allowed payment modes, etc.) and
    // takes no meaningful Intent extras, so a bare launch Intent is enough.
    Intent buildPaymentIntent(Context context, PluginCall call) throws JSONException {
        String environment = call.getString("environment");
        String environmentConst = "PRODUCTION".equalsIgnoreCase(environment) ? JioPaySDK.PRODUCTION : JioPaySDK.UAT;

        JioPaySDK.Builder builder = new JioPaySDK.Builder()
            .setEnvironment(environmentConst)
            .setAggregatorId(call.getString("aggregatorId"))
            .setMerchantId(call.getString("merchantId"))
            .setSecret(call.getString("secret"))
            .setAmount(call.getString("amount"))
            .setCustomerName(call.getString("customerName"))
            .setCustomerEmailID(call.getString("customerEmailId"))
            .setMerchantName(call.getString("merchantName"))
            .setMerchantTxnNo(call.getString("merchantTxnNo"))
            .setPaymentModeAllowed(readPaymentModes(call));

        String merchantImage = call.getString("merchantImage");
        if (merchantImage != null && !merchantImage.isEmpty()) {
            builder.setMerchantImage(merchantImage);
        }

        Integer timeout = call.getInt("timeout");
        if (timeout != null) {
            builder.setTimeout(timeout);
        }

        builder.build();

        return new Intent(context, PaymentActivity.class);
    }

    // Builder#setPaymentModeAllowed(String... var1) takes raw strings, not the
    // PaymentMode enum itself — but we still validate against PaymentMode so
    // JS callers get a clear rejection instead of a silently-ignored typo.
    private String[] readPaymentModes(PluginCall call) throws JSONException {
        JSArray modesArray = call.getArray("paymentModesAllowed");
        if (modesArray == null || modesArray.length() == 0) {
            throw new JSONException("paymentModesAllowed must include at least one payment mode");
        }
        String[] modes = new String[modesArray.length()];
        for (int i = 0; i < modesArray.length(); i++) {
            String raw = modesArray.getString(i);
            try {
                modes[i] = JioPaySDK.PaymentMode.valueOf(raw).name();
            } catch (IllegalArgumentException e) {
                throw new JSONException("Invalid payment mode: " + raw);
            }
        }
        return modes;
    }
}
