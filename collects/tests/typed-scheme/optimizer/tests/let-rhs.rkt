#;
(
TR opt: let-rhs.rkt 12:10 + -- binary float
3.0
)

#lang typed/scheme
#:optimize



(let ((x (+ 1.0 2.0)))
  x)
