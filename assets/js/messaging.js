// Messaging utilities for Flutter communication
function sendMessageToFlutter(message) {
    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('onMessage', JSON.stringify(message));
    }
}
