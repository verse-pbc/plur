package io.flutter.plugin.common;

/**
 * Mock implementation of MethodCall for the build process.
 */
public class MethodCall {
    public String method;
    public Object arguments;
    
    public MethodCall(String method, Object arguments) {
        this.method = method;
        this.arguments = arguments;
    }
}