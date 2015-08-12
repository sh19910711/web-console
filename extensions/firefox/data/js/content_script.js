function meta(name, value) {
  var meta = document.createElement("meta");
  meta.name = name;
  meta.content = value;
  return meta;
}

self.port.on("session", function(session) {
  document.head.appendChild(meta("web-console-session-id", session.sessionId));
  document.head.appendChild(meta("web-console-mount-point", session.mountPoint));
});

self.port.emit("session");
