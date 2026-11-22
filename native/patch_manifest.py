# Build ke time AndroidManifest.xml me Sara ka service aur queries jodta hai.
p = 'android/app/src/main/AndroidManifest.xml'
s = open(p).read()

launcher_query = (
    '<intent><action android:name="android.intent.action.MAIN"/>'
    '<category android:name="android.intent.category.LAUNCHER"/></intent>'
)
if '<queries>' in s:
    s = s.replace('<queries>', '<queries>\n        ' + launcher_query, 1)
else:
    s = s.replace('<application',
                  '<queries>' + launcher_query + '</queries>\n    <application', 1)

service = '''
        <service
            android:name=".ZoyaAccessibilityService"
            android:exported="true"
            android:label="Sara"
            android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE">
            <intent-filter>
                <action android:name="android.accessibilityservice.AccessibilityService"/>
            </intent-filter>
            <meta-data
                android:name="android.accessibilityservice"
                android:resource="@xml/accessibility_service_config"/>
        </service>
    '''
perms = ''.join(
    '<uses-permission android:name="android.permission.%s"/>\n    ' % p
    for p in ['FOREGROUND_SERVICE', 'FOREGROUND_SERVICE_MICROPHONE', 'POST_NOTIFICATIONS', 'CAMERA']
)
s = s.replace('<application', perms + '<application', 1)

service += '''
        <service
            android:name=".ZoyaForegroundService"
            android:exported="false"
            android:foregroundServiceType="microphone"/>
    '''
s = s.replace('</application>', service + '</application>', 1)
open(p, 'w').write(s)
print('manifest patched')
