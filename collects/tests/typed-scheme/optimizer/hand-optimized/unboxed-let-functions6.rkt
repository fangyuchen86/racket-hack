#lang racket

(require racket/unsafe/ops racket/flonum)

(let*-values (((unboxed-gensym-1) 0.0)
              ((unboxed-gensym-2) 0.0))
  ((letrec-values
    (((loop)
      (lambda (unboxed-real-1 unboxed-imag-2 l)
        (if (null? l)
            (let*-values (((unboxed-gensym-3) 0.0)
                          ((unboxed-gensym-4) 1.0)
                          ((unboxed-gensym-5) (unsafe-fl+ unboxed-real-1 unboxed-gensym-3))
                          ((unboxed-gensym-6) (unsafe-fl+ unboxed-imag-2 unboxed-gensym-4)))
              (unsafe-make-flrectangular unboxed-gensym-5 unboxed-gensym-6))
            (let*-values (((unboxed-gensym-1) (->fl (unsafe-car l)))
                          ((unboxed-gensym-2) (unsafe-fl+ unboxed-real-1 unboxed-gensym-1))
                          ((unboxed-gensym-3) unboxed-imag-2))
              (loop unboxed-gensym-2 unboxed-gensym-3
                    (unsafe-cdr l)))))))
    loop)
   unboxed-gensym-1 unboxed-gensym-2 '(1 2 3)))
(void)