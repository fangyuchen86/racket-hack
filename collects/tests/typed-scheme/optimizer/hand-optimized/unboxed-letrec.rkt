#lang racket

(require racket/unsafe/ops)

(letrec ((unboxed-gensym-1 1.0)
         (unboxed-gensym-2 2.0)
         (unboxed-gensym-3 2.0)
         (unboxed-gensym-4 4.0)
         (unboxed-gensym-5 3.0)
         (unboxed-gensym-6 6.0)
         (unboxed-gensym-7 (unsafe-fl+ unboxed-gensym-3 unboxed-gensym-5))
         (unboxed-gensym-8 (unsafe-fl+ unboxed-gensym-4 unboxed-gensym-6))
         (f (lambda (x) (f x))))
  (let* ((unboxed-gensym-9 (unsafe-fl+ unboxed-gensym-1 unboxed-gensym-7))
         (unboxed-gensym-10 (unsafe-fl+ unboxed-gensym-2 unboxed-gensym-8)))
      (unsafe-make-flrectangular unboxed-gensym-9 unboxed-gensym-10)))
(void)