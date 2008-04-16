;;; selftest.el --- Personal unit tests

;; Copyright (C) 2007  Edward O'Connor

;; Author: Edward O'Connor <hober0@gmail.com>
;; Keywords: convenience

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This is a simple library for managing your personal unit tests. If
;; you're unfamiliar with the concept, please read this blog post:
;;
;;      http://withoutane.com/rants/2007/08/personal-unit-tests

;; Here's an example use:
;;
;; (require 'selftest)
;; (define-selftest exercise
;;   "Did I get >=30min of exercise yesterday"
;;   :group 'health
;;   :when 'always)

;; The command `selftest-run' may be used to run all of your tests.

;;; History:
;; 2007-09-11: Initial version.
;; 2007-09-13: Added `selftest-analyze'.
;; 2007-09-14: Added automatic Twitter posting.
;;             Uses (a patched version of) twit.el, which see.
;; 2008-01-08: Added ability to filter when each test should be taken.

;;; Code:

(defvar selftest-tests '())

(defvar selftest-twitter-results t
  "*When non-null, post selftest results to your Twitter account.
Requires twit.el, which is available on the EmacsWiki.")

(defun selftest-ask (prompt)
  "Like `y-or-n-p', but asks (with PROMPT) for pass, fail, or skip."
  (setq prompt (format "%s (pass, fail, or skip)? " prompt))
  (let* ((answers '(("pass" . :pass) ("fail" . :fail) ("skip" . :skip)
                    ("p" . :pass) ("f" . :fail) ("s" . :skip)
                    ("y" . :pass) ("n" . :fail)))
         (answer ""))
    (while (string-equal answer "")
      (setq answer (completing-read prompt answers nil t)))
    ;; "And just in case my point you have missed
    ;; Somehow I preferred (CDR (ASSQ KEY A-LIST))"
    (cdr (assoc answer answers))))

(defmacro define-selftest (slug question &rest params)
  "Defines a new personal unit test named SLUG.
QUESTION is the question to ask the user.
PARAMS are currently ignored."
  (let ((test-func-sym (intern (format "selftest-%s" slug)))
        (group (or (plist-get params :group) 'misc))
        (predicate (or (plist-get params :when) 'always)))
    `(progn
       (defun ,test-func-sym (answer)
         ,(format "Personal unit test %s" (list 'quote slug))
         (interactive (list (selftest-ask ,question)))
         answer)
       (put ',test-func-sym :selftest-slug ',slug)
       (put ',test-func-sym :selftest-group ,group)
       (put ',test-func-sym :selftest-predicate ,predicate)
       (add-to-list 'selftest-tests ',test-func-sym)
       ;; FIXME: do something with group
       ',test-func-sym)))

(put 'define-selftest 'lisp-indent-function 1)
(put 'define-selftest 'doc-string-elt 2)

(defun selftest-analyze (results)
  "Produce a report on the pass/fail ratio in RESULTS."
  (let ((date (car results))
        (results (cdr results))
        (pass-count 0)
        (fail-count 0)
        (pass/fail-count 0)
        (skip-count 0))
    (dolist (test results)
      (when (eq (cdr test) :pass) (incf pass-count))
      (when (eq (cdr test) :fail) (incf fail-count))
      (when (eq (cdr test) :skip) (incf skip-count)))
    (setq pass/fail-count (+ pass-count fail-count))
    (format "Personal unit test results for %s: %d/%d (%d%%) passed, %d skipped."
            date pass-count pass/fail-count
            (round (* 100 (/ (float pass-count) (float pass/fail-count))))
            skip-count)))

(defun selftest-always-p ()
  t)
(put 'always :selftest-predicate 'selftest-always-p)

(defun selftest-monday-p ()
  (let ((day-of-week (nth 6 (decode-time (current-time)))))
    (= day-of-week 1)))
(put 'monday :selftest-predicate 'selftest-monday-p)

(defun selftest-weekday-p ()
  (let ((day-of-week (nth 6 (decode-time (current-time)))))
    (and (> day-of-week 0) (< day-of-week 7))))
(put 'weekday :selftest-predicate 'selftest-weekday-p)

(defun selftest-weekend-p ()
  (not (selftest-weekday-p)))
(put 'weekend :selftest-predicate 'selftest-weekend-p)

(defun selftest-predicate (sym)
  "Return the selftest predicate for SYM.
Defaults to `selftest-always-p'."
  (let ((predicate (get sym :selftest-predicate)))
    (cond (predicate (selftest-predicate predicate))
          ((functionp sym) sym)
          (t 'always))))

(defun selftest-take-test-p (test)
  "Non-null iff TEST should be taken today."
  (funcall (selftest-predicate test)))

(defun selftest-run (&rest ignore)
  "Run all defined selftests, and insert the results at point."
  (interactive)
  (let ((results '())
        result)
    (dolist (test selftest-tests)
      (if (selftest-take-test-p test)
          (setq result (call-interactively test))
        (setq result :skip))
      (add-to-list 'results (cons (get test :selftest-slug) result)))
    (setq results (cons (format-time-string "%Y-%m-%d") results))
    (prin1 results (current-buffer))
    (let ((analysis (selftest-analyze results)))
      (when (called-interactively-p)
        (message "%s" analysis))
      (when (and (require 'twit nil t) selftest-twitter-results)
        (twit-post analysis)))
    results))

(provide 'selftest)
;;; selftest.el ends here
