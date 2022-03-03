(import testament :prefix "" :exit true)
(setdyn :args ["help"])
(import ../../src/pilot/read-config :prefix "" :exit true)

(deftest read-example-config
  (let [expected @{:cat-provider "cat"
                   :copier-integration false
                   :pilot-editor "vscode"
                   :script-path "./examples/config/scripts"
                   :template-path "./examples/config/templates"}]
    (assert-equal expected (resolve-settings "./examples/config" "vscode"))))

(run-tests!)


