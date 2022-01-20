(defn file? [f] 
  (= (os/stat f :mode) :file))

(defn dir? [path] (= (os/stat path :mode) :directory))

(defn- mkdir-from-path-root
  ``
  Make the directory at path `root/dirname`, and return that path
  ``
  [root dirname]
  (let [path (string root "/" dirname)]
    (if (dir-path? path) 
      path 
      (do 
        (os/mkdir path) 
        path))))

(defn mkdir-p
  ``
  An emulation of running `mkdir -p`, i.e., create a directory at `path`, while
  creating any higher-level directories that don't already exist.
  ``
  [path &opt segments]
  (let [path-segments (string/split "/" path)]
    (reduce2 mkdir-from-path-root path-segments)))

(defn read-all
  ``
  A safer `slurp` that returns nil when the file isn't readable
  ``
  [path]
  (when (file? path) (slurp path)))

(defn make-executable 
  ``
  chmod +x a file at the given path
  ``
  [path]
  (when (file? path) 
    (os/chmod path 8r755)))

(defn write-to
  ``
  Given `path`, confirm the file at that location exists, if it does not,
  create it, and create any parent directories that don't already exist.
  ``
  [path contents &opt mode]
  (spit path contents mode))

(defn exists?
  [path]
  (truthy? (os/stat path)))

(defn- not-nil? [x] (not= nil x))

(defn dir-has-child?
  ``
  Check if directory at `path` has a child named `pattern`.
  Can require a given type of child, using a mode that would be
  returned by `os/stat`, i.e., :directory, or :file.
  ``
  [path pattern &opt mode]
  (let [pat (peg/compile pattern)
        is-mode? |(or (nil? mode) (= (os/stat $ :mode) mode))
        child (find |(peg/match pat $) (os/dir path) nil)
        child-path (when child (string path "/" child))]
    (and child (is-mode? child-path))))
