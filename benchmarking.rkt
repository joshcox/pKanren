#lang racket
(require "test-programs.rkt")
(require C311/pmatch)
(provide (all-defined-out) (all-from-out "test-programs.rkt"))

(define-syntax-rule (run/time th) (begin (collect-garbage) (time-apply th '())))

(define make-benchmark-suite list)

(define-syntax-rule (benchmark str bench) (cons str (lambda () bench)))

(define-syntax-rule (run-benchmark-suite* runner b* ...) (list (run-benchmark-suite b* runner) ...))

(define last-results (make-parameter #f))

(define run-benchmark-suite
  (lambda (benchmarks runner)
    (let ((suite-name (car benchmarks)))
      (last-results
       (for/list ((i (length (cdr benchmarks))))
         (let ((b (list-ref (cdr benchmarks) i)))
           (let ((name (car b)) (benchmark (cdr b)))
             (let-values (((ans cpu real gc) (run/time benchmark)))
               (runner suite-name name ans cpu real gc)))))))))

(define std-runner
  (lambda (s n a c r g)
    (printf "~a : ~a ~nAns: ~a ~nCpu: ~a Real: ~a GC: ~a~n" s n a c r g)))

(define (run-all-benchmarks)
  (run-benchmark-suite* std-runner microKanren-benchmarks microKanren-interpreter-benchmarks))

(define als (build-list 100 (lambda (x) 'a)))
(define als2 (build-list 500 (lambda (x) 'a)))

(define microKanren-benchmarks
  (make-benchmark-suite
   "microKanren - nonInterpreter"
   (benchmark "Basic mk"
              (run 3 (q) (call/fresh (lambda (a) (conj (== q a) (disj (== a 'a) (== a 'b)))))))
   (benchmark "Basic pmk"
              (run 3 (q) (call/fresh (lambda (a) (pconj (== q a) (pdisj (== a 'a) (== a 'b)))))))
   (benchmark "Reverseo of list of length 100" (run 1 (q) (reverseo als q)))
   (benchmark "Concurrent Reverseo of list of length 100"(run 1 (q) (preverseo als q)))))

(define microKanren-interpreter-benchmarks
  (make-benchmark-suite
   "microKanren - Interpreter"

   (benchmark
    "Reverseo of list length 100"
    (mk `(letrec ((appendo
                   (lambda (l s o)
                     (disj
                      (conj (== l '()) (== o s))
                      (call/fresh
                       (lambda (a)
                         (call/fresh
                          (lambda (b)
                            (call/fresh
                             (lambda (res)
                               (conj (== l (cons a b)) ;;`(,a . ,b) 
                                     (conj (== o (cons a res)) ;; `(,a . ,res)
                                           (lambda (s/c)
                                             (lambda ()
                                               ((appendo b s res) s/c)))))))))))))))
           (letrec ((reverseo
                     (lambda (ls o)
                       (disj
                        (conj (== ls '()) (== o ls))
                        (call/fresh
                         (lambda (a)
                           (call/fresh
                            (lambda (b)
                              (call/fresh
                               (lambda (res)
                                 (conj (== (cons a b) ls) ;; `(,a . ,b)
                                       (conj  (lambda (s/c)
                                                (lambda ()
                                                  ((reverseo b res) s/c)))
                                              (lambda (s/c)
                                                (lambda ()
                                                  ((appendo res (cons a '()) o) s/c)))))))))))))))
             (run 1 (q) (reverseo (quote ,als) q))))))

   (benchmark
    "P-Reverseo of list of length 100"
    (mk `(letrec ((appendo
                   (lambda (l s o)
                     (pdisj
                      (conj (== l '()) (== o s))
                      (call/fresh
                       (lambda (a)
                         (call/fresh
                          (lambda (b)
                            (call/fresh
                             (lambda (res)
                               (conj (== l (cons a b)) ;;`(,a . ,b) 
                                     (conj (== o (cons a res)) ;; `(,a . ,res)
                                           (lambda (s/c)
                                             (lambda ()
                                               ((appendo b s res) s/c)))))))))))))))
           (letrec ((reverseo
                     (lambda (ls o)
                       (pdisj
                        (conj (== ls '()) (== o ls))
                        (call/fresh
                         (lambda (a)
                           (call/fresh
                            (lambda (b)
                              (call/fresh
                               (lambda (res)
                                 (conj (== (cons a b) ls) ;; `(,a . ,b)
                                       (conj  (lambda (s/c)
                                                (lambda ()
                                                  ((reverseo b res) s/c)))
                                              (lambda (s/c)
                                                (lambda ()
                                                  ((appendo res (cons a '()) o) s/c)))))))))))))))
             (run 1 (q) (reverseo (quote ,als) q))))))
                  ))

(define (main)
  (run-all-benchmarks))