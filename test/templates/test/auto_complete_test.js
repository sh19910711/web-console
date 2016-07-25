suite('Autocomplete', function() {
  setup(function() {
    this.ac = new Autocomplete(['other', 'other2', 'something', 'somewhat', 'somewhere', 'test']);
    this.refine = function(prefix) { this.ac.refine(prefix); };
  });

  test('shows only five elements around the current element', function() {
    var ac = new Autocomplete(['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']);

    // A B C D E ...
    assertNotClass(ac, 0, 5, 'soft-hidden');
    assertClass(ac, 5, ac.words.length, 'soft-hidden');

    // A B C D E ...
    ac.onKeyDown(TestHelper.keyDown(TestHelper.KEY_TAB));
    assertNotClass(ac, 0, 5, 'soft-hidden');
    assertClass(ac, 5, ac.words.length, 'soft-hidden');

    // B C D E F ...
    ac.onKeyDown(TestHelper.keyDown(TestHelper.KEY_TAB));
    assertClass(ac, 0, 1, 'soft-hidden');
    assertNotClass(ac, 1, 6, 'soft-hidden');
    assertClass(ac, 6, ac.words.length, 'soft-hidden');

    // D E F G H
    for (var i = 0; i < 5; ++i) ac.onKeyDown(TestHelper.keyDown(TestHelper.KEY_TAB));
    assert.equal(6, ac.current);
    assertClass(ac, 0, 3, 'soft-hidden');
    assertNotClass(ac, 3, ac.words.length, 'soft-hidden');

    // D E F G H
    ac.onKeyDown(TestHelper.keyDown(TestHelper.KEY_TAB));
    assert.equal(7, ac.current);
    assertClass(ac, 0, 3, 'soft-hidden');
    assertNotClass(ac, 3, ac.words.length, 'soft-hidden');

    // A B C D E ...
    ac.onKeyDown(TestHelper.keyDown(TestHelper.KEY_TAB));
    assertNotClass(ac, 0, 5, 'soft-hidden');
    assertClass(ac, 5, ac.words.length, 'soft-hidden');
  });

  test('does nothing if the word list is empty', function() {
    var ac = new Autocomplete([]);
    assert.doesNotThrow(function() {
      ac.onKeyDown(TestHelper.keyDown(TestHelper.KEY_TAB));
      ac.onKeyDown(TestHelper.keyDown(TestHelper.KEY_ENTER));
    });
  });

  test('empty string', function() {
    this.refine('');

    assert(!this.ac.confirmed);
    assertRange(this, 0, this.ac.words.length, 0);
  });

  test('some', function() {
    this.refine('some');

    assert(!this.ac.confirmed);
    assertRange(this, 2, this.ac.words.length - 1, 3);
  });

  test('confirmable', function() {
    this.refine('somet');

    assert.equal(this.ac.confirmed, 'something');
    assertRange(this, 2, 3);
  });

  test('decrement', function() {
    this.refine('o');
    this.refine('');

    assertRange(this, 0, this.ac.words.length, 0);
  });

  test('other => empty => some', function() {
    this.refine('other');
    this.refine('');
    this.refine('some');

    assertRange(this, 2, this.ac.words.length - 1, 3);
  });

  test('some => empty', function() {
    this.refine('some');
    this.refine('');

    assertRange(this, 0, this.ac.words.length);
  });

  function assertClass(ac, left, right, className) {
    for (var i = left; i < right; ++i) {
      assert.ok(hasClass(ac.view.children[i], className), i + '-th element shuold have ' + className);
    }
  }

  function assertNotClass(ac, left, right, className) {
    for (var i = left; i < right; ++i) {
      assert.notOk(hasClass(ac.view.children[i], className), i + '-th element should not have ' + className);
    }
  }

  function assertRange(self, left, right, hiddenCnt) {
    assert.equal(left, self.ac.left, 'left');
    assert.equal(right, self.ac.right, 'right');
    if (hiddenCnt) assert.equal(hiddenCnt, self.ac.view.getElementsByClassName('hidden').length, 'hiddenCnt');
  }
});
