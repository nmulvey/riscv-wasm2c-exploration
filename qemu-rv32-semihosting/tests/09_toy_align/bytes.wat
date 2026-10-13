(module
  (memory 1)
  (func (export "fill")
    (local $i i32)
    (loop $l
      (i32.store8 (local.get $i)
        (i32.add (i32.mul (local.get $i) (i32.const 37)) (i32.const 11)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br_if $l (i32.lt_u (local.get $i) (i32.const 272)))))
  (func $rd4 (param $p i32) (result i32)
    (i32.or
      (i32.or
        (i32.load8_u (local.get $p))
        (i32.shl (i32.load8_u offset=1 (local.get $p)) (i32.const 8)))
      (i32.or
        (i32.shl (i32.load8_u offset=2 (local.get $p)) (i32.const 16))
        (i32.shl (i32.load8_u offset=3 (local.get $p)) (i32.const 24)))))
  (func (export "sumBytes") (param $off i32) (result i32)
    (local $i i32) (local $s i32) (local $p i32)
    (if (i32.gt_u (local.get $off) (i32.const 16)) (then (return (i32.const 0))))
    (local.set $p (local.get $off))
    (loop $l
      (local.set $s (i32.add (local.get $s) (call $rd4 (local.get $p))))
      (local.set $p (i32.add (local.get $p) (i32.const 4)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br_if $l (i32.lt_u (local.get $i) (i32.const 64))))
    (local.get $s)))
