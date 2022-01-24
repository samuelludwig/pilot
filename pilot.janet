# What I hope to be my personal command line assistant
# A bastardization of ianthehenry/sd
# For scripts, we can reliably use $0 to determine the script's location, as we
# use a script's absolute path to invoke it.

# TODO's
# - For the `script-path` make this actually get a PATH-like path from the
# config and create the logic around all that stuff
# - Add logic for actually accessing/parsing the config file
# - Copier integration for `command-new`, allow different lang templates and
# whatnot
# I'd like to be able to have multiple flags passed to pilot, currently it only
# reads one
# - Have the --new flag take a type of script in order to determine the
# template to use?
# - Add a check to see if a file is executable by the current user via uid/gid/permissions?
# - Let a directory with a `main` file act as a script?

#
# First we gather our configs
#

# (import ./argparse :as cli-args)
(import ./futils :as fs)
(import ./read-config :as conf)
(def settings conf/settings)

(defn- stat-of
  [f stat]
  (get-in f [:fstats stat]))

(def flag '(choice "-" "--")) # Technically double-hyphen is redundant
(defn flag? [s] (truthy? (peg/match flag s)))
(defn file? [f] 
  (= (stat-of f :mode) :file))
(defn dir? [f] 
  (= (stat-of f :mode) :dir))
(defn executable? [f] 
  (not 
    (nil? (string/find "x" (stat-of f :permissions)))))
(defn executable-file? [f] 
  (and (file? f) (executable? f)))

(defn- load-file
  ``
  Given `path`, return a datastructure containing the core/file located at that
  path, os stats for the file, and the original path given.
  ``
  [path &opt mode]
  {:fstats (os/stat path)
   :file (if mode (file/open path mode) (file/open path) ) 
   :path path})

(defn- close-file 
  [f] 
  (if (file? f) 
    (file/close (f :file))
    nil))

(defn- append-to-file [f text] (file/write (f :file) text))

(defn- read-file [f] (file/read (f :file) :all))

(defn- directory-help
  [f]
  (let [target (f :path) 
        append |(string target $)
        helpfile-path (if (dir? f) (append "/.help") (append ".help"))
        helpfile (load-file helpfile-path :r)
        helpfile-exists? (file? helpfile)]
    (if helpfile-exists? () ())))

(defn- nil-or-empty? [x] (or (nil? x) (empty? x)))
(defn- not-nil-or-empty? [x] (not (nil-or-empty? x)))

(defn open-in-editor
  [path]
  (os/execute [(settings :pilot-editor) path] :p))

(defn make-file
  [path]
  (let [[base-path script-name] (fs/split-path-into-base-and-child path)]
    (do 
      (fs/mkdir-p base-path)
      (os/open (string base-path "/" script-name) :c))))

(defn create-new-executable-file
  [path]
  (do 
    (make-file path)
    (os/chmod path 8r755)))

(defn touch-chmod-and-open
  [path]
  (fs/create-new-executable-file path)
  (open-in-editor path))

(defn- read-template-file 
  [template-path] 
  (fs/read-all template-path))

(defn create-file-from-template
  [path template-path &opt additional-content]
  (let [template (read-template-file template-path)
        contents (string template additional-content)]
    (fs/create-executable-file path contents)))

(defn take-until-pattern [ind pattern]
  (take-until |(string/find pattern $) ind))

# the default behavior for `sd foo bar` is:
# 
# - if `~/sd/foo` is an executable file, execute `~/sd/foo bar`.
# - if `~/sd/foo/bar` is an executable file, execute it with no arguments.
# - if `~/sd/foo/bar` is a directory, this is the same is `sd foo bar --help` 
# (see below).
# - if `~/sd/foo/bar` is a non-executable regular file, this is the same is 
# `sd foo bar --cat` (see below).
# 
# there are some special flags that are significant to `sd`. if you supply any
# one of these arguments, `sd` will not invoke your script, and will do
# something fancier instead.
# 
#     $ sd foo bar --help
#     $ sd foo bar --new
#     $ sd foo bar --edit
#     $ sd foo bar --cat
#     $ sd foo bar --which
#     $ sd foo bar --really
(defn parse-command 
  [first-arg &opt remaining-args]
  (let [[next-arg rem] (hd-tl remaining-args)
        new-path (string first-arg "/" next-arg)
        real-path (string (settings :script-path) "/" first-arg)
        fstats (os/stat real-path)]
    (cond
      # if there's no remaining arguments, our path is done, handle it
      # according to the logic above
      (nil-or-empty? remaining-args) {:path first-arg}

      # if the next argument is a flag, we pass our path, the flag, and the
      # remaining arguments to a flag-handling function
      # we will need to search for a --really flag in `arguments` in the
      # flag-handling function
      (flag? next-arg) {:path first-arg :flag next-arg :arguments rem}

      # if our path is an executable file, we want to run it, with the
      # remaining arguments passed to it
      # what happens in the case where we want to define a "new" script that
      # has a parent directory the same name of an executable?
      (executable-file? (load-file real-path)) {:path first-arg :arguments remaining-args}

      (parse-command new-path rem))))

(defn with-default 
  [x default-val] 
  (if (nil? x) default-val x))

# commands
# [x] run-script
# [ ] run-help todo
# [x] run-new
# [x] run-edit
# [x] run-cat
# [x] run-which

(defn run-help #todo
  ``
  if path does not exist, output a message mentioning that.
  if path is a directory with no .help file, output a message listing each
  script with its summary comment.
  if path is a directory with a .help file, output a message with the .help
  file, followed by the list mentioned above.
  if path is a non-executable file, output a messaging noting that, and then
  cat the file.
  if path is an executable, output its first contiguous comment block.
  ``
  [path]
  (print path " " "hello, under construction at the moment, terribly sorry...\n"))

(defn run-script 
  ``
  if path is an executable file, run it with all the arguments given. if not,
  run help command.
  ``
  [path args]
  (let [f (load-file path)
        exec? (executable-file? f)] 
    (do
      (close-file f) 
      (if exec? 
        (os/execute [path ;args])
        (run-help path)))))

(defn run-cat
  ``
  if path is a file, print it's contents to stdout using `cat-provider`,
  otherwise, run help instead.
  ``
  [path]
  (let [f (load-file path :r)
        cattable? (file? f)
        cat-provider (settings :cat-provider)]
    (do 
      (close-file f)
      (if cattable? (os/execute [cat-provider path] :p)
        (run-help path)))))

(defn run-which
  ``
  if path exists, output `path`. run help otherwise.
  `` 
  [path]
  (let [fstats (os/stat path :mode)]
    (if (truthy? fstats) (os/execute ["echo" path] :p)
      (run-help path))))

(defn run-edit
  ``
  If path exists, open up the file with `EDITOR`. Run help otherwise.
  TODO Check if dir?
  `` 
  [path]
  (let [f (load-file path)]
    (if (stat-of f :mode) 
      (os/execute [(settings :pilot-editor) path] :p)
      (run-help path))))

(defn- create-new-script
  [path template-path &opt script-body]
  (let [body-provided? (not-nil-or-empty? script-body)]
    (do
      (create-file-from-template path template-path script-body)
      (when body-provided? 
        (run-edit path)))))

(defn run-new
  ``
  Creates a file at `path` if one does not already exist, loads it with
  <template>, and then runs the edit command. It then chmods the file to be
  executable. 
  If arguments are given, they become the body of the script instead of the
  template, and the script is not opened in the editor.
  `` 
  [path &opt args]
  (let [f (load-file path)
        body-provided? (not-nil-or-empty? args)
        body (if body-provided? (string/join args " ") "")
        file-not-exists? (nil? (f :file))
        template-path "/home/dot/.config/pilot/templates/bash/default.sh"] #TODO
    (if file-not-exists? 
      (create-new-script path template-path body)
      (run-help path))))

(defn handle-command 
  [{:path p :flag f :arguments args :options opts}]
  (let [args (with-default args [])
        flag (with-default f "") # peg/match errors on nil
        # Get root path from settings and prepend it (do we want logic for
        # multiple possible root PATHs to look at?)
        real-path (string (settings :script-path) "/" p)
        file (load-file real-path)]
    (cond
      (peg/match '(choice "-v" "--verbatim") flag) (run-script real-path args)
      (peg/match '(choice "-h" "--help") flag) (run-help real-path)
      (peg/match '(choice "-n" "--new") flag) (run-new real-path args)
      (peg/match '(choice "-c" "--cat") flag) (run-cat real-path)
      (peg/match '(choice "-e" "--edit") flag) (run-edit real-path)
      (peg/match '(choice "-w" "--which") flag) (run-which real-path)
      (executable-file? file) (run-script real-path args)
      (run-help real-path))))

# TODO rethink of how i access files, i have a lot of functions opening and
# closing in the interest of isolation, but it would probably be best to just
# have them take text/file-entity instead of a filepath that they open
# themselves
#
# UPDATE: I did end up reworking this, but man do I wish I knew about the
# slurp/spit functions... though, they error when the file doesn't exist/can't
# be reached(or rather, created, in the context of `spit`), so i dont know if i
# want that.

#(handle-command {:path "nix/version" :flag "--new" :arguments ["nix --version"]})

# Expect a c
(defn main 
  [& args] 
  (let [exe-name (first args)
        command (drop 1 args)]
    (handle-command (parse-command ;(hd-tl command)))))
