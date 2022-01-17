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

(def config-file 
  (file/open (string config-location "/config.cfg") :r))

(file/read config-file :all)

(defn parse-config-buffer #TODO
  ``
  Expected format (for now) is <OPTION>=<value><whitespace><OPTION>=<value>...
  Need to fit matching options into table matching options in config-defaults
  ``
  [f] 
  (let [file-contents (file/read f :all) 
        config-opts (->> file-contents 
                        (to-lines) 
                        (map parse-key-value)
                        (filter-out-nils)
                        (filter-out-malformed-options))]
    ))

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
       (map string/trim)))

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

(def settings 
  "Settings derived from the config file"
 (if 
   (nil? config-file) 
   config-defaults 
   (merge 
     config-defaults 
     (parse-config-buffer config-file))))

(def script-path (settings :script-path))

