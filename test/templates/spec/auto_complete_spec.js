describe("Auto Complete", function() {
  describe("move functions", function() {
    context("set up with three elements", function() {
      beforeEach(function() {
        var self = this.autoComplete = new AutoComplete(["something", "somewhat", "somewhere"]);
        this.moveNext = function(times) {
          for (var i = 0; i < times; ++i) self.next();
        };
        this.assertSelect = function(pos) {
          assert.ok(hasClass(self.view.children[pos], 'selected'));
          for (var i = 0; i < self.view.children.length; ++i) {
            if (i !== pos) assert.ok(!hasClass(self.view.children[i], 'selected'));
          }
        };
      });
      it("should have three elements", function() {
        assert.ok(this.autoComplete.view.children.length === 3)
      });
      it("should have no selected element", function() {
        assert.ok(this.autoComplete.view.getElementsByClassName('selected').length === 0);
      });

      context("move next two times", function() {
        beforeEach(function() { this.moveNext(2) });
        it("should point the 1-th element", function() { this.assertSelect(1); });

        context("back once", function() {
          beforeEach(function() { this.autoComplete.back(); });
          it("should point the 0-th element", function() { this.assertSelect(0); });

          context("back once again", function() {
            beforeEach(function() { this.autoComplete.back(); });
            it("should point the last element", function() { this.assertSelect(2); });
          });
        });

        context("move next two times again", function() {
          beforeEach(function() { this.moveNext(2) });
          it("should back to the first of list", function() { this.assertSelect(0); });
        });
      });
    });
  });
});
