# Third-party notices

## Body diagram geometry

The muscle outlines in `assets/data/body_map.json`, drawn by the muscle map
feature, are derived from [MuscleMap](https://github.com/melihcolpan/MuscleMap)
by Melih Colpan, used under the MIT License reproduced below. The path data was
converted from Swift source to JSON and its sub-group shapes were dropped; the
artwork is otherwise unchanged. Only the male front and back views are included.

The same licence text is registered with Flutter's `LicenseRegistry` in
`lib/main.dart`, so it ships inside the app binary as the MIT License requires.
The app has no licences screen yet; adding `showLicensePage` to Settings would
make it visible to users.

```
MIT License

Copyright (c) 2026 Melih Colpan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## What is not included

The muscle map is modelled on the one in Iron Index (fitness-nextui), which
ported logic from openGym. openGym is licensed under the GNU AGPL v3.0 and none
of its code is included here. BeFit uses only the MIT geometry above and its
own muscle list.
