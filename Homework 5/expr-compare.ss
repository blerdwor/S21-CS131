#lang racket
(provide (all-defined-out))

(define LAMBDA (string->symbol "\u03BB"))

; helper function to form unified string
;
(define (unify-terms x y)
  (string->symbol (string-append (symbol->string x) "!" (symbol->string y))))
      
; helper function to get the index of a unified variable
;
(define (get-index val lst index)
    (if (equal? (car val) lst) index (get-index (cdr val) lst (+ 1 index)))
)

; replaces every instance of a in xfe with a!b
; breaks the list of formals and expr into separate pieces
; operates on them separately
;
; xfe = x-formals-expr
; yfe = y-formals-expr
;
(define (replace xfe yfe a a!b)
    (cond [(null? xfe) '()]							; everything has been replaced
	  [(and (list? xfe) (list? yfe)						; filter out lambda expressions
		(or (equal? (car xfe) 'lambda) (equal? (car xfe) LAMBDA))
		(or (equal? (car yfe) 'lambda) (equal? (car yfe) LAMBDA))
		(= (length xfe) 3) (= (length yfe) 3))
	     (lambda-compare xfe yfe)]
	  [(list? (car xfe)) (cons (replace (car xfe) (car yfe) a a!b) 	; xfe is still a list
				   (replace (cdr xfe) (cdr yfe) a a!b))]
	  [(member (car xfe) a) (cons (list-ref a!b (get-index a (car xfe) 0))	; variable needs to be replaced
				      (replace (cdr xfe) (cdr yfe) a a!b))]
	  [#t (cons (car xfe) (replace (cdr xfe) (cdr yfe) a a!b))]	; variable does not need to be replaced
	  )
    )

; compares the formals and makes a list of unifications that need to be made
; a!b is the list of unifications
; a is a list of the unified variables a in a!b
; b is a list of the unified variables in a!b
;
(define (unify x y a!b a b)
    (cond [(and (null? x) (null? y)) (list a!b a b)]			; return a list of the 3 lists
	  [(equal? (car x) (car y)) (unify (cdr x) (cdr y) a!b a b)]	; x = y, don't unify 
	  [#t (unify (cdr x) (cdr y)					; x != y, unify
		     (cons (unify-terms (car x) (car y)) a!b)
		     (cons (car x) a)
		     (cons (car y) b))]
	  )
    )

; compare the lambda statements
; uni is a list of 3 lists: a!b, a, and b
; descriptions above
;
(define (lambda-compare x y)
  (let ((x-hd (car x))
	(y-hd (car y))
	(uni (unify (second x) (second y) '() '() '())))
       (cond [(and (equal? 'lambda x-hd) (equal? 'lambda y-hd) (null? (car uni)))		; x and y are (lambda formals body); no unifications made
	        (list 'lambda (cadr x) (expr-compare (last x) (last y)))]
	     [(and (equal? 'lambda x-hd) (equal? 'lambda y-hd))					; x and y are (lambda formals body); unifications made
		(cons 'lambda (expr-compare (replace (cdr x) (cdr y) (second uni) (car uni))
					    (replace (cdr y) (cdr x) (last uni) (car uni))))]
	     [(null? (car uni))									; x or y are (λ formals body); no unifications made
	        (list LAMBDA (cadr x) (expr-compare (last x) (last y)))]
	     [#t (cons LAMBDA (expr-compare (replace (cdr x) (cdr y) (second uni) (car uni)) 	; x or y are (λ formals body); unifications made
					    (replace (cdr y) (cdr x) (last uni) (car uni))))]
	     )
       )
  )

; x and y are lists of the same length
; function compares elements in a list
; returns the evaluated Racket expression
;
(define (lst-compare x y)
  (let ((x-hd (car x))
	(y-hd (car y))
	(x-tl (cdr x))
	(y-tl (cdr y))
	(x-len (length x))
	(y-len (length y)))
       (cond [(and (equal? 'quote x-hd) (equal? 'quote y-hd) (= 2 x-len) (= 2 y-len))	; x and y are (quote s-exp)
	      	(if (equal? x y)
		    x
		    (list 'if '% x y))]
	     [(and (equal? 'if x-hd) (equal? 'if y-hd) (= 4 x-len) (= 4 y-len))		; x and y are (if test-expr expr expr)
                (cons 'if (lst-compare x-tl y-tl))]
	     [(and (or (equal? 'if x-hd) (equal? 'if y-hd)) (= 4 x-len) (= 4 y-len))	; x or y are (if test-expr expr expr)
                (list 'if '% x y)]
	     [(and (or (equal? 'lambda x-hd) (equal? LAMBDA x-hd))			; x and y are (λ formals body) or (lambda formals body)
		   (or (equal? 'lambda y-hd) (equal? LAMBDA y-hd))
		   (= 3 x-len) (= 3 y-len))
	        (if (not (= (length (second x)) (length (second y))))
		    (list 'if '% x y)
		    (lambda-compare x y))]
	     [(and (null? x-tl) (null? y-tl)) (list (expr-compare x-hd y-hd))]			; list with one element
	     [(equal? x-hd y-hd) (cons x-hd (lst-compare x-tl y-tl))]				; x[0] = y[0]
	     [(not (equal? x-hd y-hd)) (cons (expr-compare x-hd y-hd) (lst-compare x-tl y-tl))] ; x[0] != y[0]
	     )
       )
  )

; ideally will just handle simple expressions 
; passes lists of same size to lst-compare 
;
(define (expr-compare x y)
  (cond [(equal? x y) x]						 ; catch numbers
	[(and (boolean? x) (boolean? y)) (if x '% '(not %))]		 ; catch booleans
	[(or (not (list? x)) (not (list? y))				 ; catch symbols
	     (and (list? x) (list? y) (not (= (length x) (length y)))))	 ; x and y are lists of different lengths
	   (list 'if '% x y)]
	[#t (lst-compare x y)] 						 ; x and y are lists of the same length
	)
  )

(define test-expr-x '((lambda (a b x) (if x (quote (a)) (list a b #f #t))) 1 2 #t))
(define test-expr-y '((lambda (a c x) (if x (quote (a)) (list a c #t #f))) 1 2 #t))

(define (test-expr-compare x y)
  (and (equal? (eval x) (eval (list `let `((% #t)) (expr-compare x y))))
       (equal? (eval y) (eval (list `let `((% #f)) (expr-compare x y))))
       )
  )

; TESTCASES FROM TA GITHUB REPO
;
#|
(equal? (expr-compare 12 12) '12)
(equal? (expr-compare 12 20) '(if % 12 20))
(equal? (expr-compare #t #t) #t)
(equal? (expr-compare #f #f) #f)
(equal? (expr-compare #t #f) '%) ;#5
(equal? (expr-compare #f #t) '(not %))
(equal? (expr-compare 'a '(cons a b)) '(if % a (cons a b)))
(equal? (expr-compare '(cons a b) '(cons a b)) '(cons a b))
(equal? (expr-compare '(cons a lambda) '(cons a λ)) '(cons a (if % lambda λ)))
(equal? (expr-compare '(cons (cons a b) (cons b c)) ;#10
              '(cons (cons a c) (cons a c))) '(cons (cons a (if % b c)) (cons (if % b a) c)))
(equal? (expr-compare '(cons a b) '(list a b)) '((if % cons list) a b))
(equal? (expr-compare '(list) '(list a)) '(if % (list) (list a)))
(equal? (expr-compare ''(a b) ''(a c)) '(if % '(a b) '(a c)))
(equal? (expr-compare '(quote (a b)) '(quote (a c))) '(if % '(a b) '(a c)))
(equal? (expr-compare '(quoth (a b)) '(quoth (a c))) '(quoth (a (if % b c)))) ;#15
(equal? (expr-compare '(if x y z) '(if x z z)) '(if x (if % y z) z))
(equal? (expr-compare '(if x y z) '(g x y z)) '(if % (if x y z) (g x y z)))
(equal? (expr-compare '((lambda (a) (f a)) 1) '((lambda (a) (g a)) 2)) '((lambda (a) ((if % f g) a)) (if % 1 2)))
(equal? (expr-compare '((lambda (a) (f a)) 1) '((λ (a) (g a)) 2)) '((λ (a) ((if % f g) a)) (if % 1 2)))
(equal? (expr-compare '((lambda (a) a) c) '((lambda (b) b) d)) '((lambda (a!b) a!b) (if % c d))) ;#20
(equal? (expr-compare ''((λ (a) a) c) ''((lambda (b) b) d)) '(if % '((λ (a) a) c) '((lambda (b) b) d)))
(equal? (expr-compare '(+ #f ((λ (a b) (f a b)) 1 2))
              '(+ #t ((lambda (a c) (f a c)) 1 2))) '(+
     (not %)
     ((λ (a b!c) (f a b!c)) 1 2)))
(equal? (expr-compare '((λ (a b) (f a b)) 1 2)
              '((λ (a b) (f b a)) 1 2)) '((λ (a b) (f (if % a b) (if % b a))) 1 2))
(equal? (expr-compare '((λ (a b) (f a b)) 1 2)
              '((λ (a c) (f c a)) 1 2)) '((λ (a b!c) (f (if % a b!c) (if % b!c a))) 1 2))

(equal? (expr-compare '((lambda (lambda) (+ lambda if (f lambda))) 3) ;#25
              '((lambda (if) (+ if if (f λ))) 3)) '((lambda (lambda!if) (+ lambda!if (if % if lambda!if) (f (if % lambda!if λ)))) 3))
(equal? (expr-compare '((lambda (a) (eq? a ((λ (a b) ((λ (a b) (a b)) b a))
                                    a (lambda (a) a))))
                (lambda (b a) (b a)))
              '((λ (a) (eqv? a ((lambda (b a) ((lambda (a b) (a b)) b a))
                                a (λ (b) a))))
                (lambda (a b) (a b)))) '((λ (a)
      ((if % eq? eqv?)
       a
       ((λ (a!b b!a) ((λ (a b) (a b)) (if % b!a a!b) (if % a!b b!a)))
        a (λ (a!b) (if % a!b a)))))
     (lambda (b!a a!b) (b!a a!b))))

(equal? (expr-compare '(cons a lambda) '(cons a λ)) '(cons a (if % lambda λ)))
(equal? (expr-compare '(lambda (a) a) '(lambda (b) b)) '(lambda (a!b) a!b))
(equal? (expr-compare '(lambda (a) b) '(cons (c) b)) '(if % (lambda (a) b) (cons (c) b)))
(equal? (expr-compare '((λ (if) (+ if 1)) 3) '((lambda (fi) (+ fi 1)) 3)) '((λ (if!fi) (+ if!fi 1)) 3)) ;#30
(equal? (expr-compare '(lambda (lambda) lambda) '(λ (λ) λ)) '(λ (lambda!λ) lambda!λ))
(equal? (expr-compare ''lambda '(quote λ)) '(if % 'lambda 'λ))
(equal? (expr-compare '(lambda (a b) a) '(λ (b) b)) '(if % (lambda (a b) a) (λ (b) b)))
(equal? (expr-compare '(λ (a b) (lambda (b) b)) '(lambda (b) (λ (b) b))) '(if % (λ (a b) (lambda (b) b)) (lambda (b) (λ (b) b))))
(equal? (expr-compare '(λ (let) (let ((x 1)) x)) '(lambda (let) (let ((y 1)) y))) '(λ (let) (let (((if % x y) 1)) (if % x y)))) ;#35
(equal? (expr-compare '(λ (x) ((λ (x) x) x))
                      '(λ (y) ((λ (x) y) x))) 
	             '(λ (x!y) ((λ (x) (if % x x!y)) (if % x!y x))))
(equal? (expr-compare '(((λ (g)
                   ((λ (x) (g (λ () (x x))))     ; This is the way we define a recursive function
                    (λ (x) (g (λ () (x x))))))   ; when we don't have 'letrec'
                 (λ (r)                               ; Here (r) will be the function itself
                   (λ (n) (if (= n 0)
                              1
                              (* n ((r) (- n 1))))))) ; Therefore this thing calculates factorial of n
                10)
              '(((λ (x)
                   ((λ (n) (x (λ () (n n))))
                    (λ (r) (x (λ () (r r))))))
                 (λ (g)
                   (λ (x) (if (= x 0)
                              1
                              (* x ((g) (- x 1)))))))
                9)) '(((λ (g!x)
                    ((λ (x!n) (g!x (λ () (x!n x!n))))
                     (λ (x!r) (g!x (λ () (x!r x!r))))))
                  (λ (r!g)
                    (λ (n!x) (if (= n!x 0)
                                 1
                                 (* n!x ((r!g) (- n!x 1)))))))
                 (if % 10 9)))
|#
