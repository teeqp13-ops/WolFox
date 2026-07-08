# WolFox GPS Plus Pro

مشروع Theos جاهز لبناء ملف `.deb` من ملف واحد بامتداد `.mm`.

## الملفات

- `GPSPlusPro.mm` ملف السورس الرئيسي.
- `Makefile` إعدادات بناء Theos.
- `control` بيانات الحزمة.
- `.github/workflows/build-deb.yml` بناء تلقائي ورفع ملف `.deb` كـ Artifact.
- `scripts/build.sh` بناء محلي.

## البناء من GitHub

ادخل إلى **Actions** ثم شغّل Workflow باسم:

`Build DEB`

بعد الانتهاء ستجد ملف `.deb` داخل Artifacts باسم:

`WolFox-DEB`

## البناء محليًا

```bash
chmod +x scripts/build.sh
./scripts/build.sh
```

> ملاحظة: يحتاج Theos و iPhoneOS SDK للبناء المحلي.