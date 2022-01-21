(import ./argparse :as ap)

(def opts 
  (ap/argparse "my-desc" "help" {:kind :flag
                                 :short "h"
                                 :help "Run this help message"
                                 :action :help
                                 :short-circuit false}
                         "new" {:kind :option
                                :short "n"
                                :help "Create a new script"
                               # :action (print "I own a cat")
                                :short-ciruit false} 
                         "cat" {:kind :flag
                                :short "c"
                                :help "cat"
                                #:action (print "Making a new script")
                                :short-ciruit false} 
                         "edit" {:kind :flag
                                 :short "n"
                                 :help "Open a script in the configured editor"
                                # :action (print "Making a new script")
                                 :short-ciruit false} 
                         "which" {:kind :flag
                                  :short "n"
                                  :help "print location of a script"
                                #  :action (print "Making a new script")
                                  :short-ciruit false} 
                         :default {:kind :accumulate}))

(def path-var-count (length (take-while |(= :default $) (opts :order))))
(def 
  [path-vars rem-defaults] 
  [(take path-var-count (opts :default)) (drop path-var-count (opts :default))])
(def rem-order (drop path-var-count (opts :order)))

#(defn [target-path rest] [(take-while )])
(pp opts)
(print "---")
(pp path-var-count)
(pp path-vars)
(pp rem-defaults)
(pp rem-order)
(print "---")
(defn main 
  [& args] 
  (print "and done :^)"))
