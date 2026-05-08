(module
  (global $counter (mut i32) (i32.const 0))
  
  (func $get_counter (result i32)
    (global.get $counter)
  )
  
  (func $increment_counter
    (global.set $counter 
      (i32.add 
        (global.get $counter)
        (i32.const 1)
      )
    )
  )
  
  (func $set_counter (param $value i32)
    (global.set $counter (local.get $value))
  )
  
  (export "get_counter" (func $get_counter))
  (export "increment_counter" (func $increment_counter))
  (export "set_counter" (func $set_counter))
)
