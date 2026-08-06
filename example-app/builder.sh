npm run build
npx cap sync android
# npx cap run android
cd android
./gradlew assembleDebug
cd ..
APK=/media/antar-saha/NewVolume/works/jiopay-capacitor/jiopay-capacitorjs/example-app/android/app/build/outputs/apk/debug/app-debug.apk 
ls -la "$APK" 
adb devices 
adb install -r "$APK"
# adb -s adb-4be94547-SSct2b._adb-tls-connect._tcp shell am start -W -n com.example.plugin/com.example.plugin.MainActivity