# What I hope to be my personal command line assistant
# A bastardization of ianthehenry/sd

# TODO's
# - For the `script-path` make this actually get a PATH-like path from the
# config and create the logic around all that stuff
# - Add logic for actually accessing/parsing the config file
# - Copier integration for `command-new`, allow different lang templates and
# whatnot

(import /build/json :as json)

(def config-location 
  (let [xdg-loc (os/getenv "XDG_CONFIG_HOME")]
     (if 
       (nil? xdg-loc) 
       (string (os/getenv "HOME") "/.config/pilot")
       xdg-loc)))

(def config-defaults 
  {:script-path (string config-location "/scripts")
   :cat-provider "bat"
   :pilot-editor (or (os/getenv "EDITOR") "vi")})

(def config-file 
  (file/open config-location :r) )

(defn parse-config-buffer #TODO
  ""
  [x] (file/read x :all))

(def settings 
  "Settings derived from the config file"
 (if 
   (nil? config-file) 
   config-defaults 
   (merge 
     config-defaults 
     (parse-config-buffer config-file))))

(def script-path (settings :script-path))

(defn is-file? [fstats] 
  (= (fstats :mode) :file))
(defn is-dir? [fstats] 
  (= (fstats :mode) :dir))
(defn is-executable? [fstats] 
  # Can add more and confirm that file is executable by the given user by
  # checking the uid, gid, and where the `x`s are in the string
  (not 
    (nil? (string/find "x" (fstats :permissions)))))

(doc file/open)
(doc os/stat)
(doc or)
(file/read "/home/dot/nothing.txt" :all)

(cond
  (is-dir? fstats) (command-help f)
  (and (is-file? fstats) (is-executable? fstats)) (command-exec f script-args)
  (is-file? fstats) (command-cat f))

(defn command-help [f])
(defn command-really [f])
(defn command-new [f])
(defn command-edit [f])
(defn command-cat [f])
(defn command-which [f])

# Expect a c
(defn main 
  [& args] 
  (let [exe-name (first args)
        command (drop 1 args)]
    (print "args: " ;(interpose ", " (dyn :args)))
    (print (os/cwd))
    (print ;(interpose "\n" (os/dir "/home/dot")))))
