# Web2APK

Web2APK is a simple API server that converts a zipped Android webview project into an APK file.  
You can optionally customize the app's name, package name, version, and icon during the conversion.

---

## API Usage

### Endpoint

```
POST https://web2apk.onrender.com/to_apk
```

### Request

- Content-Type: `application/json`
- Body:  
  ```json
  {
    "file": "<URL to your zipped html, css, js project>",
    "app_name": "My App",                  // (Optional) New app name
    "package_name": "com.example.myapp",   // (Optional) New package name
    "version": "1.2.3",                    // (Optional) New version name
    "version_code": 5,                     // (Optional) New version code (integer)
    "icon": "<base64 or URL to PNG icon>"  // (Optional) Custom icon (base64 string or direct PNG URL)
  }
  ```

#### Parameters

| Parameter      | Required | Type     | Description                                                        |
|----------------|----------|----------|--------------------------------------------------------------------|
| `file`         | Yes      | string   | URL to a ZIP file containing a valid Android project structure     |
| `app_name`     | No       | string   | Custom name for the app (overrides `app_name` in `strings.xml`)    |
| `package_name` | No       | string   | Custom package name (overrides `package` in `AndroidManifest.xml`) |
| `version`      | No       | string   | Custom version name (overrides `versionName` in `build.gradle`)    |
| `version_code` | No       | integer  | Custom version code (overrides `versionCode` in `build.gradle`)    |
| `icon`         | No       | string   | Custom icon as base64 string or PNG URL (replaces `ic_launcher.png`)|

---

### Sample Request

```bash
curl -X POST https://web2apk.onrender.com/to_apk \
  -H "Content-Type: application/json" \
  -d '{
    "file": "https://example.com/mywebapp.zip",
    "app_name": "My Custom Browser",
    "package_name": "com.example.browser",
    "version": "2.0.0",
    "version_code": 7,
    "icon": "https://example.com/icon.png"
  }'
```

---

### Sample Response

```json
{
  "status": "ok",
  "result": "<URL for apk"
}
```

If there is an error (e.g., invalid ZIP or build failure):

```json
{
  "status": "error",
  "message": "Detailed error message here."
}
```

---

## Notes

- The `file` parameter must be a URL to a ZIP file containing an HTML, CSS, JS project structured for building with Gradle.
- The custom icon must be a PNG file and will replace all `ic_launcher.png` icons in the project.
- The server will clean up temporary files after each build.
---
