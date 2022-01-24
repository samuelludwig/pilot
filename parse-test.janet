(import ./argparse :as ap)
(import ./read-config :as conf)
(import ./futils :as fs)
(use ./lib)

(defn- pathify
  ``
  Join an array of strings with the proper directory separator relative to the
  OS.
  ``
  [parts]
  (string/join 
    parts
    (if (= (os/which) :windows) "\\" "/")))

(def opts 
  (ap/argparse 
    ``
    Describe script here
    `` 
    "help" {:kind :flag #TODO a bit more complicated
            :short "h"
            :help "Run this help message"
            #:action :help
            :short-circuit false}
    "base" {:kind :option
            :short "b"
            :help "Define a temporary script directory location for this command"
            #:action :help
            :short-circuit false}
    "local" {:kind :flag
            :short "l"
            :help "Shortcut for `--base ./`"
            #:action :help
            :short-circuit false}
    "new" {:kind :flag #technically an option but we treat it differently
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
            :short "e"
            :help "Open a script in the configured editor"
           # :action (print "Making a new script")
            :short-ciruit false} 
    "which" {:kind :flag
             :short "w"
             :help "print location of a script"
           #  :action (print "Making a new script")
             :short-ciruit false} 
    :default {:kind :accumulate}))

(def script-directory 
  (cond
    (opts "base") (opts "base")
    (opts "local") "./"
    (conf/settings :script-path)))

(def debased-order 
  (filter 
    |(neither? "base" "local" $) 
    (opts :order)))

(def target-arg-count 
  (length 
    (take-while |(= :default $) debased-order)))

(def [target-args command-args command-order]
  [;(break-off target-arg-count (opts :default))
   (drop target-arg-count debased-order)])

(defn is-directory-with-main? [path]
  (let [has-main? (partial has-equals? "main")]
    (and 
      (fs/entity-exists? path) 
      (has-main? (os/dir path)) 
      (fs/executable-file? 
        (pathify [path "main"])))))

# If no flags are specified (meaning command-args/order are also both empty,
# and we actually want to 'run' something), we need to parse the target args
# and break it up into the script path, and the arguments to the script.

# If a --new, --edit, --which, --cat, or --help flag is specified, all the
# target args should be considered the location of the subject only.

(defn split-into-path-and-args
  ``
  Given a sequential array of arguments, determine which arguments are suitable
  to consider as part of a filepath, and which, if any, ought to be interpreted
  as script arguments.

  There are two cases in which we may have a populated array of script
  arguments:

  A. `path` resolves to an executable file
  B. `path` resolves to a directory that contains a file with the name `main`
  ``
  [args &opt path]
  (default path script-directory)
  (let [path-append (partial join-with "/" path)
        [next-arg rem-args] (hd-tl args)]
    (cond
      (empty? args) [path []]
      (fs/executable-file? path) [path args] #run
      (is-directory-with-main? path) [(path-append "main") args] #run
      (fs/dir? path) (split-into-path-and-args rem-args (path-append next-arg))
      [(path-append ;args) []]))) # not executing (we can no longer make a valid existing path), therefore we don't have args

(defn drop-from [x & inds]
  (map |(drop x $) [;inds]))

#(def [target-location script-args] (split-into-path-and-args target-args))

(pp opts)
(print "---")
(pp target-args)
(pp command-args)
(pp command-order)
(pp (split-into-path-and-args target-args))
(print "---")

(defn parse-base-args
  [& args]
  ())

(defn main 
  [& args] 
  (print "and done :^)"))
