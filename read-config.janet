(defn- keywordize-keys
  [tab]
  (let [[ks vs] [(keys tab) (values tab)]]
    (table 
      ;(interleave 
         (map keyword ks) 
         vs))))

(defn- to-lines
  "Splits a multi-line string into an array of string, one for each line."
  [s]
  (string/split "\n" s))

(defn- parse-key-value
  ``
  Expects a string in the form `<key>=<value>`, returns `["key" "value"]`.
  ``
  [s]
  (->> s 
       (string/split "=")
       (map string/trim))) # NOTE: Should I include whitespace?

(defn- filter-out-malformed-options
  ``
  A proper option tuple looks like `["k" "v"]`.
  For some reason nils cause this function to error, though i feel like they
  should be taken care of by the first check.
  ``
  [opt-arrays]
  (filter 
    (and
      |(indexed? $)
      |(= 2 (length $)) 
      (fn [[x y]] (and (string? x) (string? y)))) 
    opt-arrays))

(defn- filter-out-nils
  [ind]
  (filter |(not (nil? $)) ind))

(defn parse-config-buffer
  ``
  Expected format (for now) is <OPTION>=<value><whitespace><OPTION>=<value>...
  Need to fit matching options into table matching options in config-defaults
  ``
  [config] 
    (->> config 
         (to-lines) 
         (map parse-key-value)
         (filter-out-nils)
         (filter-out-malformed-options)
         (from-pairs)
         (keywordize-keys)))

# Where else could I search for configs? home? Should I source from multiple?
(def config-location 
  (let [xdg-loc (os/getenv "XDG_CONFIG_HOME")]
     (if 
       (nil? xdg-loc) 
       (string (os/getenv "HOME") "/.config/pilot")
       (string xdg-loc "/pilot"))))

(def config-defaults 
  {:script-path (string config-location "/scripts")
   :cat-provider "bat"
   :pilot-editor (or (os/getenv "EDITOR") "vi")
   :copier-integration false})

(def config-buffer 
  (let [file (file/open (string config-location "/config.cfg") :r)
        contents (file/read file :all)]
    (file/close file)
    contents))

(def settings 
  "Settings derived from the config file"
 (if 
   (nil? config-buffer) 
   config-defaults 
   (merge 
     config-defaults 
     (parse-config-buffer config-buffer))))

(def script-path (settings :script-path))

