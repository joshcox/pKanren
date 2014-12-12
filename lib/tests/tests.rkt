#lang racket
(require "../miniKanren-base/miniKanren-base.rkt"
         "../numbers/numbers.rkt"
         "test-programs.rkt")
(provide main)


(define-syntax-rule (run/time th) (time-apply th '()))
(define-syntax-rule (benchmark str bench) (cons str (lambda () bench)))
(define-syntax-rule (run-benchmark-suite* runner b* ...) 
  (begin (begin (printf "~a:~n" (car b*)) (run-benchmark-suite b* runner) (newline)) ...))
(define make-benchmark-suite list)

(define run-benchmark-suite
  (lambda (benchmarks runner)
    (let ((suite-name (car benchmarks)))
      (for ((b (cdr benchmarks)))
        (begin
          (let-values (((ans cpu real gc) (run/time (cdr b))))
              (runner suite-name (car b) (car ans) cpu real gc))
          (collect-garbage))))))

;; Runners :: (suite-name, bench-name, ans, cpu-time, real-time, gc-time) -> something
(define-syntax-rule (runner (v ...) exp) (lambda (v ...) exp))
(define-syntax-rule (runners (v ...) r ...) (lambda (v ...) (begin (r v ...) ...)))

(define std-runner (runner (s n a c r g) (printf "\t~a ~n\t  Cpu: ~a Real: ~a GC: ~a~n" n c r g)))
(define print-answer (runner (s n a c r g) (printf "\t  ~a~n" a)))
(define mk-runner (runners (s n a c r g) write-answer std-runner print-answer))
(define write-answer 
  (runner (s n a c r g)
    (let ((f (open-output-file 
              (build-path (current-directory) "benchmark-results" (string-append n ".txt"))
              #:exists 'append)))
      (write r f)(newline f))))

;; MicroKanren Benchmarking
(define a '(a b c d e f g h i j k l m n o p q r s t u v w x y z))
(define ls25 (build-list 25 (lambda (i) (list-ref a (modulo i 26)))))
(define ls50 (build-list 50 (lambda (i) (list-ref a (modulo i 26)))))
(define ls100 (build-list 100 (lambda (i) (list-ref a (modulo i 26)))))
(define ls2 (build-list 200 (lambda (i) (list-ref a (modulo i 26)))))
(define num1000 (build-num 1000))
(define num2000 (build-num 2000))
(define num10000 (build-num 10000))

(define microKanren-benchmarks
  (make-benchmark-suite
   "microKanren - nonInterpreter"

   (benchmark "Parellel 1000^2" (run 1 (q) (*o num1000 num1000 q)))

   (benchmark "Parellel 2000^2" (run 1 (q) (*o num2000 num2000 q)))

   (benchmark "Parellel 10000^2" (run 1 (q) (*o num10000 num10000 q)))
   
   (benchmark "two big items"
              (run 2 (q) (disj (reverseo ls50 q) (reverseo ls50 q))))
   
   
   ;; (benchmark "Reverseo ~~ 25" (run 1 (q) (reverseo ls25 q)))
   ;; (benchmark "Concurrent Reverseo ~~ 25" (run 1 (q) (preverseo ls25 q)))
   
   ;; (benchmark "Reverseo ~~ 50" (run 1 (q) (reverseo ls50 q)))
   ;; (benchmark "Concurrent Reverseo ~~ 50" (run 1 (q) (preverseo ls50 q)))
   
   ;(benchmark "Appendo" (run 1 (q) (pappendo2 '(a b) '(c d) q)))
   ;; (benchmark "Reverseo ~~ 100" (run 1 (q) (reverseo ls100 q)))
   ;; (benchmark "Concurrent Reverseo ~~ 100" (run 1 (q) (preverseo ls100 q)))
   ;; (benchmark "Reverseo ~~ 200"(run 1 (q) (reverseo ls2 q)))
   ;; (benchmark "Concurrent Reverseo ~~ 200" (run 1 (q) (preverseo ls2 q)))
   ))

(define (main)
  (run-benchmark-suite* mk-runner microKanren-benchmarks))
