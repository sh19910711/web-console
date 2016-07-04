suite('AutocompleteTests', function() {
  setup(function() {
    var self = this.ac = new Autocomplete(["something", "somewhat", "somewhere"], '');
    this.moveNext = function(times) {
      for (var i = 0; i < times; ++i) self.next();
    };
    this.assertSelect = function(pos) {
      assert.equal(self.current, pos);
    };
    this.assertCount = function(className, cnt) {
      assert.equal(self.view.getElementsByClassName(className).length, cnt);
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
    this.assertCount('hidden', 2);
  });
});
