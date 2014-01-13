#lang racket/base

(require "test-utils.rkt"
         racket/list racket/format rackunit
         (static-contracts instantiate optimize combinators)
         (for-syntax racket/base syntax/parse))

(provide tests)
(gen-test-main)

(define-syntax (check-optimize stx)
  (syntax-parse stx
    [(_ argument* #:pos positive-expected* #:neg negative-expected*)
     #'(test-suite (~a 'argument*)
         (test-case "Trusted Positive"
           (check-optimize-helper argument* positive-expected* #t #f))
         (test-case "Trusted Negative"
           (check-optimize-helper argument* negative-expected* #f #t)))]))

(define (check-optimize-helper argument expected trusted-positive trusted-negative)
  (define trusted-side
    (cond
      [(and trusted-positive trusted-negative) 'both]
      [trusted-positive 'positive]
      [trusted-negative 'negative]
      [else 'neither]))
  (with-check-info*
    (list (make-check-info 'original argument)
          (make-check-info 'trusted trusted-side)
          (make-check-expected expected))
    (λ ()
      (let ([opt (optimize argument
                   #:trusted-positive trusted-positive
                   #:trusted-negative trusted-negative)])
        (with-check-info* (list (make-check-actual opt))
          (lambda ()
            (unless (equal? opt expected)
              (fail-check))))))))

(define tests
  (test-suite "Static Contract Optimizer Tests"
    ;; Lists
    (check-optimize (listof/sc any/sc)
      #:pos any/sc
      #:neg list?/sc)
    (check-optimize (listof/sc none/sc)
      #:pos any/sc
      #:neg empty-list/sc)

    ;; Heterogeneous Lists
    ;; TODO fix ability to test equality here
    #;
    (check-optimize (list/sc any/sc)
      #:pos any/sc
      #:neg (list-length/sc 1))
    (check-optimize (list/sc none/sc)
      #:pos any/sc
      #:neg none/sc)
    (check-optimize (list/sc)
      #:pos any/sc
      #:neg empty-list/sc)

    ;; Sets
    (check-optimize (set/sc any/sc)
      #:pos any/sc
      #:neg set?/sc)
    (check-optimize (set/sc none/sc)
      #:pos any/sc
      #:neg empty-set/sc)


    ;; Vectors
    (check-optimize (vectorof/sc any/sc)
      #:pos any/sc
      #:neg vector?/sc)
    (check-optimize (vectorof/sc none/sc)
      #:pos (vectorof/sc none/sc)
      #:neg (vectorof/sc none/sc))

    ;; Heterogeneous Vectors
    ;; TODO fix ability to test equality here
    #;
    (check-optimize (vector/sc any/sc)
      #:pos any/sc
      #:neg (vector-length/sc 1))
    (check-optimize (vector/sc none/sc)
      #:pos (vector/sc none/sc)
      #:neg (vector/sc none/sc))
    ;; TODO fix ability to test equality here
    #;
    (check-optimize (vector/sc)
      #:pos any/sc
      #:neg empty-vector/sc)
    (check-optimize (vector/sc set?/sc)
      #:pos (vector/sc set?/sc)
      #:neg (vector/sc set?/sc))

    ;; HashTables
    (check-optimize (hash/sc any/sc any/sc)
      #:pos any/sc
      #:neg hash?/sc)
    (check-optimize (hash/sc none/sc any/sc)
      #:pos (hash/sc none/sc any/sc)
      #:neg (hash/sc none/sc any/sc))
    (check-optimize (hash/sc any/sc none/sc)
      #:pos (hash/sc any/sc none/sc)
      #:neg (hash/sc any/sc none/sc))

    ;; And
    (check-optimize (and/sc set?/sc)
      #:pos any/sc
      #:neg set?/sc)
    (check-optimize (and/sc set?/sc any/sc)
      #:pos any/sc
      #:neg set?/sc)
    (check-optimize (and/sc set?/sc none/sc)
      #:pos any/sc
      #:neg none/sc)
    (check-optimize (and/sc)
      #:pos any/sc
      #:neg any/sc)
    (check-optimize (and/sc any/sc any/sc)
      #:pos any/sc
      #:neg any/sc)


    ;; Or
    (check-optimize (or/sc set?/sc)
      #:pos any/sc
      #:neg set?/sc)
    (check-optimize (or/sc set?/sc any/sc)
      #:pos any/sc
      #:neg any/sc)
    (check-optimize (or/sc set?/sc none/sc)
      #:pos any/sc
      #:neg set?/sc)
    (check-optimize (or/sc)
      #:pos any/sc
      #:neg none/sc)
    (check-optimize (or/sc none/sc none/sc)
      #:pos any/sc
      #:neg none/sc)

    ;; None
    (check-optimize none/sc
      #:pos any/sc
      #:neg none/sc)

    ;; Boxes
    (check-optimize (box/sc any/sc)
      #:pos any/sc
      #:neg box?/sc)
    (check-optimize (box/sc none/sc)
      #:pos (box/sc none/sc)
      #:neg (box/sc none/sc))
    (check-optimize (box/sc set?/sc)
      #:pos (box/sc set?/sc)
      #:neg (box/sc set?/sc))

    ;; Syntax Objects
    (check-optimize (syntax/sc any/sc)
      #:pos any/sc
      #:neg syntax?/sc)
    (check-optimize (syntax/sc none/sc)
      #:pos any/sc
      #:neg none/sc)
    (check-optimize (syntax/sc set?/sc)
      #:pos any/sc
      #:neg (syntax/sc set?/sc))

    ;; Promises
    (check-optimize (promise/sc any/sc)
      #:pos any/sc
      #:neg promise?/sc)
    (check-optimize (promise/sc none/sc)
      #:pos any/sc
      #:neg (promise/sc none/sc))
    (check-optimize (promise/sc set?/sc)
      #:pos any/sc
      #:neg (promise/sc set?/sc))
    (check-optimize (promise/sc (box/sc set?/sc))
      #:pos (promise/sc (box/sc set?/sc))
      #:neg (promise/sc (box/sc set?/sc)))

    (check-optimize
      (function/sc (list (listof/sc any/sc))
                   (list)
                   (list)
                   (list)
                   #f
                   (list (listof/sc any/sc)))
      #:pos
      (function/sc (list list?/sc)
                   (list)
                   (list)
                   (list)
                   #f
                   #f)
      #:neg
      (function/sc (list any/sc)
                   (list)
                   (list)
                   (list)
                   #f
                   (list list?/sc)))
    (check-optimize
      (function/sc (list (listof/sc any/sc))
                   (list)
                   (list)
                   (list)
                   #f
                   (list any/sc))
      #:pos
      (function/sc (list list?/sc)
                   (list)
                   (list)
                   (list)
                   #f
                   #f)
      #:neg
      (function/sc (list any/sc)
                   (list)
                   (list)
                   (list)
                   #f
                   (list any/sc)))

    (check-optimize (case->/sc empty)
      #:pos (case->/sc empty)
      #:neg (case->/sc empty))
    (check-optimize (parameter/sc list?/sc set?/sc)
      #:pos (parameter/sc list?/sc any/sc)
      #:neg (parameter/sc any/sc set?/sc))

    (check-optimize
      (case->/sc (list (arr/sc (list (listof/sc any/sc)) (listof/sc (set/sc any/sc)) (list (listof/sc any/sc)))))
      #:pos (case->/sc (list (arr/sc (list list?/sc) (listof/sc set?/sc) #f)))
      #:neg (case->/sc (list (arr/sc (list any/sc) any/sc (list list?/sc)))))

    (check-optimize
      (object/sc (list (member-spec 'field 'x (listof/sc any/sc))))
      #:pos (object/sc (list (member-spec 'field 'x list?/sc)))
      #:neg (object/sc (list (member-spec 'field 'x list?/sc))))

    (check-optimize
      (class/sc (list (member-spec 'field 'x (listof/sc any/sc))) #f empty empty)
      #:pos (class/sc (list (member-spec 'field 'x list?/sc)) #f empty empty)
      #:neg (class/sc (list (member-spec 'field 'x list?/sc)) #f empty empty))


    ))