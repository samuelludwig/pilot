(use ./../lib/prelude)
(import ./../lib/fsutils :as fs)

(defn- keywordize-keys
  [tab]
  (let [[ks vs] [(keys tab) (values tab)]]
    (-> ks
        (|(map keyword $))
        (interleave vs)
        (splice)
        (struct))))

(defn- to-lines
  "Splits a multi-line string into an array of strings, one for each line."
  [s]
  (if s (string/split "\n" s) []))

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
  Need to fit matching options into table matching options in reserve-config-defaults
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
(def resolve-config-location
  |(let [xdg-loc (os/getenv "XDG_CONFIG_HOME")]
     (if
       (nil? xdg-loc)
       (string (os/getenv "HOME") "/.config/pilot")
       (string xdg-loc "/pilot"))))

(def reserve-config-defaults
  |(let [conf-loc (resolve-config-location)]
     {:script-path (string conf-loc "/scripts")
      :template-path (string conf-loc "/templates")
      :cat-provider "bat"
      :pilot-editor (or (os/getenv "VISUAL") (os/getenv "EDITOR") "vi")
      :copier-integration false}))

(def resolve-config-file |(string (resolve-config-location) "/config.cfg"))

(def resolve-settings
  "Settings derived from the config file"
  |(merge
     (reserve-config-defaults)
     (parse-config-buffer (fs/read-all (resolve-config-file)))))

(def script-path (settings :script-path))
