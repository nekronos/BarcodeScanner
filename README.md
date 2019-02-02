## Installing dependencies

### iOS
You need the latest version of xcode and [cocoapods](https://cocoapods.org/).

### Android
`fuse install android` should install all needed dependencies

## Building

### iOS
`uno build -t=ios -d -DCOCOAPODS`

### Android
`uno build -t=android -DGRADLE`

Android by default uses the `zbar` library. Alternatively build with `-DZXING` to use the `zxing` library
