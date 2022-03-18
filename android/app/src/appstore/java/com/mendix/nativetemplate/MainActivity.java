package com.mendix.nativetemplate;

import android.os.Bundle;

import androidx.annotation.Nullable;

import com.mendix.mendixnative.activity.MendixReactActivity;
import com.mendix.mendixnative.config.AppUrl;
import com.mendix.mendixnative.react.MendixApp;
import com.mendix.mendixnative.react.MxConfiguration;

import android.view.KeyEvent;
import com.github.kevinejohn.keyevent.KeyEventModule;


public class MainActivity extends MendixReactActivity {
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        this.getLifecycle().addObserver(new MendixActivityObserver(this));
        Boolean hasDeveloperSupport = ((MainApplication) getApplication()).getUseDeveloperSupport();
        mendixApp = new MendixApp(AppUrl.getUrlFromResource(this), MxConfiguration.WarningsFilter.none, hasDeveloperSupport, false);
        super.onCreate(savedInstanceState);
    }
    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        if (event.getAction() == 0) {
            KeyEventModule.getInstance().onKeyDownEvent(event.getKeyCode(), event);
        }
        if (event.getKeyCode() == KeyEvent.KEYCODE_ENTER) {
            return true;
        } else {
            return super.dispatchKeyEvent(event);
        }
    }
}
