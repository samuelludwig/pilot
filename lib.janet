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
    :main (capture :comment-block)

