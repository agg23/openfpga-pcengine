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

ld r1,#ext_sgx // populate data slot
test r1,r2
jp z,zero

ld r14,#no_match
jp print_error_and_exit

zero:
ld r14,#match
jp print_error_and_exit

// Error handling
error_handler:
ld r14,#test_err_msg

print_error_and_exit:
printf r14
exit 1

ext_sgx:
db "sgx",0

test_err_msg:
db "Error",0

no_match:
db "No match",0

match:
db "Match",0