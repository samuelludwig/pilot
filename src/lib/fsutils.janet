(use ./../lib/prelude)

(defn split-filename-and-ext 
  [path]
  (let [is-dotfile? (string/has-prefix? "." path)]
    (if is-dotfile? path (string/split "." path 0 2))))

(defn entity-exists?
  [path]
  (truthy? (os/stat path)))

(def entity-does-not-exist? (complement entity-exists?))

(defn file? [path] 
  (= (os/stat path :mode) :file))

(defn executable-file?
  [path]
  (let [fstats (os/stat path)]
    (and 
      fstats
      (= (fstats :mode) :file)
      (not-nil? (string/find "x" (fstats :permissions))))))

(def not-executable-file? (complement executable-file?))

(defn dir? [path] (= (os/stat path :mode) :directory))

(defn- mkdir-from-path-root
  ``
  Make the directory at path `root/dirname`, and return that path.
  ``
  [root dirname]
  (let [path (string root "/" dirname)]
    (if (dir? path) 
      path 
      (do 
        (os/mkdir path) 
        path))))

(defn- all-but-last
  [ind]
  (take 
    (- (length ind) 1) 
    ind))

(defn- big-hd-tl 
  [ind]
  [(all-but-last ind) (last ind)])

(defn- index-of-last-pattern-occurance
  [str pattern]
  (->> str
       (string/find-all pattern) 
       last))

(defn split-path-into-base-and-child
  [path]
  (let [dir-sep-index (index-of-last-pattern-occurance path "/")]
    (if dir-sep-index 
      (string/split "/" path dir-sep-index) 
      path)))

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
  A safer `slurp` that returns nil when the file isn't readable.
  ``
  [path]
  (when (file? path) (slurp path)))

(defn make-executable 
  ``
  Set permissions of file at the given path to 8r755.
  ``
  [path]
  (when (file? path) 
    (os/chmod path 8r755)))

(defn write-to-file
  ``
  A version of `spit` that will create any parent directories that don't exist
  in the given `path`.
  ``
  [path contents &opt mode]
  (let [[path-root filename] (split-path-into-base-and-child path)]
    (default contents "")
    (do
      (mkdir-p path-root)
      (spit path contents mode))))

(defn mode-of [path] (os/stat path :mode))

(defn- find-pattern
  [pattern]
  (partial find |(peg/match pattern $)))

(defn- nil-or-equals?
  [subject equality-target]
  (or (nil? subject) (= subject equality-target)))

(defn dir-has-child?
  ``
  Check if directory at `path` has a child named `pattern`.
  Can require a given type of child, using a mode that would be
  returned by `os/stat`, i.e., :directory, or :file.
  ``
  [path pattern &opt mode]
  (let [pat (peg/compile pattern)
        is-mode? |(nil-or-equals? mode (mode-of $))
        child ((find-pattern pat) (os/dir path))
        child-path (when child (string path "/" child))]
    (and (truthy? child) (is-mode? child-path))))

(defn create-new-executable-file
  [path &opt contents]
  (do
    (write-to-file path contents)
    (make-executable path)))
