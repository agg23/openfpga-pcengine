architecture chip32.vm
output "chip32.bin", create

// we will put data into here that we're working on.  It's the last 1K of the 8K chip32 memory
constant rambuf = 0x1b00

constant dataslot = 0

// Host init command
constant host_init = 0x4002

// Error vector (0x0)
jp error_handler

// Init vector (0x2)
// Choose core
ld r1,#dataslot // populate data slot
ld r2,#rambuf // get ram buf position
getext r1,r2

ld r1,#ext_sgx
test r2,r1
jp z, next_1

ld r14,#ext_sgx
jp print_error_and_exit

next_1:
ld r1,#ext_pce
test r2,r1
jp nz, next_2

ld r14,#ext_pce
jp print_error_and_exit

next_2:

// Error handling
error_handler:
ld r14,#test_err_msg
exit 1

print_error_and_exit:
printf r14
exit 1

ext_sgx:
db "sgx",0

ext_pce:
db "pce",0

test_err_msg:
db "Error",0