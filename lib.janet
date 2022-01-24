(def single-line-comment-styles
  '{:slashes "//"
    :dashes "--"
    :hash "#"
    :eol (choice "\n" "\r")
    :line-comment (sequence :slashes (to :eol) :eol)
    :main (capture :line-comment)})
(def multi-line-comment-styles
  '{:opening-square-digraph "[-"
    :closing-square-digraph "-]"
    :opening-slash-digraph "/*"
    :closing-slash-digraph "*/"
    :comment-block (choice
                      (sequence 
                        :opening-square-digraph 
                        (to :closing-square-digraph) 
                        :closing-square-digraph)
                      (sequence 
                        :opening-slash-digraph 
                        (to :closing-slash-digraph) 
                        :closing-slash-digraph))
    :main (capture :comment-block)})

(def not-nil? (complement nil?))

(defn has?
  [pred ind]
  (not-nil? (find pred ind)))

(defn has-equals?
  ``
  Returns true if the indexable contains `val`, and false otherwise.
  ``
  [val ind]
  (has? |(= val $) ind))

(defn has-match?
  ``
  Like `has-equals?` but instead of checking for equality, it checks to see if
  an element satisfies `peg/match`.
  ``
  [pat ind]
  (has? |(peg/match pat $) ind))

(defn break-off 
  ``
  Named with regards to the imagery of physically "breaking off" a piece of
  some particular item, like, say, a candy bar--splitting it into two separate
  chunks; sort of a variable-sized head/tail split.
  ``
  [x ind] 
  [(take x ind) (drop x ind)])

(defn either? 
  ``
  Checks if `subject` is equal to either `x` or `y`
  ``
  [x y subject]
  (or (= x subject) (= y subject)))

(defn neither? [x y subject] (not (either? x y subject)))

(def tail (partial drop 1))
(defn hd-tl [x] [(first x) (when (not-nil? x) (tail x))])

(defn join-with
  [sep & parts]
  (string/join parts sep))
