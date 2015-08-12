var addonPort;
var tabId;
var repl;
var callbacks = {}

function sendMessage(data, callback) {
  callbacks[data.type] = callbacks[data.type] || [];
  callbacks[data.type].push(callback);
  addonPort.postMessage(data);
}

function receiveMessage(event) {
  var data = JSON.parse(event.data);
  console.log("panel: receiveMessage: ", JSON.stringify(data));
  if (data.callback) {
    var callback = callbacks[data.type].shift();
    callback(data);
  } else {
    if (data.type === "session") {
      if (repl) {
        repl.sessionId = data.sessionId;
        repl.mountPoint = data.mountPoint;
      } else {
        var options = { sessionId: data.sessionId, mountPoint: data.mountPoint };
        repl = REPLConsole.installInto("console", options);
        console.log(repl);
      }
    }
  }
}

function getTabKey(tab) {
  var nums = tab.id.match(/^server([0-9]+)\.conn([0-9]+)\.tab([0-9]+)$/);
  var tabId = nums[3];
  var outerWindowID = tab.outerWindowID;
  return outerWindowID + "-" + tabId;
}

REPLConsole.request = function(method, url, params, callback) {
  sendMessage({
    type: "request",
    method: method,
    url: url,
    params: params
  }, callback);
};

window.addEventListener("message", function(event) {
  var data = JSON.parse(event.data)
  if (data.type === "greeting") {
    addonPort = event.ports[0];
    addonPort.onmessage = receiveMessage;
  } else if (data.type === "debuggee") {
    var debuggee = event.ports[0];
    volcan.connect(debuggee)
      .then(function(root) {
        return root.listTabs();
      })
      .then(function(list) {
        addonPort.postMessage({
          type: "tab-info",
          tabId: getTabKey(list.tabs[list.selected]),
          url: list.tabs[list.selected].url
        });
      });
    var otherListener = event.ports[0].onmessage;
    debuggee.onmessage = function(event) {
      otherListener.apply(this, arguments);
    };
  }
});
