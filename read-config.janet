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

