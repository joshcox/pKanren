#lang racket
(require racket/future future-visualizer "test-programs.rkt")
(provide (all-defined-out) (all-from-out "test-programs.rkt"))

;; profiler section

(define profile
  (lambda (th)
    (visualize-futures-thunk th)))

(define-syntax run/time
  (syntax-rules ()
    ((_ th) (time (th)))))

(define-syntax run/stats*
  (syntax-rules ()
    ((_ exp ...)
     (begin
       (begin (run/time (lambda () exp))
              (display "Collecting Garbage ... ")
              (collect-garbage)
              (display "Garbage Collected \n"))
       ...
       (void)))))


(define als (build-list 100 (lambda (x) (gensym))))

(define (run-tests)
  (run/stats*
   ;; (run 3 (q) (call/fresh (lambda (a) (conj (== q a) (pdisj (== a 'a) (== a 'b))))))
   ;; (run 3 (q) (call/fresh (lambda (a) (conj (== q a) (disj (== a 'a) (== a 'b))))))

   ;;(run 1 (q) (reverseo als q))
   ;;(run 1 (q) (preverseo als q))
   (run 1 (q) (pdisj+ (reverseo als q) (reverseo als q) (reverseo als q)))
   )

  )
