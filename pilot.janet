# What I hope to be my personal command line assistant
# A bastardization of ianthehenry/sd

# TODO's
# - For the `script-path` make this actually get a PATH-like path from the
# config and create the logic around all that stuff
# - Add logic for actually accessing/parsing the config file
# - Copier integration for `command-new`, allow different lang templates and
# whatnot

(import /build/json :as json)
(import ./read-config :as conf) #TODO figure out how that works

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

(defn flag? [s] (= (first s) 45)) # 45 is the ASCII code for `-`
(defn file? [fstats] 
  (= (fstats :mode) :file))
(defn dir? [fstats] 
  (= (fstats :mode) :dir))
(defn executable? [fstats] 
  (not 
    (nil? (string/find "x" (fstats :permissions)))))
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
      (nil? remaining-args) (handle-command first-arg)
      (dir? fstats) (parse-command new-path ;rem)
      (flag? first-arg) (error) #TODO
      (and (file? fstats) (executable? fstats)) (handle-command first-arg ;remaining-args)
      (file? fstats) (handle-cat first-arg)
      (handle-help))))


(defn command-help [f])
(defn command-verbatim [f])
(defn command-new [f])
(defn command-edit [f])
(defn command-cat [f])
(defn command-which [f])

(doc take-until)
(defn take-until-pattern [ind pattern]
  (take-until |(string/find pattern $) ind))

(def single-line-comment-styles
  '{:slashes "//"
    :dashes "--"
    :hash "#"})
(def multi-line-comment-styles
  '{:opening-square-digraph "[-"
    :closing-square-digraph "-]"
    :opening-slash-digraph "/*"
    :closing-slash-digraph "*/"
    :main (choice
            (sequence :opening-square-digraph :closing-square-digraph)
            (sequence :opening-slash-digraph :closing-slash-digraph))})

# Expect a c
(defn main 
  [& args] 
  (let [exe-name (first args)
        command (drop 1 args)
        location-args (take-until-pattern command "--")
        flag-args (drop (count location-args) command)]
    (print "args: " ;(interpose ", " (dyn :args)))
    (print (os/cwd))
    (print ;(interpose "\n" (os/dir "/home/dot")))))
