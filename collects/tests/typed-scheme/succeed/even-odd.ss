#lang typed/scheme

(define-struct: (A) Z ([b : A]))
(define-struct: (A) O ([b : A]))

(define-type Bitstring (Rec B (U '() (Z B) (O B))))
(define-type EvenParity (Rec Even (U '() (Z Even) (O (Rec Odd (U (Z Odd) (O Even)))))))
(define-type OddParity (Rec Odd (U (Z Odd) (O (Rec Even (U '() (Z Even) (O Odd)))))))

(: append-one (case-lambda (EvenParity -> OddParity)
                           (OddParity -> EvenParity)
                           (Bitstring -> Bitstring)))
(define (append-one l)
  (if (null? l)
      (make-O '())
      (if (Z? l) 
          (make-Z (append-one (Z-b l)))
          (make-O (append-one (O-b l))))))