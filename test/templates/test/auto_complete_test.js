suite('AutocompleteTests', function() {
  setup(function() {
    var self = this;
    self.ac = new Autocomplete(["something", "somewhat", "somewhere"], '');
    self.called = false;
    self.ac.onClose(function() { self.called = true; });
    self.moveNext = function(times) {
      for (var i = 0; i < times; ++i) self.ac.next();
    };
    self.assertSelect = function(pos) {
      assert.equal(self.ac.current, pos);
    };
    self.assertCount = function(className, cnt) {
      assert.equal(self.ac.view.getElementsByClassName(className).length, cnt);
    }
  });

  test('noinc', function() {
    this.assertCount('hidden', 0)
  });

  test('inc(some)', function() {
    this.ac.inc('some');
    this.assertCount('hidden', 0);
  });

  test('inc(somet)', function() {
    this.ac.inc('somet');
    assert(this.called)
  });
});
