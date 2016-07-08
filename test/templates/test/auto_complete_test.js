suite('Autocomplete', function() {
  setup(function() {
    var self = this;
    self.ac = new Autocomplete(['other', 'other2', 'something', 'somewhat', 'somewhere', 'test']);
    self.assertSelect = function(pos) { assert.equal(self.ac.current, pos); };
    self.assertCount = function(className, cnt) { assert.equal(self.ac.view.getElementsByClassName(className).length, cnt); }
    self.inc = function(prefix) { self.ac.refine(prefix, true); };
    self.dec = function(prefix) { self.ac.refine(prefix, false); };
  });

  test('empty string', function() {
    this.inc('');

    assert(!this.ac.confirmed);
    assert.equal(this.ac.left, 0);
    assert.equal(this.ac.right, this.ac.words.length);
    this.assertCount('hidden', 0)
  });

  test('undefined', function() {
    this.dec();

    assert(!this.ac.confirmed);
    assert.equal(this.ac.left, 0);
    assert.equal(this.ac.right, this.ac.words.length);
    this.assertCount('hidden', 0);
  });

  test('refining', function() {
    this.inc('some');

    assert(!this.ac.confirmed);
    assert.equal(this.ac.left, 2);
    assert.equal(this.ac.right, this.ac.words.length - 1);
    this.assertCount('hidden', 3);
  });

  test('confirmed', function() {
    this.inc('somet');

    assert.equal(this.ac.confirmed, 'something');
    assert.equal(this.ac.left, 2);
    assert.equal(this.ac.right, 3);
  });

  test('decrement', function() {
    this.inc('o');
    this.dec('');

    assert.equal(this.ac.left, 0);
    assert.equal(this.ac.right, this.ac.words.length);
    this.assertCount('hidden', 0);
  });

  test('inc => dec => inc', function() {
    this.inc('other');
    this.dec('');
    this.inc('some');

    assert.equal(this.ac.left, 2);
    assert.equal(this.ac.right, this.ac.words.length - 1);
    this.assertCount('hidden', 3);
  });
});
