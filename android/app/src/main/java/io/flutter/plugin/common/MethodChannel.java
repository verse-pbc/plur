package io.flutter.plugin.common;

/**
 * Mock implementation of MethodChannel for the build process.
 */
public class MethodChannel {
    public MethodChannel(Object messenger, String channelName) {
        // No-op constructor
    }
    
    public interface MethodCallHandler {
        void onMethodCall(MethodCall call, Result result);
    }
    
    public interface Result {
        void success(Object result);
        void error(String errorCode, String errorMessage, Object errorDetails);
        void notImplemented();
    }
    
    public void invokeMethod(String method, Object arguments) {
        // No-op implementation
    }
}