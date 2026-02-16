// Messaging utilities for Flutter communication
function sendMessageToFlutter(message) {
    if (window.FlutterChannel) {
        window.FlutterChannel.postMessage(JSON.stringify(message));
    }
}
