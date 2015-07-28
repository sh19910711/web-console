const { MessageChannel } = require("sdk/messaging");

function PanelMessage(options) {
  this.options = options;
  this.channel = new MessageChannel;
  this.addonPort = this.channel.port1;
  this.panelPort = this.channel.port2;
  this.addonPort.onmessage = this.receiveMessage.bind(this);
}

PanelMessage.prototype.sendMessage = function(data) {
  this.addonPort.postMessage(JSON.stringify(data));
};

PanelMessage.prototype.receiveMessage = function(event) {
  var data = event.data;
  if (data.type === "request") {
    this.options.request.call(this, data);
  } else if (data.type === "tab-info") {
    this.options.tabInfo.call(this, data);
  }
};

exports.PanelMessage = PanelMessage;
