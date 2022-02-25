(import testament :prefix "" :exit true)

(deftest one-plus-one
  (is (= 2 (+ 1 1)) "1 + 1 = 2"))

(run-tests!)
