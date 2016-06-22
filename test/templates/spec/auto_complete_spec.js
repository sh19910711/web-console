describe("Auto Complete", function() {
  describe("move functions", function() {
    context("set up with three elements", function() {
      beforeEach(function() {
        var self = this.autoComplete = new AutoComplete(["something", "somewhat", "somewhere"]);
        this.assertSelected = function(pos) {
          for (var i = 0; i < self.view.children.length; ++i) {
            if (i === pos) {
              assert.ok(hasClass(self.view.children[i], 'selected'));
            } else {
              assert.ok(!hasClass(self.view.children[i], 'selected'));
            }
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
        beforeEach(function() {
          this.autoComplete.next();
          this.autoComplete.next();
        });
        it("should point the 1-th element", function() {
          this.assertSelected(1);
        });

        context("back once", function() {
          beforeEach(function() {
            this.autoComplete.back();
          });
          it("should point the 0-th element", function() {
            this.assertSelected(0);
          });

          context("back once again", function() {
            beforeEach(function() {
              this.autoComplete.back();
            });
            it("should point the last element", function() {
              this.assertSelected(2);
            });
          });
        });

        context("move next two times again", function() {
          beforeEach(function() {
            this.autoComplete.next();
            this.autoComplete.next();
          });
          it("should back to the first of list", function() {
            this.assertSelected(0);
          });
        });
      });
    });
  });
});
