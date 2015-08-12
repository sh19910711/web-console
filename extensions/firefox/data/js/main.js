const { Cc, Ci } = require("chrome");
var tabInfo = {};
var tabCallbacks = {};

const { HttpListener } = require("./http_listener");
const observerService = Cc["@mozilla.org/observer-service;1"]
  .getService(Ci.nsIObserverService);

function tabKey(tabId, url) {
  return tabId + "-" + url;
}

const httpListener = new HttpListener({
  onRequest: function(info) {
    tabInfo[info.tabId] = info;
  }
});
observerService.addObserver(httpListener, "http-on-examine-response", false);

//
// Add a panel to DevTools
//
const { Panel } = require("dev/panel");
const { PanelMessage } = require("./panel_message");
const { Tool } = require("dev/toolbox");
const { Class } = require("sdk/core/heritage");
const { REPLConsole } = require("../lib/console");
REPLConsole.XMLHttpRequest = require("sdk/net/xhr").XMLHttpRequest;

const MyPanel = Class({
  extends: Panel,
  label: "Console (Rails)",
  icon: "img/icon_128.png",
  url: "html/panel.html",

  setup: function(options) {
    var panel = this;
    this.debuggee = options.debuggee;
    this.panelMessage = new PanelMessage({
      request: function(data) {
        var self = this;
        var callback = function(xhr) {
          self.sendMessage({
            type: "request",
            status: xhr.status,
            responseText: xhr.responseText,
            callback: true
          });
        };
        REPLConsole.request(data.method, data.url, data.params, callback);
      },
      tabInfo: function(data) {
        var self = this;
        panel.tabId = data.tabId;
        panel.url = data.url;
        tabCallbacks[panel.tabId] = function(url) {
          var info = tabInfo[panel.tabId];
          info.type = "session";
          self.sendMessage(info);
        };
        var info = tabInfo[panel.tabId];
        info.type = "session";
        this.sendMessage(info);
      }
    });
  },

  dispose: function() {
    this.debuggee = null;
    this.panelMessage = null;
    tabCallbacks[this.tabId] = null;
  },

  onReady: function() {
    this.postMessage(JSON.stringify({ type: "greeting" }), [ this.panelMessage.panelPort ]);
    this.debuggee.start();
    this.postMessage(JSON.stringify({ type: "debuggee" }), [ this.debuggee ]);
  }
});

const myTool = new Tool({
  panels: {
    myPanel: MyPanel
  }
});

const tabs = require("sdk/tabs");
const tabUtils = require("sdk/tabs/utils");
const windowUtils = require("sdk/window/utils");
const { viewFor } = require("sdk/view/core");
tabs.on("ready", updateTab);
tabs.on("pageshow", updateTab);

function updateTab(tab) {
  var lowLevelTab = viewFor(tab);
  var tabId = tab.id.match(/^-\d+-(\d+)$/)[1];
  var contentWindow = tabUtils.getTabContentWindow(lowLevelTab);
  var outerWindowId = windowUtils.getOuterId(contentWindow);
  var key = outerWindowId + "-" + tabId;
  if (tabCallbacks[key]) {
    tabCallbacks[key](tab.url);
  }
}

const self = require("sdk/self");
const { PageMod } = require("sdk/page-mod");
const { setTimeout } = require("sdk/timers");

PageMod({
  include: "*",
  attachTo: ["existing", "top"],
  contentScriptFile: self.data.url("js/content_script.js"),
  contentScriptWhen: "end",
  onAttach: function(worker) {
    var lowLevelTab = viewFor(worker.tab);
    var tabId = worker.tab.id.match(/^-\d+-(\d+)$/)[1];
    var contentWindow = tabUtils.getTabContentWindow(lowLevelTab);
    var outerWindowId = windowUtils.getOuterId(contentWindow);
    var key = outerWindowId + "-" + tabId;
    worker.port.on("session", function() {
      worker.port.emit("session", tabInfo[key]);
    });
  }
});
