var hello = document.createElement("div");
hello.innerHTML = "hello<br>";
document.body.appendChild(hello);

self.port.on("hello", function() {
  hello.innerHTML += "add-on said hello<br>";
});

self.port.emit("hello");
