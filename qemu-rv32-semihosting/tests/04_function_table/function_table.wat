(module
  ;; Function table with 5 functions
  (func $add_one (param $x i32) (result i32)
    (i32.add
      (local.get $x)
      (i32.const 1)
    )
  )
  
  (func $add_ten (param $x i32) (result i32)
    (i32.add
      (local.get $x)
      (i32.const 10)
    )
  )
  
  (func $multiply_two (param $x i32) (result i32)
    (i32.mul
      (local.get $x)
      (i32.const 2)
    )
  )
  
  (func $multiply_three (param $x i32) (result i32)
    (i32.mul
      (local.get $x)
      (i32.const 3)
    )
  )
  
  (func $square (param $x i32) (result i32)
    (i32.mul
      (local.get $x)
      (local.get $x)
    )
  )
  
  ;; Function table: maps indices to functions
  (table 5 funcref)
  (elem (i32.const 0) $add_one $add_ten $multiply_two $multiply_three $square)
  
  ;; Call function by index with bounds checking
  (func $call_by_index (param $index i32) (param $arg i32) (result i32)
    (if (i32.ge_u (local.get $index) (i32.const 5))
      (then
        (return (i32.const 0))
      )
    )
    (call_indirect (type $func_type) (local.get $arg) (local.get $index))
  )
  
  ;; Type signature for functions: (i32) -> i32
  (type $func_type (func (param i32) (result i32)))
  
  ;; Export for testing
  (export "add_one" (func $add_one))
  (export "add_ten" (func $add_ten))
  (export "multiply_two" (func $multiply_two))
  (export "multiply_three" (func $multiply_three))
  (export "square" (func $square))
  (export "call_by_index" (func $call_by_index))
)
