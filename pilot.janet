#!/usr/bin/env janet
(import ./argparse :as ap)
(import ./read-config :as conf)
(import ./futils :as fs)
(use ./lib)

``
`target` is an array of arguments, which can be composed of either path
segments, or script arguments, or both
``

(def path-separator 
  (if (= (os/which) :windows) "\\" "/"))

(defn- pathify
  ``
  Join an array of strings with the proper directory separator relative to the
  OS.
  ``
  [& parts]
  (string/join parts path-separator))

(defn- is-directory-with-main? [path]
  (let [has-main? (partial has-equals? "main")]
    (and 
      (fs/entity-exists? path) 
      (fs/dir? path)
      (has-main? (os/dir path)) 
      (fs/executable-file? 
        (pathify path "main")))))

(defn- is-directory-with-dot-help? [path]
  (let [has-dot-help? (partial has-equals? ".help")]
    (and 
      (fs/entity-exists? path) 
      (has-dot-help? (os/dir path)))))

(defn- mainpath-of
  [path]
  (let [path-append (partial pathify path)]
    (if (is-directory-with-main? path) 
      (path-append "main") 
      path)))

(def settings conf/settings)

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
           #:action (print "I own a cat")
           :short-ciruit false} 
    "template" {:kind :option
                :short "t"
                :help "Used with `--new` to indicate the path of the template to use"
                #:action (print "I own a cat")
                :short-ciruit false
                :default "default"} 
    "no-template" {:kind :option
                   :help "Used with `--new` to make the new script in a blank file"
                   #:action (print "I own a cat")
                   :short-ciruit false} 
    "cat" {:kind :flag
           :short "c"
           :help "cat"
           #:action (print "Making a new script")
           :short-ciruit false} 
    "edit" {:kind :flag
            :short "e"
            :help "Open a script in the configured editor"
            #:action (print "Making a new script")
            :short-ciruit false} 
    "which" {:kind :flag
             :short "w"
             :help "print location of a script"
             #:action (print "Making a new script")
             :short-ciruit false} 
    "debug" {:kind :flag
             :help "Print out debug info in addition to normal output"
             #:action (print "Making a new script")
             :short-ciruit false} 
    :default {:kind :accumulate}))

(def modifier-flags 
  ``
  Flags that change some behavior, but have no explicit action associated with
  them.
  ``
  ["base" "local" "template" "no-template" "debug"])

(defn determine-script-directory 
  ``
  The root path where our scripts are stored/referenced from.

  Subsequent calls to `base` or `local` will not affect the value of
  script-directory.
  ``
  [base-settings opts]
  (cond
    (opts "base") (opts "base")
    (opts "local") "./"
    (base-settings :script-path)))

(def template-directory
  ``
  The root path where our templates are stored/referenced from.
  TODO?
  ``
  (settings :template-path))

(def template-path
  ``
  The root path where our scripts are stored/referenced from.

  Subsequent calls to `base` or `local` will not affect the value of
  script-directory.
  ``
  (or (opts "template") (settings :template-path)))

(def template 
  (if (opts :no-template) "" (fs/read-all template-path)))

(def debased-order 
  (filter 
    |(neither? "base" "local" $) 
    (opts :order)))

(defn count-while
  [pred ind]
  (let [take-trues (partial take-while pred)]
    (-> ind 
        take-trues
        length)))

(def [target-args command-args command-order]
  ``
  command-args/command-order should only be populated if a flag is specified.
  NOTE: Technically, they should only be populated if the `new` flag is given,
  at least for now.
  ``
  (let [target-arg-count (count-while |(= :default $) debased-order)]
    [;(break-off target-arg-count (opts :default))
     (drop target-arg-count debased-order)]))

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

(defn define-parameters
  [opts]
  ``
  :target will either be a group of path segments, or a group of path segments
  and arguments to pass to the script at the given path
  ``
  (let [using-template? (not (opts :no-template))
        template-location (string (settings :template-path) "/default")]
    {:target target-args 
     :command-flag command-flag
     :command-args command-args
     :script-directory (determine-script-directory settings opts)
     :template-directory (settings :template-path)
     :template-file (when using-template? template-location)}))

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
  (default path ((define-parameters opts) :script-directory))
  (let [path-append (partial pathify path)
        [next-arg rem-args] (hd-tl args)]
    (cond
      (is-directory-with-main? path) [(path-append "main") args] #run
      (fs/executable-file? path) [path args] #run
      (empty? args) [path []]
      (fs/dir? path) (split-into-path-and-args rem-args (path-append next-arg))
      [(path-append ;args) []]))) # not executing (we can no longer make a valid existing path), therefore we don't have args

