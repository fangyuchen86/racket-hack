#lang plai/mutator
(allocator-setup "../good-collectors/good-collector.ss" 100)
(define x (cons 1 2))
((set-first! x 2) 1)