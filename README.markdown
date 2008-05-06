This is a simple library for managing your personal unit tests. If
you're unfamiliar with the concept, please read [this blog post][].

   [this blog post]: http://withoutane.com/rants/2007/08/personal-unit-tests

Here's an example use:

    (require 'selftest)
    (define-selftest exercise
      "Did I get >=30min of exercise yesterday"
      :group 'health
      :when 'always)

The command `selftest-run` may be used to run all of your tests.
