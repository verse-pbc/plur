#ifndef SentryFlutterPlugin_h
#define SentryFlutterPlugin_h

#import <Flutter/Flutter.h>

@interface SentryFlutterPlugin : NSObject<FlutterPlugin>
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;
@end

#endif /* SentryFlutterPlugin_h */
