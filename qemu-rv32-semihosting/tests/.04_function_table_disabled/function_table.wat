(module
  (func $add (param $a i32) (param $b i32) (result i32)
    (i32.add (local.get $a) (local.get $b))
  )
  
  (func $subtract (param $a i32) (param $b i32) (result i32)
    (i32.sub (local.get $a) (local.get $b))
  )
  
  (func $multiply (param $a i32) (param $b i32) (result i32)
    (i32.mul (local.get $a) (local.get $b))
  )
  
  (type $binary_op (func (param i32 i32) (result i32)))
  
  (table $table 3 funcref)
  (elem (i32.const 0) $add $subtract $multiply)
  
  (func $call_op (param $op_index i32) (param $a i32) (param $b i32) (result i32)
    (call_indirect (type $binary_op)
      (local.get $a)
      (local.get $b)
      (local.get $op_index)
    )
  )
  
  (export "add" (func $add))
  (export "subtract" (func $subtract))
  (export "multiply" (func $multiply))
  (export "call_op" (func $call_op))
)
