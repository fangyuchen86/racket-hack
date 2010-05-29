#lang at-exp s-exp meta/web/html

;; list of a header paragraphs and sub paragraphs (don't use `p' since it looks
;; like they should not be nested)
(provide parlist)
(define (parlist first . rest)
  (list (div class: 'parlisttitle first)
        (map (lambda (p) (div class: 'parlistitem p)) rest)))