(import testament :prefix "" :exit true)
(setdyn :args ["help"])
(import ../../src/pilot/core :prefix "" :exit true)

(deftest one-plus-one
  (assert-equal 2 (+ 1 1)
    "1 + 1 = 2"))

(run-tests!)
