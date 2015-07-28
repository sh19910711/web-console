// Observe HTTP
const { Cc, Ci } = require("chrome");
const tabUtils = require("sdk/tabs/utils");
const windowUtils = require("sdk/window/utils");

function HttpListener(options) {
  this.options = options;
}

HttpListener.prototype = {
  observe: function(subject, topic, data) {
    subject.QueryInterface(Ci.nsIHttpChannel);
    var sessionId = subject.getResponseHeader("X-Web-Console-Session-Id");
    var mountPoint = subject.getResponseHeader("X-Web-Console-Mount-Point");
    var url = subject.URI.spec;
    if (contentWindow = this.getWindowForChannel(subject)) {
      var currentTab = tabUtils.getTabForContentWindow(contentWindow);
      var tabId = tabUtils.getTabId(currentTab).match(/^-[0-9]+-([0-9]+)$/)[1];
      var outerWindowId = windowUtils.getOuterId(contentWindow);
      var key = outerWindowId + "-" + tabId;
      var remoteHost = url.match(/([^:]+:\/\/[^\/]+)\/?/)[1];
      this.options.onRequest.call(this, {
        tabId: key,
        url: url,
        sessionId: sessionId,
        mountPoint: mountPoint,
        remoteHost: remoteHost
      });
    }
  },

  getTabFromContentWindow: function(contentWindow) {
    var browser = this.getBrowserFromContentWindow(contentWindow);
    return browser._getTabForContentWindow(contentWindow.top);
  },

  getBrowserFromContentWindow: function(contentWindow) {
    var domWindow = contentWindow.top.QueryInterface(Ci.nsIInterfaceRequestor)
      .getInterface(Ci.nsIWebNavigation)
      .QueryInterface(Ci.nsIDocShellTreeItem)
      .rootTreeItem
      .QueryInterface(Ci.nsIInterfaceRequestor)
      .getInterface(Ci.nsIDOMWindow);
    return domWindow.gBrowser;
  },

  getLoadContext: function(channel) {
    notificationCallbacks = this.getNotificationCallbacks(channel);
    return notificationCallbacks.getInterface(Ci.nsILoadContext);
  },

  getNotificationCallbacks: function(channel) {
    if (channel.notificationCallbacks) {
      return channel.notificationCallbacks;
    } else {
      return channel.loadGroup.notificationCallbacks;
    }
  },

  getWindowForChannel: function(channel) {
    return this.getLoadContext(channel).associatedWindow;
  }
};

exports.HttpListener = HttpListener;
