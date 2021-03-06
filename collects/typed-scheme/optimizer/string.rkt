#lang scheme/base

(require syntax/parse
         (for-template scheme/base scheme/unsafe/ops)
         "../utils/utils.rkt"
         (types abbrev)
         (optimizer utils logging))

(provide string-opt-expr string-expr bytes-expr)

(define-syntax-class string-expr
  #:commit
  (pattern e:expr
           #:when (isoftype? #'e -String)
           #:with opt ((optimize) #'e)))
(define-syntax-class bytes-expr
  #:commit
  (pattern e:expr
           #:when (isoftype? #'e -Bytes)
           #:with opt ((optimize) #'e)))

(define-syntax-class string-opt-expr
  #:commit
  (pattern (#%plain-app (~literal string-length) s:string-expr)
           #:with opt
           (begin (log-optimization "string-length" #'op)
                  #'(unsafe-string-length s.opt)))
  (pattern (#%plain-app (~literal bytes-length) s:bytes-expr)
           #:with opt
           (begin (log-optimization "bytes-length" #'op)
                  #'(unsafe-bytes-length s.opt))))
