suite('AutocompleteTests', function() {
  setup(function() {
    var self = this;
    self.ac = new Autocomplete(['something', 'somewhat', 'somewhere']);
    self.assertSelect = function(pos) {
      assert.equal(self.ac.current, pos);
    };
    self.assertCount = function(className, cnt) {
      assert.equal(self.ac.view.getElementsByClassName(className).length, cnt);
    }
  });

  test('inc()', function() {
    this.ac.inc('');
    assert(!this.ac.confirmed);
    this.assertCount('hidden', 0)
  });

  test('inc(some)', function() {
    this.ac.inc('some');
    assert(!this.ac.confirmed);
    this.assertCount('hidden', 0);
  });

  test('inc(somet)', function() {
    this.ac.inc('somet');
    assert.equal(this.ac.confirmed, 'something');
  });

  test('inc(somewh)', function() {
    this.ac.inc('somewh');
    assert(!this.ac.confirmed);
    this.assertCount('hidden', 1);
  });

  test('inc(somewh) => dec(some)', function() {
    this.ac.inc('somewh');
    this.ac.dec('some');
    assert(!this.ac.confirmed);
    this.assertCount('hidden', 0);
  });
});
