# What I hope to be my personal command line assistant
# A bastardization of ianthehenry/sd

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

(import /build/json :as json)
(import ./read-config :as conf) #TODO figure out how that works

# (import ./argparse :as cli-args)
(def settings conf/settings)

(def flag-commands
  {:help ()
   :verbatim ()
   :new ()
   :edit ()
   :cat ()
   :which ()})
#
# First we gather our configs
#

(os/stat (string conf/config-location "/scripts/hello/world.sh"))

(def flag '(choice "-" "--")) # Technically double-hyphen is redundant
(defn flag? [s] (peg/match flag s))
(defn file? [fstats] 
  (= (fstats :mode) :file))
(defn dir? [fstats] 
  (= (fstats :mode) :dir))
(defn executable? [fstats] 
  (not 
    (nil? (string/find "x" (fstats :permissions)))))
(defn executable-file? [fstats] 
  (and (executable? fstats) (file? fstats)))
(defn executable-by-user? [fstats user] 
  # Can add more and confirm that file is executable by the given user by
  # checking the uid, gid, and where the `x`s are in the string
  # <check if belongs to user or users group>
  (not 
    (nil? (string/find "x" (fstats :permissions)))))

(defn hd-tl [x] [(first x) (drop 1 x)])

# The default behavior for `sd foo bar` is:
# 
# - If `~/sd/foo` is an executable file, execute `~/sd/foo bar`.
# - If `~/sd/foo/bar` is an executable file, execute it with no arguments.
# - If `~/sd/foo/bar` is a directory, this is the same is `sd foo bar --help` 
# (see below).
# - If `~/sd/foo/bar` is a non-executable regular file, this is the same is 
# `sd foo bar --cat` (see below).
# 
# There are some special flags that are significant to `sd`. If you supply any
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
        fstats (os/stat first-arg)]
    (cond
      # If there's no remaining arguments, our path is done, handle it
      # according to the logic above
      (nil? remaining-args) {:path first-arg}

      # If the next argument is a flag, we pass our path, the flag, and the
      # remaining arguments to a flag-handling function
      # We will need to search for a --really flag in `arguments` in the
      # flag-handling function
      (flag? next-arg) {:path first-arg :flag next-arg :arguments rem}

      # If our path is an executable file, we want to run it, with the
      # remaining arguments passed to it
      # What happens in the case where we want to define a "new" script that
      # has a parent directory the same name of an executable?
      (executable-file? fstats) {:path first-arg :arguments remaining-args}

      (parse-command new-path ;rem))))

(defn with-default 
  [x default-val] 
  (if (nil? x) default-val x))

(defn handle-command 
  [{:path p :flag f :arguments args}]
  (let [fstats (os/stat p)
        args (with-default args [])
        f (with-default f "") # peg/match errors on nil
        # Get root path from settings and prepend it (do we want logic for
        # multiple possible root PATHs to look at?)
        real-path (string (settings :path) "/" p)]
    (cond
      (peg/match '(choice "-v" "--verbatim") f) (run-script real-path args)
      (peg/match '(choice "-h" "--help") f) (run-help real-path)
      (peg/match '(choice "-n" "--new") f) (run-new real-path args)
      (peg/match '(choice "-c" "--cat") f) (run-cat real-path)
      (peg/match '(choice "-e" "--edit") f) (run-edit real-path)
      (peg/match '(choice "-w" "--which") f) (run-which real-path)
      (executable-file? real-path) (run-script real-path args)
      (run-help real-path))))

# COMMANDS
# [x] run-script
# [ ] run-help
# [x] run-new
# [x] run-edit
# [x] run-cat
# [x] run-which

(defn run-script 
  ``
  If path is an executable file, run it with all the arguments given. If not,
  run help command.
  ``
  [path args]
  (let [fstats (os/stat path)] 
    (if
      (executable-file? fstats) (os/execute [path ;args])
      (run-help path))))

(defn run-cat
  ``
  If path is a file, print it's contents to stdout using `cat-provider`,
  otherwise, run help instead.
  ``
  [path]
  (let [fstats (os/stat path)
        cat-provider (settings :cat-provider)]
    (if (file? fstats) (os/execute [cat-provider path])
      (run-help path))))

(defn run-which
  ``
  If path exists, output `path`. Run help otherwise.
  `` 
  [path]
  (let [fstats (os/stat path :mode)]
    (if (fstats) (os/execute ["echo" path] :p)
      (run-help path))))

(defn run-edit
  ``
  If path exists, open up the file with `EDITOR`. Run help otherwise.
  `` 
  [path]
  (let [fstats (os/stat path :mode)]
    (if (fstats) (os/execute [(settings :pilot-editor) path] :p)
      (run-help path))))

(defn run-new
  ``
  Creates a file at `path` if one does not already exist, loads it with
  <template>, and then runs the edit command. It then chmods the file to be
  executable. 
  If arguments are given, they become the body of the script instead of the
  template, and the script is not opened in the editor.
  `` 
  [path &opt args]
  (let [fstats (os/stat path :mode)
        body-provided? (not-nil-or-empty? args)
        body (if (body-provided?) (string/join args " ") "")
        file-not-exists? (nil? fstats)
        template-path "/home/dot/.config/pilot/templates/bash/default.sh"] #TODO
    (if 
      (file-not-exists?) (create-new-script path template-path body)
      (run-help path))))

(defn run-help
  ``
  TODO
  ``
  [path]
  (print path " " "hello, under construction at the moment, terribly sorry...\n"))

(create-new-script
  [path template-path &opt script-body]
  (let [body-provided? (empty? script-body)]
    (do
      (create-file-from-template path template-path)
      (if 
        (body-provided?) (append-to-file path script-body)
        (run-edit path)))))

(defn- append-to-file
  [path text]
  (file/write (file/open path :a) text))

(not-nil-or-empty? [x] (not (or (nil? x) (empty? x))))

(defn open-in-editor
  [path]
  (os/execute [(settings :pilot-editor) path] :p))

(defn touch-chmod-and-open
  [path]
  (os/open path :c)
  (os/chmod path 8r755)
  (open-in-editor path))

(defn create-new-executable-file
  [path]
  (os/open path :c)
  (os/chmod path 8r755))

(defn create-file-from-template
  [path template-path]
  (let [t (file/open template-path :r)
        template (if (nil? t) :dne (file/read t :all))]
    (create-executable-file-with-contents path template)))

(defn create-executable-file-with-contents
  [path contents]
  (let [f (file/open path)]
    (create-new-executable-file path)
    (copy-to-file f)))

(defn take-until-pattern [ind pattern]
  (take-until |(string/find pattern $) ind))

# Expect a c
(defn main 
  [& args] 
  (let [exe-name (first args)
        command (drop 1 args)
        location-args (take-until-pattern command "-")
        flag-args (drop (count location-args) command)]
    (print "args: " ;(interpose ", " (dyn :args)))
    (print (os/cwd))
    (print ;(interpose "\n" (os/dir "/home/dot")))))
