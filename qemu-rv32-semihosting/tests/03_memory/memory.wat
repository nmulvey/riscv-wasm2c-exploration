(module
  (memory $mem 1)
  
  (func $write_byte (param $offset i32) (param $value i32)
    (i32.store8
      (local.get $offset)
      (local.get $value)
    )
  )
  
  (func $read_byte (param $offset i32) (result i32)
    (i32.load8_u
      (local.get $offset)
    )
  )
  
  (func $write_int (param $offset i32) (param $value i32)
    (i32.store
      (local.get $offset)
      (local.get $value)
    )
  )
  
  (func $read_int (param $offset i32) (result i32)
    (i32.load
      (local.get $offset)
    )
  )
  
  (export "write_byte" (func $write_byte))
  (export "read_byte" (func $read_byte))
  (export "write_int" (func $write_int))
  (export "read_int" (func $read_int))
)
