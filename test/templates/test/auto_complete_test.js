suite('Autocomplete', function() {
  setup(function() {
    var self = this;
    self.ac = new Autocomplete(['other', 'other2', 'something', 'somewhat', 'somewhere', 'test']);
    self.inc = function(prefix) { self.ac.refine(prefix, true); };
    self.dec = function(prefix) { self.ac.refine(prefix, false); };
  });

  test('empty string', function() {
    this.inc('');

    assert(!this.ac.confirmed);
    assertRange(this, 0, this.ac.words.length, 0);
  });

  test('undefined', function() {
    this.dec();

    assert(!this.ac.confirmed);
    assertRange(this, 0, this.ac.words.length, 0);
  });

  test('refining', function() {
    this.inc('some');

    assert(!this.ac.confirmed);
    assertRange(this, 2, this.ac.words.length - 1, 3);
  });

  test('confirmed', function() {
    this.inc('somet');

    assert.equal(this.ac.confirmed, 'something');
    assertRange(this, 2, 3);
  });

  test('decrement', function() {
    this.inc('o');
    this.dec('');

    assertRange(this, 0, this.ac.words.length, 0);
  });

  test('other => empty => some', function() {
    this.inc('other');
    this.dec('');
    this.inc('some');

    assertRange(this, 2, this.ac.words.length - 1, 3);
  });

  test('some => empty', function() {
    this.inc('some');
    this.dec('');

    assertRange(this, 0, this.ac.words.length);
  });

  function assertRange(self, left, right, hiddenCnt) {
    assert.equal(left, self.ac.left, 'left');
    assert.equal(right, self.ac.right, 'right');
    if (hiddenCnt) assert.equal(hiddenCnt, self.ac.view.getElementsByClassName('hidden').length, 'hiddenCnt');
  }
});
