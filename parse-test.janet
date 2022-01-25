(import ./argparse :as ap)
(import ./read-config :as conf)
(import ./futils :as fs)
(use ./lib)

(defn- pathify
  ``
  Join an array of strings with the proper directory separator relative to the
  OS.
  ``
  [& parts]
  (string/join 
    ;parts
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

(def modifier-flags 
  ``
  Flags that change some behavior, but have no explicit action associated with
  them.
  ``
  ["base" "local"])

(def script-directory 
  ``
  The root path where our scripts are stored/referenced from.

  Subsequent calls to `base` or `local` will not affect the value of
  script-directory.
  ``
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
  ``
  command-args/command-order should only be populated if a flag is specified.
  NOTE: Technically, they should only be populated if the `new` flag is given,
  at least for now.
  ``
  [;(break-off target-arg-count (opts :default))
   (drop target-arg-count debased-order)])

(def command-flag 
  ``
  The name of the first non-modifier flag passed in, `nil` if there is none.

  This flag will define what action we actually perform.
  ``
  (first 
    (filter 
      |(none-of? [:default :order ;modifier-flags] $) 
      (keys opts))))

(def command-flag-provided? (not-nil? command-flag))

(def deflagged-order
  ``
  We only want to pay mind to the first flag thats passed through, so we're
  going to discard all the others. The remaining order should consist of all
  the arguments we want to pass on to that flags associated action.
  ``
  (filter |(= :default $) command-order))

(defn is-directory-with-main? [path]
  (let [has-main? (partial has-equals? "main")]
    (and 
      (fs/entity-exists? path) 
      (has-main? (os/dir path)) 
      (fs/executable-file? 
        (pathify path "main")))))

(defn is-directory-with-dot-help? [path]
  (let [has-dot-help? (partial has-equals? ".help")]
    (and 
      (fs/entity-exists? path) 
      (has-dot-help? (os/dir path)))))

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

  All other cases will result in an empty array of script args, and a path that
  may or may not be valid.
  ``
  [args &opt path]
  (default path script-directory)
  (let [path-append (partial pathify path)
        [next-arg rem-args] (hd-tl args)]
    (cond
      (empty? args) [path []]
      (fs/executable-file? path) [path args] #run
      (is-directory-with-main? path) [(path-append "main") args] #run
      (fs/dir? path) (split-into-path-and-args rem-args (path-append next-arg))
      [(path-append ;args) []]))) # not executing (we can no longer make a valid existing path), therefore we don't have args

#(def [target-location script-args] (split-into-path-and-args target-args))

(pp opts)
(print "---")
(pp target-args)
(pp command-args)
(pp command-order)
(pp (split-into-path-and-args target-args))
(print "---")

(def invalid-path? 
  (partial 
    meets-any-criteria? [fs/entity-does-not-exist? fs/not-executable-file?]))

(defn dir-help [target]
  (let [has-helpfile? (is-directory-with-dot-help? target)]
    (if has-helpfile? 
      (cat-command (pathify target ".help"))
      ())))

(defn script-help [target]
  (let [has-helpfile? ()]
    (if has-helpfile? 
      (cat-command (pathify target "TODO.help"))
      ())))

(defn write-help 
  [help-type target &opt data]
  (case help-type
    :invalid-path (string target " is not reachable")
    :dir-help (dir-help target)
    :script-help (script-help target)))

(defn run-command [target] 
  (let [[path args] (split-into-path-and-args target)]
    (cond
      (fs/entity-does-not-exist? path) (help-command target)
      (fs/dir?) (help-command target)
      (fs/not-executable-file? path) (cat-command target)
      (os/execute [path ;args] :p))))

(defn dispatch-command
  [command-flag command-args target]
  (case command-flag
    nil (run-command target)
    "new" (new-command target ;command-args)
    "edit" (edit-command target)
    "which" (which-command target)
    "cat" (cat-command target)
    "help" (help-command target)
    (help-command target)))

(defn main 
  [& args] 
  (print "and done :^)"))