(def invalid-path? 
  (partial 
    meets-any-criteria? [fs/entity-does-not-exist? fs/not-executable-file?]))

(defn open-in-editor
  [path]
  (os/execute [(settings :pilot-editor) (mainpath-of path)] :p))

(def append-to-script-directory (partial pathify (( define-parameters opts ) :script-directory)))

(defn build-target-path-from-segment-list
  [target]
  (first (split-into-path-and-args target)))

(defn run-cat 
  [path]
  (os/execute [(settings :cat-provider) (mainpath-of path)] :p))

(defn run-edit [path] (open-in-editor path))

(defn run-which 
  [path]
  (os/execute ["echo" path] :p))

(defn dir-help [path]
  (let [has-helpfile? (is-directory-with-dot-help? path)
        exec-or-dir? |(or (fs/dir? (pathify path $)) (fs/executable-file? (pathify path $)))]
    (if has-helpfile? 
      (run-cat (pathify path ".help"))
      (join-with "\n" ;(filter exec-or-dir? (os/dir path)))))) # TODO, add appending of quick help info

(defn script-help [target]
  (let [has-helpfile? nil]
    (if has-helpfile? 
      (fs/read-all (pathify target "TODO.help"))
      (fs/read-all (pathify target)))))

(defn write-help 
  ``
  Dispatch to the correct write-help-function
  ``
  [help-type target &opt data]
  (case help-type
    :invalid-path (string target " is not reachable")
    :dir-help (dir-help target)
    :script-help (script-help target)
    :undefined (string "Oh dear, I honestly have no idea what's gone wrong... " target)))

(defn run-help 
  ``
  Determine the help-type and pass it, the target path, and any other pertinent
  data along to the write-help function.
  ``
  [target &opt args]
  (let [target-path (build-target-path-from-segment-list target)]
    (cond
      (fs/entity-does-not-exist? target-path) (write-help :invalid-path target-path)
      (fs/dir? target-path) (print (write-help :dir-help target-path))
      (fs/not-executable-file? target-path) (run-cat target-path)
      (fs/executable-file? target-path) (print (script-help target-path))
      (print (write-help :undefined target-path args)))))

(defn run-new
  ``
  Creates a file at `path` if one does not already exist, loads it with
  <template>, and then runs the edit command. It then chmods the file to be
  executable. 
  If arguments are given, they become the body of the script instead of the
  template, and the script is not opened in the editor.
  
  TODO maybe prompt to confirm if we need to make new parent directories, in
  case a name gets typo'ed?
  `` 
  [path params & args]
  (let [template-provided? (neither? "" nil template) #NOTE: Currently unused
        template (fs/read-all (params :template-file))
        contents (string template (join-with " " ;args))]
    (if (fs/entity-does-not-exist? path) 
      (do 
        (fs/create-new-executable-file path contents)
        (run-edit path))
      (run-help path))))

(defn run-script [target] 
  (let [[path args] (split-into-path-and-args target)]
    (cond
      (fs/entity-does-not-exist? path) (run-help target)
      (fs/dir? path) (run-help target)
      (fs/not-executable-file? path) (run-cat path)
      (os/execute [path ;args] :p))))

(defn dispatch-command
  ``
  Maybe I should just send the `params` to each command function?
  ``
  [params]
  (let [command-flag (params :command-flag)
        target (or (params :target) [""])
        command-args (params :command-args)
        script-dir (params :script-directory)
        target-path (pathify script-dir ;target)]
    (case command-flag
      nil (run-script target)
      "new" (run-new target-path params ;command-args)
      "edit" (run-edit target-path)
      "which" (run-which target-path)
      "cat" (run-cat target-path)
      "help" (run-help target params)
      (run-help target params))))

(when (opts "debug")
  (do
    (print "\n---[OPTIONS]---\n")
    (pp opts)
    (print "\n---[TARGET-ARGS]---\n")
    (pp target-args)
    (print "\n---[COMMAND-ARGS]---\n")
    (pp command-args)
    (print "\n---[COMMAND-ORDER]---\n")
    (pp command-order)
    (print "\n---[SCRIPT-PATH-AND-ARGS-IF-EXECUTED]---")
    (pp (split-into-path-and-args target-args))
    (print "\n---[PARSED-PARAMS]---\n")
    (pp (define-parameters opts))
    (print "\n---\n")))

(defn main 
  [& args] 
  (do
    (dispatch-command 
      (define-parameters opts))))

