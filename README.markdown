This is a simple library for managing your personal unit tests. If
you're unfamiliar with the concept, please read [this blog post][].
[Michal Wallace][] came up with the idea. Here's how he describes them:

   [this blog post]: http://withoutane.com/rants/2007/08/personal-unit-tests
   [Michal Wallace]: http://withoutane.com/

> The way I see it, there are certain things I ought to be doing to be
> productive and effective no matter what my goals are. These are things
> that are relatively easy to set up, but take discipline and awareness
> to maintain. I really think that if I focus on maintaining these
> habits or processes, then the goals will take care of themselves.
>
> Basically, I've made a list of personal unit tests: assertions about
> myself that I'd like to be true.

Here's an example use of `selftest.el`:

    (require 'selftest)
    (define-selftest exercise
      "Did I get >=30min of exercise yesterday"
      :group 'health
      :when 'always)

The command `selftest-run` may be used to run all of your tests.
