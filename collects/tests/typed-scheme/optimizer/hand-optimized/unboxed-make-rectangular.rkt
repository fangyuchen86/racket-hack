#lang racket

(require racket/unsafe/ops)

(let*-values (((unboxed-gensym-1) 1.0)
              ((unboxed-gensym-2) 2.0)
              ((unboxed-gensym-3) 2.0)
              ((unboxed-gensym-4) 4.0)
              ((unboxed-gensym-5) (unsafe-fl+ unboxed-gensym-1 unboxed-gensym-3))
              ((unboxed-gensym-6) (unsafe-fl+ unboxed-gensym-2 unboxed-gensym-4)))
  (unsafe-make-flrectangular unboxed-gensym-5 unboxed-gensym-6))
(let*-values (((unboxed-gensym-1) 1.0)
              ((unboxed-gensym-2) 2.0)
              ((unboxed-gensym-3) 2.0)
              ((unboxed-gensym-4) 4.0)
              ((unboxed-gensym-5) (unsafe-fl+ unboxed-gensym-1 unboxed-gensym-3))
              ((unboxed-gensym-6) (unsafe-fl+ unboxed-gensym-2 unboxed-gensym-4)))
  (unsafe-make-flrectangular unboxed-gensym-5 unboxed-gensym-6))
(void)