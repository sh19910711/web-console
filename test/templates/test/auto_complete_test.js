suite('AutocompleteTests', function() {
  setup(function() {
    var self = this;
    self.ac = new Autocomplete(['other', 'other2', 'something', 'somewhat', 'somewhere', 'test']);
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
    assert.equal(this.ac.left, 0);
    assert.equal(this.ac.right, this.ac.words.length);
    this.assertCount('hidden', 0)
  });

  test('inc(some)', function() {
    this.ac.inc('some');

    assert(!this.ac.confirmed);
    assert.equal(this.ac.left, 2);
    assert.equal(this.ac.right, this.ac.words.length - 1);
    this.assertCount('hidden', 3);
  });

  test('inc(somet)', function() {
    this.ac.inc('somet');

    assert.equal(this.ac.confirmed, 'something');
    assert.equal(this.ac.left, 2);
    assert.equal(this.ac.right, 3);
  });

  test('inc(somewh)', function() {
    this.ac.inc('somewh');

    this.assertCount('hidden', 4);
    assert(!this.ac.confirmed);
    assert.equal(this.ac.left, 3);
    assert.equal(this.ac.right, this.ac.words.length - 1);
  });

  test('inc(o) => dec()', function() {
    this.ac.inc('o');
    this.ac.dec('');

    assert.equal(this.ac.left, 0);
    assert.equal(this.ac.right, this.ac.words.length);
    this.assertCount('hidden', 0);
  });

  test('inc(other) => dec() => inc(some)', function() {
    this.ac.inc('other');
    this.ac.dec('');
    this.ac.inc('some');

    assert.equal(this.ac.left, 2);
    assert.equal(this.ac.right, this.ac.words.length - 1);
    this.assertCount('hidden', 3);
  });
});
