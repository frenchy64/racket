#lang info

(define collection 'multi)

(define deps '("scheme-lib"
               "base"
               "data-lib"
               "tex-table"
               "profile-lib"
               "unstable-2d"))
(define build-deps '("rackunit-lib"))

(define pkg-desc "implementation (no documentation) part of \"redex\"")

(define pkg-authors '(robby bfetscher))
