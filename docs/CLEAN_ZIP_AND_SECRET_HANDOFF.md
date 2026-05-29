# Clean zip and release secret handoff

Last updated: 2026-05-29

## Clean source zip

Use this command when preparing a source-only package for outside review:

```powershell
powershell -ExecutionPolicy Bypass -File tools\create_clean_source_zip.ps1
```

The script excludes local build output, dependency caches, debug folders,
temporary logs, `.git`, and signing secrets. It also verifies the final zip does
not contain private signing files such as `android/key.properties`, `.jks`,
`.keystore`, `.p12`, or `.pem`.

The clean package is written next to the project folder with a timestamped name:

```text
C:\Users\Casper\Desktop\rxpro_mobile_clean_<timestamp>.zip
```

## Android release signing handoff

For clean source sharing, release signing secrets were moved outside the project
folder to:

```text
C:\Users\Casper\Desktop\rxpro_release_secrets_backup
```

The backup currently contains:

- `key.properties`
- `fix-release-key.jks`
- `rxpro-upload-keystore.jks`

Before running a local Android release build, restore them with:

```powershell
powershell -ExecutionPolicy Bypass -File tools\restore_android_release_secrets.ps1
```

After restoring, run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\user_release_build.ps1
```

Do not include the restored signing files in any source zip or external analysis
package. They are ignored by git and by the clean zip script.
