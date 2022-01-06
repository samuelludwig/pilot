# What I hope to be my personal command line assistant
(import /build/json :as json)

(def config-location 
  (let [xdg-loc (os/getenv "XDG_CONFIG")]
     (if 
       (nil? xdg-loc) 
       (string (os/getenv "HOME") "/.config/pilot")
       xdg-loc)))

(defn)

(def settings 
  "Settings derived from the config file"
 (if () () () ) )


(doc "file/")
(def config-file (file/open) )
(file/read "/home/dot/nothing.txt" :all)

# Expect a c
(defn main [& args] 
  (print "args: " ;(interpose ", " (dyn :args)))
  (print (os/cwd))
  (print ;(interpose "\n" (os/dir "/home/dot"))))
