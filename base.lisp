(in-package :arc)

(defun +INTERNAL-FLATTEN (lis)
  (cond ((atom lis) lis)
        ((listp (car lis))
         (append (+INTERNAL-FLATTEN (car lis)) (+INTERNAL-FLATTEN (cdr lis))))
        (t (append (list (car lis)) (+INTERNAL-FLATTEN (cdr lis))))))

;(defmacro +INTERNAL-DEPARAM (param &body body)
;  (DESTRUCTURING-BIND ,param ,g
;    (DECLARE (IGNORABLE ,@(+internal-flatten args)))
;    ,@body))

(defmacro FN ((&rest args) &body body)
  (cl:let ((g (gensym)))
    `(LAMBDA (&rest ,g)
       (DESTRUCTURING-BIND ,args ,g
         (DECLARE (IGNORABLE ,@(+internal-flatten args)))
         ,@body))))

;; let var val [body ...]
(defmacro let (var val &body body)
  "The let statement sets the variable var to the value within the
scope of the body. Outside the let statement, any existing value
of var is unaffected. Let is like with but with a single variable
binding."
  `(DESTRUCTURING-BIND (,var) (list ,val)
     (DECLARE (IGNORABLE ,@(+internal-flatten `(,var))))
     ,@body))

;; with ([var val ...]) [body ...]
;>(with (a 1 b 2 c 3) (+ a b c))

(defmacro with (binds &body body)
  "Creates a new variable binding and executes the body. The values
are computed before any of the assignments are done (like
Scheme's let, rather than let*). If the last variable doesn't
have a value, it is assigned nil."
  (cl:loop :for x :on binds :by #'cddr 
           :collect (first x) :into vars
           :collect (second x) :into vals
           :finally (return
                      `(DESTRUCTURING-BIND ,vars (list ,@vals)
                         (DECLARE (IGNORABLE ,@(+internal-flatten vars)))
                         ,@body))))

;; withs ([var val ...]) [body ...]

"Creates a new variable binding and executes the body. The values
are computed sequentially (like Scheme's let*, rather than
let). If the last variable doesn't have a value, it is assigned
nil."

(defmacro withs (binds &body body)
  (cl:let ((binds (loop :for vv :on binds :by #'cddr  
                        :collect `(,(car vv) ,(cadr vv)))))
    (cl:reduce (lambda (vv res) `(arc::let ,@vv ,res))
               binds
               :initial-value `(progn ,@body)
               :from-end 'T)))

;>(withs (a 1 b (+ a 1)) (+ a b))
;3

;(withs (a 1 b 2 (c d) '(3 4)) (+ a b c d))

(defmacro do (&body forms)
  `(progn ,@forms))
