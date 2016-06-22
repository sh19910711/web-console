describe("Auto Complete", function() {
  describe("move functions", function() {
    context("set up with three elements", function() {
      beforeEach(function() {
        this.autoComplete = new AutoComplete(["something", "somewhat", "somewhere"]);
      });
      it("should have three elements", function() {
        assert.ok(this.autoComplete.view.children.length === 3)
      });
      it("should have no selected element", function() {
        assert.ok(this.autoComplete.view.getElementsByClassName('selected').length === 0);
      });

      context("move next two times", function() {
        beforeEach(function() {
          this.autoComplete.next();
          this.autoComplete.next();
        });
        it("should have selected element in the second", function() {
          assert.ok(!hasClass(this.autoComplete.view.children[0], 'selected'));
          assert.ok(hasClass(this.autoComplete.view.children[1], 'selected'));
          assert.ok(!hasClass(this.autoComplete.view.children[2], 'selected'));
        });

        context("back once", function() {
          beforeEach(function() {
            this.autoComplete.back();
          });
          it("should have selected element in the first", function() {
            assert.ok(hasClass(this.autoComplete.view.children[0], 'selected'));
            assert.ok(!hasClass(this.autoComplete.view.children[1], 'selected'));
            assert.ok(!hasClass(this.autoComplete.view.children[2], 'selected'));
          });

          context("back once again", function() {
            beforeEach(function() {
              this.autoComplete.back();
            });
            it("should have selected element in the last element", function() {
              assert.ok(!hasClass(this.autoComplete.view.children[0], 'selected'));
              assert.ok(!hasClass(this.autoComplete.view.children[1], 'selected'));
              assert.ok(hasClass(this.autoComplete.view.children[2], 'selected'));
            });
          });
        });

        context("move next two times again", function() {
          beforeEach(function() {
            this.autoComplete.next();
            this.autoComplete.next();
          });
          it("should back to the first of list", function() {
            assert.ok(hasClass(this.autoComplete.view.children[0], 'selected'));
            assert.ok(!hasClass(this.autoComplete.view.children[1], 'selected'));
            assert.ok(!hasClass(this.autoComplete.view.children[2], 'selected'));
          });
        });
      });
    });
  });
});
