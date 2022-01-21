(import ./argparse :as ap)

(def opts 
  (ap/argparse "my-desc" "help" {:kind :flag
                                 :short "h"
                                 :help "Run this help message"
                                 #:action :help
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

(def base-arg-count (length (take-while |(= :default $) (opts :order))))
(def 
  [base-args rem-defaults] 
  [(take base-arg-count (opts :default)) (drop base-arg-count (opts :default))])
(def rem-order (drop base-arg-count (opts :order)))

#(defn [target-path rest] [(take-while )])
(pp opts)
(print "---")
(pp base-arg-count)
(pp base-args)
(pp rem-defaults)
(pp rem-order)
(print "---")

(defn parse-base-args
  [& args]
  )

(defn is-directory-with-main?)

(defn main 
  [& args] 
  (print "and done :^)"))
