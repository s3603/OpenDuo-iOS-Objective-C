# Open Duo iOS for Objective C

*其他语言版本： [简体中文](README.md)*

**In this sample project, the calculation of dynamic key is performed on the mobile device. For security and avoidance of errors, it is recommended to calculate on your own business server. Please refer to [Dynamic Key](https://docs.agora.io/en/2.0.2/product/Voice/Product%20Overview/key) **

The Open Duo iOS for Objective C Sample App is an open-source demo that will help you get video chat integrated directly into your iOS applications using the Agora Video SDK and Agora Signaling SDK.

With this sample app, you can:

- Login signaling service
- Dial and call
- Accept and hang up
- Mute / unmute audio
- Switch camera

Agora Video SDK and Agora Signaling SDK supports iOS / Android / Web etc. You can find demos of these platform here:

- [OpenDuo-Android](https://github.com/AgoraIO/OpenDuo-Android)
- [OpenDuo-Web](https://github.com/AgoraIO/OpenDuo-Web)

## Running the App
First, create a developer account at [Agora.io](https://dashboard.agora.io/signin/), and obtain an App ID. Update "KeyCenter.mm" with your App ID and App Certificate.

```
static NSString * const kAppID = @"Your App ID"
static NSString * const kAppCertificate = @"Your App Certificate";
```

Next, download the **Agora Video SDK** from [Agora.io SDK](https://www.agora.io/en/download/). Unzip the downloaded SDK package and copy the **libs/AgoraRtcEngineKit.framework** to the "OpenDuo" folder in project. 
Download the **Agora Signaling SDK**, unzip the downloaded SDK package and copy the **libs/AgoraSigKit.framework** to the "OpenDuo" folder in project.

Finally, Open OpenDuo.xcodeproj, connect your iPhone／iPad device, setup your development signing and run.

## Developer Environment Requirements
* XCode 9.0 +
* Real devices (iPhone or iPad)
* iOS simulator is NOT supported

## Connect Us

- You can find full API document at [Document Center](https://docs.agora.io/en/)
- You can file bugs about this demo at [issue](https://github.com/AgoraIO/OpenDuo-iOS-Objective-C/issues)

## License

The MIT License (MIT).
