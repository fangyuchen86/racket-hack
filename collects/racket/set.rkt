#lang racket/base
(require (for-syntax racket/base)
         racket/serialize
         racket/pretty
         racket/contract)

(provide set seteq seteqv
         set? set-eq? set-eqv? set-equal?
         set-empty? set-count
         set-member? set-add set-remove
         set-union set-intersect set-subtract set-symmetric-difference
         subset? proper-subset?
         set-map set-for-each 
         (rename-out [*in-set in-set])
         for/set for/seteq for/seteqv
         for*/set for*/seteq for*/seteqv
         (rename-out [*set/c set/c])
         set=?
         set->list
         list->set list->seteq list->seteqv)

(define-serializable-struct set (ht)
  #:omit-define-syntaxes
  #:property prop:custom-print-quotable 'never
  #:property prop:custom-write
  (lambda (s port mode)
    (define recur-print (cond
                         [(not mode) display]
                         [(integer? mode) (lambda (p port) (print p port mode))]
                         [else write]))
    (define (print-prefix port)
      (cond
        [(equal? 0 mode)
         (write-string "(set" port)
         (print-prefix-id port)]
        [else
         (write-string "#<set" port)
         (print-prefix-id port)
         (write-string ":" port)]))
    (define (print-prefix-id port)
      (cond
        [(set-equal? s) (void)]
        [(set-eqv? s) (write-string "eqv" port)]
        [(set-eq? s) (write-string "eq" port)]))
    (define (print-suffix port)
      (if (equal? 0 mode)
          (write-string ")" port)
          (write-string ">" port)))
    (define (print-one-line port)
      (print-prefix port)
      (set-for-each s 
                    (lambda (e) 
                      (write-string " " port)
                      (recur-print e port)))
      (print-suffix port))
    (define (print-multi-line port)
      (let-values ([(line col pos) (port-next-location port)])
        (print-prefix port)
        (set-for-each s 
                      (lambda (e) 
                        (pretty-print-newline port (pretty-print-columns))
                        (write-string (make-string (add1 col) #\space) port)
                        (recur-print e port)))
        (print-suffix port)))
    (cond
     [(and (pretty-printing)
           (integer? (pretty-print-columns)))
      ((let/ec esc
         (letrec ([tport (make-tentative-pretty-print-output-port
                          port
                          (- (pretty-print-columns) 1)
                          (lambda () 
                            (esc
                             (lambda ()
                               (tentative-pretty-print-port-cancel tport)
                               (print-multi-line port)))))])
           (print-one-line tport)
           (tentative-pretty-print-port-transfer tport port))
         void))]
     [else (print-one-line port)]))
  #:property prop:equal+hash (list 
                              (lambda (set1 set2 =?)
                                (=? (set-ht set1) (set-ht set2)))
                              (lambda (set hc) (add1 (hc (set-ht set))))
                              (lambda (set hc) (add1 (hc (set-ht set)))))
  #:property prop:sequence (lambda (v) (*in-set v)))

(define (set . elems)
  (make-set (make-immutable-hash (map (lambda (k) (cons k #t)) elems))))
(define (seteq . elems)
  (make-set (make-immutable-hasheq (map (lambda (k) (cons k #t)) elems))))
(define (seteqv . elems)
  (make-set (make-immutable-hasheqv (map (lambda (k) (cons k #t)) elems))))

(define (set-eq? set)
  (unless (set? set) (raise-type-error 'set-eq? "set" 0 set))
  (hash-eq? (set-ht set)))
(define (set-eqv? set)
  (unless (set? set) (raise-type-error 'set-eqv? "set" 0 set))
  (hash-eqv? (set-ht set)))
(define (set-equal? set)
  (unless (set? set) (raise-type-error 'set-equal? "set" 0 set))
  (let* ([ht (set-ht set)])
    (not (or (hash-eq? ht)
             (hash-eqv? ht)))))

(define (set-empty? set)
  (unless (set? set) (raise-type-error 'set-empty? "set" 0 set))
  (zero? (hash-count (set-ht set))))

(define (set-count set)
  (unless (set? set) (raise-type-error 'set-count "set" 0 set))
  (hash-count (set-ht set)))

(define (set-member? set v)
  (unless (set? set) (raise-type-error 'set-member? "set" 0 set v))
  (hash-ref (set-ht set) v #f))

(define (set-add set v)
  (unless (set? set) (raise-type-error 'set-add "set" 0 set v))
  (make-set (hash-set (set-ht set) v #t)))

(define (set-remove set v)
  (unless (set? set) (raise-type-error 'set-remove "set" 0 set v))
  (make-set (hash-remove (set-ht set) v)))

(define set-union
  (case-lambda
   ;; No 0 argument set exists because its not clear what type of set
   ;; to return. A keyword is unsatisfactory because it may be hard to
   ;; remember. A simple solution is just to provide the type of the
   ;; empty set that you want, like (set-union (set)) or
   ;; (set-union (set-eqv))
   ;; [() (set)]
   [(set) 
    (unless (set? set) (raise-type-error 'set-union "set" 0 set))
    set]
   [(set set2)
    (unless (set? set) (raise-type-error 'set-union "set" 0 set set2))
    (unless (set? set2) (raise-type-error 'set-union "set" 1 set set2))
    (let ([ht (set-ht set)]
          [ht2 (set-ht set2)])
      (unless (and (eq? (hash-eq? ht) (hash-eq? ht2))
                   (eq? (hash-eqv? ht) (hash-eqv? ht2)))
        (raise-mismatch-error 'set-union "set's equivalence predicate is not the same as the first set: "
                              set2))
      (let-values ([(ht ht2)
                    (if ((hash-count ht2) . > . (hash-count ht))
                        (values ht2 ht)
                        (values ht ht2))])
        (make-set
         (for/fold ([ht ht]) ([v (in-hash-keys ht2)])
           (hash-set ht v #t)))))]
   [(set . sets)
    (for ([s (in-list (cons set sets))]
          [i (in-naturals)])
      (unless (set? s) (apply raise-type-error 'set-union "set" i (cons set sets))))
    (for/fold ([set set]) ([set2 (in-list sets)])
      (set-union set set2))]))

(define (empty-like ht)
  (cond
   [(hash-eqv? ht) #hasheqv()]
   [(hash-eq? ht) #hasheq()]
   [else #hash()]))

(define set-intersect
  (case-lambda
   [(set) 
    (unless (set? set) (raise-type-error 'set-intersect "set" 0 set))
    set]
   [(set set2)
    (unless (set? set) (raise-type-error 'set-intersect "set" 0 set set2))
    (unless (set? set2) (raise-type-error 'set-intersect "set" 1 set set2))
    (let ([ht1 (set-ht set)]
          [ht2 (set-ht set2)])
      (unless (and (eq? (hash-eq? ht1) (hash-eq? ht2))
                   (eq? (hash-eqv? ht1) (hash-eqv? ht2)))
        (raise-mismatch-error 'set-union "set's equivalence predicate is not the same as the first set: "
                              set2))
      (let-values ([(ht1 ht2) (if ((hash-count ht1) . < . (hash-count ht2))
                                  (values ht1 ht2)
                                  (values ht2 ht1))])
        (make-set
         (for/fold ([ht (empty-like (set-ht set))]) ([v (in-hash-keys ht1)])
           (if (hash-ref ht2 v #f)
               (hash-set ht v #t)
               ht)))))]
   [(set . sets)
    (for ([s (in-list (cons set sets))]
          [i (in-naturals)])
      (unless (set? s) (apply raise-type-error 'set-intersect "set" i (cons set sets))))
    (for/fold ([set set]) ([set2 (in-list sets)])
      (set-intersect set set2))]))

(define set-subtract
  (case-lambda
   [(set) 
    (unless (set? set) (raise-type-error 'set-subtract "set" 0 set))
    set]
   [(set set2)
    (unless (set? set) (raise-type-error 'set-subtract "set" 0 set set2))
    (unless (set? set2) (raise-type-error 'set-subtract "set" 1 set set2))
    (let ([ht1 (set-ht set)]
          [ht2 (set-ht set2)])
      (unless (and (eq? (hash-eq? ht1) (hash-eq? ht2))
                   (eq? (hash-eqv? ht1) (hash-eqv? ht2)))
        (raise-mismatch-error 'set-union "set's equivalence predicate is not the same as the first set: "
                              set2))
      (if ((* 2 (hash-count ht1)) . < . (hash-count ht2))
          ;; Add elements from ht1 that are not in ht2:
          (make-set
           (for/fold ([ht (empty-like ht1)]) ([v (in-hash-keys ht1)])
             (if (hash-ref ht2 v #f)
                 ht
                 (hash-set ht v #t))))
          ;; Remove elements from ht1 that are in ht2
          (make-set
           (for/fold ([ht ht1]) ([v (in-hash-keys ht2)])
             (hash-remove ht v)))))]
   [(set . sets)
    (for ([s (in-list (cons set sets))]
          [i (in-naturals)])
      (unless (set? s) (apply raise-type-error 'set-subtract "set" i (cons s sets))))
    (for/fold ([set set]) ([set2 (in-list sets)])
      (set-subtract set set2))]))

(define (subset* who set2 set1 proper?)
  (unless (set? set2) (raise-type-error who "set" 0 set2 set1))
  (unless (set? set1) (raise-type-error who "set" 0 set2 set1))
  (let ([ht1 (set-ht set1)]
        [ht2 (set-ht set2)])
    (unless (and (eq? (hash-eq? ht1) (hash-eq? ht2))
                 (eq? (hash-eqv? ht1) (hash-eqv? ht2)))
      (raise-mismatch-error who
                            "second set's equivalence predicate is not the same as the first set: "
                            set2))
    (and (for/and ([v (in-hash-keys ht2)])
           (hash-ref ht1 v #f))
         (if proper?
             (< (hash-count ht2) (hash-count ht1))
             #t))))

(define (subset? one two)
  (subset* 'subset? one two #f))

(define (proper-subset? one two)
  (subset* 'proper-subset? one two #t))

(define (set-map set proc)
  (unless (set? set) (raise-type-error 'set-map "set" 0 set proc))
  (unless (and (procedure? proc)
               (procedure-arity-includes? proc 1))
    (raise-type-error 'set-map "procedure (arity 1)" 1 set proc))
  (for/list ([v (in-set set)])
    (proc v)))

(define (set-for-each set proc)
  (unless (set? set) (raise-type-error 'set-for-each "set" 0 set proc))
  (unless (and (procedure? proc)
               (procedure-arity-includes? proc 1))
    (raise-type-error 'set-for-each "procedure (arity 1)" 1 set proc))
  (for ([v (in-set set)])
    (proc v)))

(define (in-set set)
  (unless (set? set) (raise-type-error 'in-set "set" 0 set))
  (in-hash-keys (set-ht set)))

(define-sequence-syntax *in-set
  (lambda () #'in-set)
  (lambda (stx)
    (syntax-case stx ()
      [[(id) (_ st)]
       #`[(id)
          (:do-in
           ;; outer bindings:
           ([(ht) (let ([s st]) (if (set? s) (set-ht s) (list s)))])
           ;; outer check:
           (unless (hash? ht)
             ;; let `in-set' report the error:
             (in-set (car ht)))
           ;; loop bindings:
           ([pos (hash-iterate-first ht)])
           ;; pos check
           pos
           ;; inner bindings
           ([(id) (hash-iterate-key ht pos)])
           ;; pre guard
           #t
           ;; post guard
           #t
           ;; loop args
           ((hash-iterate-next ht pos)))]])))

(define-syntax-rule (define-for for/fold/derived for/set set)
  (define-syntax (for/set stx)
    (syntax-case stx ()
      [(_ bindings . body)
       (quasisyntax/loc stx
         (for/fold/derived #,stx ([s (set)]) bindings (set-add s (let () . body))))])))

(define-for for/fold/derived for/set set)
(define-for for*/fold/derived for*/set set)
(define-for for/fold/derived for/seteq seteq)
(define-for for*/fold/derived for*/seteq seteq)
(define-for for/fold/derived for/seteqv seteqv)
(define-for for*/fold/derived for*/seteqv seteqv)

(define (get-pred a-set/c)
  (case (set/c-cmp a-set/c)
    [(dont-care) set?]
    [(eq) set-eq?]
    [(eqv) set-eqv?]
    [(equal) set-equal?]))

(define (get-name a-set/c)
  (case (set/c-cmp a-set/c)
    [(dont-care) 'set]
    [(eq) 'set-eq]
    [(eqv) 'set-eqv]
    [(equal) 'set-equal]))

(define *set/c
  (let ()
    (define (set/c ctc #:cmp [cmp 'dont-care])
      (unless (memq cmp '(dont-care equal eq eqv))
        (raise-type-error 'set/c 
                          "(or/c 'dont-care 'equal? 'eq? 'eqv)" 
                          cmp))
      (if (flat-contract? ctc)
          (flat-set/c ctc cmp (flat-contract-predicate ctc))
          (make-set/c ctc cmp)))
    set/c))

(define (set/c-name c)
  `(set/c ,(contract-name (set/c-ctc c))
          ,@(if (eq? (set/c-cmp c) 'dont-care)
                '()
                `(#:cmp ',(set/c-cmp c)))))

(define (set/c-stronger this that)
  (and (set/c? that)
       (or (eq? (set/c-cmp this)
                (set/c-cmp that))
           (eq? (set/c-cmp that) 'dont-care))
       (contract-stronger? (set/c-ctc this)
                           (set/c-ctc that))))

(define (set/c-proj c)
  (let ([proj (contract-projection (set/c-ctc c))]
        [pred (get-pred c)])
    (λ (blame)
      (let ([pb (proj blame)])
        (λ (s)
          (if (pred s)
              (cond
                [(set-equal? s)
                 (for/set ((e (in-set s)))
                          (pb e))]
                [(set-eqv? s)
                 (for/seteqv ((e (in-set s)))
                             (pb e))]
                [(set-eq? s)
                 (for/seteq ((e (in-set s)))
                            (pb e))])
              (raise-blame-error
               blame
               s
               "expected a <~a>, got ~v" 
               (get-name c)
               s)))))))

(define-struct set/c (ctc cmp)
  #:property prop:contract
  (build-contract-property 
   #:name set/c-name
   #:first-order get-pred
   #:stronger set/c-stronger
   #:projection set/c-proj))

(define (flat-first-order c)
  (let ([inner-pred (flat-set/c-pred c)]
        [pred (get-pred c)])
    (λ (s)
      (and (pred s)
           (for/and ((e (in-set s)))
             (inner-pred e))))))

(define-values (flat-set/c flat-set/c-pred)
  (let ()
    (define-struct (flat-set/c set/c)  (pred)
      #:property prop:flat-contract
      (build-flat-contract-property 
       #:name set/c-name
       #:first-order flat-first-order
       #:stronger set/c-stronger
       #:projection set/c-proj))
    (values make-flat-set/c flat-set/c-pred)))

;; ----

(define (set=? one two)
  (unless (set? one) (raise-type-error 'set=? "set" 0 one two))
  (unless (set? two) (raise-type-error 'set=? "set" 1 one two))
  ;; Sets implement prop:equal+hash
  (equal? one two))

(define set-symmetric-difference
  (case-lambda
    [(set)
     (unless (set? set) (raise-type-error 'set-symmetric-difference "set" 0 set))
     set]
    [(set set2)
     (unless (set? set) (raise-type-error 'set-symmetric-difference "set" 0 set set2))
     (unless (set? set2) (raise-type-error 'set-symmetric-difference "set" 1 set set2))
     (let ([ht1 (set-ht set)]
           [ht2 (set-ht set2)])
      (unless (and (eq? (hash-eq? ht1) (hash-eq? ht2))
                   (eq? (hash-eqv? ht1) (hash-eqv? ht2)))
        (raise-mismatch-error 'set-symmetric-difference
                              "set's equivalence predicate is not the same as the first set: "
                              set2))
      (let-values ([(big small)
                    (if (>= (hash-count ht1) (hash-count ht2))
                        (values ht1 ht2)
                        (values ht2 ht1))])
        (make-set
         (for/fold ([ht big]) ([e (in-hash-keys small)])
           (if (hash-ref ht e #f)
               (hash-remove ht e)
               (hash-set ht e #t))))))]
    [(set . sets)
     (for ([s (in-list (cons set sets))]
           [i (in-naturals)])
       (unless (set? s) (apply raise-type-error 'set-symmetric-difference "set" i (cons s sets))))
     (for/fold ([set set]) ([set2 (in-list sets)])
       (set-symmetric-difference set set2))]))

(define (set->list set)
  (unless (set? set) (raise-type-error 'set->list "set" 0 set))
  (for/list ([elem (in-hash-keys (set-ht set))]) elem))
(define (list->set elems)
  (unless (list? elems) (raise-type-error 'list->set "list" 0 elems))
  (apply set elems))
(define (list->seteq elems)
  (unless (list? elems) (raise-type-error 'list->seteq "list" 0 elems))
  (apply seteq elems))
(define (list->seteqv elems)
  (unless (list? elems) (raise-type-error 'list->seteqv "list" 0 elems))
  (apply seteqv elems))
